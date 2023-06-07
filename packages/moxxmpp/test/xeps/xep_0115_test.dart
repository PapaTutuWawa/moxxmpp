import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxmpp/src/util/typed_map.dart';
import 'package:test/test.dart';

import '../helpers/logging.dart';
import '../helpers/manager.dart';

class StubbedDiscoManager extends DiscoManager {
  StubbedDiscoManager() : super([]);

  /// Inject an identity twice.
  bool multipleEqualIdentities = false;

  /// Inject a disco feature twice.
  bool multipleEqualFeatures = false;

  /// Inject the same (correct) extended info form twice.
  bool multipleExtendedFormsWithSameType = false;

  /// No FORM_TYPE
  bool invalidExtension1 = false;

  /// FORM_TYPE is not hidden
  bool invalidExtension2 = false;

  /// FORM_TYPE has more than one different values
  bool invalidExtension3 = false;

  @override
  Future<Result<DiscoError, DiscoInfo>> discoInfoQuery(
    JID entity, {
    String? node,
    bool shouldEncrypt = true,
    bool shouldCache = true,
  }) async {
    return Result(
      DiscoInfo(
        [
          'http://jabber.org/protocol/caps',
          'http://jabber.org/protocol/disco#info',
          'http://jabber.org/protocol/disco#items',
          'http://jabber.org/protocol/muc',
          if (multipleEqualFeatures) 'http://jabber.org/protocol/muc',
        ],
        [
          const Identity(
            category: 'client',
            type: 'pc',
            name: 'Exodus 0.9.1',
          ),
          if (multipleEqualIdentities)
            const Identity(
              category: 'client',
              type: 'pc',
              name: 'Exodus 0.9.1',
            ),
        ],
        [
          if (multipleExtendedFormsWithSameType)
            const DataForm(
              type: 'result',
              instructions: [],
              fields: [
                DataFormField(
                  options: [],
                  values: [
                    'http://jabber.org/network/serverinfo',
                  ],
                  isRequired: false,
                  varAttr: 'FORM_TYPE',
                  type: 'hidden',
                )
              ],
              reported: [],
              items: [],
            ),
          if (multipleExtendedFormsWithSameType)
            const DataForm(
              type: 'result',
              instructions: [],
              fields: [
                DataFormField(
                  options: [],
                  values: [
                    'http://jabber.org/network/serverinfo',
                  ],
                  isRequired: false,
                  varAttr: 'FORM_TYPE',
                  type: 'hidden',
                ),
              ],
              reported: [],
              items: [],
            ),
          if (invalidExtension1)
            const DataForm(
              type: 'result',
              instructions: [],
              fields: [],
              reported: [],
              items: [],
            ),
          if (invalidExtension2)
            const DataForm(
              type: 'result',
              instructions: [],
              fields: [
                DataFormField(
                  options: [],
                  values: [
                    'http://jabber.org/network/serverinfo',
                  ],
                  isRequired: false,
                  varAttr: 'FORM_TYPE',
                ),
              ],
              reported: [],
              items: [],
            ),
          if (invalidExtension3)
            const DataForm(
              type: 'result',
              instructions: [],
              fields: [
                DataFormField(
                  options: [],
                  values: [
                    'http://jabber.org/network/serverinfo',
                    'http://jabber.org/network/better-serverinfo',
                  ],
                  isRequired: false,
                  varAttr: 'FORM_TYPE',
                  type: 'hidden',
                ),
              ],
              reported: [],
              items: [],
            ),
        ],
        null,
        JID.fromString('some@user.local/test'),
      ),
    );
  }
}

