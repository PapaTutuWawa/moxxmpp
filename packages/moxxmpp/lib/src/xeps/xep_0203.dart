import 'package:meta/meta.dart';
import 'package:moxxmpp/src/managers/base.dart';
import 'package:moxxmpp/src/managers/data.dart';
import 'package:moxxmpp/src/managers/handlers.dart';
import 'package:moxxmpp/src/managers/namespaces.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/stanza.dart';

@immutable
class DelayedDelivery {
  const DelayedDelivery(this.from, this.timestamp);
  final DateTime timestamp;
  final String from;
}

class DelayedDeliveryManager extends XmppManagerBase {
  DelayedDeliveryManager() : super(delayedDeliveryManager);

  @override
  Future<bool> isSupported() async => true;

  @override
  List<StanzaHandler> getIncomingStanzaHandlers() => [
    StanzaHandler(
      stanzaTag: 'message',
      callback: _onIncomingMessage,
      priority: 200,
    ),
  ];

  Future<StanzaHandlerData> _onIncomingMessage(Stanza stanza, StanzaHandlerData state) async {
    final delay = stanza.firstTag('delay', xmlns: delayedDeliveryXmlns);
    if (delay == null) return state;

    return state.copyWith(
      delayedDelivery: DelayedDelivery(
        delay.attributes['from']! as String,
        DateTime.parse(delay.attributes['stamp']! as String),
      ),
    );
  }
}
