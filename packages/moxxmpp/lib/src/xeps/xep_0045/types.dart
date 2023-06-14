import 'package:moxxmpp/src/jid.dart';
import 'package:moxxmpp/src/xeps/xep_0030/types.dart';

class RoomInformation {
  RoomInformation({
    required this.jid,
    required this.features,
    required this.name,
  });

  factory RoomInformation.fromDiscoInfo({
    required DiscoInfo discoInfo,
  }) =>
      RoomInformation(
        jid: discoInfo.jid!,
        features: discoInfo.features,
        name: discoInfo.identities[0].name!,
      );

  final JID jid;
  final List<String> features;
  final String name;
}
