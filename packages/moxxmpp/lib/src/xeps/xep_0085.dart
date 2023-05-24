import 'package:moxxmpp/src/managers/base.dart';
import 'package:moxxmpp/src/managers/data.dart';
import 'package:moxxmpp/src/managers/handlers.dart';
import 'package:moxxmpp/src/managers/namespaces.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/stanza.dart';
import 'package:moxxmpp/src/stringxml.dart';

enum ChatState { active, composing, paused, inactive, gone }

ChatState chatStateFromString(String raw) {
  switch (raw) {
    case 'active':
      {
        return ChatState.active;
      }
    case 'composing':
      {
        return ChatState.composing;
      }
    case 'paused':
      {
        return ChatState.paused;
      }
    case 'inactive':
      {
        return ChatState.inactive;
      }
    case 'gone':
      {
        return ChatState.gone;
      }
    default:
      {
        return ChatState.gone;
      }
  }
}

String chatStateToString(ChatState state) => state.toString().split('.').last;

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
    ChatState? chatState;

    switch (element.tag) {
      case 'active':
        {
          chatState = ChatState.active;
        }
        break;
      case 'composing':
        {
          chatState = ChatState.composing;
        }
        break;
      case 'paused':
        {
          chatState = ChatState.paused;
        }
        break;
      case 'inactive':
        {
          chatState = ChatState.inactive;
        }
        break;
      case 'gone':
        {
          chatState = ChatState.gone;
        }
        break;
      default:
        {
          logger.warning("Received invalid chat state '${element.tag}'");
        }
    }

    return state.copyWith(chatState: chatState);
  }

  /// Send a chat state notification to [to]. You can specify the type attribute
  /// of the message with [messageType].
  void sendChatState(
    ChatState state,
    String to, {
    String messageType = 'chat',
  }) {
    final tagName = state.toString().split('.').last;

    getAttributes().sendStanza(
      StanzaDetails(
        Stanza.message(
          to: to,
          type: messageType,
          children: [
            XMLNode.xmlns(tag: tagName, xmlns: chatStateXmlns),
          ],
        ),
      ),
    );
  }
}
