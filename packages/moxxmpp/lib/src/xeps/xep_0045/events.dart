import 'package:moxxmpp/src/events.dart';
import 'package:moxxmpp/src/jid.dart';
import 'package:moxxmpp/src/xeps/xep_0045/types.dart';

/// Triggered when the MUC changes our nickname.
class OwnDataChangedEvent extends XmppEvent {
  OwnDataChangedEvent(
    this.roomJid,
    this.nick,
    this.affiliation,
    this.role,
  );

  /// The JID of the room.
  final JID roomJid;

  /// Our nickname.
  final String nick;

  /// Our affiliation.
  final Affiliation affiliation;

  /// Our role.
  final Role role;
}

/// Triggered when an entity joins the MUC.
class MemberJoinedEvent extends XmppEvent {
  MemberJoinedEvent(this.roomJid, this.member);

  /// The JID of the room.
  final JID roomJid;

  /// The new member.
  final RoomMember member;
}

/// Triggered when an entity changes their presence in the MUC.
class MemberChangedEvent extends XmppEvent {
  MemberChangedEvent(this.roomJid, this.member);

  /// The JID of the room.
  final JID roomJid;

  /// The new member.
  final RoomMember member;
}

/// Triggered when an entity leaves the MUC.
class MemberLeftEvent extends XmppEvent {
  MemberLeftEvent(this.roomJid, this.nick);

  /// The JID of the room.
  final JID roomJid;

  /// The nick of the user who left.
  final String nick;
}
