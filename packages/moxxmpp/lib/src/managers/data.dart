import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:moxxmpp/src/stanza.dart';
import 'package:moxxmpp/src/xeps/xep_0066.dart';
import 'package:moxxmpp/src/xeps/xep_0085.dart';
import 'package:moxxmpp/src/xeps/xep_0203.dart';
import 'package:moxxmpp/src/xeps/xep_0359.dart';
import 'package:moxxmpp/src/xeps/xep_0380.dart';
import 'package:moxxmpp/src/xeps/xep_0385.dart';
import 'package:moxxmpp/src/xeps/xep_0424.dart';
import 'package:moxxmpp/src/xeps/xep_0444.dart';
import 'package:moxxmpp/src/xeps/xep_0446.dart';
import 'package:moxxmpp/src/xeps/xep_0447.dart';
import 'package:moxxmpp/src/xeps/xep_0461.dart';

part 'data.freezed.dart';

@freezed
class StanzaHandlerData with _$StanzaHandlerData {
  factory StanzaHandlerData(
    // Indicates to the runner that processing is now done. This means that all
    // pre-processing is done and no other handlers should be consulted.
    bool done,
    // Indicates to the runner that processing is to be cancelled and no further handlers
    // should run. The stanza also will not be sent.
    bool cancel,
    // The reason why we cancelled the processing and sending
    dynamic cancelReason,
    // The stanza that is being dealt with. SHOULD NOT be overwritten, unless it is absolutely
    // necessary, e.g. with Message Carbons or OMEMO
    Stanza stanza,
    {
      // Whether the stanza is retransmitted. Only useful in the context of outgoing
      // stanza handlers. MUST NOT be overwritten.
      @Default(false) bool retransmitted,
      StatelessMediaSharingData? sims,
      StatelessFileSharingData? sfs,
      OOBData? oob,
      StableStanzaId? stableId,
      ReplyData? reply,
      ChatState? chatState,
      @Default(false) bool isCarbon,
      @Default(false) bool deliveryReceiptRequested,
      @Default(false) bool isMarkable,
      // File Upload Notifications
      // A notification
      FileMetadataData? fun,
      // The stanza id this replaces
      String? funReplacement,
      // The stanza id this cancels
      String? funCancellation,
      // Whether the stanza was received encrypted
      @Default(false) bool encrypted,
      // The stated type of encryption used, if any was used
      ExplicitEncryptionType? encryptionType,
      // Delayed Delivery
      DelayedDelivery? delayedDelivery,
      // This is for stanza handlers that are not part of the XMPP library but still need
      // pass data around.
      @Default(<String, dynamic>{}) Map<String, dynamic> other,
      // If non-null, then it indicates the origin Id of the message that should be
      // retracted
      MessageRetractionData? messageRetraction,
      // If non-null, then the message is a correction for the specified stanza Id
      String? lastMessageCorrectionSid,
      // Reactions data
      MessageReactions? messageReactions,
      // The Id of the sticker pack this sticker belongs to
      String? stickerPackId,
    }
  ) = _StanzaHandlerData;
}
