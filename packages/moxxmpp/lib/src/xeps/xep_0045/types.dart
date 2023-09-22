import 'package:moxxmpp/src/jid.dart';
import 'package:moxxmpp/src/xeps/xep_0030/types.dart';

class RoomInformation {
  /// Represents information about a Multi-User Chat (MUC) room.
  RoomInformation({
    required this.jid,
    required this.features,
    required this.name,
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
      );

  /// The JID of the Multi-User Chat (MUC) room.
  final JID jid;

  /// A list of features supported by the Multi-User Chat (MUC) room.
  final List<String> features;

  /// The name or title of the Multi-User Chat (MUC) room.
  final String name;
}

class RoomState {
  RoomState({required this.roomJid, this.nick, required this.joined});

  /// The JID of the room.
  final JID roomJid;

  /// The nick we're joined with.
  String? nick;

  /// Flag whether we're joined and can process messages
  bool joined;

  RoomState copyWith({
    bool? joined,
    String? nick,
  }) {
    return RoomState(
      roomJid: roomJid,
      joined: joined ?? this.joined,
      nick: nick ?? this.nick,
    );
  }
}
