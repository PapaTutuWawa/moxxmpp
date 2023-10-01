import 'package:logging/logging.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:test/test.dart';
import '../helpers/logging.dart';
import '../helpers/xmpp.dart';

void main() {
  initLogger();

  test(
    'Test connecting to MUCs after a reconnection without stream resumption',
    () async {
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
    <bind xmlns="urn:ietf:params:xml:ns:xmpp-bind">
      <required/>
    </bind>
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
          '<presence to="channel@muc.example.org/test" xmlns="jabber:client"><x xmlns="http://jabber.org/protocol/muc"><history maxstanzas="0"/></x></presence>',
          '<message from="channel@muc.example.org" type="groupchat" xmlns="jabber:client"><subject/></message>',
          ignoreId: true,
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
    </mechanisms>
    <bind xmlns="urn:ietf:params:xml:ns:xmpp-bind">
      <required/>
    </bind>
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
          '<presence to="channel@muc.example.org/test" xmlns="jabber:client"><x xmlns="http://jabber.org/protocol/muc"><history maxstanzas="0"/></x></presence>',
          '<message from="channel@muc.example.org" type="groupchat" xmlns="jabber:client"><subject/></message>',
          ignoreId: true,
        ),
      ]);
      final conn = XmppConnection(
        TestingSleepReconnectionPolicy(1),
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
        DiscoManager([]),
        MUCManager(),
      ]);

      await conn.registerFeatureNegotiators([
        SaslPlainNegotiator(),
        ResourceBindingNegotiator(),
      ]);

      await conn.connect(
        waitUntilLogin: true,
        shouldReconnect: true,
      );

      // Join a groupchat
      final joinResult =
          await conn.getManagerById<MUCManager>(mucManager)!.joinRoom(
                JID.fromString('channel@muc.example.org'),
                'test',
                maxHistoryStanzas: 0,
              );
      expect(joinResult.isType<bool>(), true);
      expect(joinResult.get<bool>(), true);

      // Trigger a reconnection reason.
      Logger('Test').info('Injecting socket fault');
      fakeSocket.injectSocketFault();

      await Future<void>.delayed(const Duration(seconds: 4));
      expect(fakeSocket.getState(), 10);
    },
  );

  test(
    'Test joining a MUC with other members',
    () async {
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
    <bind xmlns="urn:ietf:params:xml:ns:xmpp-bind">
      <required/>
    </bind>
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
          '<presence to="channel@muc.example.org/test" xmlns="jabber:client"><x xmlns="http://jabber.org/protocol/muc"><history maxstanzas="0"/></x></presence>',
          '',
          ignoreId: true,
        ),
      ]);
      final conn = XmppConnection(
        TestingSleepReconnectionPolicy(1),
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
        DiscoManager([]),
        MUCManager(),
      ]);

      await conn.registerFeatureNegotiators([
        SaslPlainNegotiator(),
        ResourceBindingNegotiator(),
      ]);

      await conn.connect(
        waitUntilLogin: true,
        shouldReconnect: false,
      );

      // Join a groupchat
      final roomJid = JID.fromString('channel@muc.example.org');
      final joinResult = conn.getManagerById<MUCManager>(mucManager)!.joinRoom(
            roomJid,
            'test',
            maxHistoryStanzas: 0,
          );
      await Future<void>.delayed(const Duration(seconds: 1));

      fakeSocket
        ..injectRawXml(
          '''
        <presence
           from='channel@muc.example.org/firstwitch'
           id='3DCB0401-D7CF-4E31-BE05-EDF8D057BFBD'>
          <x xmlns='http://jabber.org/protocol/muc#user'>
            <item affiliation='owner' role='moderator'/>
          </x>
        </presence>
        ''',
        )
        ..injectRawXml(
          '''
        <presence
           from='channel@muc.example.org/secondwitch'
           id='C2CD9EE3-8421-431E-854A-A2AD0CE2E23D'>
          <x xmlns='http://jabber.org/protocol/muc#user'>
            <item affiliation='admin' role='moderator'/>
          </x>
        </presence>
        ''',
        )
        ..injectRawXml(
          '''
        <presence
           from='channel@muc.example.org/test'
           id='C2CD9EE3-8421-431E-854A-A2AD0CE2E23E'>
          <x xmlns='http://jabber.org/protocol/muc#user'>
            <item affiliation='member' role='none'/>
            <status code='110' />
          </x>
        </presence>
        ''',
        )
        ..injectRawXml(
          '''
        <message from="channel@muc.example.org" type="groupchat" xmlns="jabber:client">
          <subject/>
        </message>
        ''',
        );

      await joinResult;
      expect(fakeSocket.getState(), 5);

      final room = (await conn
          .getManagerById<MUCManager>(mucManager)!
          .getRoomState(roomJid))!;
      expect(room.joined, true);
      expect(
        room.members.length,
        2,
      );
      expect(
        room.members['test'],
        null,
      );
      expect(
        room.members['secondwitch']!.role,
        Role.moderator,
      );
      expect(
        room.members['secondwitch']!.affiliation,
        Affiliation.admin,
      );
      expect(
        room.members['firstwitch']!.role,
        Role.moderator,
      );
      expect(
        room.members['firstwitch']!.affiliation,
        Affiliation.owner,
      );
    },
  );

  test(
    'Testing a user joining a room',
    () async {
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
    <bind xmlns="urn:ietf:params:xml:ns:xmpp-bind">
      <required/>
    </bind>
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
          '<presence to="channel@muc.example.org/test" xmlns="jabber:client"><x xmlns="http://jabber.org/protocol/muc"><history maxstanzas="0"/></x></presence>',
          '',
          ignoreId: true,
        ),
      ]);
      final conn = XmppConnection(
        TestingSleepReconnectionPolicy(1),
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
        DiscoManager([]),
        MUCManager(),
      ]);

      await conn.registerFeatureNegotiators([
        SaslPlainNegotiator(),
        ResourceBindingNegotiator(),
      ]);

      await conn.connect(
        waitUntilLogin: true,
        shouldReconnect: false,
      );

      // Join a groupchat
      final roomJid = JID.fromString('channel@muc.example.org');
      final joinResult = conn.getManagerById<MUCManager>(mucManager)!.joinRoom(
            roomJid,
            'test',
            maxHistoryStanzas: 0,
          );
      await Future<void>.delayed(const Duration(seconds: 1));

      fakeSocket
        ..injectRawXml(
          '''
        <presence
           from='channel@muc.example.org/firstwitch'
           id='3DCB0401-D7CF-4E31-BE05-EDF8D057BFBD'>
          <x xmlns='http://jabber.org/protocol/muc#user'>
            <item affiliation='owner' role='moderator'/>
          </x>
        </presence>
        ''',
        )
        ..injectRawXml(
          '''
        <presence
           from='channel@muc.example.org/secondwitch'
           id='C2CD9EE3-8421-431E-854A-A2AD0CE2E23D'>
          <x xmlns='http://jabber.org/protocol/muc#user'>
            <item affiliation='admin' role='moderator'/>
          </x>
        </presence>
        ''',
        )
        ..injectRawXml(
          '''
        <presence
           from='channel@muc.example.org/test'
           id='C2CD9EE3-8421-431E-854A-A2AD0CE2E23E'>
          <x xmlns='http://jabber.org/protocol/muc#user'>
            <item affiliation='member' role='none'/>
            <status code='110' />
          </x>
        </presence>
        ''',
        )
        ..injectRawXml(
          '''
        <message from="channel@muc.example.org" type="groupchat" xmlns="jabber:client">
          <subject/>
        </message>
        ''',
        );

      await joinResult;
      final room = (await conn
          .getManagerById<MUCManager>(mucManager)!
          .getRoomState(roomJid))!;
      expect(room.joined, true);
      expect(
        room.members.length,
        2,
      );

      // Now a new user joins the room.
      MemberJoinedEvent? event;
      conn.asBroadcastStream().listen((e) {
        if (e is MemberJoinedEvent) {
          event = e;
        }
      });

      fakeSocket.injectRawXml(
        '''
        <presence
           from='channel@muc.example.org/papatutuwawa'
           id='C2CD9EE3-8421-431E-854A-A2AD0CE2E23G'>
          <x xmlns='http://jabber.org/protocol/muc#user'>
            <item affiliation='admin' role='participant'/>
          </x>
        </presence>
        ''',
      );

      await Future<void>.delayed(const Duration(seconds: 2));
      expect(event != null, true);
      expect(event!.member.nick, 'papatutuwawa');
      expect(event!.member.affiliation, Affiliation.admin);
      expect(event!.member.role, Role.participant);

      final roomAfterJoin = (await conn
          .getManagerById<MUCManager>(mucManager)!
          .getRoomState(roomJid))!;
      expect(roomAfterJoin.members.length, 3);
    },
  );

  test(
    'Testing a user leaving a room',
    () async {
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
    <bind xmlns="urn:ietf:params:xml:ns:xmpp-bind">
      <required/>
    </bind>
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
          '<presence to="channel@muc.example.org/test" xmlns="jabber:client"><x xmlns="http://jabber.org/protocol/muc"><history maxstanzas="0"/></x></presence>',
          '',
          ignoreId: true,
        ),
      ]);
      final conn = XmppConnection(
        TestingSleepReconnectionPolicy(1),
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
        DiscoManager([]),
        MUCManager(),
      ]);

      await conn.registerFeatureNegotiators([
        SaslPlainNegotiator(),
        ResourceBindingNegotiator(),
      ]);

      await conn.connect(
        waitUntilLogin: true,
        shouldReconnect: false,
      );

      // Join a groupchat
      final roomJid = JID.fromString('channel@muc.example.org');
      final joinResult = conn.getManagerById<MUCManager>(mucManager)!.joinRoom(
            roomJid,
            'test',
            maxHistoryStanzas: 0,
          );
      await Future<void>.delayed(const Duration(seconds: 1));

      fakeSocket
        ..injectRawXml(
          '''
        <presence
           from='channel@muc.example.org/firstwitch'
           id='3DCB0401-D7CF-4E31-BE05-EDF8D057BFBD'>
          <x xmlns='http://jabber.org/protocol/muc#user'>
            <item affiliation='owner' role='moderator'/>
          </x>
        </presence>
        ''',
        )
        ..injectRawXml(
          '''
        <presence
           from='channel@muc.example.org/secondwitch'
           id='C2CD9EE3-8421-431E-854A-A2AD0CE2E23D'>
          <x xmlns='http://jabber.org/protocol/muc#user'>
            <item affiliation='admin' role='moderator'/>
          </x>
        </presence>
        ''',
        )
        ..injectRawXml(
          '''
        <presence
           from='channel@muc.example.org/test'
           id='C2CD9EE3-8421-431E-854A-A2AD0CE2E23E'>
          <x xmlns='http://jabber.org/protocol/muc#user'>
            <item affiliation='member' role='none'/>
            <status code='110' />
          </x>
        </presence>
        ''',
        )
        ..injectRawXml(
          '''
        <message from="channel@muc.example.org" type="groupchat" xmlns="jabber:client">
          <subject/>
        </message>
        ''',
        );

      await joinResult;
      final room = (await conn
          .getManagerById<MUCManager>(mucManager)!
          .getRoomState(roomJid))!;
      expect(room.joined, true);
      expect(
        room.members.length,
        2,
      );

      // Now a user leaves the room.
      MemberLeftEvent? event;
      conn.asBroadcastStream().listen((e) {
        if (e is MemberLeftEvent) {
          event = e;
        }
      });

      fakeSocket.injectRawXml(
        '''
        <presence
           from='channel@muc.example.org/secondwitch'
           id='C2CD9EE3-8421-431E-854A-A2AD0CE2E23G'
           type='unavailable'>
          <x xmlns='http://jabber.org/protocol/muc#user'>
            <item affiliation='admin' role='none'/>
          </x>
        </presence>
        ''',
      );

      await Future<void>.delayed(const Duration(seconds: 2));
      expect(event != null, true);
      expect(event!.nick, 'secondwitch');

      final roomAfterLeave = (await conn
          .getManagerById<MUCManager>(mucManager)!
          .getRoomState(roomJid))!;
      expect(roomAfterLeave.members.length, 1);
    },
  );

  test(
    'Test a user changing their nick name',
    () async {
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
    <bind xmlns="urn:ietf:params:xml:ns:xmpp-bind">
      <required/>
    </bind>
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
          '<presence to="channel@muc.example.org/test" xmlns="jabber:client"><x xmlns="http://jabber.org/protocol/muc"><history maxstanzas="0"/></x></presence>',
          '',
          ignoreId: true,
        ),
      ]);
      final conn = XmppConnection(
        TestingSleepReconnectionPolicy(1),
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
        DiscoManager([]),
        MUCManager(),
      ]);

      await conn.registerFeatureNegotiators([
        SaslPlainNegotiator(),
        ResourceBindingNegotiator(),
      ]);

      await conn.connect(
        waitUntilLogin: true,
        shouldReconnect: false,
      );

      // Join a groupchat
      final roomJid = JID.fromString('channel@muc.example.org');
      final joinResult = conn.getManagerById<MUCManager>(mucManager)!.joinRoom(
            roomJid,
            'test',
            maxHistoryStanzas: 0,
          );
      await Future<void>.delayed(const Duration(seconds: 1));

      fakeSocket
        ..injectRawXml(
          '''
        <presence
           from='channel@muc.example.org/firstwitch'
           id='3DCB0401-D7CF-4E31-BE05-EDF8D057BFBD'>
          <x xmlns='http://jabber.org/protocol/muc#user'>
            <item affiliation='owner' role='moderator'/>
          </x>
        </presence>
        ''',
        )
        ..injectRawXml(
          '''
        <presence
           from='channel@muc.example.org/secondwitch'
           id='C2CD9EE3-8421-431E-854A-A2AD0CE2E23D'>
          <x xmlns='http://jabber.org/protocol/muc#user'>
            <item affiliation='admin' role='moderator'/>
          </x>
        </presence>
        ''',
        )
        ..injectRawXml(
          '''
        <presence
           from='channel@muc.example.org/test'
           id='C2CD9EE3-8421-431E-854A-A2AD0CE2E23E'>
          <x xmlns='http://jabber.org/protocol/muc#user'>
            <item affiliation='member' role='none'/>
            <status code='110' />
          </x>
        </presence>
        ''',
        )
        ..injectRawXml(
          '''
        <message from="channel@muc.example.org" type="groupchat" xmlns="jabber:client">
          <subject/>
        </message>
        ''',
        );

      await joinResult;
      final room = (await conn
          .getManagerById<MUCManager>(mucManager)!
          .getRoomState(roomJid))!;
      expect(room.joined, true);
      expect(
        room.members.length,
        2,
      );

      // Now a new user changes their nick.
      MemberChangedNickEvent? event;
      conn.asBroadcastStream().listen((e) {
        if (e is MemberChangedNickEvent) {
          event = e;
        }
      });

      fakeSocket.injectRawXml(
        '''
        <presence
           from='channel@muc.example.org/firstwitch'
           id='3DCB0401-D7CF-4E31-BE05-EDF8D057BFBD'
           type='unavailable'>
          <x xmlns='http://jabber.org/protocol/muc#user'>
            <item affiliation='owner' role='moderator' nick='papatutuwawa'/>
            <status code='303'/>
          </x>
        </presence>
        ''',
      );

      await Future<void>.delayed(const Duration(seconds: 2));
      expect(event != null, true);
      expect(event!.oldNick, 'firstwitch');
      expect(event!.newNick, 'papatutuwawa');

      final roomAfterChange = (await conn
          .getManagerById<MUCManager>(mucManager)!
          .getRoomState(roomJid))!;
      expect(roomAfterChange.members.length, 2);
      expect(roomAfterChange.members['firstwitch'], null);
      expect(roomAfterChange.members['papatutuwawa'] != null, true);
    },
  );
}
