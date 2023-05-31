import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxmpp/src/xeps/xep_0045/errors.dart';

class RoomInformation {
  RoomInformation({
    required this.jid,
    required this.features,
    required this.name,
  });

  factory RoomInformation.fromStanza({
    required JID roomJID,
    required XMLNode stanza,
  }) {
    final featureNodes = stanza.children[0].findTags('feature');
    final identityNodes = stanza.children[0].findTags('identity');

    if (featureNodes.isNotEmpty && identityNodes.isNotEmpty) {
      final features = featureNodes
          .map((xmlNode) => xmlNode.attributes['var'].toString())
          .toList();
      final name = identityNodes[0].attributes['name'].toString();

      return RoomInformation(
        jid: roomJID,
        features: features,
        name: name,
      );
    } else {
      // ignore: only_throw_errors
      throw InvalidStanzaFormat();
    }
  }
  final JID jid;
  final List<String> features;
  final String name;
}
