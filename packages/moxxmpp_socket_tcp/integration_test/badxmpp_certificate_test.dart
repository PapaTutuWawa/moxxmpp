import 'package:logging/logging.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxmpp_socket_tcp/moxxmpp_socket_tcp.dart';
import 'package:test/test.dart';

Future<void> _runTest(String domain) async {
  var gotTLSException = false;
  final socket = TCPSocketWrapper(false);
  final log = Logger('TestLogger');
  socket.getEventStream().listen((event) {
    if (event is XmppSocketTLSFailedEvent) {
      log.info('Got XmppSocketTLSFailedEvent from socket');
      gotTLSException = true;
    }
  });

  final connection = XmppConnection(
    ExponentialBackoffReconnectionPolicy(),
    socket,
  );
  connection.registerFeatureNegotiators([
    StartTlsNegotiator(),
  ]);
  connection.registerManagers([
    DiscoManager(),
    RosterManager(),
    PingManager(),
    MessageManager(),
    PresenceManager('http://moxxmpp.example'),
  ]);

  connection.setConnectionSettings(
    ConnectionSettings(
      jid: JID.fromString('testuser@$domain'),
      password: 'abc123',
      useDirectTLS: true,
      allowPlainAuth: true,
    ),
  );

  final result = await connection.connectAwaitable();
  expect(result.success, false);
  expect(gotTLSException, true);
}

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
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
