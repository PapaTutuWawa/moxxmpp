import 'package:logging/logging.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxmpp_socket_tcp/moxxmpp_socket_tcp.dart';
import 'package:test/test.dart';

Future<void> _runTest(String domain) async {
  var gotTLSException = false;
  final socket = TCPSocketWrapper();
  final log = Logger('TestLogger');
  socket.getEventStream().listen((event) {
    if (event is XmppSocketTLSFailedEvent) {
      log.info('Got XmppSocketTLSFailedEvent from socket');
      gotTLSException = true;
    }
  });

  final connection = XmppConnection(
    TestingReconnectionPolicy(),
    AlwaysConnectedConnectivityManager(),
    socket,
  )..registerFeatureNegotiators([
      StartTlsNegotiator(),
    ]);
  await connection.registerManagers([
    DiscoManager([]),
    RosterManager(TestingRosterStateManager('', [])),
    MessageManager(),
    PresenceManager(),
  ]);

  connection.setConnectionSettings(
    ConnectionSettings(
      jid: JID.fromString('testuser@$domain'),
      password: 'abc123',
      useDirectTLS: true,
    ),
  );

  final result = await connection.connect(
    shouldReconnect: false,
    waitUntilLogin: true,
    enableReconnectOnSuccess: false,
  );
  expect(result.isType<XmppError>(), false);
  expect(gotTLSException, true);
}

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  for (final domain in [
    'self-signed.badxmpp.eu',
    'expired.badxmpp.eu',
    'wrong-name.badxmpp.eu',
    'missing-chain.badxmpp.eu',
    // TODO(Unknown): Technically, this one should not fail
    //'ecdsa.badxmpp.eu',
  ]) {
    test('$domain with connectAwaitable', () async {
      await _runTest(domain);
    });
  }
}
