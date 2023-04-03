import 'dart:async';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:test/test.dart';
import 'helpers/logging.dart';
import 'helpers/xmpp.dart';

/// Returns true if the roster manager triggeres an event for a given stanza
Future<bool> testRosterManager(
  String bareJid,
  String resource,
  String stanzaString,
) async {
  var eventTriggered = false;
  final roster = RosterManager(TestingRosterStateManager('', []))
    ..register(
      XmppManagerAttributes(
        sendStanza: (
          _, {
          StanzaFromType addFrom = StanzaFromType.full,
          bool addId = true,
          bool retransmitted = false,
          bool awaitable = true,
          bool encrypted = false,
          bool forceEncryption = false,
        }) async =>
            XMLNode(tag: 'hallo'),
        sendEvent: (event) {
          eventTriggered = true;
        },
        sendNonza: (_) {},
        getConnectionSettings: () => ConnectionSettings(
          jid: JID.fromString(bareJid),
          password: 'password',
          useDirectTLS: true,
        ),
        getManagerById: getManagerNullStub,
        getNegotiatorById: getNegotiatorNullStub,
        getFullJID: () => JID.fromString('$bareJid/$resource'),
        getSocket: () => StubTCPSocket([]),
        getConnection: () => XmppConnection(
          TestingReconnectionPolicy(),
          AlwaysConnectedConnectivityManager(),
          ClientToServerNegotiator(),
          StubTCPSocket([]),
        ),
      ),
    );

  final stanza = Stanza.fromXMLNode(XMLNode.fromString(stanzaString));
  for (final handler in roster.getIncomingStanzaHandlers()) {
    if (handler.matches(stanza)) {
      await handler.callback(
        stanza,
        StanzaHandlerData(
          false,
          false,
          null,
          stanza,
        ),
      );
    }
  }

  return eventTriggered;
}

