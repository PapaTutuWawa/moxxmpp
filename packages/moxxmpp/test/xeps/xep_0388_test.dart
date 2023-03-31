import 'package:moxxmpp/moxxmpp.dart';
import 'package:test/test.dart';
import '../helpers/logging.dart';
import '../helpers/xmpp.dart';

void main() {
  initLogger();

  test('Test simple SASL2 negotiation', () async {
    final fakeSocket = StubTCPSocket([
      StringExpectation(
        "<stream:stream xmlns='jabber:client' version='1.0' xmlns:stream='http://etherx.jabber.org/streams' to='test.server' xml:lang='en'>",
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
    </authentication>
    <bind xmlns="urn:ietf:params:xml:ns:xmpp-bind">
      <required/>
    </bind>
  </stream:features>''',
      ),
      StanzaExpectation(
        "<authenticate xmlns='urn:xmpp:sasl:2' mechanism='PLAIN'><user-agent id='d4565fa7-4d72-4749-b3d3-740edbf87770'><software>moxxmpp</software><device>PapaTutuWawa's awesome device</device></user-agent><initial-response>AHBvbHlub21kaXZpc2lvbgBhYWFh</initial-response></authenticate>",
        '''
<success xmlns='urn:xmpp:sasl:2'>
  <authorization-identifier>polynomdivision@test.server</authorization-identifier>
</success>
        ''',
      ),
      StanzaExpectation(
        "<iq xmlns='jabber:client' type='set' id='aaaa'><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind' /></iq>",
        '''
'<iq xmlns="jabber:client" type="result" id="a"><bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"><jid>polynomdivision@test.server/MU29eEZn</jid></bind></iq>',
        ''',
        adjustId: true,
        ignoreId: true,
      ),
    ]);
    final conn = XmppConnection(
      TestingReconnectionPolicy(),
      AlwaysConnectedConnectivityManager(),
      fakeSocket,
    )..setConnectionSettings(
        ConnectionSettings(
          jid: JID.fromString('polynomdivision@test.server'),
          password: 'aaaa',
          useDirectTLS: true,
        ),
      );
    await conn.registerManagers([
      PresenceManager(),
      RosterManager(TestingRosterStateManager('', [])),
      DiscoManager([]),
    ]);
    await conn.registerFeatureNegotiators([
      SaslPlainNegotiator(),
      ResourceBindingNegotiator(),
      Sasl2Negotiator(
        userAgent: const UserAgent(
          id: 'd4565fa7-4d72-4749-b3d3-740edbf87770',
          software: 'moxxmpp',
          device: "PapaTutuWawa's awesome device",
        ),
      ),
    ]);

    final result = await conn.connect(
      waitUntilLogin: true,
      shouldReconnect: false,
      enableReconnectOnSuccess: false,
    );
    expect(result.isType<NegotiatorError>(), false);
  });

  test('Test SCRAM-SHA-1 SASL2 negotiation with a valid signature', () async {
    final fakeSocket = StubTCPSocket([
      StringExpectation(
        "<stream:stream xmlns='jabber:client' version='1.0' xmlns:stream='http://etherx.jabber.org/streams' to='server' xml:lang='en'>",
        '''
<stream:stream
    xmlns="jabber:client"
    version="1.0"
    xmlns:stream="http://etherx.jabber.org/streams"
    from="server"
    xml:lang="en">
  <stream:features xmlns="http://etherx.jabber.org/streams">
    <mechanisms xmlns="urn:ietf:params:xml:ns:xmpp-sasl">
      <mechanism>PLAIN</mechanism>
      <mechanism>SCRAM-SHA-256</mechanism>
    </mechanisms>
    <authentication xmlns='urn:xmpp:sasl:2'>
      <mechanism>PLAIN</mechanism>
      <mechanism>SCRAM-SHA-256</mechanism>
    </authentication>
    <bind xmlns="urn:ietf:params:xml:ns:xmpp-bind">
      <required/>
    </bind>
  </stream:features>''',
      ),
      StanzaExpectation(
        "<authenticate xmlns='urn:xmpp:sasl:2' mechanism='SCRAM-SHA-256'><user-agent id='d4565fa7-4d72-4749-b3d3-740edbf87770'><software>moxxmpp</software><device>PapaTutuWawa's awesome device</device></user-agent><initial-response>biwsbj11c2VyLHI9ck9wck5HZndFYmVSV2diTkVrcU8=</initial-response></authenticate>",
        '''
<challenge xmlns='urn:xmpp:sasl:2'>cj1yT3ByTkdmd0ViZVJXZ2JORWtxTyVodllEcFdVYTJSYVRDQWZ1eEZJbGopaE5sRiRrMCxzPVcyMlphSjBTTlk3c29Fc1VFamI2Z1E9PSxpPTQwOTY=</challenge>
        ''',
      ),
      StanzaExpectation(
        '<response xmlns="urn:xmpp:sasl:2">Yz1iaXdzLHI9ck9wck5HZndFYmVSV2diTkVrcU8laHZZRHBXVWEyUmFUQ0FmdXhGSWxqKWhObEYkazAscD1kSHpiWmFwV0lrNGpVaE4rVXRlOXl0YWc5empmTUhnc3FtbWl6N0FuZFZRPQ==</response>',
        '<success xmlns="urn:xmpp:sasl:2"><additional-data>dj02cnJpVFJCaTIzV3BSUi93dHVwK21NaFVaVW4vZEI1bkxUSlJzamw5NUc0PQ==</additional-data><authorization-identifier>user@server</authorization-identifier></success>',
      ),
      StanzaExpectation(
        "<iq xmlns='jabber:client' type='set' id='aaaa'><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind' /></iq>",
        '''
'<iq xmlns="jabber:client" type="result" id="a"><bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"><jid>polynomdivision@test.server/MU29eEZn</jid></bind></iq>',
        ''',
        adjustId: true,
        ignoreId: true,
      ),
    ]);
    final conn = XmppConnection(
      TestingReconnectionPolicy(),
      AlwaysConnectedConnectivityManager(),
      fakeSocket,
    )..setConnectionSettings(
        ConnectionSettings(
          jid: JID.fromString('user@server'),
          password: 'pencil',
          useDirectTLS: true,
        ),
      );
    await conn.registerManagers([
      PresenceManager(),
      RosterManager(TestingRosterStateManager('', [])),
      DiscoManager([]),
    ]);
    await conn.registerFeatureNegotiators([
      SaslPlainNegotiator(),
      SaslScramNegotiator(
        10,
        'n=user,r=rOprNGfwEbeRWgbNEkqO',
        'rOprNGfwEbeRWgbNEkqO',
        ScramHashType.sha256,
      ),
      ResourceBindingNegotiator(),
      Sasl2Negotiator(
        userAgent: const UserAgent(
          id: 'd4565fa7-4d72-4749-b3d3-740edbf87770',
          software: 'moxxmpp',
          device: "PapaTutuWawa's awesome device",
        ),
      ),
    ]);

    final result = await conn.connect(
      waitUntilLogin: true,
      shouldReconnect: false,
      enableReconnectOnSuccess: false,
    );
    expect(result.isType<XmppError>(), false);
  });

  test('Test SCRAM-SHA-1 SASL2 negotiation with an invalid signature',
      () async {
    final fakeSocket = StubTCPSocket([
      StringExpectation(
        "<stream:stream xmlns='jabber:client' version='1.0' xmlns:stream='http://etherx.jabber.org/streams' to='server' xml:lang='en'>",
        '''
<stream:stream
    xmlns="jabber:client"
    version="1.0"
    xmlns:stream="http://etherx.jabber.org/streams"
    from="server"
    xml:lang="en">
  <stream:features xmlns="http://etherx.jabber.org/streams">
    <mechanisms xmlns="urn:ietf:params:xml:ns:xmpp-sasl">
      <mechanism>PLAIN</mechanism>
      <mechanism>SCRAM-SHA-256</mechanism>
    </mechanisms>
    <authentication xmlns='urn:xmpp:sasl:2'>
      <mechanism>PLAIN</mechanism>
      <mechanism>SCRAM-SHA-256</mechanism>
    </authentication>
    <bind xmlns="urn:ietf:params:xml:ns:xmpp-bind">
      <required/>
    </bind>
  </stream:features>''',
      ),
      StanzaExpectation(
        "<authenticate xmlns='urn:xmpp:sasl:2' mechanism='SCRAM-SHA-256'><user-agent id='d4565fa7-4d72-4749-b3d3-740edbf87770'><software>moxxmpp</software><device>PapaTutuWawa's awesome device</device></user-agent><initial-response>biwsbj11c2VyLHI9ck9wck5HZndFYmVSV2diTkVrcU8=</initial-response></authenticate>",
        '''
<challenge xmlns='urn:xmpp:sasl:2'>cj1yT3ByTkdmd0ViZVJXZ2JORWtxTyVodllEcFdVYTJSYVRDQWZ1eEZJbGopaE5sRiRrMCxzPVcyMlphSjBTTlk3c29Fc1VFamI2Z1E9PSxpPTQwOTY=</challenge>
        ''',
      ),
      StanzaExpectation(
        '<response xmlns="urn:xmpp:sasl:2">Yz1iaXdzLHI9ck9wck5HZndFYmVSV2diTkVrcU8laHZZRHBXVWEyUmFUQ0FmdXhGSWxqKWhObEYkazAscD1kSHpiWmFwV0lrNGpVaE4rVXRlOXl0YWc5empmTUhnc3FtbWl6N0FuZFZRPQ==</response>',
        '<success xmlns="urn:xmpp:sasl:2"><additional-data>dj1zbUY5cHFWOFM3c3VBb1pXamE0ZEpSa0ZzS1E9</additional-data><authorization-identifier>user@server</authorization-identifier></success>',
      ),
    ]);
    final conn = XmppConnection(
      TestingReconnectionPolicy(),
      AlwaysConnectedConnectivityManager(),
      fakeSocket,
    )..setConnectionSettings(
        ConnectionSettings(
          jid: JID.fromString('user@server'),
          password: 'pencil',
          useDirectTLS: true,
        ),
      );
    await conn.registerManagers([
      PresenceManager(),
      RosterManager(TestingRosterStateManager('', [])),
      DiscoManager([]),
    ]);
    await conn.registerFeatureNegotiators([
      SaslPlainNegotiator(),
      SaslScramNegotiator(
        10,
        'n=user,r=rOprNGfwEbeRWgbNEkqO',
        'rOprNGfwEbeRWgbNEkqO',
        ScramHashType.sha256,
      ),
      ResourceBindingNegotiator(),
      Sasl2Negotiator(
        userAgent: const UserAgent(
          id: 'd4565fa7-4d72-4749-b3d3-740edbf87770',
          software: 'moxxmpp',
          device: "PapaTutuWawa's awesome device",
        ),
      ),
    ]);

    final result = await conn.connect(
      waitUntilLogin: true,
      shouldReconnect: false,
      enableReconnectOnSuccess: false,
    );
    expect(result.isType<NegotiatorError>(), true);
    expect(result.get<NegotiatorError>() is InvalidServerSignatureError, true);
  });
}
