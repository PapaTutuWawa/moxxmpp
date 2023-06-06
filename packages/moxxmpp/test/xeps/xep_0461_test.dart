import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxmpp/src/util/typed_map.dart';
import 'package:test/test.dart';

import '../helpers/xmpp.dart';

void main() {
  test('Test building a singleline quote', () {
    final quote = QuoteData.fromBodies('Hallo Welt', 'Hello Earth!');

    expect(quote.body, '> Hallo Welt\nHello Earth!');
    expect(quote.fallbackLength, 13);
  });

  test('Test building a multiline quote', () {
    final quote = QuoteData.fromBodies(
      'Hallo Welt\nHallo Erde',
      'How are you?',
    );

    expect(quote.body, '> Hallo Welt\n> Hallo Erde\nHow are you?');
    expect(quote.fallbackLength, 26);
  });

  test('Applying a singleline quote', () {
    const reply = ReplyData(
      '',
      start: 0,
      end: 13,
      body: '> Hallo Welt\nHello right back!',
    );

    expect(reply.withoutFallback, 'Hello right back!');
  });

  test('Applying a multiline quote', () {
    const reply = ReplyData(
      '',
      start: 0,
      end: 28,
      body: "> Hallo Welt\n> How are you?\nI'm fine.\nThank you!",
    );

    expect(reply.withoutFallback, "I'm fine.\nThank you!");
  });

  test('Test calling the message sending callback', () {
    final result = MessageRepliesManager().messageSendingCallback(
      TypedMap()
        ..set(
          ReplyData.fromQuoteData(
            'some-random-id',
            QuoteData.fromBodies(
              'Hello world',
              'How are you doing?',
            ),
            jid: JID.fromString('quoted-user@example.org'),
          ),
        ),
    );

    final reply = result.firstWhere((e) => e.tag == 'reply');
    final body = result.firstWhere((e) => e.tag == 'body');
    final fallback = result.firstWhere((e) => e.tag == 'fallback');

    expect(reply.attributes['to'], 'quoted-user@example.org');
    expect(body.innerText(), '> Hello world\nHow are you doing?');
    expect(fallback.children.first.attributes['start'], '0');
    expect(fallback.children.first.attributes['end'], '14');
  });

  test('Test parsing a reply without fallback', () async {
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
      MessageRepliesManager(),
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
  <body>Great idea!</body>
  <reply to='anna@example.com/tablet' id='message-id1' xmlns='urn:xmpp:reply:0' />
</message>
''',
    );

    await Future<void>.delayed(const Duration(seconds: 2));
    final reply = messageEvent!.reply!;
    expect(reply.withoutFallback, 'Great idea!');
    expect(reply.id, 'message-id1');
    expect(reply.jid, JID.fromString('anna@example.com/tablet'));
    expect(reply.start, null);
    expect(reply.end, null);
  });

  test('Test parsing a reply with a fallback', () async {
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
      MessageRepliesManager(),
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
  <body>> Anna wrote:\n> We should bake a cake\nGreat idea!</body>
  <reply to='anna@example.com/laptop' id='message-id1' xmlns='urn:xmpp:reply:0' />
  <fallback xmlns='urn:xmpp:feature-fallback:0' for='urn:xmpp:reply:0'>
    <body start="0" end="38" />
  </fallback>
</message>
''',
    );

    await Future<void>.delayed(const Duration(seconds: 2));
    final reply = messageEvent!.reply!;
    expect(reply.withoutFallback, 'Great idea!');
    expect(reply.id, 'message-id1');
    expect(reply.jid, JID.fromString('anna@example.com/laptop'));
    expect(reply.start, 0);
    expect(reply.end, 38);
  });
}
