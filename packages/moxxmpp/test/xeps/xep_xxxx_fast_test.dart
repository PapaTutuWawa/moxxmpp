import 'package:moxxmpp/moxxmpp.dart';
import 'package:test/test.dart';
import '../helpers/logging.dart';
import '../helpers/xmpp.dart';

void main() {
  initLogger();

  test('Test FAST authentication without a token', () async {
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
      <mechanism>HT-SHA-256-NONE</mechanism>
    </mechanisms>
    <authentication xmlns='urn:xmpp:sasl:2'>
      <mechanism>PLAIN</mechanism>
      <mechanism>HT-SHA-256-NONE</mechanism>
      <mechanism>HT-SHA-256-ENDP</mechanism>
      <inline>
        <bind xmlns="urn:xmpp:bind:0" />
        <fast xmlns="urn:xmpp:fast:0">
          <mechanism>HT-SHA-256-NONE</mechanism>
          <mechanism>HT-SHA-256-ENDP</mechanism>
        </fast>
      </inline>
    </authentication>
    <bind xmlns="urn:ietf:params:xml:ns:xmpp-bind">
      <required/>
    </bind>
  </stream:features>''',
      ),
      StanzaExpectation(
        "<authenticate xmlns='urn:xmpp:sasl:2' mechanism='PLAIN'><user-agent id='d4565fa7-4d72-4749-b3d3-740edbf87770'><software>moxxmpp</software><device>PapaTutuWawa's awesome device</device></user-agent><initial-response>AHBvbHlub21kaXZpc2lvbgBhYWFh</initial-response><request-token xmlns='urn:xmpp:fast:0' mechanism='HT-SHA-256-NONE' /></authenticate>",
        '''
<success xmlns='urn:xmpp:sasl:2'>
  <authorization-identifier>polynomdivision@test.server</authorization-identifier>
  <token xmlns='urn:xmpp:fast:0' 
           expiry='2020-03-12T14:36:15Z' 
           token='WXZzciBwYmFmdmZnZiBqdmd1IGp2eXFhcmZm' />
</success>
        ''',
      ),
      StanzaExpectation(
        '<iq xmlns="jabber:client" type="set" id="a"><bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"/></iq>',
        '<iq xmlns="jabber:client" type="result" id="a"><bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"><jid>polynomdivision@test.server/MU29eEZn</jid></bind></iq>',
        ignoreId: true,
      ),
      StringExpectation(
        '',
        '',
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
    <mechanisms xmlns="urn:ietf:params:xml:ns:xmpp-sasl">
      <mechanism>PLAIN</mechanism>
      <mechanism>HT-SHA-256-NONE</mechanism>
    </mechanisms>
    <authentication xmlns='urn:xmpp:sasl:2'>
      <mechanism>PLAIN</mechanism>
      <mechanism>HT-SHA-256-NONE</mechanism>
      <mechanism>HT-SHA-256-ENDP</mechanism>
      <inline>
        <bind xmlns="urn:xmpp:bind:0" />
        <fast xmlns="urn:xmpp:fast:0">
          <mechanism>HT-SHA-256-NONE</mechanism>
          <mechanism>HT-SHA-256-ENDP</mechanism>
        </fast>
      </inline>
    </authentication>
    <bind xmlns="urn:ietf:params:xml:ns:xmpp-bind">
      <required/>
    </bind>
  </stream:features>''',
      ),
      StanzaExpectation(
        "<authenticate xmlns='urn:xmpp:sasl:2' mechanism='HT-SHA-256-NONE'><user-agent id='d4565fa7-4d72-4749-b3d3-740edbf87770'><software>moxxmpp</software><device>PapaTutuWawa's awesome device</device></user-agent><initial-response>WXZzciBwYmFmdmZnZiBqdmd1IGp2eXFhcmZm</initial-response><fast xmlns='urn:xmpp:fast:0' /></authenticate>",
        '''
<success xmlns='urn:xmpp:sasl:2'>
  <authorization-identifier>polynomdivision@test.server</authorization-identifier>
</success>
        ''',
      ),
      StanzaExpectation(
        '<iq xmlns="jabber:client" type="set" id="a"><bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"/></iq>',
        '<iq xmlns="jabber:client" type="result" id="a"><bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"><jid>polynomdivision@test.server/MU29eEZn</jid></bind></iq>',
        ignoreId: true,
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
      FASTSaslNegotiator(),
      Sasl2Negotiator()
        ..userAgent = const UserAgent(
          id: 'd4565fa7-4d72-4749-b3d3-740edbf87770',
          software: 'moxxmpp',
          device: "PapaTutuWawa's awesome device",
        ),
    ]);

    final result1 = await conn.connect(
      waitUntilLogin: true,
      shouldReconnect: false,
      enableReconnectOnSuccess: false,
    );
    expect(result1.isType<NegotiatorError>(), false);
    expect(conn.resource, 'MU29eEZn');
    expect(fakeSocket.getState(), 3);

    final token = conn
        .getNegotiatorById<FASTSaslNegotiator>(saslFASTNegotiator)!
        .fastToken;
    expect(token != null, true);
    expect(token!.token, 'WXZzciBwYmFmdmZnZiBqdmd1IGp2eXFhcmZm');

    // Disconnect
    await conn.disconnect();

    // Connect again, but use FAST this time
    final result2 = await conn.connect(
      waitUntilLogin: true,
      shouldReconnect: false,
      enableReconnectOnSuccess: false,
    );
    expect(result2.isType<NegotiatorError>(), false);
    expect(conn.resource, 'MU29eEZn');
    expect(fakeSocket.getState(), 7);
  });

  test('Test failed FAST authentication with a token', () async {
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
      <mechanism>HT-SHA-256-NONE</mechanism>
    </mechanisms>
    <authentication xmlns='urn:xmpp:sasl:2'>
      <mechanism>PLAIN</mechanism>
      <mechanism>HT-SHA-256-NONE</mechanism>
      <mechanism>HT-SHA-256-ENDP</mechanism>
      <inline>
        <bind xmlns="urn:xmpp:bind:0" />
        <fast xmlns="urn:xmpp:fast:0">
          <mechanism>HT-SHA-256-NONE</mechanism>
          <mechanism>HT-SHA-256-ENDP</mechanism>
        </fast>
      </inline>
    </authentication>
    <bind xmlns="urn:ietf:params:xml:ns:xmpp-bind">
      <required/>
    </bind>
  </stream:features>''',
      ),
      StanzaExpectation(
        "<authenticate xmlns='urn:xmpp:sasl:2' mechanism='HT-SHA-256-NONE'><user-agent id='d4565fa7-4d72-4749-b3d3-740edbf87770'><software>moxxmpp</software><device>PapaTutuWawa's awesome device</device></user-agent><initial-response>WXZzciBwYmFmdmZnZiBqdmd1IGp2eXFhcmZm</initial-response><fast xmlns='urn:xmpp:fast:0' /></authenticate>",
        '''
<failure xmlns='urn:xmpp:sasl:2'>
  <not-authorized xmlns='urn:ietf:params:xml:ns:xmpp-sasl'/>
</failure>
        ''',
      ),
      StanzaExpectation(
        "<authenticate xmlns='urn:xmpp:sasl:2' mechanism='PLAIN'><user-agent id='d4565fa7-4d72-4749-b3d3-740edbf87770'><software>moxxmpp</software><device>PapaTutuWawa's awesome device</device></user-agent><initial-response>AHBvbHlub21kaXZpc2lvbgBhYWFh</initial-response><request-token xmlns='urn:xmpp:fast:0' mechanism='HT-SHA-256-NONE' /></authenticate>",
        '''
<success xmlns='urn:xmpp:sasl:2'>
  <authorization-identifier>polynomdivision@test.server</authorization-identifier>
  <token xmlns='urn:xmpp:fast:0' 
           expiry='2020-03-12T14:36:15Z' 
           token='ed00e36cb42449a365a306a413f51ffd5ea8' />
</success>
        ''',
      ),
      StanzaExpectation(
        '<iq xmlns="jabber:client" type="set" id="a"><bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"/></iq>',
        '<iq xmlns="jabber:client" type="result" id="a"><bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"><jid>polynomdivision@test.server/MU29eEZn</jid></bind></iq>',
        ignoreId: true,
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
      FASTSaslNegotiator()
        ..fastToken = const FASTToken(
          'WXZzciBwYmFmdmZnZiBqdmd1IGp2eXFhcmZm',
          '2020-03-12T14:36:15Z',
        ),
      Sasl2Negotiator()
        ..userAgent = const UserAgent(
          id: 'd4565fa7-4d72-4749-b3d3-740edbf87770',
          software: 'moxxmpp',
          device: "PapaTutuWawa's awesome device",
        ),
    ]);

    final result1 = await conn.connect(
      waitUntilLogin: true,
      shouldReconnect: false,
      enableReconnectOnSuccess: false,
    );
    expect(result1.isType<NegotiatorError>(), false);
    expect(conn.resource, 'MU29eEZn');
    expect(fakeSocket.getState(), 4);

    final token = conn
        .getNegotiatorById<FASTSaslNegotiator>(saslFASTNegotiator)!
        .fastToken;
    expect(token != null, true);
    expect(token!.token, 'ed00e36cb42449a365a306a413f51ffd5ea8');
  });
}
