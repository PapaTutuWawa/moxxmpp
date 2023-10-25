import 'package:moxxmpp/moxxmpp.dart';
import 'package:test/test.dart';
import 'helpers/logging.dart';
import 'helpers/xmpp.dart';

void main() {
  initLogger();

  test('Test a versioned roster fetch returning an empty iq', () async {
    final sm = TestingRosterStateManager('ver14', []);
    final rm = RosterManager(sm);
    final cs = ConnectionSettings(
      jid: JID.fromString('user@example.org'),
      password: 'abc123',
    );
    final socket = StubTCPSocket([
      ...buildAuthenticatedPlay(cs),
      StanzaExpectation(
        '<iq xmlns="jabber:client" id="r1h3vzp7" type="get"><query xmlns="jabber:iq:roster" ver="ver14"/></iq>',
        '<iq xmlns="jabber:client" id="r1h3vzp7" type="result" />',
        ignoreId: true,
        adjustId: true,
      ),
    ]);
    final conn = XmppConnection(
      TestingReconnectionPolicy(),
      AlwaysConnectedConnectivityManager(),
      ClientToServerNegotiator(),
      socket,
    )..connectionSettings = cs;
    await conn.registerManagers([
      rm,
      PresenceManager(),
    ]);
    await conn.registerFeatureNegotiators([
      SaslPlainNegotiator(),
      ResourceBindingNegotiator(),
      RosterFeatureNegotiator(),
    ]);

    // Connect
    await conn.connect(
      shouldReconnect: false,
      waitUntilLogin: true,
    );

    // Request the roster
    final rawResult = await rm.requestRoster();
    expect(rawResult.isType<RosterRequestResult>(), true);
    final result = rawResult.get<RosterRequestResult>();
    expect(result.items.isEmpty, true);
  });
}
