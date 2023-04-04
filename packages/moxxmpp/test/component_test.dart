import 'package:moxxmpp/moxxmpp.dart';
import 'package:test/test.dart';
import 'helpers/logging.dart';
import 'helpers/xmpp.dart';

const exampleXmlns1 = 'im:moxxmpp:example1';
const exampleNamespace1 = 'im.moxxmpp.test.example1';
const exampleXmlns2 = 'im:moxxmpp:example2';
const exampleNamespace2 = 'im.moxxmpp.test.example2';

void main() {
  initLogger();

  test('Test connecting as a component', () async {
    final socket = StubTCPSocket([
      StringExpectation(
          "<stream:stream xmlns='jabber:component:accept' xmlns:stream='http://etherx.jabber.org/streams' to='component.example.org'>",
          '''
<stream:stream
    xmlns:stream='http://etherx.jabber.org/streams'
    xmlns='jabber:component:accept'
    from='component.example.org'
    id='3BF96D32'>'''),
      StringExpectation(
        '<handshake>ee8567f3b4c6e315345416b45ca2e47dbe921565</handshake>',
        '<handshake />',
      ),
    ]);
    final conn = XmppConnection(
      TestingReconnectionPolicy(),
      AlwaysConnectedConnectivityManager(),
      ComponentToServerNegotiator(),
      socket,
    )..connectionSettings = ConnectionSettings(
        jid: JID.fromString('component.example.org'),
        password: 'abc123',
        useDirectTLS: true,
      );
    await conn.registerManagers([
      RosterManager(TestingRosterStateManager('', [])),
      DiscoManager([]),
    ]);
    final result = await conn.connect(
      waitUntilLogin: true,
    );
    expect(result.isType<bool>(), true);
  });
}
