import 'dart:convert';
import 'package:moxxmpp/src/jid.dart';
import 'package:moxxmpp/src/managers/base.dart';
import 'package:moxxmpp/src/managers/data.dart';
import 'package:moxxmpp/src/managers/handlers.dart';
import 'package:moxxmpp/src/managers/namespaces.dart';
import 'package:moxxmpp/src/message.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/rfcs/rfc_4790.dart';
import 'package:moxxmpp/src/stanza.dart';
import 'package:moxxmpp/src/stringxml.dart';
import 'package:moxxmpp/src/types/result.dart';
import 'package:moxxmpp/src/util/typed_map.dart';
import 'package:moxxmpp/src/xeps/xep_0060/errors.dart';
import 'package:moxxmpp/src/xeps/xep_0060/xep_0060.dart';
import 'package:moxxmpp/src/xeps/xep_0300.dart';
import 'package:moxxmpp/src/xeps/xep_0446.dart';
import 'package:moxxmpp/src/xeps/xep_0447.dart';

class Sticker {
  const Sticker(this.metadata, this.sources, this.suggests);

  factory Sticker.fromXML(XMLNode node) {
    assert(node.tag == 'item', 'sticker has wrong tag');

    return Sticker(
      FileMetadataData.fromXML(
        node.firstTag('file', xmlns: fileMetadataXmlns)!,
      ),
      processStatelessFileSharingSources(node, checkXmlns: false),
      {},
    );
  }

  final FileMetadataData metadata;
  final List<StatelessFileSharingSource> sources;
  // Language -> suggestion
  final Map<String, String> suggests;

  XMLNode toPubSubXML() {
    final suggestsElements = suggests.keys.map((suggest) {
      Map<String, String> attrs;
      if (suggest.isEmpty) {
        attrs = {};
      } else {
        attrs = {
          'xml:lang': suggest,
        };
      }

      return XMLNode(
        tag: 'suggest',
        attributes: attrs,
        text: suggests[suggest],
      );
    });

    return XMLNode(
      tag: 'item',
      children: [
        metadata.toXML(),
        ...sources.map((source) => source.toXml()),
        ...suggestsElements,
      ],
    );
  }
}

class StickerPack {
  const StickerPack(
    this.id,
    this.name,
    this.summary,
    this.hashAlgorithm,
    this.hashValue,
    this.stickers,
    this.restricted,
  );

  factory StickerPack.fromXML(
    String id,
    XMLNode node, {
    bool hashAvailable = true,
  }) {
    assert(node.tag == 'pack', 'node has wrong tag');
    assert(node.attributes['xmlns'] == stickersXmlns, 'node has wrong XMLNS');

    var hashAlgorithm = HashFunction.sha256;
    var hashValue = '';
    if (hashAvailable) {
      final hash = node.firstTag('hash', xmlns: hashXmlns)!;
      hashAlgorithm = HashFunction.fromName(hash.attributes['algo']! as String);
      hashValue = hash.innerText();
    }

    return StickerPack(
      id,
      node.firstTag('name')!.innerText(),
      node.firstTag('summary')!.innerText(),
      hashAlgorithm,
      hashValue,
      node.children
          .where((e) => e.tag == 'item')
          .map<Sticker>(Sticker.fromXML)
          .toList(),
      node.firstTag('restricted') != null,
    );
  }

  final String id;
  // TODO(PapaTutuWawa): Turn name and summary into a Map as it may contain a xml:lang
  final String name;
  final String summary;
  final HashFunction hashAlgorithm;
  final String hashValue;
  final List<Sticker> stickers;
  final bool restricted;

  /// When using the fromXML factory to parse a description of a sticker pack with a
  /// yet unknown hash, then this function can be used in order to apply the freshly
  /// calculated hash to the object.
  StickerPack copyWithId(HashFunction newHashFunction, String newId) {
    return StickerPack(
      newId,
      name,
      summary,
      newHashFunction,
      newId,
      stickers,
      restricted,
    );
  }

  XMLNode toXML() {
    return XMLNode.xmlns(
      tag: 'pack',
      xmlns: stickersXmlns,
      children: [
        // Pack metadata
        XMLNode(
          tag: 'name',
          text: name,
        ),
        XMLNode(
          tag: 'summary',
          text: summary,
        ),
        constructHashElement(
          hashAlgorithm,
          hashValue,
        ),

        ...restricted ? [XMLNode(tag: 'restricted')] : [],

        // Stickers
        ...stickers.map((sticker) => sticker.toPubSubXML()),
      ],
    );
  }

