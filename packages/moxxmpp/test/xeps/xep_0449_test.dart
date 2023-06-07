import 'package:moxxmpp/moxxmpp.dart';
import 'package:test/test.dart';

import '../helpers/logging.dart';
import '../helpers/manager.dart';
import '../helpers/xmpp.dart';

void main() {
  initLogger();

  test('Test parsing a large sticker pack', () {
    // Example sticker pack based on the "miho" sticker pack by Movim
    final rawPack = XMLNode.fromString('''
<pack xmlns='urn:xmpp:stickers:0'>
    <name>Miho</name>
    <summary>XMPP-chan.</summary>
    <item>
        <file xmlns='urn:xmpp:file:metadata:0'>
            <media-type>image/png</media-type>
            <desc>:miho no:</desc>
            <name>no.png</name>
            <size>32088</size>
            <dimensions>400x400</dimensions>
            <hash xmlns='urn:xmpp:hashes:2' algo='sha-256'>LmIVPPPfOfmf8JLCCi0UFbjzILuRhJlkgzeN/nKIrm8=</hash>
        </file>
        <sources xmlns='urn:xmpp:sfs:0'>
            <url-data xmlns='http://jabber.org/protocol/url-data' target='https://github.com/movim/movim/raw/master/public/stickers/miho/fd759226e3ec153956f3e941b81ed820614792a6.png' />
        </sources>
    </item>
    <item>
        <file xmlns='urn:xmpp:file:metadata:0'>
            <media-type>image/png</media-type>
            <desc>:miho good:</desc>
            <name>good.png</name>
            <size>35529</size>
            <dimensions>400x400</dimensions>
            <hash xmlns='urn:xmpp:hashes:2' algo='sha-256'>Yu8qycCh5e3ZjZGTL5jadHAzni8ufvI+9Y7sKXjFLfE=</hash>
        </file>
        <sources xmlns='urn:xmpp:sfs:0'>
            <url-data xmlns='http://jabber.org/protocol/url-data' target='https://github.com/movim/movim/raw/master/public/stickers/miho/100bdb0e14c557b87ad4d253018b71eb65b80725.png' />
        </sources>
    </item>
    <item>
        <file xmlns='urn:xmpp:file:metadata:0'>
            <media-type>image/png</media-type>
            <desc>:miho think:</desc>
            <name>think.png</name>
            <size>36045</size>
            <dimensions>400x400</dimensions>
            <hash xmlns='urn:xmpp:hashes:2' algo='sha-256'>imQS2JiFO6S0e49p090ZVMDUhMK00LNWvRIpZJCF3wE=</hash>
        </file>
        <sources xmlns='urn:xmpp:sfs:0'>
            <url-data xmlns='http://jabber.org/protocol/url-data' target='https://github.com/movim/movim/raw/master/public/stickers/miho/fc0f48df75138fa0f3aec605629226b8ac57c639.png' />
        </sources>
    </item>
    <item>
        <file xmlns='urn:xmpp:file:metadata:0'>
            <media-type>image/png</media-type>
            <desc>:miho sorry:</desc>
            <name>sorry.png</name>
            <size>29542</size>
            <dimensions>400x400</dimensions>
            <hash xmlns='urn:xmpp:hashes:2' algo='sha-256'>ypwf+tCDjfHYRWNccIM0mh48IwP9YO/xieCZ5EwIUoY=</hash>
        </file>
        <sources xmlns='urn:xmpp:sfs:0'>
            <url-data xmlns='http://jabber.org/protocol/url-data' target='https://github.com/movim/movim/raw/master/public/stickers/miho/f038ef01f098cae73a727618c0fbf9adf3e96ef6.png' />
        </sources>
    </item>
    <item>
        <file xmlns='urn:xmpp:file:metadata:0'>
            <media-type>image/png</media-type>
            <desc>:miho confused:</desc>
            <name>confused.png</name>
            <size>35965</size>
            <dimensions>400x400</dimensions>
            <hash xmlns='urn:xmpp:hashes:2' algo='sha-256'>Za809qdsDuCrDsPxpPAlTrEY4c10Wiap4IXtb+F+dEo=</hash>
        </file>
        <sources xmlns='urn:xmpp:sfs:0'>
            <url-data xmlns='http://jabber.org/protocol/url-data' target='https://github.com/movim/movim/raw/master/public/stickers/miho/eb7d0dd12b283017edee25243c3edacd62033ed0.png' />
        </sources>
    </item>
    <item>
        <file xmlns='urn:xmpp:file:metadata:0'>
            <media-type>image/png</media-type>
            <desc>:miho sparkle:</desc>
            <name>sparkle.png</name>
            <size>35965</size>
            <dimensions>400x400</dimensions>
            <hash xmlns='urn:xmpp:hashes:2' algo='sha-256'>PaNrKyVZtSrqf/qLcf3K6h5u9l90h+P803hDU/yrh9M=</hash>
        </file>
        <sources xmlns='urn:xmpp:sfs:0'>
            <url-data xmlns='http://jabber.org/protocol/url-data' target='https://github.com/movim/movim/raw/master/public/stickers/miho/e599dca3de182a821ef2e92234fb2bfca04a325e.png' />
        </sources>
    </item>
    <item>
        <file xmlns='urn:xmpp:file:metadata:0'>
            <media-type>image/png</media-type>
            <desc>:miho glad:</desc>
            <name>glad.png</name>
            <size>55894</size>
            <dimensions>400x400</dimensions>
            <hash xmlns='urn:xmpp:hashes:2' algo='sha-256'>EeNaIsEp026KJL/OGCluO0lMuFBcqN/FACUBF52lDDc=</hash>
        </file>
        <sources xmlns='urn:xmpp:sfs:0'>
            <url-data xmlns='http://jabber.org/protocol/url-data' target='https://github.com/movim/movim/raw/master/public/stickers/miho/580999b6110e859e336229913a73ec0ae640ef06.png' />
        </sources>
    </item>
    <item>
        <file xmlns='urn:xmpp:file:metadata:0'>
            <media-type>image/png</media-type>
            <desc>:miho shock:</desc>
            <name>shock.png</name>
            <size>34478</size>
            <dimensions>400x400</dimensions>
            <hash xmlns='urn:xmpp:hashes:2' algo='sha-256'>nvoMdblXUoJonvGeMJUgmCOAww17mwNgaQInT1vmi2s=</hash>
        </file>
        <sources xmlns='urn:xmpp:sfs:0'>
            <url-data xmlns='http://jabber.org/protocol/url-data' target='https://github.com/movim/movim/raw/master/public/stickers/miho/c42fc57e5234c4d19a2455178eff2b30bced20ef.png' />
        </sources>
    </item>
    <item>
        <file xmlns='urn:xmpp:file:metadata:0'>
            <media-type>image/png</media-type>
            <desc>:miho stare:</desc>
            <name>stare.png</name>
            <size>34574</size>
            <dimensions>400x400</dimensions>
            <hash xmlns='urn:xmpp:hashes:2' algo='sha-256'>VDhOMXWPeLL64rhJ/SBTz/Remt7AWhxb0HzdPYc48tY=</hash>
        </file>
        <sources xmlns='urn:xmpp:sfs:0'>
            <url-data xmlns='http://jabber.org/protocol/url-data' target='https://github.com/movim/movim/raw/master/public/stickers/miho/c069c6deff735fab3e4416ca354594a64a79ae40.png' />
        </sources>
    </item>
    <item>
        <file xmlns='urn:xmpp:file:metadata:0'>
            <media-type>image/png</media-type>
            <desc>:miho happy:</desc>
            <name>happy.png</name>
            <size>32984</size>
            <dimensions>400x400</dimensions>
            <hash xmlns='urn:xmpp:hashes:2' algo='sha-256'>P5AvAPByh8n0hOCamrN4YCc9oA7XwdGvSbBHMJf8RBg=</hash>
        </file>
        <sources xmlns='urn:xmpp:sfs:0'>
            <url-data xmlns='http://jabber.org/protocol/url-data' target='https://github.com/movim/movim/raw/master/public/stickers/miho/ae0ba6cdae25fbe512dc53c7e0413d706a9410f8.png' />
        </sources>
    </item>
    <item>
        <file xmlns='urn:xmpp:file:metadata:0'>
            <media-type>image/png</media-type>
            <desc>:miho angry:</desc>
            <name>angry.png</name>
            <size>37862</size>
            <dimensions>400x400</dimensions>
            <hash xmlns='urn:xmpp:hashes:2' algo='sha-256'>m/NrSawqkK0qdO6fi6HPiagsizqBJMZWoIhS0g2O3m0=</hash>
        </file>
        <sources xmlns='urn:xmpp:sfs:0'>
            <url-data xmlns='http://jabber.org/protocol/url-data' target='https://github.com/movim/movim/raw/master/public/stickers/miho/a3366676e1aea97dd9425fe7cc45a6ed86288f2e.png' />
        </sources>
    </item>
    <item>
        <file xmlns='urn:xmpp:file:metadata:0'>
            <media-type>image/png</media-type>
            <desc>:miho speechless:</desc>
            <name>speechless.png</name>
            <size>30721</size>
            <dimensions>400x400</dimensions>
            <hash xmlns='urn:xmpp:hashes:2' algo='sha-256'>tIxqUrkiXWHRWUC4/Pk/rO/B0EuwyQq8GkawxE/NsF8=</hash>
        </file>
        <sources xmlns='urn:xmpp:sfs:0'>
            <url-data xmlns='http://jabber.org/protocol/url-data' target='https://github.com/movim/movim/raw/master/public/stickers/miho/777e80a69ccc9c9938457844f9723f4debac0653.png' />
        </sources>
    </item>
    <item>
        <file xmlns='urn:xmpp:file:metadata:0'>
            <media-type>image/png</media-type>
            <desc>:miho laugh:</desc>
            <name>laugh.png</name>
            <size>36209</size>
            <dimensions>400x400</dimensions>
            <hash xmlns='urn:xmpp:hashes:2' algo='sha-256'>MqH3vXkXJn1k3nZ6YBAT2di6ZhXVxk/StVbgX/nI9/0=</hash>
        </file>
        <sources xmlns='urn:xmpp:sfs:0'>
            <url-data xmlns='http://jabber.org/protocol/url-data' target='https://github.com/movim/movim/raw/master/public/stickers/miho/6bbee3f5bcaeecbaa9fac68ba1aa4656e10a158d.png' />
        </sources>
    </item>
    <item>
        <file xmlns='urn:xmpp:file:metadata:0'>
            <media-type>image/png</media-type>
            <desc>:miho surprise:</desc>
            <name>surprise.png</name>
            <size>34655</size>
            <dimensions>400x400</dimensions>
            <hash xmlns='urn:xmpp:hashes:2' algo='sha-256'>3CsvFu1vZNpLVLgHDPPQJ8w9Dm4Hd3VPpuKZn7+wcXc=</hash>
        </file>
        <sources xmlns='urn:xmpp:sfs:0'>
            <url-data xmlns='http://jabber.org/protocol/url-data' target='https://github.com/movim/movim/raw/master/public/stickers/miho/34a406c2212522d7e6b60e888665267b16fc37ba.png' />
        </sources>
    </item>
    <item>
        <file xmlns='urn:xmpp:file:metadata:0'>
            <media-type>image/png</media-type>
            <desc>:miho sad:</desc>
            <name>sad.png</name>
            <size>32655</size>
            <dimensions>400x400</dimensions>
            <hash xmlns='urn:xmpp:hashes:2' algo='sha-256'>12pOZSdygnaaaXeDDAN6995LXdLfalKXTRrVbnBxjE0=</hash>
        </file>
        <sources xmlns='urn:xmpp:sfs:0'>
            <url-data xmlns='http://jabber.org/protocol/url-data' target='https://github.com/movim/movim/raw/master/public/stickers/miho/3142d1222d82d9f2dbe48d284c8f189660f418c3.png' />
        </sources>
    </item>
    <item>
        <file xmlns='urn:xmpp:file:metadata:0'>
            <media-type>image/png</media-type>
            <desc>:miho blush:</desc>
            <name>blush.png</name>
            <size>30476</size>
            <dimensions>400x400</dimensions>
            <hash xmlns='urn:xmpp:hashes:2' algo='sha-256'>Q8wdGYxHvO5EmMEEqWbwESr99hiKfLlK/LPp4yL8UgY=</hash>
        </file>
        <sources xmlns='urn:xmpp:sfs:0'>
            <url-data xmlns='http://jabber.org/protocol/url-data' target='https://github.com/movim/movim/raw/master/public/stickers/miho/04214b0b967163915432d5406adec8c4017e093b.png' />
        </sources>
    </item>
    <hash xmlns='urn:xmpp:hashes:2' algo='sha-256'>Epasa8DHHzFrE4zd+xaNpVb4jbu4s74XtioExNjQzZ0=</hash>
</pack>''');
    final pack = StickerPack.fromXML(
      'Epasa8DHHzFrE4zd+xaNpVb4jbu4s74XtioExNjQzZ0=',
      rawPack,
    );

    expect(pack.stickers.length, 16);
  });

  test('Test sending a sticker', () async {
    final manager = MessageManager();
    final holder = TestingManagerHolder(
      stubSocket: StubTCPSocket([
        StanzaExpectation(
          // Example taken from https://xmpp.org/extensions/xep-0449.html#send
          // - Replaced <dimensions /> with <width /> and <height />
          '''
<message to="user@example.org" type="chat">
  <sticker xmlns='urn:xmpp:stickers:0' pack='EpRv28DHHzFrE4zd+xaNpVb4' />
  <file-sharing xmlns='urn:xmpp:sfs:0'>
    <file xmlns='urn:xmpp:file:metadata:0'>
      <media-type>image/png</media-type>
      <desc>😘</desc>
      <size>67016</size>
      <width>512</width>
      <height>512</height>
      <hash xmlns='urn:xmpp:hashes:2' algo='sha-256'>gw+6xdCgOcvCYSKuQNrXH33lV9NMzuDf/s0huByCDsY=</hash>
    </file>
    <sources>
      <url-data xmlns='http://jabber.org/protocol/url-data' target='https://download.montague.lit/51078299-d071-46e1-b6d3-3de4a8ab67d6/sticker_marsey_kiss.png' />
    </sources>
  </file-sharing>
</message>
''',
          '',
        ),
      ]),
    );
    await holder.register([
      manager,
      StickersManager(),
      SFSManager(),
    ]);

    await manager.sendMessage(
      JID.fromString('user@example.org'),
      TypedMap()
        ..set(
          StickersData(
            'EpRv28DHHzFrE4zd+xaNpVb4',
            StatelessFileSharingData(
              const FileMetadataData(
                mediaType: 'image/png',
                desc: '😘',
                size: 67016,
                width: 512,
                height: 512,
                hashes: {
                  HashFunction.sha256:
                      'gw+6xdCgOcvCYSKuQNrXH33lV9NMzuDf/s0huByCDsY=',
                },
                thumbnails: [],
              ),
              [
                StatelessFileSharingUrlSource(
                  'https://download.montague.lit/51078299-d071-46e1-b6d3-3de4a8ab67d6/sticker_marsey_kiss.png',
                ),
              ],
            ),
          ),
        ),
    );
    await Future<void>.delayed(const Duration(seconds: 1));

    expect(holder.socket.getState(), 1);
  });

  test('Test receiving a sticker', () async {
    final fakeSocket = StubTCPSocket(
      [
        StringExpectation(
          "<stream:stream xmlns='jabber:client' version='1.0' xmlns:stream='http://etherx.jabber.org/streams' to='test.server' from='polynomdivision@test.server' xml:lang='en'>",
          '''
<stream:stream
    xmlns="jabber:client"
    version="1.0"
    xmlns:stream="http://etherx.jabber.org/streams"
    from="test.server"
    xml:lang="en">
  <stream:features xmlns="http://etherx.jabber.org/streams">
    <mechanisms xmlns="urn:ietf:params:xml:ns:xmpp-sasl">
      <mechanism>PLAIN</mechanism>
    </mechanisms>
  </stream:features>''',
        ),
        StringExpectation(
          "<auth xmlns='urn:ietf:params:xml:ns:xmpp-sasl' mechanism='PLAIN'>AHBvbHlub21kaXZpc2lvbgBhYWFh</auth>",
          '<success xmlns="urn:ietf:params:xml:ns:xmpp-sasl" />',
        ),
        StringExpectation(
          "<stream:stream xmlns='jabber:client' version='1.0' xmlns:stream='http://etherx.jabber.org/streams' to='test.server' from='polynomdivision@test.server' xml:lang='en'>",
          '''
<stream:stream
    xmlns="jabber:client"
    version="1.0"
    xmlns:stream="http://etherx.jabber.org/streams"
    from="test.server"
    xml:lang="en">
  <stream:features xmlns="http://etherx.jabber.org/streams">
    <bind xmlns="urn:ietf:params:xml:ns:xmpp-bind">
      <required/>
    </bind>
    <session xmlns="urn:ietf:params:xml:ns:xmpp-session">
      <optional/>
    </session>
    <csi xmlns="urn:xmpp:csi:0"/>
    <sm xmlns="urn:xmpp:sm:3"/>
  </stream:features>
''',
        ),
        StanzaExpectation(
          '<iq xmlns="jabber:client" type="set" id="a"><bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"/></iq>',
          '<iq xmlns="jabber:client" type="result" id="a"><bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"><jid>polynomdivision@test.server/MU29eEZn</jid></bind></iq>',
          ignoreId: true,
        ),
      ],
    );
    final conn = XmppConnection(
      TestingReconnectionPolicy(),
      AlwaysConnectedConnectivityManager(),
      ClientToServerNegotiator(),
      fakeSocket,
    )..connectionSettings = ConnectionSettings(
        jid: JID.fromString('polynomdivision@test.server'),
        password: 'aaaa',
      );
    await conn.registerManagers([
      MessageManager(),
      SFSManager(),
      StickersManager(),
    ]);
    await conn.registerFeatureNegotiators([
      SaslPlainNegotiator(),
      ResourceBindingNegotiator(),
    ]);
    await conn.connect(
      shouldReconnect: false,
      enableReconnectOnSuccess: false,
      waitUntilLogin: true,
    );

    MessageEvent? messageEvent;
    conn.asBroadcastStream().listen((event) {
      if (event is MessageEvent) {
        messageEvent = event;
      }
    });

    // Send the fake message
    fakeSocket.injectRawXml(
      '''
<message id="aaaaaaaaa" from="user@example.org" to="polynomdivision@test.server/abc123" type="chat">
  <sticker xmlns='urn:xmpp:stickers:0' pack='EpRv28DHHzFrE4zd+xaNpVb4' />
  <file-sharing xmlns='urn:xmpp:sfs:0'>
    <file xmlns='urn:xmpp:file:metadata:0'>
      <media-type>image/png</media-type>
      <desc>😘</desc>
      <size>67016</size>
      <width>512</width>
      <height>512</height>
      <hash xmlns='urn:xmpp:hashes:2' algo='sha-256'>gw+6xdCgOcvCYSKuQNrXH33lV9NMzuDf/s0huByCDsY=</hash>
    </file>
    <sources>
      <url-data xmlns='http://jabber.org/protocol/url-data' target='https://download.montague.lit/51078299-d071-46e1-b6d3-3de4a8ab67d6/sticker_marsey_kiss.png' />
    </sources>
  </file-sharing>
</message>
''',
    );

    await Future<void>.delayed(const Duration(seconds: 2));
    final sticker = messageEvent!.extensions.get<StickersData>()!;
    final sfs = messageEvent!.extensions.get<StatelessFileSharingData>()!;
    expect(sticker.stickerPackId, 'EpRv28DHHzFrE4zd+xaNpVb4');
    expect(sfs.metadata.desc, '😘');
    expect(
      sfs.sources.first is StatelessFileSharingUrlSource,
      true,
    );
  });
}
