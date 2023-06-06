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

enum ChatMarker {
  received,
  displayed,
  acknowledged;

  factory ChatMarker.fromName(String name) {
    switch (name) {
      case 'received':
        return ChatMarker.received;
      case 'displayed':
        return ChatMarker.displayed;
      case 'acknowledged':
        return ChatMarker.acknowledged;
    }

    throw Exception('Invalid chat marker $name');
  }

  XMLNode toXML() {
    String tag;
    switch (this) {
      case ChatMarker.received:
        tag = 'received';
        break;
      case ChatMarker.displayed:
        tag = 'displayed';
        break;
      case ChatMarker.acknowledged:
        tag = 'acknowledged';
        break;
    }

    return XMLNode.xmlns(
      tag: tag,
      xmlns: chatMarkersXmlns,
    );
  }
}

class MarkableData implements StanzaHandlerExtension {
  const MarkableData(this.isMarkable);

  /// Indicates whether the message can be replied to with a chat marker.
  final bool isMarkable;

  XMLNode toXML() {
    assert(isMarkable, '');

    return XMLNode.xmlns(
      tag: 'markable',
      xmlns: chatMarkersXmlns,
    );
  }
}

class ChatMarkerData implements StanzaHandlerExtension {
  const ChatMarkerData(this.marker, this.id);

  /// The actual chat state
  final ChatMarker marker;

  /// The ID the chat marker applies to
  final String id;

  XMLNode toXML() {
    final tag = marker.toXML();
    return XMLNode.xmlns(
      tag: tag.tag,
      xmlns: chatMarkersXmlns,
      attributes: {
        'id': id,
      },
    );
  }
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
    final element = message.firstTagByXmlns(chatMarkersXmlns)!;

    // Handle the <markable /> explicitly
    if (element.tag == 'markable') {
      return state..extensions.set(const MarkableData(true));
    }

    try {
      getAttributes().sendEvent(
        ChatMarkerEvent(
          JID.fromString(message.from!),
          ChatMarker.fromName(element.tag),
          element.attributes['id']! as String,
        ),
      );
    } catch (_) {
      logger.warning("Unknown message marker '${element.tag}' found.");
    }

    return state..done = true;
  }

  List<XMLNode> _messageSendingCallback(
    TypedMap<StanzaHandlerExtension> extensions,
  ) {
    final children = List<XMLNode>.empty(growable: true);
    final marker = extensions.get<ChatMarkerData>();
    if (marker != null) {
      children.add(marker.toXML());
    }

    final markable = extensions.get<MarkableData>();
    if (markable != null) {
      children.add(markable.toXML());
    }

    return children;
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
