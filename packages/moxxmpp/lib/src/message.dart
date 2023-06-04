import 'package:moxlib/moxlib.dart';
import 'package:moxxmpp/src/events.dart';
import 'package:moxxmpp/src/jid.dart';
import 'package:moxxmpp/src/managers/base.dart';
import 'package:moxxmpp/src/managers/data.dart';
import 'package:moxxmpp/src/managers/handlers.dart';
import 'package:moxxmpp/src/managers/namespaces.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/stanza.dart';
import 'package:moxxmpp/src/stringxml.dart';
import 'package:moxxmpp/src/xeps/staging/file_upload_notification.dart';
import 'package:moxxmpp/src/xeps/xep_0066.dart';
import 'package:moxxmpp/src/xeps/xep_0085.dart';
import 'package:moxxmpp/src/xeps/xep_0184.dart';
import 'package:moxxmpp/src/xeps/xep_0280.dart';
import 'package:moxxmpp/src/xeps/xep_0308.dart';
import 'package:moxxmpp/src/xeps/xep_0333.dart';
import 'package:moxxmpp/src/xeps/xep_0334.dart';
import 'package:moxxmpp/src/xeps/xep_0359.dart';
import 'package:moxxmpp/src/xeps/xep_0385.dart';
import 'package:moxxmpp/src/xeps/xep_0424.dart';
import 'package:moxxmpp/src/xeps/xep_0444.dart';
import 'package:moxxmpp/src/xeps/xep_0446.dart';
import 'package:moxxmpp/src/xeps/xep_0447.dart';
import 'package:moxxmpp/src/xeps/xep_0448.dart';
import 'package:moxxmpp/src/xeps/xep_0449.dart';
import 'package:moxxmpp/src/xeps/xep_0461.dart';

/// Data used to build a message stanza.
///
/// [setOOBFallbackBody] indicates, when using SFS, whether a OOB fallback should be
/// added. This is recommended when sharing files but may cause issues when the message
/// stanza should include a SFS element without any fallbacks.
class MessageDetails {
  const MessageDetails({
    required this.to,
    this.body,
    this.requestDeliveryReceipt = false,
    this.requestChatMarkers = true,
    this.id,
    this.originId,
    this.quoteBody,
    this.quoteId,
    this.quoteFrom,
    this.chatState,
    this.sfs,
    this.fun,
    this.funReplacement,
    this.funCancellation,
    this.shouldEncrypt = false,
    this.messageRetraction,
    this.lastMessageCorrectionId,
    this.messageReactions,
    this.messageProcessingHints,
    this.stickerPackId,
    this.setOOBFallbackBody = true,
  });
  final String to;
  final String? body;
  final bool requestDeliveryReceipt;
  final bool requestChatMarkers;
  final String? id;
  final String? originId;
  final String? quoteBody;
  final String? quoteId;
  final String? quoteFrom;
  final ChatState? chatState;
  final StatelessFileSharingData? sfs;
  final FileMetadataData? fun;
  final String? funReplacement;
  final String? funCancellation;
  final bool shouldEncrypt;
  final MessageRetractionData? messageRetraction;
  final String? lastMessageCorrectionId;
  final MessageReactions? messageReactions;
  final String? stickerPackId;
  final List<MessageProcessingHint>? messageProcessingHints;
  final bool setOOBFallbackBody;
}

class MessageManager extends XmppManagerBase {
  MessageManager() : super(messageManager);

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

