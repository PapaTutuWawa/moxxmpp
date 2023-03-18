import 'package:moxxmpp/moxxmpp.dart';
import 'package:test/test.dart';
import '../helpers/logging.dart';
import '../helpers/xmpp.dart';

Future<void> runIncomingStanzaHandlers(
  StreamManagementManager man,
  Stanza stanza,
) async {
  for (final handler in man.getIncomingPreStanzaHandlers()) {
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
}

Future<void> runOutgoingStanzaHandlers(
  StreamManagementManager man,
  Stanza stanza,
) async {
  for (final handler in man.getOutgoingPostStanzaHandlers()) {
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
}

XmppManagerAttributes mkAttributes(void Function(Stanza) callback) {
  return XmppManagerAttributes(
    sendStanza: (
      stanza, {
      StanzaFromType addFrom = StanzaFromType.full,
      bool addId = true,
      bool awaitable = true,
      bool encrypted = false,
      bool forceEncryption = false,
    }) async {
      callback(stanza);

      return Stanza.message();
    },
    sendNonza: (nonza) {},
    sendEvent: (event) {},
    getManagerById: getManagerNullStub,
    getConnectionSettings: () => ConnectionSettings(
      jid: JID.fromString('hallo@example.server'),
      password: 'password',
      useDirectTLS: true,
    ),
    isFeatureSupported: (_) => false,
    getFullJID: () => JID.fromString('hallo@example.server/uwu'),
    getSocket: () => StubTCPSocket([]),
    getConnection: () => XmppConnection(
      TestingReconnectionPolicy(),
      AlwaysConnectedConnectivityManager(),
      StubTCPSocket([]),
    ),
    getNegotiatorById: getNegotiatorNullStub,
  );
}

XMLNode mkAck(int h) => XMLNode.xmlns(
      tag: 'a',
      xmlns: 'urn:xmpp:sm:3',
      attributes: {
        'h': h.toString(),
      },
    );

void main() {
  initLogger();

  final stanza = Stanza(
    to: 'some.user@server.example',
    tag: 'message',
  );

  test('Test stream with SM enablement', () async {
    final attributes = mkAttributes((_) {});
    final manager = StreamManagementManager()..register(attributes);

    // [...]
    // <enable /> // <enabled />
    await manager.onXmppEvent(StreamManagementEnabledEvent(resource: 'hallo'));
    expect(manager.state.c2s, 0);
    expect(manager.state.s2c, 0);

    expect(manager.isStreamManagementEnabled(), true);

    // Send a stanza 5 times
    for (var i = 0; i < 5; i++) {
      await runOutgoingStanzaHandlers(manager, stanza);
    }
    expect(manager.state.c2s, 5);

    // Receive 3 stanzas
    for (var i = 0; i < 3; i++) {
      await runIncomingStanzaHandlers(manager, stanza);
    }
    expect(manager.state.s2c, 3);
  });

  group('Acking', () {
    test('Test completely clearing the queue', () async {
      final attributes = mkAttributes((_) {});
      final manager = StreamManagementManager()..register(attributes);

      await manager
          .onXmppEvent(StreamManagementEnabledEvent(resource: 'hallo'));

      // Send a stanza 5 times
      for (var i = 0; i < 5; i++) {
        await runOutgoingStanzaHandlers(manager, stanza);
      }

      // <a h='5'/>
      await manager.runNonzaHandlers(mkAck(5));
      expect(manager.getUnackedStanzas().length, 0);
    });
    test('Test partially clearing the queue', () async {
      final attributes = mkAttributes((_) {});
      final manager = StreamManagementManager()..register(attributes);

      await manager.onXmppEvent(
        StreamManagementEnabledEvent(resource: 'hallo'),
      );

      // Send a stanza 5 times
      for (var i = 0; i < 5; i++) {
        await runOutgoingStanzaHandlers(manager, stanza);
      }

      // <a h='3'/>
      await manager.runNonzaHandlers(mkAck(3));
      expect(manager.getUnackedStanzas().length, 2);
    });
    test('Send an ack with h > c2s', () async {
      final attributes = mkAttributes((_) {});
      final manager = StreamManagementManager()..register(attributes);

      await manager.onXmppEvent(
        StreamManagementEnabledEvent(resource: 'hallo'),
      );

      // Send a stanza 5 times
      for (var i = 0; i < 5; i++) {
        await runOutgoingStanzaHandlers(manager, stanza);
      }

      // <a h='3'/>
      await manager.runNonzaHandlers(mkAck(6));
      expect(manager.getUnackedStanzas().length, 0);
      expect(manager.state.c2s, 6);
    });
    test('Send an ack with h < c2s', () async {
      final attributes = mkAttributes((_) {});
      final manager = StreamManagementManager()..register(attributes);

      await manager.onXmppEvent(
        StreamManagementEnabledEvent(resource: 'hallo'),
      );

      // Send a stanza 5 times
      for (var i = 0; i < 5; i++) {
        await runOutgoingStanzaHandlers(manager, stanza);
      }

      // <a h='3'/>
      await manager.runNonzaHandlers(mkAck(3));
      expect(manager.getUnackedStanzas().length, 2);
      expect(manager.state.c2s, 5);
    });
  });

  group('Counting acks', () {
    test('Sending all pending acks at once', () async {
      final attributes = mkAttributes((_) {});
      final manager = StreamManagementManager()..register(attributes);
      await manager.onXmppEvent(
        StreamManagementEnabledEvent(resource: 'hallo'),
      );

      // Send a stanza 5 times
      for (var i = 0; i < 5; i++) {
        await runOutgoingStanzaHandlers(manager, stanza);
      }
      expect(await manager.getPendingAcks(), 5);

      // Ack all of them at once
      await manager.runNonzaHandlers(mkAck(5));
      expect(await manager.getPendingAcks(), 0);
    });
    test('Sending partial pending acks at once', () async {
      final attributes = mkAttributes((_) {});
      final manager = StreamManagementManager()..register(attributes);
      await manager.onXmppEvent(
        StreamManagementEnabledEvent(resource: 'hallo'),
      );

      // Send a stanza 5 times
      for (var i = 0; i < 5; i++) {
        await runOutgoingStanzaHandlers(manager, stanza);
      }
      expect(await manager.getPendingAcks(), 5);

      // Ack only 3 of them at once
      await manager.runNonzaHandlers(mkAck(3));
      expect(await manager.getPendingAcks(), 2);
    });

    test('Test counting incoming stanzas for which handlers end early',
        () async {
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
  </stream:features>''',
        ),
        StringExpectation(
          "<auth xmlns='urn:ietf:params:xml:ns:xmpp-sasl' mechanism='PLAIN'>AHBvbHlub21kaXZpc2lvbgBhYWFh</auth>",
          '<success xmlns="urn:ietf:params:xml:ns:xmpp-sasl" />',
        ),
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
        StringExpectation(
          "<enable xmlns='urn:xmpp:sm:3' resume='true' />",
          '<enabled xmlns="urn:xmpp:sm:3" id="some-long-sm-id" resume="true" />',
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
      final sm = StreamManagementManager();
      await conn.registerManagers([
        PresenceManager(),
        RosterManager(TestingRosterStateManager('', [])),
        DiscoManager([]),
        PingManager(),
        sm,
        CarbonsManager()..forceEnable(),
        EntityCapabilitiesManager('http://moxxmpp.example'),
      ]);
      conn.registerFeatureNegotiators([
        SaslPlainNegotiator(),
        ResourceBindingNegotiator(),
        StreamManagementNegotiator(),
      ]);

      await conn.connect(
        waitUntilLogin: true,
      );
      expect(fakeSocket.getState(), 5);
      expect(await conn.getConnectionState(), XmppConnectionState.connected);
      expect(
        conn
            .getManagerById<StreamManagementManager>(smManager)!
            .isStreamManagementEnabled(),
        true,
      );

      // Send an invalid carbon
      fakeSocket.injectRawXml('''
<message xmlns='jabber:client'
         from='romeo@montague.example'
         to='romeo@montague.example/home'
         type='chat'>
  <received xmlns='urn:xmpp:carbons:2'>
    <forwarded xmlns='urn:xmpp:forward:0'>
      <message xmlns='jabber:client'
               from='juliet@capulet.example/balcony'
               to='romeo@montague.example/garden'
               type='chat'>
        <body>What man art thou that, thus bescreen'd in night, so stumblest on my counsel?</body>
        <thread>0e3141cd80894871a68e6fe6b1ec56fa</thread>
      </message>
    </forwarded>
  </received>
</message>
      ''');

      await Future<void>.delayed(const Duration(seconds: 2));
      expect(sm.state.s2c, 1);
    });

    test('Test counting incoming stanzas that are awaited', () async {
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
  </stream:features>''',
        ),
        StringExpectation(
          "<auth xmlns='urn:ietf:params:xml:ns:xmpp-sasl' mechanism='PLAIN'>AHBvbHlub21kaXZpc2lvbgBhYWFh</auth>",
          '<success xmlns="urn:ietf:params:xml:ns:xmpp-sasl" />',
        ),
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
        StringExpectation(
          "<enable xmlns='urn:xmpp:sm:3' resume='true' />",
          '<enabled xmlns="urn:xmpp:sm:3" id="some-long-sm-id" resume="true" />',
        ),
        // StringExpectation(
        //   "<presence xmlns='jabber:client' from='polynomdivision@test.server/MU29eEZn'><show>chat</show></presence>",
        //   '<iq type="result" />',
        // ),
        StanzaExpectation(
          "<iq to='user@example.com' type='get' id='a' xmlns='jabber:client' />",
          "<iq from='user@example.com' type='result' id='a' />",
          ignoreId: true,
          adjustId: true,
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
      final sm = StreamManagementManager();
      await conn.registerManagers([
        PresenceManager(),
        RosterManager(TestingRosterStateManager('', [])),
        DiscoManager([]),
        PingManager(),
        sm,
        CarbonsManager()..forceEnable(),
        //EntityCapabilitiesManager('http://moxxmpp.example'),
      ]);
      conn.registerFeatureNegotiators([
        SaslPlainNegotiator(),
        ResourceBindingNegotiator(),
        StreamManagementNegotiator(),
      ]);

      await conn.connect(
        waitUntilLogin: true,
      );
      expect(fakeSocket.getState(), 5);
      expect(await conn.getConnectionState(), XmppConnectionState.connected);
      expect(
        conn
            .getManagerById<StreamManagementManager>(smManager)!
            .isStreamManagementEnabled(),
        true,
      );

      // Await an iq
      await conn.sendStanza(
        Stanza.iq(
          to: 'user@example.com',
          type: 'get',
        ),
        addFrom: StanzaFromType.none,
      );

      expect(sm.state.s2c, /*2*/ 1);
    });
  });

  group('Stream resumption', () {
    test('Stanza retransmission', () async {
      var stanzaCount = 0;
      final attributes = mkAttributes((_) {
        stanzaCount++;
      });
      final manager = StreamManagementManager()..register(attributes);

      await manager.onXmppEvent(
        StreamManagementEnabledEvent(resource: 'hallo'),
      );

      // Send 5 stanzas
      for (var i = 0; i < 5; i++) {
        await runOutgoingStanzaHandlers(manager, stanza);
      }

      // Only ack 3
      // <a h='3' />
      await manager.runNonzaHandlers(mkAck(3));
      expect(manager.getUnackedStanzas().length, 2);

      // Lose connection
      // [ Reconnect ]
      await manager.onXmppEvent(StreamResumedEvent(h: 3));

      expect(stanzaCount, 2);
    });
    test('Resumption with prior state', () async {
      var stanzaCount = 0;
      final attributes = mkAttributes((_) {
        stanzaCount++;
      });
      final manager = StreamManagementManager()..register(attributes);

      // [ ... ]
      await manager.onXmppEvent(
        StreamManagementEnabledEvent(resource: 'hallo'),
      );
      await manager.setState(manager.state.copyWith(c2s: 150, s2c: 70));

      // Send some stanzas but don't ack them
      for (var i = 0; i < 5; i++) {
        await runOutgoingStanzaHandlers(manager, stanza);
      }
      expect(manager.getUnackedStanzas().length, 5);

      // Lose connection
      // [ Reconnect ]
      await manager.onXmppEvent(StreamResumedEvent(h: 150));
      expect(manager.getUnackedStanzas().length, 0);
      expect(stanzaCount, 5);
    });
  });

  group('Test the negotiator', () {
    test('Test successful stream enablement', () async {
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
  </stream:features>''',
        ),
        StringExpectation(
          "<auth xmlns='urn:ietf:params:xml:ns:xmpp-sasl' mechanism='PLAIN'>AHBvbHlub21kaXZpc2lvbgBhYWFh</auth>",
          '<success xmlns="urn:ietf:params:xml:ns:xmpp-sasl" />',
        ),
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
        StringExpectation(
          "<enable xmlns='urn:xmpp:sm:3' resume='true' />",
          '<enabled xmlns="urn:xmpp:sm:3" id="some-long-sm-id" resume="true" />',
        )
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
        PingManager(),
        StreamManagementManager(),
      ]);
      conn.registerFeatureNegotiators([
        SaslPlainNegotiator(),
        ResourceBindingNegotiator(),
        StreamManagementNegotiator(),
      ]);

      await conn.connect(
        waitUntilLogin: true,
      );

      expect(fakeSocket.getState(), 5);
      expect(await conn.getConnectionState(), XmppConnectionState.connected);
      expect(
        conn
            .getManagerById<StreamManagementManager>(smManager)!
            .isStreamManagementEnabled(),
        true,
      );
    });

    test('Test a failed stream resumption', () async {
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
  </stream:features>''',
        ),
        StringExpectation(
          "<auth xmlns='urn:ietf:params:xml:ns:xmpp-sasl' mechanism='PLAIN'>AHBvbHlub21kaXZpc2lvbgBhYWFh</auth>",
          '<success xmlns="urn:ietf:params:xml:ns:xmpp-sasl" />',
        ),
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
        StringExpectation(
          "<resume xmlns='urn:xmpp:sm:3' previd='id-1' h='10' />",
          "<failed xmlns='urn:xmpp:sm:3' h='another-sequence-number'><item-not-found xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'/></failed>",
        ),
        StanzaExpectation(
          '<iq xmlns="jabber:client" type="set" id="a"><bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"/></iq>',
          '<iq xmlns="jabber:client" type="result" id="a"><bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"><jid>polynomdivision@test.server/MU29eEZn</jid></bind></iq>',
          ignoreId: true,
        ),
        StringExpectation(
          "<enable xmlns='urn:xmpp:sm:3' resume='true' />",
          '<enabled xmlns="urn:xmpp:sm:3" id="id-2" resume="true" />',
        )
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
        PingManager(),
        StreamManagementManager(),
      ]);
      conn.registerFeatureNegotiators([
        SaslPlainNegotiator(),
        ResourceBindingNegotiator(),
        StreamManagementNegotiator(),
      ]);
      await conn.getManagerById<StreamManagementManager>(smManager)!.setState(
            StreamManagementState(
              10,
              10,
              streamResumptionId: 'id-1',
            ),
          );

      await conn.connect(
        waitUntilLogin: true,
      );
      expect(fakeSocket.getState(), 6);
      expect(await conn.getConnectionState(), XmppConnectionState.connected);
      expect(
        conn
            .getManagerById<StreamManagementManager>(smManager)!
            .isStreamManagementEnabled(),
        true,
      );
    });

    test('Test a successful stream resumption', () async {
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
  </stream:features>''',
        ),
        StringExpectation(
          "<auth xmlns='urn:ietf:params:xml:ns:xmpp-sasl' mechanism='PLAIN'>AHBvbHlub21kaXZpc2lvbgBhYWFh</auth>",
          '<success xmlns="urn:ietf:params:xml:ns:xmpp-sasl" />',
        ),
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
        StringExpectation(
          "<resume xmlns='urn:xmpp:sm:3' previd='id-1' h='10' />",
          "<resumed xmlns='urn:xmpp:sm:3' h='id-1' h='12' />",
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
        PingManager(),
        StreamManagementManager(),
      ]);
      conn.registerFeatureNegotiators([
        SaslPlainNegotiator(),
        ResourceBindingNegotiator(),
        StreamManagementNegotiator(),
      ]);
      await conn.getManagerById<StreamManagementManager>(smManager)!.setState(
            StreamManagementState(
              10,
              10,
              streamResumptionId: 'id-1',
            ),
          );

      await conn.connect(
        lastResource: 'abc123',
        waitUntilLogin: true,
      );
      expect(fakeSocket.getState(), 4);
      expect(await conn.getConnectionState(), XmppConnectionState.connected);
      final sm = conn.getManagerById<StreamManagementManager>(smManager)!;
      expect(sm.isStreamManagementEnabled(), true);
      expect(sm.streamResumed, true);
    });
  });
}
