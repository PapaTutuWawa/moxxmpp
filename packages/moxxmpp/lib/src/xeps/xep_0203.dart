import 'package:meta/meta.dart';
import 'package:moxxmpp/src/jid.dart';
import 'package:moxxmpp/src/managers/base.dart';
import 'package:moxxmpp/src/managers/data.dart';
import 'package:moxxmpp/src/managers/handlers.dart';
import 'package:moxxmpp/src/managers/namespaces.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/stanza.dart';

@immutable
class DelayedDeliveryData implements StanzaHandlerExtension {
  const DelayedDeliveryData(this.from, this.timestamp);

  /// The timestamp the message was originally sent.
  final DateTime timestamp;

  /// The JID that originally sent the message.
  final JID from;
}

class DelayedDeliveryManager extends XmppManagerBase {
  DelayedDeliveryManager() : super(delayedDeliveryManager);

  @override
  Future<bool> isSupported() async => true;

  @override
  List<StanzaHandler> getIncomingStanzaHandlers() => [
        StanzaHandler(
          stanzaTag: 'message',
          tagName: 'delay',
          tagXmlns: delayedDeliveryXmlns,
          callback: _onIncomingMessage,
          priority: 200,
        ),
      ];

  Future<StanzaHandlerData> _onIncomingMessage(
    Stanza stanza,
    StanzaHandlerData state,
  ) async {
    final delay = stanza.firstTag('delay', xmlns: delayedDeliveryXmlns)!;

    return state
      ..extensions.set(
        DelayedDeliveryData(
          JID.fromString(delay.attributes['from']! as String),
          DateTime.parse(delay.attributes['stamp']! as String),
        ),
      );
  }
}
