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
}
