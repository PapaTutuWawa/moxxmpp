import 'package:moxxmpp/src/jid.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/stanza.dart';
import 'package:moxxmpp/src/stringxml.dart';

// TODO(PapaTutuWawa): Move types into types.dart

Stanza buildDiscoInfoQueryStanza(JID entity, String? node) {
  return Stanza.iq(
    to: entity.toString(),
    type: 'get',
    children: [
      XMLNode.xmlns(
        tag: 'query',
        xmlns: discoInfoXmlns,
        attributes: {
          if (node != null) 'node': node,
        },
      ),
    ],
  );
}

Stanza buildDiscoItemsQueryStanza(JID entity, {String? node}) {
  return Stanza.iq(
    to: entity.toString(),
    type: 'get',
    children: [
      XMLNode.xmlns(
        tag: 'query',
        xmlns: discoItemsXmlns,
        attributes: {
          if (node != null) 'node': node,
        },
      ),
    ],
  );
}