void main() {
  initLogger();

  test('Test a successful login attempt with no SM', () async {
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
          "<enable xmlns='urn:xmpp:sm:3' resume='true' />",
          "<enabled xmlns='urn:xmpp:sm:3' id='some-long-sm-id' resume='true'/>",
        ),
      ],
    );
    // TODO(Unknown): This test is broken since we query the server and enable carbons
    final conn = XmppConnection(
      TestingReconnectionPolicy(),
      AlwaysConnectedConnectivityManager(),
      ClientToServerNegotiator(),
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
      StreamManagementManager(),
      EntityCapabilitiesManager('http://moxxmpp.example'),
    ]);
    await conn.registerFeatureNegotiators([
      SaslPlainNegotiator(),
      SaslScramNegotiator(10, '', '', ScramHashType.sha512),
      ResourceBindingNegotiator(),
      StreamManagementNegotiator(),
    ]);

    await conn.connect(
      waitUntilLogin: true,
    );
    expect(fakeSocket.getState(), /*6*/ 5);
    expect(conn.resource, 'MU29eEZn');
  });

  test('Test a failed SASL auth', () async {
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
          '<failure xmlns="urn:ietf:params:xml:ns:xmpp-sasl"><not-authorized /></failure>',
        ),
      ],
    );
    var receivedEvent = false;
    final conn = XmppConnection(
      TestingReconnectionPolicy(),
      AlwaysConnectedConnectivityManager(),
      ClientToServerNegotiator(),
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
      EntityCapabilitiesManager('http://moxxmpp.example'),
    ]);
    await conn.registerFeatureNegotiators([
      SaslPlainNegotiator(),
    ]);

    conn.asBroadcastStream().listen((event) {
      if (event is AuthenticationFailedEvent &&
          event.saslError == 'not-authorized') {
        receivedEvent = true;
      }
    });

    await conn.connect(
      waitUntilLogin: true,
    );
    expect(receivedEvent, true);
  });

  test('Test another failed SASL auth', () async {
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
          '<failure xmlns="urn:ietf:params:xml:ns:xmpp-sasl"><mechanism-too-weak /></failure>',
        ),
      ],
    );
    var receivedEvent = false;
    final conn = XmppConnection(
      TestingReconnectionPolicy(),
      AlwaysConnectedConnectivityManager(),
      ClientToServerNegotiator(),
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
      EntityCapabilitiesManager('http://moxxmpp.example'),
    ]);
    await conn.registerFeatureNegotiators([SaslPlainNegotiator()]);

    conn.asBroadcastStream().listen((event) {
      if (event is AuthenticationFailedEvent &&
          event.saslError == 'mechanism-too-weak') {
        receivedEvent = true;
      }
    });

    await conn.connect(
      waitUntilLogin: true,
    );
    expect(receivedEvent, true);
  });

  group('Test roster pushes', () {
    test('Test for a CVE-2015-8688 style vulnerability', () async {
      var eventTriggered = false;
      final roster = RosterManager(TestingRosterStateManager('', []))
        ..register(
          XmppManagerAttributes(
            sendStanza: (
              _, {
              StanzaFromType addFrom = StanzaFromType.full,
              bool addId = true,
              bool retransmitted = false,
              bool awaitable = true,
              bool encrypted = false,
              bool forceEncryption = false,
            }) async =>
                XMLNode(tag: 'hallo'),
            sendEvent: (event) {
              eventTriggered = true;
            },
            sendNonza: (_) {},
            getConnectionSettings: () => ConnectionSettings(
              jid: JID.fromString('some.user@example.server'),
              password: 'password',
              useDirectTLS: true,
            ),
            getManagerById: getManagerNullStub,
            getNegotiatorById: getNegotiatorNullStub,
            getFullJID: () => JID.fromString('some.user@example.server/aaaaa'),
            getSocket: () => StubTCPSocket([]),
            getConnection: () => XmppConnection(
              TestingReconnectionPolicy(),
              AlwaysConnectedConnectivityManager(),
              ClientToServerNegotiator(),
              StubTCPSocket([]),
            ),
          ),
        );

      // NOTE: Based on https://gultsch.de/gajim_roster_push_and_message_interception.html
      // NOTE: Added a from attribute as a server would add it itself.
      final maliciousStanza = Stanza.fromXMLNode(
        XMLNode.fromString(
          "<iq type=\"set\" from=\"eve@siacs.eu/bbbbb\" to=\"some.user@example.server/aaaaa\"><query xmlns='jabber:iq:roster'><item subscription=\"both\" jid=\"eve@siacs.eu\" name=\"Bob\" /></query></iq>",
        ),
      );

      for (final handler in roster.getIncomingStanzaHandlers()) {
        if (handler.matches(maliciousStanza)) {
          await handler.callback(
            maliciousStanza,
            StanzaHandlerData(
              false,
              false,
              null,
              maliciousStanza,
            ),
          );
        }
      }

      expect(
        eventTriggered,
        false,
        reason: 'Was able to inject a malicious roster push',
      );
    });
    test('The manager should accept pushes from our bare jid', () async {
      final result = await testRosterManager(
        'test.user@server.example',
        'aaaaa',
        "<iq from='test.user@server.example' type='result' id='82c2aa1e-cac3-4f62-9e1f-bbe6b057daf3' to='test.user@server.example/aaaaa' xmlns='jabber:client'><query ver='64' xmlns='jabber:iq:roster'><item jid='some.other.user@server.example' subscription='to' /></query></iq>",
      );
      expect(
        result,
        true,
        reason: 'Roster pushes from our bare JID should be accepted',
      );
    });
    test(
        'The manager should accept pushes from a jid that, if the resource is stripped, is our bare jid',
        () async {
      final result1 = await testRosterManager(
        'test.user@server.example',
        'aaaaa',
        "<iq from='test.user@server.example/aaaaa' type='result' id='82c2aa1e-cac3-4f62-9e1f-bbe6b057daf3' to='test.user@server.example/aaaaa' xmlns='jabber:client'><query ver='64' xmlns='jabber:iq:roster'><item jid='some.other.user@server.example' subscription='to' /></query></iq>",
      );
      expect(
        result1,
        true,
        reason:
            'Roster pushes should be accepted if the bare JIDs are the same',
      );

      final result2 = await testRosterManager(
        'test.user@server.example',
        'aaaaa',
        "<iq from='test.user@server.example/bbbbb' type='result' id='82c2aa1e-cac3-4f62-9e1f-bbe6b057daf3' to='test.user@server.example/aaaaa' xmlns='jabber:client'><query ver='64' xmlns='jabber:iq:roster'><item jid='some.other.user@server.example' subscription='to' /></query></iq>",
      );
      expect(
        result2,
        true,
        reason:
            'Roster pushes should be accepted if the bare JIDs are the same',
      );
    });
  });

  test('Test failing due to the server only allowing SASL PLAIN', () async {
    final fakeSocket = StubTCPSocket(
      [
        StringExpectation(
          "<stream:stream xmlns='jabber:client' version='1.0' xmlns:stream='http://etherx.jabber.org/streams' to='example.org' from='testuser@example.org' xml:lang='en'>",
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
      ],
    );

    final conn = XmppConnection(
      TestingReconnectionPolicy(),
      AlwaysConnectedConnectivityManager(),
      ClientToServerNegotiator(),
      fakeSocket,
    );
    await conn.registerManagers([
      PresenceManager(),
      RosterManager(TestingRosterStateManager('', [])),
      DiscoManager([]),
    ]);
    await conn.registerFeatureNegotiators([
      // SaslPlainNegotiator(),
      ResourceBindingNegotiator(),
    ]);
    conn.setConnectionSettings(
      ConnectionSettings(
        jid: JID.fromString('testuser@example.org'),
        password: 'abc123',
        useDirectTLS: false,
      ),
    );

    final result = await conn.connect(
      waitUntilLogin: true,
    );

    expect(
      result.isType<NoMatchingAuthenticationMechanismAvailableError>(),
      true,
    );
  });

  test('Test losing the connection while negotiation', () async {
    final fakeSocket = StubTCPSocket(
      [
        StringExpectation(
          "<stream:stream xmlns='jabber:client' version='1.0' xmlns:stream='http://etherx.jabber.org/streams' to='example.org' from='testuser@example.org' xml:lang='en'>",
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
          "<auth xmlns='urn:ietf:params:xml:ns:xmpp-sasl' mechanism='PLAIN'>AHRlc3R1c2VyAGFiYzEyMw==</auth>",
          '',
        ),
        StringExpectation(
          "<stream:stream xmlns='jabber:client' version='1.0' xmlns:stream='http://etherx.jabber.org/streams' to='example.org' from='testuser@example.org' xml:lang='en'>",
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
          "<auth xmlns='urn:ietf:params:xml:ns:xmpp-sasl' mechanism='PLAIN'>AHRlc3R1c2VyAGFiYzEyMw==</auth>",
          '<success xmlns="urn:ietf:params:xml:ns:xmpp-sasl" />',
        ),
        StringExpectation(
          "<stream:stream xmlns='jabber:client' version='1.0' xmlns:stream='http://etherx.jabber.org/streams' to='example.org' from='testuser@example.org' xml:lang='en'>",
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
  </stream:features>''',
        ),
        StanzaExpectation(
          '<iq xmlns="jabber:client" type="set" id="a"><bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"/></iq>',
          '<iq xmlns="jabber:client" type="result" id="a"><bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"><jid>testuser@example.org/MU29eEZn</jid></bind></iq>',
          ignoreId: true,
        ),
      ],
    );

    final conn = XmppConnection(
      TestingReconnectionPolicy(),
      AlwaysConnectedConnectivityManager(),
      ClientToServerNegotiator(),
      fakeSocket,
    );
    await conn.registerManagers([
      RosterManager(TestingRosterStateManager('', [])),
      DiscoManager([]),
    ]);
    await conn.registerFeatureNegotiators([
      SaslPlainNegotiator(),
      ResourceBindingNegotiator(),
    ]);
    conn.setConnectionSettings(
      ConnectionSettings(
        jid: JID.fromString('testuser@example.org'),
        password: 'abc123',
        useDirectTLS: false,
      ),
    );

    final result1 = conn.connect(
      waitUntilLogin: true,
    );
    await Future<void>.delayed(const Duration(seconds: 2));

    // Inject a fault
    fakeSocket.injectSocketFault();
    expect(
      (await result1).isType<bool>(),
      false,
    );

    // Try to connect again
    final result2 = await conn.connect(
      waitUntilLogin: true,
    );
    expect(
      fakeSocket.getState(),
      6,
    );
    expect(
      result2.isType<bool>(),
      true,
    );
  });
}
