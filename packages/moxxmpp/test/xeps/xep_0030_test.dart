import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxmpp/src/xeps/xep_0030/cache.dart';
import 'package:test/test.dart';

import '../helpers/logging.dart';
import '../helpers/manager.dart';
import '../helpers/xmpp.dart';

void main() {
  initLogger();

  test('Test having multiple disco requests for the same JID', () async {
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
        StanzaExpectation(
          "<presence xmlns='jabber:client'><show>chat</show><c xmlns='http://jabber.org/protocol/caps' hash='sha-1' node='http://moxxmpp.example' ver='3QvQ2RAy45XBDhArjxy/vEWMl+E=' /></presence>",
          '',
        ),
        StanzaExpectation(
          "<iq type='get' id='ec325efc-9924-4c48-93f8-ed34a2b0e5fc' to='romeo@montague.lit/orchard' xmlns='jabber:client'><query xmlns='http://jabber.org/protocol/disco#info' /></iq>",
          '',
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
      PresenceManager(),
      RosterManager(TestingRosterStateManager(null, [])),
      DiscoManager([]),
      EntityCapabilitiesManager('http://moxxmpp.example'),
    ]);
    await conn.registerFeatureNegotiators([
      SaslPlainNegotiator(),
      SaslScramNegotiator(10, '', '', ScramHashType.sha512),
      ResourceBindingNegotiator(),
    ]);

    final disco = conn.getManagerById<DiscoManager>(discoManager)!;

    await conn.connect();
    await Future<void>.delayed(const Duration(seconds: 3));

    final jid = JID.fromString('romeo@montague.lit/orchard');
    final result1 = disco.discoInfoQuery(jid);
    final result2 = disco.discoInfoQuery(jid);

    await Future<void>.delayed(const Duration(seconds: 1));
    expect(
      disco.infoTracker.getRunningTasks(DiscoCacheKey(jid, null)).length,
      1,
    );
    fakeSocket.injectRawXml(
      "<iq type='result' id='${fakeSocket.lastId!}' from='romeo@montague.lit/orchard' to='polynomdivision@test.server/MU29eEZn' xmlns='jabber:client'><query xmlns='http://jabber.org/protocol/disco#info' /></iq>",
    );

    await Future<void>.delayed(const Duration(seconds: 2));

    expect(fakeSocket.getState(), 6);
    expect(await result1, await result2);
    expect(disco.infoTracker.hasTasksRunning(), false);
  });

  group('Interactions with Entity Capabilities', () {
    test('Do not query when the capability hash is cached', () async {
      final tm = TestingManagerHolder();
      final ecm = EntityCapabilitiesManager('');
      final dm = DiscoManager([]);

      await tm.register([dm, ecm]);

      // Inject a capability hash into the cache
      final aliceJid = JID.fromString('alice@example.org/abc123');
      ecm.injectIntoCache(
        aliceJid,
        'AAAAAAAAAAAAA',
        DiscoInfo(
          const [],
          const [],
          const [],
          '',
          aliceJid,
        ),
      );

      // Query Alice's device
      final result = await dm.discoInfoQuery(aliceJid);
      expect(result.isType<DiscoError>(), false);
      expect(tm.socket.getState(), 0);
    });
  });
}
