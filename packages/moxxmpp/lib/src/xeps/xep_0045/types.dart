import 'package:collection/collection.dart';
import 'package:moxxmpp/src/jid.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/xeps/xep_0004.dart';
import 'package:moxxmpp/src/xeps/xep_0030/types.dart';

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

  late final List<PendingMessage> pendingMessages;
}
