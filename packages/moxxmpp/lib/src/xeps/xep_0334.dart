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

class MessageProcessingHintData implements StanzaHandlerExtension {
  const MessageProcessingHintData(this.hints);

  /// The attached message processing hints.
  final List<MessageProcessingHint> hints;
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
    final elements = stanza.findTagsByXmlns(messageProcessingHintsXmlns);
    return state
      ..extensions.set(
        MessageProcessingHintData(
          elements
              .map((element) => MessageProcessingHint.fromName(element.tag))
              .toList(),
        ),
      );
  }

  List<XMLNode> _messageSendingCallback(
    TypedMap<StanzaHandlerExtension> extensions,
  ) {
    final data = extensions.get<MessageProcessingHintData>();
    return data != null ? data.hints.map((hint) => hint.toXML()).toList() : [];
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
