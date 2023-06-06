import 'package:moxxmpp/src/managers/base.dart';
import 'package:moxxmpp/src/managers/data.dart';
import 'package:moxxmpp/src/managers/handlers.dart';
import 'package:moxxmpp/src/managers/namespaces.dart';
import 'package:moxxmpp/src/message.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/stanza.dart';
import 'package:moxxmpp/src/stringxml.dart';
import 'package:moxxmpp/src/util/typed_map.dart';

enum ChatState implements StanzaHandlerExtension {
  active,
  composing,
  paused,
  inactive,
  gone;

  factory ChatState.fromName(String state) {
    switch (state) {
      case 'active':
        return ChatState.active;
      case 'composing':
        return ChatState.composing;
      case 'paused':
        return ChatState.paused;
      case 'inactive':
        return ChatState.inactive;
      case 'gone':
        return ChatState.gone;
    }

    throw Exception('Invalid chat state $state');
  }

  @override
  String toString() {
    switch (this) {
      case ChatState.active:
        return 'active';
      case ChatState.composing:
        return 'composing';
      case ChatState.paused:
        return 'paused';
      case ChatState.inactive:
        return 'inactive';
      case ChatState.gone:
        return 'gone';
    }
  }

  XMLNode toXML() {
    return XMLNode.xmlns(
      tag: toString(),
      xmlns: chatStateXmlns,
    );
  }
}

class ChatStateManager extends XmppManagerBase {
  ChatStateManager() : super(chatStateManager);

  @override
  List<String> getDiscoFeatures() => [chatStateXmlns];

  @override
  List<StanzaHandler> getIncomingStanzaHandlers() => [
        StanzaHandler(
          stanzaTag: 'message',
          tagXmlns: chatStateXmlns,
          callback: _onChatStateReceived,
          // Before the message handler
          priority: -99,
        )
      ];

  @override
  Future<bool> isSupported() async => true;

  Future<StanzaHandlerData> _onChatStateReceived(
    Stanza message,
    StanzaHandlerData state,
  ) async {
    final element = state.stanza.firstTagByXmlns(chatStateXmlns)!;

    try {
      state.extensions.set(ChatState.fromName(element.tag));
    } catch (_) {
      logger.finest('Ignoring invalid chat state ${element.tag}'); 
    }

    return state;
  }

  /// Send a chat state notification to [to]. You can specify the type attribute
  /// of the message with [messageType].
  Future<void> sendChatState(
    ChatState state,
    String to, {
    String messageType = 'chat',
  }) async {
    await getAttributes().sendStanza(
      StanzaDetails(
        Stanza.message(
          to: to,
          type: messageType,
          children: [
            XMLNode.xmlns(tag: state.toString(), xmlns: chatStateXmlns),
          ],
        ),
        awaitable: false,
      ),
    );
  }

  List<XMLNode> _messageSendingCallback(TypedMap<StanzaHandlerExtension> extensions) {
    final data = extensions.get<ChatState>();
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
