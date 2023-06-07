import 'package:moxxmpp/src/events.dart';
import 'package:moxxmpp/src/managers/base.dart';
import 'package:moxxmpp/src/managers/data.dart';
import 'package:moxxmpp/src/managers/handlers.dart';
import 'package:moxxmpp/src/managers/namespaces.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/stanza.dart';
import 'package:moxxmpp/src/stringxml.dart';
import 'package:moxxmpp/src/xeps/xep_0030/xep_0030.dart';

class BlockingManager extends XmppManagerBase {
  BlockingManager() : super(blockingManager);

  bool _supported = false;
  bool _gotSupported = false;

  @override
  List<StanzaHandler> getIncomingStanzaHandlers() => [
        StanzaHandler(
          stanzaTag: 'iq',
          tagName: 'unblock',
          tagXmlns: blockingXmlns,
          callback: _unblockPush,
        ),
        StanzaHandler(
          stanzaTag: 'iq',
          tagName: 'block',
          tagXmlns: blockingXmlns,
          callback: _blockPush,
        )
      ];

  @override
  Future<bool> isSupported() async {
    if (_gotSupported) return _supported;

    // Query the server
    final disco = getAttributes().getManagerById<DiscoManager>(discoManager)!;
    _supported = await disco.supportsFeature(
      getAttributes().getConnectionSettings().serverJid,
      blockingXmlns,
    );
    _gotSupported = true;
    return _supported;
  }

  @override
  Future<void> onXmppEvent(XmppEvent event) async {
    if (event is StreamNegotiationsDoneEvent) {
      final newStream = await isNewStream();
      if (newStream) {
        _gotSupported = false;
        _supported = false;
      }
    }
  }

  Future<StanzaHandlerData> _blockPush(
    Stanza iq,
    StanzaHandlerData state,
  ) async {
    final block = iq.firstTag('block', xmlns: blockingXmlns)!;

    getAttributes().sendEvent(
      BlocklistBlockPushEvent(
        items: block
            .findTags('item')
            .map((i) => i.attributes['jid']! as String)
            .toList(),
      ),
    );

    return state..done = true;
  }

  Future<StanzaHandlerData> _unblockPush(
    Stanza iq,
    StanzaHandlerData state,
  ) async {
    final unblock = iq.firstTag('unblock', xmlns: blockingXmlns)!;
    final items = unblock.findTags('item');

    if (items.isNotEmpty) {
      getAttributes().sendEvent(
        BlocklistUnblockPushEvent(
          items: items.map((i) => i.attributes['jid']! as String).toList(),
        ),
      );
    } else {
      getAttributes().sendEvent(
        BlocklistUnblockAllPushEvent(),
      );
    }

    return state..done = true;
  }

  Future<bool> block(List<String> items) async {
    final result = (await getAttributes().sendStanza(
      StanzaDetails(
        Stanza.iq(
          type: 'set',
          children: [
            XMLNode.xmlns(
              tag: 'block',
              xmlns: blockingXmlns,
              children: items.map((item) {
                return XMLNode(
                  tag: 'item',
                  attributes: <String, String>{'jid': item},
                );
              }).toList(),
            )
          ],
        ),
      ),
    ))!;

    return result.attributes['type'] == 'result';
  }

  Future<bool> unblockAll() async {
    final result = (await getAttributes().sendStanza(
      StanzaDetails(
        Stanza.iq(
          type: 'set',
          children: [
            XMLNode.xmlns(
              tag: 'unblock',
              xmlns: blockingXmlns,
            )
          ],
        ),
      ),
    ))!;

    return result.attributes['type'] == 'result';
  }

  Future<bool> unblock(List<String> items) async {
    assert(items.isNotEmpty, 'The list of items to unblock must be non-empty');

    final result = (await getAttributes().sendStanza(
      StanzaDetails(
        Stanza.iq(
          type: 'set',
          children: [
            XMLNode.xmlns(
              tag: 'unblock',
              xmlns: blockingXmlns,
              children: items
                  .map(
                    (item) => XMLNode(
                      tag: 'item',
                      attributes: <String, String>{'jid': item},
                    ),
                  )
                  .toList(),
            )
          ],
        ),
      ),
    ))!;

    return result.attributes['type'] == 'result';
  }

  Future<List<String>> getBlocklist() async {
    final result = (await getAttributes().sendStanza(
      StanzaDetails(
        Stanza.iq(
          type: 'get',
          children: [
            XMLNode.xmlns(
              tag: 'blocklist',
              xmlns: blockingXmlns,
            )
          ],
        ),
      ),
    ))!;

    final blocklist = result.firstTag('blocklist', xmlns: blockingXmlns)!;
    return blocklist
        .findTags('item')
        .map((item) => item.attributes['jid']! as String)
        .toList();
  }
}
