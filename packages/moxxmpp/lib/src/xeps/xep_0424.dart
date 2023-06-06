import 'package:moxxmpp/src/managers/base.dart';
import 'package:moxxmpp/src/managers/data.dart';
import 'package:moxxmpp/src/managers/handlers.dart';
import 'package:moxxmpp/src/managers/namespaces.dart';
import 'package:moxxmpp/src/message.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/stanza.dart';
import 'package:moxxmpp/src/stringxml.dart';
import 'package:moxxmpp/src/util/typed_map.dart';

class MessageRetractionData implements StanzaHandlerExtension {
  MessageRetractionData(this.id, this.fallback);

  /// A potential fallback message to set the body to when retracting.
  final String? fallback;

  /// The id of the message that is retracted.
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

  List<XMLNode> _messageSendingCallback(TypedMap<StanzaHandlerExtension> extensions) {
    final data = extensions.get<MessageRetractionData>();
    return data != null
        ? [
            XMLNode.xmlns(
              tag: 'apply-to',
              xmlns: fasteningXmlns,
              attributes: <String, String>{
                'id': data.id,
              },
              children: [
                XMLNode.xmlns(
                  tag: 'retract',
                  xmlns: messageRetractionXmlns,
                ),
              ],
            ),
            if (data.fallback != null)
              XMLNode(
                tag: 'body',
                text: data.fallback,
              ),
            if (data.fallback != null)
              XMLNode.xmlns(
                tag: 'fallback',
                xmlns: fallbackIndicationXmlns,
              ),
          ]
        : [];
  }

  @override
  Future<void> postRegisterCallback() async {
    await super.postRegisterCallback();

    // Register the sending callback
    getAttributes()
        .getManagerById<MessageManager>(messageManager)
        ?.registerMessageSendingCallback(_messageSendingCallback);
  }
}
