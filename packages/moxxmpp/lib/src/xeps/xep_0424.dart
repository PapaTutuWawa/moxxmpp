import 'package:moxxmpp/src/managers/base.dart';
import 'package:moxxmpp/src/managers/data.dart';
import 'package:moxxmpp/src/managers/handlers.dart';
import 'package:moxxmpp/src/managers/namespaces.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/stanza.dart';

class MessageRetractionData {
  MessageRetractionData(this.id, this.fallback);
  final String? fallback;
  final String id;
}

class MessageRetractionManager extends XmppManagerBase {
  MessageRetractionManager() : super(messageRetractionManager);

  @override
  List<String> getDiscoFeatures() => [messageRetractionXmlns];

  @override
  List<StanzaHandler> getIncomingStanzaHandlers() => [
        StanzaHandler(
          stanzaTag: 'message',
          callback: _onMessage,
          // Before the MessageManager
          priority: -99,
        )
      ];

  @override
  Future<bool> isSupported() async => true;

  Future<StanzaHandlerData> _onMessage(
    Stanza message,
    StanzaHandlerData state,
  ) async {
    final applyTo = message.firstTag('apply-to', xmlns: fasteningXmlns);
    if (applyTo == null) {
      return state;
    }

    final retract = applyTo.firstTag('retract', xmlns: messageRetractionXmlns);
    if (retract == null) {
      return state;
    }

    final isFallbackBody =
        message.firstTag('fallback', xmlns: fallbackIndicationXmlns) != null;

    return state
      ..extensions.set(
        MessageRetractionData(
          applyTo.attributes['id']! as String,
          isFallbackBody ? message.firstTag('body')?.innerText() : null,
        ),
      );
  }
}
