import 'package:moxxmpp/src/managers/base.dart';
import 'package:moxxmpp/src/managers/data.dart';
import 'package:moxxmpp/src/managers/handlers.dart';
import 'package:moxxmpp/src/managers/namespaces.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/stanza.dart';
import 'package:moxxmpp/src/stringxml.dart';
import 'package:moxxmpp/src/util/typed_map.dart';

class LastMessageCorrectionData {
  const LastMessageCorrectionData(this.id);

  /// The id the LMC applies to.
  final String id;

  XMLNode toXML() {
    return XMLNode.xmlns(
      tag: 'replace',
      xmlns: lmcXmlns,
      attributes: {
        'id': id,
      },
    );
  }

  static List<XMLNode> messageSendingCallback(TypedMap extensions) {
    final data = extensions.get<LastMessageCorrectionData>();
    return data != null
        ? [
            data.toXML(),
          ]
        : [];
  }
}

class LastMessageCorrectionManager extends XmppManagerBase {
  LastMessageCorrectionManager() : super(lastMessageCorrectionManager);

  @override
  List<String> getDiscoFeatures() => [lmcXmlns];

  @override
  List<StanzaHandler> getIncomingStanzaHandlers() => [
        StanzaHandler(
          stanzaTag: 'message',
          tagName: 'replace',
          tagXmlns: lmcXmlns,
          callback: _onMessage,
          // Before the message handler
          priority: -99,
        )
      ];

  @override
  Future<bool> isSupported() async => true;

  Future<StanzaHandlerData> _onMessage(
    Stanza stanza,
    StanzaHandlerData state,
  ) async {
    final edit = stanza.firstTag('replace', xmlns: lmcXmlns)!;
    return state
      ..extensions.set(
        LastMessageCorrectionData(edit.attributes['id']! as String),
      );
  }
}
