import 'package:moxxmpp/src/managers/base.dart';
import 'package:moxxmpp/src/managers/data.dart';
import 'package:moxxmpp/src/managers/handlers.dart';
import 'package:moxxmpp/src/managers/namespaces.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/stanza.dart';
import 'package:moxxmpp/src/stringxml.dart';

XMLNode makeLastMessageCorrectionEdit(String id) {
  return XMLNode.xmlns(
    tag: 'replace',
    xmlns: lmcXmlns,
    attributes: <String, String>{
      'id': id,
    },
  );
}

class LastMessageCorrectionManager extends XmppManagerBase {
  @override
  String getName() => 'LastMessageCorrectionManager';

  @override
  String getId() => lastMessageCorrectionManager;

  @override
  List<String> getDiscoFeatures() => [ lmcXmlns ];
  
  @override
  List<StanzaHandler> getIncomingStanzaHandlers() => [
    StanzaHandler(
      stanzaTag: 'message',
      tagName: 'reply',
      tagXmlns: replyXmlns,
      callback: _onMessage,
      // Before the message handler
      priority: -99,
    )
  ];

  @override
  Future<bool> isSupported() async => true;
  
  Future<StanzaHandlerData> _onMessage(Stanza stanza, StanzaHandlerData state) async {
    final edit = stanza.firstTag('replace', xmlns: lmcXmlns);
    if (edit == null) return state;

    return state.copyWith(
      lastMessageCorrectionSid: edit.attributes['id']! as String,
    );
  }
}
