import 'package:moxxmpp/src/managers/base.dart';
import 'package:moxxmpp/src/managers/data.dart';
import 'package:moxxmpp/src/managers/handlers.dart';
import 'package:moxxmpp/src/managers/namespaces.dart';
import 'package:moxxmpp/src/message.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/stanza.dart';
import 'package:moxxmpp/src/stringxml.dart';
import 'package:moxxmpp/src/util/typed_map.dart';

enum MessageProcessingHint {
  noPermanentStore,
  noStore,
  noCopies,
  store;

  factory MessageProcessingHint.fromName(String name) {
    switch (name) {
      case 'no-permanent-store':
        return MessageProcessingHint.noPermanentStore;
      case 'no-store':
        return MessageProcessingHint.noStore;
      case 'no-copy':
        return MessageProcessingHint.noCopies;
      case 'store':
        return MessageProcessingHint.store;
    }

    assert(false, 'Invalid Message Processing Hint: $name');
    return MessageProcessingHint.noStore;
  }

  XMLNode toXML() {
    String tag;
    switch (this) {
      case MessageProcessingHint.noPermanentStore:
        tag = 'no-permanent-store';
        break;
      case MessageProcessingHint.noStore:
        tag = 'no-store';
        break;
      case MessageProcessingHint.noCopies:
        tag = 'no-copy';
        break;
      case MessageProcessingHint.store:
        tag = 'store';
        break;
    }

    return XMLNode.xmlns(
      tag: tag,
      xmlns: messageProcessingHintsXmlns,
    );
  }
}

class MessageProcessingHintManager extends XmppManagerBase {
  MessageProcessingHintManager() : super(messageProcessingHintManager);

  @override
  Future<bool> isSupported() async => true;

  @override
  List<StanzaHandler> getIncomingStanzaHandlers() => [
        StanzaHandler(
          stanzaTag: 'message',
          tagXmlns: messageProcessingHintsXmlns,
          callback: _onMessage,
          // Before the message handler
          priority: -99,
        ),
      ];

  // TODO: Test
  Future<StanzaHandlerData> _onMessage(
    Stanza stanza,
    StanzaHandlerData state,
  ) async {
    // TODO(Unknown): Do we need to consider multiple hints?
    final element = stanza.findTagsByXmlns(messageProcessingHintsXmlns).first;
    return state..extensions.set(MessageProcessingHint.fromName(element.tag));
  }

  List<XMLNode> _messageSendingCallback(TypedMap extensions) {
    // TODO(Unknown): Do we need to consider multiple hints?
    final data = extensions.get<MessageProcessingHint>();
    return data != null
        ? [
            data.toXML(),
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
