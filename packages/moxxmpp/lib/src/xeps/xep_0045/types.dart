import 'package:collection/collection.dart';
import 'package:moxxmpp/src/jid.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/xeps/xep_0004.dart';
import 'package:moxxmpp/src/xeps/xep_0030/types.dart';

class InvalidAffiliationException implements Exception {}

class InvalidRoleException implements Exception {}

enum Affiliation {
  owner('owner'),
  admin('admin'),
  member('member'),
  outcast('outcast'),
  none('none');

  const Affiliation(this.value);

  factory Affiliation.fromString(String value) {
    switch (value) {
      case 'owner':
        return Affiliation.owner;
      case 'admin':
        return Affiliation.admin;
      case 'member':
        return Affiliation.member;
      case 'outcast':
        return Affiliation.outcast;
      case 'none':
        return Affiliation.none;
      default:
        throw InvalidAffiliationException();
    }
  }

  /// The value to use for an attribute referring to this affiliation.
  final String value;
}

enum Role {
  moderator('moderator'),
  participant('participant'),
  visitor('visitor'),
  none('none');

  const Role(this.value);

  factory Role.fromString(String value) {
    switch (value) {
      case 'moderator':
        return Role.moderator;
      case 'participant':
        return Role.participant;
      case 'visitor':
        return Role.visitor;
      case 'none':
        return Role.none;
      default:
        throw InvalidRoleException();
    }
  }

  /// The value to use for an attribute referring to this role.
  final String value;
}

class RoomInformation {
  /// Represents information about a Multi-User Chat (MUC) room.
  RoomInformation({
    required this.jid,
    required this.features,
    required this.name,
    this.roomInfo,
  });

  /// Constructs a [RoomInformation] object from a [DiscoInfo] object.
  /// The [DiscoInfo] object contains the necessary information to populate
  /// the [RoomInformation] fields.
  factory RoomInformation.fromDiscoInfo({
    required DiscoInfo discoInfo,
  }) =>
      RoomInformation(
        jid: discoInfo.jid!,
        features: discoInfo.features,
        name: discoInfo.identities
            .firstWhere((i) => i.category == 'conference')
            .name!,
        roomInfo: discoInfo.extendedInfo.firstWhereOrNull((form) {
          final field = form.getFieldByVar(formVarFormType);
          return field?.type == 'hidden' &&
              field?.values.first == roomInfoFormType;
        }),
      );

  /// The JID of the Multi-User Chat (MUC) room.
  final JID jid;

  /// A list of features supported by the Multi-User Chat (MUC) room.
  final List<String> features;

  /// The name or title of the Multi-User Chat (MUC) room.
  final String name;

  /// The data form containing room information.
  final DataForm? roomInfo;
}

/// The used message-id and an optional origin-id.
typedef PendingMessage = (String, String?);

/// An entity inside a MUC room. The name "member" here does not refer to an affiliation of member.
class RoomMember {
  const RoomMember(this.nick, this.affiliation, this.role);

  /// The entity's nickname.
  final String nick;

  /// The assigned affiliation.
  final Affiliation affiliation;

  /// The assigned role.
  final Role role;

  RoomMember copyWith({
    String? nick,
    Affiliation? affiliation,
    Role? role,
  }) {
    return RoomMember(
      nick ?? this.nick,
      affiliation ?? this.affiliation,
      role ?? this.role,
    );
  }
}

class RoomState {
  RoomState({required this.roomJid, this.nick, required this.joined}) {
    pendingMessages = List<PendingMessage>.empty(growable: true);
  }

  /// The JID of the room.
  final JID roomJid;

  /// The nick we're joined with.
  String? nick;

  /// Flag whether we're joined and can process messages
  bool joined;

  /// Our own affiliation inside the MUC.
  Affiliation? affiliation;

  /// Our own role inside the MUC.
  Role? role;

  /// The list of messages that we sent and are waiting for their echo.
  late final List<PendingMessage> pendingMessages;

  /// "List" of entities inside the MUC.
  final Map<String, RoomMember> members = {};
}
