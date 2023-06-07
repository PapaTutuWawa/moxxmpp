import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:moxxmpp/src/events.dart';
import 'package:moxxmpp/src/jid.dart';
import 'package:moxxmpp/src/managers/base.dart';
import 'package:moxxmpp/src/managers/data.dart';
import 'package:moxxmpp/src/managers/handlers.dart';
import 'package:moxxmpp/src/managers/namespaces.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/negotiators/namespaces.dart';
import 'package:moxxmpp/src/stanza.dart';
import 'package:moxxmpp/src/stringxml.dart';
import 'package:moxxmpp/src/xeps/xep_0030/xep_0030.dart';
import 'package:moxxmpp/src/xeps/xep_0297.dart';
import 'package:moxxmpp/src/xeps/xep_0386.dart';

class CarbonsData implements StanzaHandlerExtension {
  const CarbonsData(this.isCarbon);

  /// Indicates whether this message is a carbon.
  final bool isCarbon;
}

/// This manager class implements support for XEP-0280.
class CarbonsManager extends XmppManagerBase {
  CarbonsManager() : super(carbonsManager);

  /// Indicates that message carbons are enabled.
  bool _isEnabled = false;

  /// Indicates that the server supports message carbons.
  bool _supported = false;

  /// Indicates that we know that [CarbonsManager._supported] is accurate.
  bool _gotSupported = false;

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
      getAttributes().getConnectionSettings().serverJid,
      carbonsXmlns,
    );
    _gotSupported = true;
    return _supported;
  }

  @override
  Future<void> onXmppEvent(XmppEvent event) async {
    if (event is StreamNegotiationsDoneEvent) {
      // Reset disco cache info on a new stream
      final newStream = await isNewStream();
      if (newStream) {
        _gotSupported = false;
        _supported = false;
      }
    }
  }

  Future<StanzaHandlerData> _onMessageReceived(
    Stanza message,
    StanzaHandlerData state,
  ) async {
    final from = JID.fromString(message.attributes['from']! as String);
    final received = message.firstTag('received', xmlns: carbonsXmlns)!;
    if (!isCarbonValid(from)) return state..done = true;

    final forwarded = received.firstTag('forwarded', xmlns: forwardedXmlns)!;
    final carbon = unpackForwarded(forwarded);

    return state
      ..extensions.set(const CarbonsData(true))
      ..stanza = carbon;
  }

  Future<StanzaHandlerData> _onMessageSent(
    Stanza message,
    StanzaHandlerData state,
  ) async {
    final from = JID.fromString(message.attributes['from']! as String);
    final sent = message.firstTag('sent', xmlns: carbonsXmlns)!;
    if (!isCarbonValid(from)) return state..done = true;

    final forwarded = sent.firstTag('forwarded', xmlns: forwardedXmlns)!;
    final carbon = unpackForwarded(forwarded);

    return state
      ..extensions.set(const CarbonsData(true))
      ..stanza = carbon;
  }

  /// Send a request to the server, asking it to enable Message Carbons.
  ///
  /// Returns true if carbons were enabled. False, if not.
  Future<bool> enableCarbons() async {
    final attrs = getAttributes();
    final result = (await attrs.sendStanza(
      StanzaDetails(
        Stanza.iq(
          to: attrs.getFullJID().toBare().toString(),
          type: 'set',
          children: [
            XMLNode.xmlns(
              tag: 'enable',
              xmlns: carbonsXmlns,
            )
          ],
        ),
      ),
    ))!;

    if (result.attributes['type'] != 'result') {
      logger.warning('Failed to enable message carbons');

      return false;
    }

    logger.fine('Successfully enabled message carbons');

    _isEnabled = true;
    return true;
  }

  /// Send a request to the server, asking it to disable Message Carbons.
  ///
  /// Returns true if carbons were disabled. False, if not.
  Future<bool> disableCarbons() async {
    final result = (await getAttributes().sendStanza(
      StanzaDetails(
        Stanza.iq(
          type: 'set',
          children: [
            XMLNode.xmlns(
              tag: 'disable',
              xmlns: carbonsXmlns,
            )
          ],
        ),
      ),
    ))!;

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

  @internal
  void setEnabled() {
    _isEnabled = true;
  }

  @internal
  void setDisabled() {
    _isEnabled = false;
  }

  /// Checks if a carbon sent by [senderJid] is valid to prevent vulnerabilities like
  /// the ones listed at https://xmpp.org/extensions/xep-0280.html#security.
  ///
  /// Returns true if the carbon is valid. Returns false if not.
  bool isCarbonValid(JID senderJid) {
    return _isEnabled &&
        getAttributes().getFullJID().bareCompare(
              senderJid,
              ensureBare: true,
            );
  }
}

class CarbonsNegotiator extends Bind2FeatureNegotiator {
  CarbonsNegotiator() : super(0, carbonsXmlns, carbonsNegotiator);

  /// Flag indicating whether we requested to enable carbons inline (true) or not
  /// (false).
  bool _requestedEnablement = false;

  /// Logger
  final Logger _log = Logger('CarbonsNegotiator');

  @override
  Future<void> onBind2Success(XMLNode response) async {
    if (!_requestedEnablement) {
      return;
    }

    final enabled = response.firstTag('enabled', xmlns: carbonsXmlns);
    final cm = attributes.getManagerById<CarbonsManager>(carbonsManager)!;
    if (enabled != null) {
      _log.finest('Successfully enabled Message Carbons inline');
      cm.setEnabled();
    } else {
      _log.warning('Failed to enable Message Carbons inline');
      cm.setDisabled();
    }
  }

  @override
  Future<List<XMLNode>> onBind2FeaturesReceived(
    List<String> bind2Features,
  ) async {
    if (!bind2Features.contains(carbonsXmlns)) {
      return [];
    }

    _requestedEnablement = true;
    return [
      XMLNode.xmlns(
        tag: 'enable',
        xmlns: carbonsXmlns,
      ),
    ];
  }

  @override
  void reset() {
    _requestedEnablement = false;

    super.reset();
  }
}
