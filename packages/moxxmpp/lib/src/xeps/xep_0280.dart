import 'package:meta/meta.dart';
import 'package:moxxmpp/src/connection.dart';
import 'package:moxxmpp/src/events.dart';
import 'package:moxxmpp/src/jid.dart';
import 'package:moxxmpp/src/managers/base.dart';
import 'package:moxxmpp/src/managers/data.dart';
import 'package:moxxmpp/src/managers/handlers.dart';
import 'package:moxxmpp/src/managers/namespaces.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/stanza.dart';
import 'package:moxxmpp/src/stringxml.dart';
import 'package:moxxmpp/src/xeps/xep_0030/xep_0030.dart';
import 'package:moxxmpp/src/xeps/xep_0297.dart';

class CarbonsManager extends XmppManagerBase {
  CarbonsManager() : super();
  bool _isEnabled = false;
  bool _supported = false;
  bool _gotSupported = false;
  
  @override
  String getId() => carbonsManager;

  @override
  String getName() => 'CarbonsManager';

  @override
  List<StanzaHandler> getIncomingPreStanzaHandlers() => [
    StanzaHandler(
      stanzaTag: 'message',
      tagName: 'received',
      tagXmlns: carbonsXmlns,
      callback: _onMessageReceived,
      priority: -98,
    ),
    StanzaHandler(
      stanzaTag: 'message',
      tagName: 'sent',
      tagXmlns: carbonsXmlns,
      callback: _onMessageSent,
      priority: -98,
    )
  ];

  @override
  Future<bool> isSupported() async {
    if (_gotSupported) return _supported;

    // Query the server
    final disco = getAttributes().getManagerById<DiscoManager>(discoManager)!;
    _supported = await disco.supportsFeature(
      getAttributes().getConnectionSettings().jid.toBare(),
      carbonsXmlns,
    );
    _gotSupported = true;
    return _supported;
  }

  @override
  Future<void> onXmppEvent(XmppEvent event) async {
    if (event is ServerDiscoDoneEvent && !_isEnabled) {
      final attrs = getAttributes();

      if (attrs.isFeatureSupported(carbonsXmlns)) {
        logger.finest('Message carbons supported. Enabling...');
        await enableCarbons();
        logger.finest('Message carbons enabled');
      } else {
        logger.info('Message carbons not supported.');
      }
    } else if (event is StreamResumeFailedEvent) {
      _gotSupported = false;
      _supported = false;
    }
  }
  
  Future<StanzaHandlerData> _onMessageReceived(Stanza message, StanzaHandlerData state) async {
    final from = JID.fromString(message.attributes['from']! as String);
    final received = message.firstTag('received', xmlns: carbonsXmlns)!;
    if (!isCarbonValid(from)) return state.copyWith(done: true);

    final forwarded = received.firstTag('forwarded', xmlns: forwardedXmlns)!;
    final carbon = unpackForwarded(forwarded);

    return state.copyWith(
      isCarbon: true,
      stanza: carbon,
    );
  }

  Future<StanzaHandlerData> _onMessageSent(Stanza message, StanzaHandlerData state) async {
    final from = JID.fromString(message.attributes['from']! as String);
    final sent = message.firstTag('sent', xmlns: carbonsXmlns)!;
    if (!isCarbonValid(from)) return state.copyWith(done: true);

    final forwarded = sent.firstTag('forwarded', xmlns: forwardedXmlns)!;
    final carbon = unpackForwarded(forwarded);

    return state.copyWith(
      isCarbon: true,
      stanza: carbon,
    );
  }
  
  Future<bool> enableCarbons() async {
    final result = await getAttributes().sendStanza(
      Stanza.iq(
        type: 'set',
        children: [
          XMLNode.xmlns(
            tag: 'enable',
            xmlns: carbonsXmlns,
          )
        ],
      ),
      addFrom: StanzaFromType.full,
      addId: true,
    );

    if (result.attributes['type'] != 'result') {
      logger.warning('Failed to enable message carbons');

      return false;
    }

    logger.fine('Successfully enabled message carbons');

    _isEnabled = true;
    return true;
  }

  Future<bool> disableCarbons() async {
    final result = await getAttributes().sendStanza(
      Stanza.iq(
        type: 'set',
        children: [
          XMLNode.xmlns(
            tag: 'disable',
            xmlns: carbonsXmlns,
          )
        ],
      ),
      addFrom: StanzaFromType.full,
      addId: true,
    );

    if (result.attributes['type'] != 'result') {
      logger.warning('Failed to disable message carbons');

      return false;
    }

    logger.fine('Successfully disabled message carbons');
    
    _isEnabled = false;
    return true;
  }

  /// True if Message Carbons are enabled. False, if not.
  bool get isEnabled => _isEnabled;
  
  @visibleForTesting
  void forceEnable() {
    _isEnabled = true;
  }
  
  bool isCarbonValid(JID senderJid) {
    return _isEnabled && senderJid == getAttributes().getConnectionSettings().jid.toBare();
  }
}