  /// Calculates the sticker pack's hash as specified by XEP-0449.
  Future<String> getHash(HashFunction hashFunction) async {
    // Build the meta string
    final metaTmp = [
      <int>[
        ...utf8.encode('name'),
        0x1f,
        0x1f,
        ...utf8.encode(name),
        0x1f,
        0x1e,
      ],
      <int>[
        ...utf8.encode('summary'),
        0x1f,
        0x1f,
        ...utf8.encode(summary),
        0x1f,
        0x1e,
      ],
    ]..sort(ioctetSortComparatorRaw);
    final metaString = List<int>.empty(growable: true);
    for (final m in metaTmp) {
      metaString.addAll(m);
    }
    metaString.add(0x1c);

    // Build item hashes
    final items = List<List<int>>.empty(growable: true);
    for (final sticker in stickers) {
      final tmp = List<int>.empty(growable: true)
        ..addAll(utf8.encode(sticker.metadata.desc!))
        ..add(0x1e);

      final hashes = List<List<int>>.empty(growable: true);
      for (final hash in sticker.metadata.hashes.keys) {
        hashes.add([
          ...utf8.encode(hash.toName()),
          0x1f,
          ...utf8.encode(sticker.metadata.hashes[hash]!),
          0x1f,
          0x1e,
        ]);
      }
      hashes.sort(ioctetSortComparatorRaw);

      for (final hash in hashes) {
        tmp.addAll(hash);
      }
      tmp.add(0x1d);
      items.add(tmp);
    }
    items.sort(ioctetSortComparatorRaw);
    final stickersString = List<int>.empty(growable: true);
    for (final item in items) {
      stickersString.addAll(item);
    }
    stickersString.add(0x1c);

    // Calculate the hash
    final rawHash = await CryptographicHashManager.hashFromData(
      hashFunction,
      [
        ...metaString,
        ...stickersString,
      ],
    );
    return base64.encode(rawHash).substring(0, 24);
  }
}

class StickersData {
  const StickersData(this.stickerPackId, this.sticker);

  /// The id of the sticker pack the referenced sticker is from.
  final String stickerPackId;

  /// The metadata of the sticker.
  final StatelessFileSharingData sticker;
}

class StickersManager extends XmppManagerBase {
  StickersManager() : super(stickersManager);

  @override
  Future<bool> isSupported() async => true;

  @override
  List<StanzaHandler> getIncomingStanzaHandlers() => [
        StanzaHandler(
          stanzaTag: 'message',
          tagXmlns: stickersXmlns,
          tagName: 'sticker',
          callback: _onIncomingMessage,
          priority: -99,
        ),
      ];

  Future<StanzaHandlerData> _onIncomingMessage(
    Stanza stanza,
    StanzaHandlerData state,
  ) async {
    final sticker = stanza.firstTag('sticker', xmlns: stickersXmlns)!;
    return state
      ..extensions.set(
        StickersData(
          sticker.attributes['pack']! as String,
          state.extensions.get<StatelessFileSharingData>()!,
        ),
      );
  }

  List<XMLNode> _messageSendingCallback(TypedMap extensions) {
    final data = extensions.get<StickersData>();
    return data != null
        ? [
            XMLNode.xmlns(
              tag: 'sticker',
              xmlns: stickersXmlns,
              attributes: {
                'pack': data.stickerPackId,
              },
            ),
            data.sticker.toXML(),
          ]
        : [];
  }

  /// Publishes the StickerPack [pack] to the PubSub node of [jid]. If specified, then
  /// [accessModel] will be used as the PubSub node's access model.
  ///
  /// On success, returns true. On failure, returns a PubSubError.
  Future<Result<PubSubError, bool>> publishStickerPack(
    JID jid,
    StickerPack pack, {
    String? accessModel,
  }) async {
    assert(pack.id != '', 'The sticker pack must have an id');
    final pm = getAttributes().getManagerById<PubSubManager>(pubsubManager)!;

    return pm.publish(
      jid.toBare(),
      stickersXmlns,
      pack.toXML(),
      id: pack.id,
      options: PubSubPublishOptions(
        maxItems: 'max',
        accessModel: accessModel,
      ),
    );
  }

  /// Removes the sticker pack with id [id] from the PubSub node of [jid].
  ///
  /// On success, returns the true. On failure, returns a PubSubError.
  Future<Result<PubSubError, bool>> retractStickerPack(
    JID jid,
    String id,
  ) async {
    final pm = getAttributes().getManagerById<PubSubManager>(pubsubManager)!;

    return pm.retract(
      jid,
      stickersXmlns,
      id,
    );
  }

  /// Fetches the sticker pack with id [id] from [jid].
  ///
  /// On success, returns the StickerPack. On failure, returns a PubSubError.
  Future<Result<PubSubError, StickerPack>> fetchStickerPack(
    JID jid,
    String id,
  ) async {
    final pm = getAttributes().getManagerById<PubSubManager>(pubsubManager)!;
    final stickerPackDataRaw = await pm.getItem(
      jid.toBare().toString(),
      stickersXmlns,
      id,
    );
    if (stickerPackDataRaw.isType<PubSubError>()) {
      return Result(stickerPackDataRaw.get<PubSubError>());
    }

    final stickerPackData = stickerPackDataRaw.get<PubSubItem>();
    final stickerPack = StickerPack.fromXML(
      stickerPackData.id,
      stickerPackData.payload,
    );

    return Result(stickerPack);
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