void main() {
  initLogger();

  test('Test XEP example', () async {
    final data = DiscoInfo(
      const [
        'http://jabber.org/protocol/caps',
        'http://jabber.org/protocol/disco#info',
        'http://jabber.org/protocol/disco#items',
        'http://jabber.org/protocol/muc'
      ],
      const [
        Identity(
          category: 'client',
          type: 'pc',
          name: 'Exodus 0.9.1',
        )
      ],
      const [],
      null,
      JID.fromString('some@user.local/test'),
    );

    final hash = await calculateCapabilityHash(HashFunction.sha1, data);
    expect(hash, 'QgayPKawpkPSDYmwT/WM94uAlu0=');
  });

  test('Test complex generation example', () async {
    const extDiscoDataString =
        "<x xmlns='jabber:x:data' type='result'><field var='FORM_TYPE' type='hidden'><value>urn:xmpp:dataforms:softwareinfo</value></field><field var='ip_version' type='text-multi' ><value>ipv4</value><value>ipv6</value></field><field var='os'><value>Mac</value></field><field var='os_version'><value>10.5.1</value></field><field var='software'><value>Psi</value></field><field var='software_version'><value>0.11</value></field></x>";
    final data = DiscoInfo(
      const [
        'http://jabber.org/protocol/caps',
        'http://jabber.org/protocol/disco#info',
        'http://jabber.org/protocol/disco#items',
        'http://jabber.org/protocol/muc'
      ],
      const [
        Identity(
          category: 'client',
          type: 'pc',
          name: 'Psi 0.11',
          lang: 'en',
        ),
        Identity(
          category: 'client',
          type: 'pc',
          name: 'Ψ 0.11',
          lang: 'el',
        ),
      ],
      [parseDataForm(XMLNode.fromString(extDiscoDataString))],
      null,
      JID.fromString('some@user.local/test'),
    );

    final hash = await calculateCapabilityHash(HashFunction.sha1, data);
    expect(hash, 'q07IKJEyjvHSyhy//CH0CxmKi8w=');
  });

  test('Test Gajim capability hash computation', () async {
    // TODO(Unknown): This one fails
    /*
    final data = DiscoInfo(
      features: [
        "http://jabber.org/protocol/bytestreams",
        "http://jabber.org/protocol/muc",
        "http://jabber.org/protocol/commands",
        "http://jabber.org/protocol/disco#info",
        "jabber:iq:last",
        "jabber:x:data",
        "jabber:x:encrypted",
        "urn:xmpp:ping",
        "http://jabber.org/protocol/chatstates",
        "urn:xmpp:receipts",
        "urn:xmpp:time",
        "jabber:iq:version",
        "http://jabber.org/protocol/rosterx",
        "urn:xmpp:sec-label:0",
        "jabber:x:conference",
        "urn:xmpp:message-correct:0",
        "urn:xmpp:chat-markers:0",
        "urn:xmpp:eme:0",
        "http://jabber.org/protocol/xhtml-im",
        "urn:xmpp:hashes:2",
        "urn:xmpp:hash-function-text-names:md5",
        "urn:xmpp:hash-function-text-names:sha-1",
        "urn:xmpp:hash-function-text-names:sha-256",
        "urn:xmpp:hash-function-text-names:sha-512",
        "urn:xmpp:hash-function-text-names:sha3-256",
        "urn:xmpp:hash-function-text-names:sha3-512",
        "urn:xmpp:hash-function-text-names:id-blake2b256",
        "urn:xmpp:hash-function-text-names:id-blake2b512",
        "urn:xmpp:jingle:1",
        "urn:xmpp:jingle:apps:file-transfer:5",
        "urn:xmpp:jingle:security:xtls:0",
        "urn:xmpp:jingle:transports:s5b:1",
        "urn:xmpp:jingle:transports:ibb:1",
        "urn:xmpp:avatar:metadata+notify",
        "urn:xmpp:message-moderate:0",
        "http://jabber.org/protocol/tune+notify",
        "http://jabber.org/protocol/geoloc+notify",
        "http://jabber.org/protocol/nick+notify",
        "eu.siacs.conversations.axolotl.devicelist+notify",
      ],
      identities: [
        Identity(
          category: "client",
          type: "pc",
          name: "Gajim"
        )
      ]
    );

    final hash = await calculateCapabilityHash(HashFunction.sha1, data);
    expect(hash, "T7fOZrtBnV8sDA2fFTS59vyOyUs=");
    */
  });

  test('Test Conversations hash computation', () async {
    final data = DiscoInfo(
      const [
        'eu.siacs.conversations.axolotl.devicelist+notify',
        'http://jabber.org/protocol/caps',
        'http://jabber.org/protocol/chatstates',
        'http://jabber.org/protocol/disco#info',
        'http://jabber.org/protocol/muc',
        'http://jabber.org/protocol/nick+notify',
        'jabber:iq:version',
        'jabber:x:conference',
        'jabber:x:oob',
        'storage:bookmarks+notify',
        'urn:xmpp:avatar:metadata+notify',
        'urn:xmpp:chat-markers:0',
        'urn:xmpp:jingle-message:0',
        'urn:xmpp:jingle:1',
        'urn:xmpp:jingle:apps:dtls:0',
        'urn:xmpp:jingle:apps:file-transfer:3',
        'urn:xmpp:jingle:apps:file-transfer:4',
        'urn:xmpp:jingle:apps:file-transfer:5',
        'urn:xmpp:jingle:apps:rtp:1',
        'urn:xmpp:jingle:apps:rtp:audio',
        'urn:xmpp:jingle:apps:rtp:video',
        'urn:xmpp:jingle:jet-omemo:0',
        'urn:xmpp:jingle:jet:0',
        'urn:xmpp:jingle:transports:ibb:1',
        'urn:xmpp:jingle:transports:ice-udp:1',
        'urn:xmpp:jingle:transports:s5b:1',
        'urn:xmpp:message-correct:0',
        'urn:xmpp:ping',
        'urn:xmpp:receipts',
        'urn:xmpp:time'
      ],
      const [
        Identity(
          category: 'client',
          type: 'phone',
          name: 'Conversations',
        )
      ],
      const [],
      null,
      JID.fromString('user@server.local/test'),
    );

    final hash = await calculateCapabilityHash(HashFunction.sha1, data);
    expect(hash, 'zcIke+Rk13ah4d1pwDG7bEZsVwA=');
  });

  group('Receiving a capability hash', () {
    final aliceJid = JID.fromString('alice@example.org/abc123');

    test('Caching a correct capability hash', () async {
      final tm = TestingManagerHolder();
      final manager = EntityCapabilitiesManager('');

      await tm.register([
        StubbedDiscoManager(),
        manager,
      ]);

      final stanza = Stanza.presence(
        from: aliceJid.toString(),
        children: [
          XMLNode.xmlns(
            tag: 'c',
            xmlns: capsXmlns,
            attributes: {
              'hash': 'sha-1',
              'node': 'http://example.org/client',
              'ver': 'QgayPKawpkPSDYmwT/WM94uAlu0=',
            },
          ),
        ],
      );
      await manager.onPresence(
        stanza,
        StanzaHandlerData(false, false, stanza, TypedMap()),
      );

      expect(
        await manager.getCachedDiscoInfoFromJid(aliceJid) != null,
        true,
      );
    });

    test('Not caching an incorrect capability hash string', () async {
      final tm = TestingManagerHolder();
      final manager = EntityCapabilitiesManager('');

      await tm.register([
        StubbedDiscoManager(),
        manager,
      ]);

      final stanza = Stanza.presence(
        from: aliceJid.toString(),
        children: [
          XMLNode.xmlns(
            tag: 'c',
            xmlns: capsXmlns,
            attributes: {
              'hash': 'sha-1',
              'node': 'http://example.org/client',
              'ver': 'QgayPKawpkPSDYmwT/WM94AAAAA=',
            },
          ),
        ],
      );
      await manager.onPresence(
        stanza,
        StanzaHandlerData(false, false, stanza, TypedMap()),
      );

      expect(
        await manager.getCachedDiscoInfoFromJid(aliceJid),
        null,
      );
    });

    test('Not caching ill-formed identities', () async {
      final tm = TestingManagerHolder();
      final manager = EntityCapabilitiesManager('');

      await tm.register([
        StubbedDiscoManager()..multipleEqualIdentities = true,
        manager,
      ]);

      final stanza = Stanza.presence(
        from: aliceJid.toString(),
        children: [
          XMLNode.xmlns(
            tag: 'c',
            xmlns: capsXmlns,
            attributes: {
              'hash': 'sha-1',
              'node': 'http://example.org/client',
              'ver': 'QgayPKawpkPSDYmwT/WM94uAlu0=',
            },
          ),
        ],
      );
      await manager.onPresence(
        stanza,
        StanzaHandlerData(false, false, stanza, TypedMap()),
      );

      expect(
        await manager.getCachedDiscoInfoFromJid(aliceJid),
        null,
      );
    });

    test('Not caching ill-formed features', () async {
      final tm = TestingManagerHolder();
      final manager = EntityCapabilitiesManager('');

      await tm.register([
        StubbedDiscoManager()..multipleEqualFeatures = true,
        manager,
      ]);

      final stanza = Stanza.presence(
        from: aliceJid.toString(),
        children: [
          XMLNode.xmlns(
            tag: 'c',
            xmlns: capsXmlns,
            attributes: {
              'hash': 'sha-1',
              'node': 'http://example.org/client',
              'ver': 'QgayPKawpkPSDYmwT/WM94uAlu0=',
            },
          ),
        ],
      );
      await manager.onPresence(
        stanza,
        StanzaHandlerData(false, false, stanza, TypedMap()),
      );

      expect(
        await manager.getCachedDiscoInfoFromJid(aliceJid),
        null,
      );
    });

    test('Not caching multiple forms with equal FORM_TYPE', () async {
      final tm = TestingManagerHolder();
      final manager = EntityCapabilitiesManager('');

      await tm.register([
        StubbedDiscoManager()..multipleExtendedFormsWithSameType = true,
        manager,
      ]);

      final stanza = Stanza.presence(
        from: aliceJid.toString(),
        children: [
          XMLNode.xmlns(
            tag: 'c',
            xmlns: capsXmlns,
            attributes: {
              'hash': 'sha-1',
              'node': 'http://example.org/client',
              'ver': 'QgayPKawpkPSDYmwT/WM94uAlu0=',
            },
          ),
        ],
      );
      await manager.onPresence(
        stanza,
        StanzaHandlerData(false, false, stanza, TypedMap()),
      );

      expect(
        await manager.getCachedDiscoInfoFromJid(aliceJid),
        null,
      );
    });

    test('Caching without invalid form (no FORM_TYPE)', () async {
      final tm = TestingManagerHolder();
      final manager = EntityCapabilitiesManager('');

      await tm.register([
        StubbedDiscoManager()..invalidExtension1 = true,
        manager,
      ]);

      final stanza = Stanza.presence(
        from: aliceJid.toString(),
        children: [
          XMLNode.xmlns(
            tag: 'c',
            xmlns: capsXmlns,
            attributes: {
              'hash': 'sha-1',
              'node': 'http://example.org/client',
              'ver': 'QgayPKawpkPSDYmwT/WM94uAlu0=',
            },
          ),
        ],
      );
      await manager.onPresence(
        stanza,
        StanzaHandlerData(false, false, stanza, TypedMap()),
      );

      final cachedItem = await manager.getCachedDiscoInfoFromJid(aliceJid);
      expect(
        cachedItem != null,
        true,
      );
      expect(cachedItem!.extendedInfo.isEmpty, true);
    });

    test('Caching without invalid form (FORM_TYPE not hidden)', () async {
      final tm = TestingManagerHolder();
      final manager = EntityCapabilitiesManager('');

      await tm.register([
        StubbedDiscoManager()..invalidExtension2 = true,
        manager,
      ]);

      final stanza = Stanza.presence(
        from: aliceJid.toString(),
        children: [
          XMLNode.xmlns(
            tag: 'c',
            xmlns: capsXmlns,
            attributes: {
              'hash': 'sha-1',
              'node': 'http://example.org/client',
              'ver': 'QgayPKawpkPSDYmwT/WM94uAlu0=',
            },
          ),
        ],
      );
      await manager.onPresence(
        stanza,
        StanzaHandlerData(false, false, stanza, TypedMap()),
      );

      final cachedItem = await manager.getCachedDiscoInfoFromJid(aliceJid);
      expect(
        cachedItem != null,
        true,
      );
      expect(cachedItem!.extendedInfo.isEmpty, true);
    });

    test("Not caching as FORM_TYPE's values are distinct", () async {
      final tm = TestingManagerHolder();
      final manager = EntityCapabilitiesManager('');

      await tm.register([
        StubbedDiscoManager()..invalidExtension3 = true,
        manager,
      ]);

      final stanza = Stanza.presence(
        from: aliceJid.toString(),
        children: [
          XMLNode.xmlns(
            tag: 'c',
            xmlns: capsXmlns,
            attributes: {
              'hash': 'sha-1',
              'node': 'http://example.org/client',
              'ver': 'QgayPKawpkPSDYmwT/WM94uAlu0=',
            },
          ),
        ],
      );
      await manager.onPresence(
        stanza,
        StanzaHandlerData(false, false, stanza, TypedMap()),
      );

      expect(
        await manager.getCachedDiscoInfoFromJid(aliceJid),
        null,
      );
    });
  });
}
