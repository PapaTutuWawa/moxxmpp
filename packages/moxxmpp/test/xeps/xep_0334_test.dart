import 'package:moxxmpp/moxxmpp.dart';
import 'package:test/test.dart';

import '../helpers/manager.dart';
import '../helpers/xmpp.dart';

void main() {
  test('Test receiving a message processing hint', () async {
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
      MessageProcessingHintManager(),
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
  <no-copy xmlns="urn:xmpp:hints"/>
  <no-store xmlns="urn:xmpp:hints"/>
</message>
''',
    );

    await Future<void>.delayed(const Duration(seconds: 2));
    expect(
      messageEvent!.extensions
          .get<MessageProcessingHintData>()!
          .hints
          .contains(MessageProcessingHint.noCopies),
      true,
    );
    expect(
      messageEvent!.extensions
          .get<MessageProcessingHintData>()!
          .hints
          .contains(MessageProcessingHint.noStore),
      true,
    );
  });

  test('Test sending a message processing hint', () async {
    final manager = MessageManager();
    final holder = TestingManagerHolder(
      stubSocket: StubTCPSocket([
        StanzaExpectation(
          '''
<message to="user@example.org" type="chat">
  <no-copy xmlns="urn:xmpp:hints"/>
  <no-store xmlns="urn:xmpp:hints"/>
</message>
''',
          '',
        )
      ]),
    );

    await holder.register([
      manager,
      MessageProcessingHintManager(),
    ]);

    await manager.sendMessage(
      JID.fromString('user@example.org'),
      TypedMap()
        ..set(
          const MessageProcessingHintData([
            MessageProcessingHint.noCopies,
            MessageProcessingHint.noStore,
          ]),
        ),
    );
  });
}
