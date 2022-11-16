import 'package:logging/logging.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxmpp_socket_tcp/moxxmpp_socket_tcp.dart';
import 'package:test/test.dart';

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
  final log = Logger('FailureReconnectionTest');

  test('Failing an awaited connection with TestingSleepReconnectionPolicy', () async {
    var errors = 0;
    final connection = XmppConnection(
      TestingSleepReconnectionPolicy(10),
      TCPSocketWrapper(false),
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
    connection.asBroadcastStream().listen((event) {
      if (event is ConnectionStateChangedEvent) {
        if (event.state == XmppConnectionState.error) {
          errors++;
        }
      }
    });

    connection.setConnectionSettings(
      ConnectionSettings(
        jid: JID.fromString('testuser@no-sasl.badxmpp.eu'),
        password: 'abc123',
        useDirectTLS: true,
        allowPlainAuth: true,
      ),
    );

    final result = await connection.connectAwaitable();
    log.info('Connection failed as expected');
    expect(result.success, false);
    expect(errors, 1);

    log.info('Waiting 20 seconds for unexpected reconnections');
    await Future.delayed(const Duration(seconds: 20));
    expect(errors, 1);
  }, timeout: Timeout.factor(2));

  test('Failing an awaited connection with ExponentialBackoffReconnectionPolicy', () async {
    var errors = 0;
    final connection = XmppConnection(
      ExponentialBackoffReconnectionPolicy(1),
      TCPSocketWrapper(false),
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
    connection.asBroadcastStream().listen((event) {
      if (event is ConnectionStateChangedEvent) {
        if (event.state == XmppConnectionState.error) {
          errors++;
        }
      }
    });

    connection.setConnectionSettings(
      ConnectionSettings(
        jid: JID.fromString('testuser@no-sasl.badxmpp.eu'),
        password: 'abc123',
        useDirectTLS: true,
        allowPlainAuth: true,
      ),
    );

    final result = await connection.connectAwaitable();
    log.info('Connection failed as expected');
    expect(result.success, false);
    expect(errors, 1);

    log.info('Waiting 20 seconds for unexpected reconnections');
    await Future.delayed(const Duration(seconds: 20));
    expect(errors, 1);
  }, timeout: Timeout.factor(2));
}
