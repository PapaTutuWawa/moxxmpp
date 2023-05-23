import 'package:meta/meta.dart';
import 'package:moxxmpp/src/jid.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/stringxml.dart';
import 'package:moxxmpp/src/xeps/xep_0004.dart';

class Identity {
  const Identity({
    required this.category,
    required this.type,
    this.name,
    this.lang,
  });
  final String category;
  final String type;
  final String? name;
  final String? lang;

  XMLNode toXMLNode() {
    return XMLNode(
      tag: 'identity',
      attributes: <String, dynamic>{
        'category': category,
        'type': type,
        'name': name,
        ...lang == null
            ? <String, dynamic>{}
            : <String, dynamic>{'xml:lang': lang}
      },
    );
  }
}

@immutable
class DiscoInfo {
  const DiscoInfo(
    this.features,
    this.identities,
    this.extendedInfo,
    this.node,
    this.jid,
  );

  factory DiscoInfo.fromQuery(XMLNode query, JID jid) {
    final features = List<String>.empty(growable: true);
    final identities = List<Identity>.empty(growable: true);
    final extendedInfo = List<DataForm>.empty(growable: true);

    for (final element in query.children) {
      if (element.tag == 'feature') {
        features.add(element.attributes['var']! as String);
      } else if (element.tag == 'identity') {
        identities.add(
          Identity(
            category: element.attributes['category']! as String,
            type: element.attributes['type']! as String,
            name: element.attributes['name'] as String?,
          ),
        );
      } else if (element.tag == 'x' &&
          element.attributes['xmlns'] == dataFormsXmlns) {
        extendedInfo.add(
          parseDataForm(element),
        );
      }
    }

    return DiscoInfo(
      features,
      identities,
      extendedInfo,
      query.attributes['node'] as String?,
      jid,
    );
  }

  final List<String> features;
  final List<Identity> identities;
  final List<DataForm> extendedInfo;
  final String? node;
  final JID? jid;

  XMLNode toXml() {
    return XMLNode.xmlns(
      tag: 'query',
      xmlns: discoInfoXmlns,
      attributes: node != null
          ? <String, String>{
              'node': node!,
            }
          : <String, String>{},
      children: [
        ...identities.map((identity) => identity.toXMLNode()),
        ...features.map(
          (feature) => XMLNode(
            tag: 'feature',
            attributes: {
              'var': feature,
            },
          ),
        ),
        if (extendedInfo.isNotEmpty) ...extendedInfo.map((ei) => ei.toXml()),
      ],
    );
  }
}

@immutable
class DiscoItem {
  const DiscoItem({required this.jid, this.node, this.name});
  final JID jid;
  final String? node;
  final String? name;

  XMLNode toXml() {
    final attributes = {
      'jid': jid.toString(),
    };
    if (node != null) {
      attributes['node'] = node!;
    }
    if (name != null) {
      attributes['name'] = name!;
    }

    return XMLNode(
      tag: 'node',
      attributes: attributes,
    );
  }
}