  /// Send a message to to with the content body. If deliveryRequest is true, then
  /// the message will also request a delivery receipt from the receiver.
  /// If id is non-null, then it will be the id of the message stanza.
  /// element to this id. If originId is non-null, then it will create an "origin-id"
  /// child in the message stanza and set its id to originId.
  Future<void> sendMessage(MessageDetails details) async {
    assert(
      implies(
        details.quoteBody != null,
        details.quoteFrom != null && details.quoteId != null,
      ),
      'When quoting a message, then quoteFrom and quoteId must also be non-null',
    );

    final stanza = Stanza.message(
      to: details.to,
      type: 'chat',
      id: details.id,
      children: [],
    );

    if (details.quoteBody != null) {
      final quote = QuoteData.fromBodies(details.quoteBody!, details.body!);

      stanza
        ..addChild(
          XMLNode(tag: 'body', text: quote.body),
        )
        ..addChild(
          XMLNode.xmlns(
            tag: 'reply',
            xmlns: replyXmlns,
            attributes: {'to': details.quoteFrom!, 'id': details.quoteId!},
          ),
        )
        ..addChild(
          XMLNode.xmlns(
            tag: 'fallback',
            xmlns: fallbackXmlns,
            attributes: {'for': replyXmlns},
            children: [
              XMLNode(
                tag: 'body',
                attributes: <String, String>{
                  'start': '0',
                  'end': '${quote.fallbackLength}',
                },
              )
            ],
          ),
        );
    } else {
      var body = details.body;
      if (details.sfs != null && details.setOOBFallbackBody) {
        // TODO(Unknown): Maybe find a better solution
        final firstSource = details.sfs!.sources.first;
        if (firstSource is StatelessFileSharingUrlSource) {
          body = firstSource.url;
        } else if (firstSource is StatelessFileSharingEncryptedSource) {
          body = firstSource.source.url;
        }
      } else if (details.messageRetraction?.fallback != null) {
        body = details.messageRetraction!.fallback;
      }

      if (body != null) {
        stanza.addChild(
          XMLNode(tag: 'body', text: body),
        );
      }
    }

    if (details.requestDeliveryReceipt) {
      stanza.addChild(makeMessageDeliveryRequest());
    }
    if (details.requestChatMarkers) {
      stanza.addChild(makeChatMarkerMarkable());
    }
    if (details.originId != null) {
      stanza.addChild(StableIdData(details.originId, null).toOriginIdElement());
    }

    if (details.sfs != null) {
      stanza.addChild(details.sfs!.toXML());

      final source = details.sfs!.sources.first;
      if (source is StatelessFileSharingUrlSource &&
          details.setOOBFallbackBody) {
        // SFS recommends OOB as a fallback
        stanza.addChild(OOBData(source.url, null).toXML());
      }
    }

    if (details.chatState != null) {
      stanza.addChild(
        details.chatState!.toXML(),
      );
    }

    if (details.fun != null) {
      stanza.addChild(
        XMLNode.xmlns(
          tag: 'file-upload',
          xmlns: fileUploadNotificationXmlns,
          children: [
            details.fun!.toXML(),
          ],
        ),
      );
    }

    if (details.funReplacement != null) {
      stanza.addChild(
        XMLNode.xmlns(
          tag: 'replaces',
          xmlns: fileUploadNotificationXmlns,
          attributes: <String, String>{
            'id': details.funReplacement!,
          },
        ),
      );
    }

    if (details.messageRetraction != null) {
      stanza.addChild(
        XMLNode.xmlns(
          tag: 'apply-to',
          xmlns: fasteningXmlns,
          attributes: <String, String>{
            'id': details.messageRetraction!.id,
          },
          children: [
            XMLNode.xmlns(
              tag: 'retract',
              xmlns: messageRetractionXmlns,
            ),
          ],
        ),
      );

      if (details.messageRetraction!.fallback != null) {
        stanza.addChild(
          XMLNode.xmlns(
            tag: 'fallback',
            xmlns: fallbackIndicationXmlns,
          ),
        );
      }
    }

    if (details.lastMessageCorrectionId != null) {
      stanza.addChild(
        LastMessageCorrectionData(
          details.lastMessageCorrectionId!,
        ).toXML(),
      );
    }

    if (details.messageReactions != null) {
      stanza.addChild(details.messageReactions!.toXml());
    }

    if (details.messageProcessingHints != null) {
      for (final hint in details.messageProcessingHints!) {
        stanza.addChild(hint.toXML());
      }
    }

    if (details.stickerPackId != null) {
      stanza.addChild(
        XMLNode.xmlns(
          tag: 'sticker',
          xmlns: stickersXmlns,
          attributes: {
            'pack': details.stickerPackId!,
          },
        ),
      );
    }

    await getAttributes().sendStanza(
      StanzaDetails(
        stanza,
        awaitable: false,
      ),
    );
  }
}
