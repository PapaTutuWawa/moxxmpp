import 'package:moxxmpp/src/connection.dart';
import 'package:moxxmpp/src/jid.dart';
import 'package:moxxmpp/src/managers/data.dart';
import 'package:moxxmpp/src/roster/roster.dart';
import 'package:moxxmpp/src/stanza.dart';
import 'package:moxxmpp/src/xeps/xep_0030/types.dart';
import 'package:moxxmpp/src/xeps/xep_0060/xep_0060.dart';
import 'package:moxxmpp/src/xeps/xep_0066.dart';
import 'package:moxxmpp/src/xeps/xep_0085.dart';
import 'package:moxxmpp/src/xeps/xep_0334.dart';
import 'package:moxxmpp/src/xeps/xep_0359.dart';
import 'package:moxxmpp/src/xeps/xep_0385.dart';
import 'package:moxxmpp/src/xeps/xep_0424.dart';
import 'package:moxxmpp/src/xeps/xep_0444.dart';
import 'package:moxxmpp/src/xeps/xep_0446.dart';
import 'package:moxxmpp/src/xeps/xep_0447.dart';
import 'package:moxxmpp/src/xeps/xep_0461.dart';

abstract class XmppEvent {}

/// Triggered when the connection state of the XmppConnection has
/// changed.
class ConnectionStateChangedEvent extends XmppEvent {
  ConnectionStateChangedEvent(this.state, this.before, this.resumed);
  final XmppConnectionState before;
  final XmppConnectionState state;
  final bool resumed;
}

/// Triggered when we encounter a stream error.
class StreamErrorEvent extends XmppEvent {
  StreamErrorEvent({ required this.error });
  final String error;
}

/// Triggered after the SASL authentication has failed.
class AuthenticationFailedEvent extends XmppEvent {
  AuthenticationFailedEvent(this.saslError);
  final String saslError;
}

/// Triggered after the SASL authentication has succeeded.
class AuthenticationSuccessEvent extends XmppEvent {}

/// Triggered when we want to ping the connection open
class SendPingEvent extends XmppEvent {}

/// Triggered when the stream resumption was successful
class StreamResumedEvent extends XmppEvent {
  StreamResumedEvent({ required this.h });
  final int h;
}

/// Triggered when stream resumption failed
class StreamResumeFailedEvent extends XmppEvent {}

/// Triggered when the roster has been modified
class RosterUpdatedEvent extends XmppEvent {
  RosterUpdatedEvent(this.removed, this.modified, this.added);

  /// A list of bare JIDs that are removed from the roster
  final List<String> removed;

  /// A list of XmppRosterItems that are modified. Can be correlated with one's cache
  /// using the jid attribute.
  final List<XmppRosterItem> modified;

  /// A list of XmppRosterItems that are added to the roster.
  final List<XmppRosterItem> added;
}

/// Triggered when a message is received
class MessageEvent extends XmppEvent {
  MessageEvent({
    required this.body,
    required this.fromJid,
    required this.toJid,
    required this.sid,
    required this.stanzaId,
    required this.isCarbon,
    required this.deliveryReceiptRequested,
    required this.isMarkable,
    required this.encrypted,
    required this.other,
    this.error,
    this.type,
    this.oob,
    this.sfs,
    this.sims,
    this.reply,
    this.chatState,
    this.fun,
    this.funReplacement,
    this.funCancellation,
    this.messageRetraction,
    this.messageCorrectionId,
    this.messageReactions,
    this.messageProcessingHints,
    this.stickerPackId,
  });
  final StanzaError? error;
  final String body;
  final JID fromJid;
  final JID toJid;
  final String sid;
  final String? type;
  final StableStanzaId stanzaId;
  final bool isCarbon;
  final bool deliveryReceiptRequested;
  final bool isMarkable;
  final OOBData? oob;
  final StatelessFileSharingData? sfs;
  final StatelessMediaSharingData? sims;
  final ReplyData? reply;
  final ChatState? chatState;
  final FileMetadataData? fun;
  final String? funReplacement;
  final String? funCancellation;
  final bool encrypted;
  final MessageRetractionData? messageRetraction;
  final String? messageCorrectionId;
  final MessageReactions? messageReactions;
  final List<MessageProcessingHint>? messageProcessingHints;
  final String? stickerPackId;
  final Map<String, dynamic> other;
}

/// Triggered when a client responds to our delivery receipt request
class DeliveryReceiptReceivedEvent extends XmppEvent {
  DeliveryReceiptReceivedEvent({ required this.from, required this.id });
  final JID from;
  final String id;
}

class ChatMarkerEvent extends XmppEvent {
  ChatMarkerEvent({
    required this.type,
    required this.from,
    required this.id,
  });
  final JID from;
  final String type;
  final String id;
}

// Triggered when we received a Stream resumption ID
class StreamManagementEnabledEvent extends XmppEvent {
  StreamManagementEnabledEvent({
      required this.resource,
      this.id,
      this.location,
  });
  final String resource;
  final String? id;
  final String? location;
}

/// Triggered when we bound a resource
class ResourceBindingSuccessEvent extends XmppEvent {
  ResourceBindingSuccessEvent({ required this.resource });
  final String resource;
}

/// Triggered when we receive presence
class PresenceReceivedEvent extends XmppEvent {
  PresenceReceivedEvent(this.jid, this.presence);
  final JID jid;
  final Stanza presence;
}

/// Triggered when we are starting an connection attempt
class ConnectingEvent extends XmppEvent {}

/// Triggered when we found out what the server supports
class ServerDiscoDoneEvent extends XmppEvent {}

class ServerItemDiscoEvent extends XmppEvent {
  ServerItemDiscoEvent(this.info);
  final DiscoInfo info;
}

/// Triggered when we receive a subscription request
class SubscriptionRequestReceivedEvent extends XmppEvent {
  SubscriptionRequestReceivedEvent({ required this.from });
  final JID from;
}

/// Triggered when we receive a new or updated avatar
class AvatarUpdatedEvent extends XmppEvent {
  AvatarUpdatedEvent({ required this.jid, required this.base64, required this.hash });
  final String jid;
  final String base64;
  final String hash;
}

/// Triggered when a PubSub notification has been received
class PubSubNotificationEvent extends XmppEvent {
  PubSubNotificationEvent({ required this.item, required this.from });
  final PubSubItem item;
  final String from;
}

/// Triggered by the StreamManagementManager if a stanza has been acked
class StanzaAckedEvent extends XmppEvent {
  StanzaAckedEvent(this.stanza);
  final Stanza stanza;
}

/// Triggered when receiving a push of the blocklist
class BlocklistBlockPushEvent extends XmppEvent {
  BlocklistBlockPushEvent({ required this.items });
  final List<String> items;
}

/// Triggered when receiving a push of the blocklist
class BlocklistUnblockPushEvent extends XmppEvent {
  BlocklistUnblockPushEvent({ required this.items });
  final List<String> items;
}

/// Triggered when receiving a push of the blocklist
class BlocklistUnblockAllPushEvent extends XmppEvent {
  BlocklistUnblockAllPushEvent();
}

/// Triggered when a stanza has not been sent because a stanza handler
/// wanted to cancel the entire process.
class StanzaSendingCancelledEvent extends XmppEvent {
  StanzaSendingCancelledEvent(this.data);
  final StanzaHandlerData data;
}

/// Triggered when the device list of a Jid is updated
class OmemoDeviceListUpdatedEvent extends XmppEvent {
  OmemoDeviceListUpdatedEvent(this.jid, this.deviceList);
  final JID jid;
  final List<int> deviceList;
}
