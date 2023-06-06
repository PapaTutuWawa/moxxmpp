import 'package:moxxmpp/src/connection.dart';
import 'package:moxxmpp/src/errors.dart';
import 'package:moxxmpp/src/jid.dart';
import 'package:moxxmpp/src/managers/data.dart';
import 'package:moxxmpp/src/roster/roster.dart';
import 'package:moxxmpp/src/stanza.dart';
import 'package:moxxmpp/src/util/typed_map.dart';
import 'package:moxxmpp/src/xeps/xep_0030/types.dart';
import 'package:moxxmpp/src/xeps/xep_0060/xep_0060.dart';
import 'package:moxxmpp/src/xeps/xep_0084.dart';

abstract class XmppEvent {}

/// Triggered when the connection state of the XmppConnection has
/// changed.
class ConnectionStateChangedEvent extends XmppEvent {
  ConnectionStateChangedEvent(this.state, this.before);
  final XmppConnectionState before;
  final XmppConnectionState state;

  /// Indicates whether the connection state switched from a not connected state to a
  /// connected state.
  bool get connectionEstablished =>
      before != XmppConnectionState.connected &&
      state == XmppConnectionState.connected;
}

/// Triggered when we encounter a stream error.
class StreamErrorEvent extends XmppEvent {
  StreamErrorEvent({required this.error});
  final String error;
}

/// Triggered after the SASL authentication has failed.
class AuthenticationFailedEvent extends XmppEvent {
  AuthenticationFailedEvent(this.saslError);
  final String saslError;
}

/// Triggered after the SASL authentication has succeeded.
class AuthenticationSuccessEvent extends XmppEvent {}

/// Triggered when the stream resumption was successful
class StreamResumedEvent extends XmppEvent {
  StreamResumedEvent({required this.h});
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
  MessageEvent(
    this.from,
    this.to,
    this.id,
    this.extensions, {
    this.type,
    this.error,
  });

  /// The from attribute of the message.
  final JID from;

  /// The to attribute of the message.
  final JID to;

  /// The id attribute of the message.
  final String id;

  /// The type attribute of the message.
  final String? type;

  final StanzaError? error;

  /// Data added by other handlers.
  final TypedMap extensions;
}

/// Triggered when a client responds to our delivery receipt request
class DeliveryReceiptReceivedEvent extends XmppEvent {
  DeliveryReceiptReceivedEvent({required this.from, required this.id});
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
class ResourceBoundEvent extends XmppEvent {
  ResourceBoundEvent(this.resource);

  /// The resource that was just bound.
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
  SubscriptionRequestReceivedEvent({required this.from});
  final JID from;
}

/// Triggered when we receive a new or updated avatar via XEP-0084
class UserAvatarUpdatedEvent extends XmppEvent {
  UserAvatarUpdatedEvent(
    this.jid,
    this.metadata,
  );

  /// The JID of the user updating their avatar.
  final JID jid;

  /// The metadata of the avatar.
  final List<UserAvatarMetadata> metadata;
}

/// Triggered when we receive a new or updated avatar via XEP-0054
class VCardAvatarUpdatedEvent extends XmppEvent {
  VCardAvatarUpdatedEvent(
    this.jid,
    this.base64,
    this.hash,
  );

  /// The JID of the entity that updated their avatar.
  final JID jid;

  /// The base64-encoded avatar data.
  final String base64;

  /// The SHA-1 hash of the avatar.
  final String hash;
}

/// Triggered when a PubSub notification has been received
class PubSubNotificationEvent extends XmppEvent {
  PubSubNotificationEvent({required this.item, required this.from});
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
  BlocklistBlockPushEvent({required this.items});
  final List<String> items;
}

/// Triggered when receiving a push of the blocklist
class BlocklistUnblockPushEvent extends XmppEvent {
  BlocklistUnblockPushEvent({required this.items});
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

/// Triggered when a reconnection is not performed due to a non-recoverable
/// error.
class NonRecoverableErrorEvent extends XmppEvent {
  NonRecoverableErrorEvent(this.error);

  /// The error in question.
  final XmppError error;
}

/// Triggered when the stream negotiations are done.
class StreamNegotiationsDoneEvent extends XmppEvent {
  StreamNegotiationsDoneEvent(this.resumed);

  /// Flag indicating whether we resumed a previous stream (true) or are in a completely
  /// new stream (false).
  final bool resumed;
}
