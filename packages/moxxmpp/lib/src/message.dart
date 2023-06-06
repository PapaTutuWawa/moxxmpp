import 'package:collection/collection.dart';
import 'package:moxxmpp/src/events.dart';
import 'package:moxxmpp/src/jid.dart';
import 'package:moxxmpp/src/managers/base.dart';
import 'package:moxxmpp/src/managers/data.dart';
import 'package:moxxmpp/src/managers/handlers.dart';
import 'package:moxxmpp/src/managers/namespaces.dart';
import 'package:moxxmpp/src/stanza.dart';
import 'package:moxxmpp/src/stringxml.dart';
import 'package:moxxmpp/src/util/typed_map.dart';
import 'package:moxxmpp/src/xeps/xep_0066.dart';
import 'package:moxxmpp/src/xeps/xep_0447.dart';
import 'package:moxxmpp/src/xeps/xep_0449.dart';
import 'package:moxxmpp/src/xeps/xep_0461.dart';

/// A callback that is called whenever a message is sent using
/// [MessageManager.sendMessage]. The input the typed map that is passed to
/// sendMessage.
typedef MessageSendingCallback = List<XMLNode> Function(
  TypedMap<StanzaHandlerExtension>,
);

/// The raw content of the <body /> element.
class MessageBodyData {
  const MessageBodyData(this.body);

  /// The content of the <body /> element.
  final String? body;

  XMLNode toXML() {
    return XMLNode(
      tag: 'body',
      text: body,
    );
  }
}

/// The id attribute of the message stanza.
class MessageIdData {
  const MessageIdData(this.id);

  /// The id attribute of the stanza.
  final String id;
}

class MessageManager extends XmppManagerBase {
  MessageManager() : super(messageManager);

  /// A list of callbacks that are called when a message is sent in order to add
  /// appropriate child elements.
  final List<MessageSendingCallback> _messageSendingCallbacks =
      List<MessageSendingCallback>.empty(growable: true);

  void registerMessageSendingCallback(MessageSendingCallback callback) {
    _messageSendingCallbacks.add(callback);
  }

  @override
  List<StanzaHandler> getIncomingStanzaHandlers() => [
        StanzaHandler(
          stanzaTag: 'message',
          callback: _onMessage,
          priority: -100,
        )
      ];

  @override
  Future<bool> isSupported() async => true;

  Future<StanzaHandlerData> _onMessage(
    Stanza _,
    StanzaHandlerData state,
  ) async {
    getAttributes().sendEvent(
      MessageEvent(
        JID.fromString(state.stanza.attributes['from']! as String),
        JID.fromString(state.stanza.attributes['to']! as String),
        state.stanza.attributes['id']! as String,
        state.extensions,
        type: state.stanza.attributes['type'] as String?,
        error: StanzaError.fromStanza(state.stanza),
      ),
    );

    return state..done = true;
  }

  /// Send an unawaitable message to [to]. [extensions] is a typed map that contains
  /// data for building the message.
  Future<void> sendMessage(
    JID to,
    TypedMap<StanzaHandlerExtension> extensions,
  ) async {
    await getAttributes().sendStanza(
      StanzaDetails(
        Stanza.message(
          to: to.toString(),
          id: extensions.get<MessageIdData>()?.id,
          type: 'chat',
          children: _messageSendingCallbacks
              .map((c) => c(extensions))
              .flattened
              .toList(),
        ),
        awaitable: false,
      ),
    );
  }

  List<XMLNode> _messageSendingCallback(
    TypedMap<StanzaHandlerExtension> extensions,
  ) {
    if (extensions.get<ReplyData>() != null) {
      return [];
    }
    if (extensions.get<StickersData>() != null) {
      return [];
    }
    if (extensions.get<StatelessFileSharingData>() != null) {
      return [];
    }
    if (extensions.get<OOBData>() != null) {
      return [];
    }

    final data = extensions.get<MessageBodyData>();
    return data != null ? [data.toXML()] : [];
  }

  @override
  Future<void> postRegisterCallback() async {
    await super.postRegisterCallback();

    // Register the sending callback
    registerMessageSendingCallback(_messageSendingCallback);
  }
}
