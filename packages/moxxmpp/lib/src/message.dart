import 'package:collection/collection.dart';
import 'package:moxxmpp/src/events.dart';
import 'package:moxxmpp/src/jid.dart';
import 'package:moxxmpp/src/managers/base.dart';
import 'package:moxxmpp/src/managers/data.dart';
import 'package:moxxmpp/src/managers/handlers.dart';
import 'package:moxxmpp/src/managers/namespaces.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/stanza.dart';
import 'package:moxxmpp/src/stringxml.dart';
import 'package:moxxmpp/src/util/typed_map.dart';
import 'package:moxxmpp/src/xeps/staging/file_upload_notification.dart';
import 'package:moxxmpp/src/xeps/xep_0066.dart';
import 'package:moxxmpp/src/xeps/xep_0085.dart';
import 'package:moxxmpp/src/xeps/xep_0184.dart';
import 'package:moxxmpp/src/xeps/xep_0280.dart';
import 'package:moxxmpp/src/xeps/xep_0333.dart';
import 'package:moxxmpp/src/xeps/xep_0334.dart';
import 'package:moxxmpp/src/xeps/xep_0359.dart';
import 'package:moxxmpp/src/xeps/xep_0385.dart';
import 'package:moxxmpp/src/xeps/xep_0424.dart';
import 'package:moxxmpp/src/xeps/xep_0444.dart';
import 'package:moxxmpp/src/xeps/xep_0447.dart';
import 'package:moxxmpp/src/xeps/xep_0449.dart';
import 'package:moxxmpp/src/xeps/xep_0461.dart';

/// A callback that is called whenever a message is sent using
/// [MessageManager.sendMessage]. The input the typed map that is passed to
/// sendMessage.
typedef MessageSendingCallback = List<XMLNode> Function(TypedMap);

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
    final message = state.stanza;
    final body = message.firstTag('body');

    final hints = List<MessageProcessingHint>.empty(growable: true);
    for (final element
        in message.findTagsByXmlns(messageProcessingHintsXmlns)) {
      hints.add(MessageProcessingHint.fromName(element.tag));
    }

    getAttributes().sendEvent(
      MessageEvent(
        body: body != null ? body.innerText() : '',
        fromJid: JID.fromString(message.attributes['from']! as String),
        toJid: JID.fromString(message.attributes['to']! as String),
        sid: message.attributes['id']! as String,
        originId: state.extensions.get<StableIdData>()?.originId,
        stanzaIds: state.extensions.get<StableIdData>()?.stanzaIds,
        isCarbon: state.extensions.get<CarbonsData>()?.isCarbon ?? false,
        deliveryReceiptRequested: state.extensions
                .get<MessageDeliveryReceiptData>()
                ?.receiptRequested ??
            false,
        isMarkable: state.extensions.get<ChatMarkerData>()?.isMarkable ?? false,
        type: message.attributes['type'] as String?,
        oob: state.extensions.get<OOBData>(),
        sfs: state.extensions.get<StatelessFileSharingData>(),
        sims: state.extensions.get<StatelessMediaSharingData>(),
        reply: state.extensions.get<ReplyData>(),
        chatState: state.extensions.get<ChatState>(),
        fun: state.extensions.get<FileUploadNotificationData>()?.metadata,
        funReplacement:
            state.extensions.get<FileUploadNotificationReplacementData>()?.id,
        funCancellation:
            state.extensions.get<FileUploadNotificationCancellationData>()?.id,
        encrypted: state.encrypted,
        messageRetraction: state.extensions.get<MessageRetractionData>(),
        messageCorrectionId: state.extensions.get<MessageRetractionData>()?.id,
        messageReactions: state.extensions.get<MessageReactions>(),
        messageProcessingHints: hints.isEmpty ? null : hints,
        stickerPackId: state.extensions.get<StickersData>()?.stickerPackId,
        other: {},
        error: StanzaError.fromStanza(message),
      ),
    );

    return state..done = true;
  }

  /// Send an unawaitable message to [to]. [extensions] is a typed map that contains
  /// data for building the message.
  Future<void> sendMessage(JID to, TypedMap extensions) async {
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

  List<XMLNode> _messageSendingCallback(TypedMap extensions) {
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
