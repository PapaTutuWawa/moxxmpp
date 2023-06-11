import 'package:moxxmpp/moxxmpp.dart';
import 'package:test/test.dart';
import '../helpers/logging.dart';
import '../helpers/xmpp.dart';

void main() {
  initLogger();

  test("Test if we're vulnerable against CVE-2020-26547 style vulnerabilities",
      () async {
    final attributes = XmppManagerAttributes(
      sendStanza: (StanzaDetails details) async {
        // ignore: avoid_print
        print('==> ${details.stanza.toXml()}');
        return XMLNode(tag: 'iq', attributes: {'type': 'result'});
      },
      sendNonza: (nonza) {},
      sendEvent: (event) {},
      getManagerById: getManagerNullStub,
      getConnectionSettings: () => ConnectionSettings(
        jid: JID.fromString('bob@xmpp.example'),
        password: 'password',
      ),
      getFullJID: () => JID.fromString('bob@xmpp.example/uwu'),
      getSocket: () => StubTCPSocket([]),
      getConnection: () => XmppConnection(
        TestingReconnectionPolicy(),
        AlwaysConnectedConnectivityManager(),
        ClientToServerNegotiator(),
        StubTCPSocket([]),
      ),
      getNegotiatorById: getNegotiatorNullStub,
    );
    final manager = CarbonsManager()..register(attributes);
    await manager.enableCarbons();

    expect(
      manager.isCarbonValid(JID.fromString('mallory@evil.example')),
      false,
    );
    expect(
      manager.isCarbonValid(JID.fromString('bob@xmpp.example')),
      true,
    );
    expect(
      manager.isCarbonValid(JID.fromString('bob@xmpp.example/abc')),
      false,
    );
  });

  test('Test enabling message carbons inline with Bind2', () async {
    final fakeSocket = StubTCPSocket([
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
    <authentication xmlns='urn:xmpp:sasl:2'>
      <mechanism>PLAIN</mechanism>
      <inline>
        <resume xmlns="urn:xmpp:sm:3" />
        <bind xmlns="urn:xmpp:bind:0">
          <inline>
            <feature var="urn:xmpp:sm:3" />
            <feature var="urn:xmpp:carbons:2" />
          </inline>
        </bind>
      </inline>
    </authentication>
    <bind xmlns="urn:ietf:params:xml:ns:xmpp-bind">
      <required/>
    </bind>
  </stream:features>''',
      ),
      StanzaExpectation(
        "<authenticate xmlns='urn:xmpp:sasl:2' mechanism='PLAIN'><user-agent id='d4565fa7-4d72-4749-b3d3-740edbf87770'><software>moxxmpp</software><device>PapaTutuWawa's awesome device</device></user-agent><initial-response>AHBvbHlub21kaXZpc2lvbgBhYWFh</initial-response><bind xmlns='urn:xmpp:bind:0'><enable xmlns='urn:xmpp:carbons:2' /></bind></authenticate>",
        '''
<success xmlns='urn:xmpp:sasl:2'>
  <authorization-identifier>polynomdivision@test.server/test-resource</authorization-identifier>
  <bound xmlns='urn:xmpp:bind:0'>
    <enabled xmlns='urn:xmpp:carbons:2' />
  </bound>
</success>
        ''',
      ),
    ]);
    final conn = XmppConnection(
      TestingReconnectionPolicy(),
      AlwaysConnectedConnectivityManager(),
      ClientToServerNegotiator(),
      fakeSocket,
    )
      ..connectionSettings = ConnectionSettings(
        jid: JID.fromString('polynomdivision@test.server'),
        password: 'aaaa',
      )
      ..setResource('test-resource', triggerEvent: false);
    await conn.registerManagers([
      RosterManager(TestingRosterStateManager('', [])),
      DiscoManager([]),
      CarbonsManager(),
    ]);

    await conn.registerFeatureNegotiators([
      SaslPlainNegotiator(),
      ResourceBindingNegotiator(),
      CarbonsNegotiator(),
      Bind2Negotiator(),
      Sasl2Negotiator()
        ..userAgent = const UserAgent(
          id: 'd4565fa7-4d72-4749-b3d3-740edbf87770',
          software: 'moxxmpp',
          device: "PapaTutuWawa's awesome device",
        ),
    ]);

    final result = await conn.connect(
      waitUntilLogin: true,
      shouldReconnect: false,
      enableReconnectOnSuccess: false,
    );
    expect(result.isType<NegotiatorError>(), false);
    expect(conn.resource, 'test-resource');
    expect(
      conn.getManagerById<CarbonsManager>(carbonsManager)!.isEnabled,
      true,
    );
  });
}
