import 'package:moxxmpp/src/managers/base.dart';
import 'package:moxxmpp/src/managers/data.dart';
import 'package:moxxmpp/src/managers/handlers.dart';
import 'package:moxxmpp/src/managers/namespaces.dart';
import 'package:moxxmpp/src/message.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/stanza.dart';
import 'package:moxxmpp/src/stringxml.dart';
import 'package:moxxmpp/src/util/typed_map.dart';

/// A data class representing the jabber:x:oob tag.
class OOBData implements StanzaHandlerExtension {
  const OOBData(this.url, this.desc);

  /// The communicated URL of the OOB data
  final String? url;

  /// The description of the url.
  final String? desc;

  XMLNode toXML() {
    return XMLNode.xmlns(
      tag: 'x',
      xmlns: oobDataXmlns,
      children: [
        if (url != null) XMLNode(tag: 'url', text: url),
        if (desc != null) XMLNode(tag: 'desc', text: desc),
      ],
    );
  }
}

class OOBManager extends XmppManagerBase {
  OOBManager() : super(oobManager);

  @override
  List<String> getDiscoFeatures() => [oobDataXmlns];

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

  Future<StanzaHandlerData> _onMessage(
    Stanza message,
    StanzaHandlerData state,
  ) async {
    final x = message.firstTag('x', xmlns: oobDataXmlns)!;
    final url = x.firstTag('url');
    final desc = x.firstTag('desc');

    return state
      ..extensions.set(
        OOBData(
          url?.innerText(),
          desc?.innerText(),
        ),
      );
  }

  List<XMLNode> _messageSendingCallback(
    TypedMap<StanzaHandlerExtension> extensions,
  ) {
    final data = extensions.get<OOBData>();
    return data != null
        ? [
            data.toXML(),
          ]
        : [];
  }

  @override
  Future<void> postRegisterCallback() async {
    await super.postRegisterCallback();

    // Register the sending callback
    getAttributes()
        .getManagerById<MessageManager>(messageManager)
        ?.registerMessageSendingCallback(_messageSendingCallback);
  }
}
