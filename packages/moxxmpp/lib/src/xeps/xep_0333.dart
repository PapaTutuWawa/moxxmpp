import 'package:moxxmpp/src/events.dart';
import 'package:moxxmpp/src/jid.dart';
import 'package:moxxmpp/src/managers/base.dart';
import 'package:moxxmpp/src/managers/data.dart';
import 'package:moxxmpp/src/managers/handlers.dart';
import 'package:moxxmpp/src/managers/namespaces.dart';
import 'package:moxxmpp/src/message.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/stanza.dart';
import 'package:moxxmpp/src/stringxml.dart';
import 'package:moxxmpp/src/util/typed_map.dart';

class ChatMarkerData {
  const ChatMarkerData(this.isMarkable);

  /// Indicates whether the message can be replied to with a chat marker.
  final bool isMarkable;
}

XMLNode makeChatMarkerMarkable() {
  return XMLNode.xmlns(
    tag: 'markable',
    xmlns: chatMarkersXmlns,
  );
}

XMLNode makeChatMarker(String tag, String id) {
  assert(
    ['received', 'displayed', 'acknowledged'].contains(tag),
    'Invalid chat marker',
  );
  return XMLNode.xmlns(
    tag: tag,
    xmlns: chatMarkersXmlns,
    attributes: {'id': id},
  );
}

class ChatMarkerManager extends XmppManagerBase {
  ChatMarkerManager() : super(chatMarkerManager);

  @override
  List<String> getDiscoFeatures() => [chatMarkersXmlns];

  @override
  List<StanzaHandler> getIncomingStanzaHandlers() => [
        StanzaHandler(
          stanzaTag: 'message',
          tagXmlns: chatMarkersXmlns,
          callback: _onMessage,
          // Before the message handler
          priority: -99,
        )
      ];

  @override
  Future<bool> isSupported() async => true;

  Future<StanzaHandlerData> _onMessage(
    Stanza message,
    StanzaHandlerData state,
  ) async {
    final marker = message.firstTagByXmlns(chatMarkersXmlns)!;

    // Handle the <markable /> explicitly
    if (marker.tag == 'markable') {
      return state..extensions.set(const ChatMarkerData(true));
    }

    if (!['received', 'displayed', 'acknowledged'].contains(marker.tag)) {
      logger.warning("Unknown message marker '${marker.tag}' found.");
    } else {
      getAttributes().sendEvent(
        ChatMarkerEvent(
          from: JID.fromString(message.from!),
          type: marker.tag,
          id: marker.attributes['id']! as String,
        ),
      );
    }

    return state..done = true;
  }

  // TODO: Implement
  List<XMLNode> _messageSendingCallback(TypedMap extensions) {
    return [];
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
