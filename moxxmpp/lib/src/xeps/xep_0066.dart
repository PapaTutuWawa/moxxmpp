import 'package:moxxmpp/src/managers/base.dart';
import 'package:moxxmpp/src/managers/data.dart';
import 'package:moxxmpp/src/managers/handlers.dart';
import 'package:moxxmpp/src/managers/namespaces.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/stanza.dart';
import 'package:moxxmpp/src/stringxml.dart';

/// A data class representing the jabber:x:oob tag.
class OOBData {

  const OOBData({ this.url, this.desc });
  final String? url;
  final String? desc;
}

XMLNode constructOOBNode(OOBData data) {
  final children = List<XMLNode>.empty(growable: true);

  if (data.url != null) {
    children.add(XMLNode(tag: 'url', text: data.url));
  }
  if (data.desc != null) {
    children.add(XMLNode(tag: 'desc', text: data.desc));
  }
  
  return XMLNode.xmlns(
    tag: 'x',
    xmlns: oobDataXmlns,
    children: children,
  );
}

class OOBManager extends XmppManagerBase {
  @override
  String getName() => 'OOBName';

  @override
  String getId() => oobManager;

  @override
  List<String> getDiscoFeatures() => [ oobDataXmlns ];

  @override
  List<StanzaHandler> getIncomingStanzaHandlers() => [
    StanzaHandler(
      stanzaTag: 'message',
      tagName: 'x',
      tagXmlns: oobDataXmlns,
      callback: _onMessage,
      // Before the message manager
      priority: -99,
    )
  ];

  @override
  Future<bool> isSupported() async => true;
  
  Future<StanzaHandlerData> _onMessage(Stanza message, StanzaHandlerData state) async {
    final x = message.firstTag('x', xmlns: oobDataXmlns)!;
    final url = x.firstTag('url');
    final desc = x.firstTag('desc');

    return state.copyWith(
      oob: OOBData(
        url: url?.innerText(),
        desc: desc?.innerText(),
      ),
    );
  }
}
