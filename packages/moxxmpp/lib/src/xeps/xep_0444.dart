import 'package:moxxmpp/src/managers/base.dart';
import 'package:moxxmpp/src/managers/data.dart';
import 'package:moxxmpp/src/managers/handlers.dart';
import 'package:moxxmpp/src/managers/namespaces.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/stanza.dart';
import 'package:moxxmpp/src/stringxml.dart';
import 'package:moxxmpp/src/util/typed_map.dart';

class MessageReactions {
  const MessageReactions(this.messageId, this.emojis);
  final String messageId;
  final List<String> emojis;

  XMLNode toXML() {
    return XMLNode.xmlns(
      tag: 'reactions',
      xmlns: messageReactionsXmlns,
      attributes: <String, String>{
        'id': messageId,
      },
      children: emojis.map((emoji) {
        return XMLNode(
          tag: 'reaction',
          text: emoji,
        );
      }).toList(),
    );
  }

  static List<XMLNode> messageSendingCallback(TypedMap extensions) {
    final data = extensions.get<MessageReactions>();
    return data != null
        ? [
            data.toXML(),
          ]
        : [];
  }
}

class MessageReactionsManager extends XmppManagerBase {
  MessageReactionsManager() : super(messageReactionsManager);

  @override
  List<String> getDiscoFeatures() => [messageReactionsXmlns];

  @override
  List<StanzaHandler> getIncomingStanzaHandlers() => [
        StanzaHandler(
          stanzaTag: 'message',
          tagName: 'reactions',
          tagXmlns: messageReactionsXmlns,
          callback: _onReactionsReceived,
          // Before the message handler
          priority: -99,
        ),
      ];

  @override
  Future<bool> isSupported() async => true;

  Future<StanzaHandlerData> _onReactionsReceived(
    Stanza message,
    StanzaHandlerData state,
  ) async {
    final reactionsElement =
        message.firstTag('reactions', xmlns: messageReactionsXmlns)!;
    return state
      ..extensions.set(
        MessageReactions(
          reactionsElement.attributes['id']! as String,
          reactionsElement.children
              .where((c) => c.tag == 'reaction')
              .map((c) => c.innerText())
              .toList(),
        ),
      );
  }
}
