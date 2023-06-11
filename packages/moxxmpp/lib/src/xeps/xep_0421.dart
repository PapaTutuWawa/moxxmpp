import 'dart:async';
import 'package:moxxmpp/src/managers/base.dart';
import 'package:moxxmpp/src/managers/data.dart';
import 'package:moxxmpp/src/managers/handlers.dart';
import 'package:moxxmpp/src/managers/namespaces.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/stanza.dart';
import 'package:moxxmpp/src/stringxml.dart';

/// Representation of a <occupant-id /> element.
class OccupantIdData implements StanzaHandlerExtension {
  const OccupantIdData(
    this.id,
  );

  /// The unique occupant id.
  final String id;

  XMLNode toXML() {
    return XMLNode.xmlns(
      tag: 'occupant-id',
      xmlns: occupantIdXmlns,
      attributes: {
        'id': id,
      },
    );
  }
}

class OccupantIdManager extends XmppManagerBase {
  OccupantIdManager() : super(occupantIdManager);

  @override
  List<String> getDiscoFeatures() => [
        occupantIdXmlns,
      ];

  @override
  List<StanzaHandler> getIncomingStanzaHandlers() => [
        StanzaHandler(
          stanzaTag: 'message',
          callback: _onMessage,
          // Before the MessageManager
          priority: -99,
        ),
      ];

  @override
  Future<bool> isSupported() async => true;

  Future<StanzaHandlerData> _onMessage(
    Stanza stanza,
    StanzaHandlerData state,
  ) async {
    OccupantIdData? occupantId;
    final occupantIdElement =
        stanza.firstTag('occupant-id', xmlns: occupantIdXmlns);
    // Process the occupant id
    if (occupantIdElement != null) {
      occupantId =
          OccupantIdData(occupantIdElement.attributes['id']! as String);
      state.extensions.set(occupantId);
    }
    return state;
  }
}
