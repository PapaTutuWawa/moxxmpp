import 'package:moxxmpp/moxxmpp.dart';
import 'package:test/test.dart';
import '../helpers/logging.dart';
import '../helpers/xmpp.dart';

void main() {
  initLogger();

  test('Test simple Bind2 negotiation', () async {
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
        <bind xmlns="urn:xmpp:bind:0" />
      </inline>
    </authentication>
    <bind xmlns="urn:ietf:params:xml:ns:xmpp-bind">
      <required/>
    </bind>
  </stream:features>''',
      ),
      StanzaExpectation(
        "<authenticate xmlns='urn:xmpp:sasl:2' mechanism='PLAIN'><user-agent id='d4565fa7-4d72-4749-b3d3-740edbf87770'><software>moxxmpp</software><device>PapaTutuWawa's awesome device</device></user-agent><initial-response>AHBvbHlub21kaXZpc2lvbgBhYWFh</initial-response><bind xmlns='urn:xmpp:bind:0' /></authenticate>",
        '''
<success xmlns='urn:xmpp:sasl:2'>
  <authorization-identifier>polynomdivision@test.server/random.resource</authorization-identifier>
</success>
        ''',
      ),
    ]);
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
      RosterManager(TestingRosterStateManager('', [])),
      DiscoManager([]),
    ]);
    await conn.registerFeatureNegotiators([
      SaslPlainNegotiator(),
      ResourceBindingNegotiator(),
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
    expect(conn.resource, 'random.resource');
  });

  test('Test simple Bind2 negotiation with a provided tag', () async {
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
        <bind xmlns="urn:xmpp:bind:0" />
      </inline>
    </authentication>
    <bind xmlns="urn:ietf:params:xml:ns:xmpp-bind">
      <required/>
    </bind>
  </stream:features>''',
      ),
      StanzaExpectation(
        "<authenticate xmlns='urn:xmpp:sasl:2' mechanism='PLAIN'><user-agent id='d4565fa7-4d72-4749-b3d3-740edbf87770'><software>moxxmpp</software><device>PapaTutuWawa's awesome device</device></user-agent><initial-response>AHBvbHlub21kaXZpc2lvbgBhYWFh</initial-response><bind xmlns='urn:xmpp:bind:0'><tag>moxxmpp</tag></bind></authenticate>",
        '''
<success xmlns='urn:xmpp:sasl:2'>
  <authorization-identifier>polynomdivision@test.server/moxxmpp.random.resource</authorization-identifier>
</success>
        ''',
      ),
    ]);
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
      RosterManager(TestingRosterStateManager('', [])),
      DiscoManager([]),
    ]);
    await conn.registerFeatureNegotiators([
      SaslPlainNegotiator(),
      ResourceBindingNegotiator(),
      Bind2Negotiator()..tag = 'moxxmpp',
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
    expect(conn.resource, 'moxxmpp.random.resource');
  });
}
