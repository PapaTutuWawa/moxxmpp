import 'package:moxxmpp/src/jid.dart';
import 'package:moxxmpp/src/managers/base.dart';
import 'package:moxxmpp/src/managers/data.dart';
import 'package:moxxmpp/src/managers/handlers.dart';
import 'package:moxxmpp/src/managers/namespaces.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/stanza.dart';
import 'package:moxxmpp/src/stringxml.dart';
import 'package:moxxmpp/src/xeps/xep_0030/types.dart';
import 'package:moxxmpp/src/xeps/xep_0030/xep_0030.dart';

/// Represents data provided by XEP-0359.
/// NOTE: [StableStanzaId.stanzaId] must not be confused with the actual id attribute of
///       the message stanza.
class StableStanzaId {
  const StableStanzaId({this.originId, this.stanzaId, this.stanzaIdBy});
  final String? originId;
  final String? stanzaId;
  final String? stanzaIdBy;
}

XMLNode makeOriginIdElement(String id) {
  return XMLNode.xmlns(
    tag: 'origin-id',
    xmlns: stableIdXmlns,
    attributes: {'id': id},
  );
}

class StableIdManager extends XmppManagerBase {
  StableIdManager() : super(stableIdManager);

  @override
  List<String> getDiscoFeatures() => [stableIdXmlns];

  @override
  List<StanzaHandler> getIncomingStanzaHandlers() => [
        StanzaHandler(
          stanzaTag: 'message',
          callback: _onMessage,
          // Before the MessageManager
          priority: -99,
        )
      ];

  @override
  Future<bool> isSupported() async => true;

  Future<StanzaHandlerData> _onMessage(
    Stanza message,
    StanzaHandlerData state,
  ) async {
    final from = JID.fromString(message.attributes['from']! as String);
    String? originId;
    String? stanzaId;
    String? stanzaIdBy;
    final originIdTag = message.firstTag('origin-id', xmlns: stableIdXmlns);
    final stanzaIdTag = message.firstTag('stanza-id', xmlns: stableIdXmlns);

    // Process the origin id
    if (originIdTag != null) {
      logger.finest('Found origin Id tag');
      originId = originIdTag.attributes['id']! as String;
    }

    // Process the stanza id tag
    if (stanzaIdTag != null) {
      logger.finest('Found stanza Id tag');
      final attrs = getAttributes();
      final disco = attrs.getManagerById<DiscoManager>(discoManager)!;
      final result = await disco.discoInfoQuery(from);
      if (result.isType<DiscoInfo>()) {
        final info = result.get<DiscoInfo>();
        logger.finest('Got info for ${from.toString()}');
        if (info.features.contains(stableIdXmlns)) {
          logger.finest('${from.toString()} supports $stableIdXmlns.');
          stanzaId = stanzaIdTag.attributes['id']! as String;
          stanzaIdBy = stanzaIdTag.attributes['by']! as String;
        } else {
          logger.finest(
            '${from.toString()} does not support $stableIdXmlns. Ignoring stanza id... ',
          );
        }
      } else {
        logger.finest(
          'Failed to find out if ${from.toString()} supports $stableIdXmlns. Ignoring... ',
        );
      }
    }

    return state.copyWith(
      stableId: StableStanzaId(
        originId: originId,
        stanzaId: stanzaId,
        stanzaIdBy: stanzaIdBy,
      ),
    );
  }
}
