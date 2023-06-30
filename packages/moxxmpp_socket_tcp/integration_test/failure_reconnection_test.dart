import 'package:logging/logging.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxmpp_socket_tcp/moxxmpp_socket_tcp.dart';
import 'package:test/test.dart';

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
  final log = Logger('FailureReconnectionTest');

  test(
    'Failing an awaited connection with TestingSleepReconnectionPolicy',
    () async {
      var errors = 0;
      final connection = XmppConnection(
        TestingSleepReconnectionPolicy(10),
        AlwaysConnectedConnectivityManager(),
        ClientToServerNegotiator(),
        TCPSocketWrapper(),
      )..connectionSettings = ConnectionSettings(
          jid: JID.fromString('testuser@no-sasl.badxmpp.eu'),
          password: 'abc123',
        );
      await connection.registerFeatureNegotiators([
        StartTlsNegotiator(),
      ]);
      connection.asBroadcastStream().listen((event) {
        if (event is ConnectionStateChangedEvent) {
          if (event.state == XmppConnectionState.error) {
            errors++;
          }
        }
      });

      final result = await connection.connect(
        shouldReconnect: false,
        waitUntilLogin: true,
        enableReconnectOnSuccess: false,
      );
      log.info('Connection failed as expected');
      expect(result.isType<XmppError>(), false);
      expect(errors, 1);

      log.info('Waiting 20 seconds for unexpected reconnections');
      await Future<void>.delayed(const Duration(seconds: 20));
      expect(errors, 1);
    },
    timeout: const Timeout.factor(2),
  );

  test(
    'Failing an awaited connection with ExponentialBackoffReconnectionPolicy',
    () async {
      var errors = 0;
      final connection = XmppConnection(
        TestingReconnectionPolicy(),
        AlwaysConnectedConnectivityManager(),
        ClientToServerNegotiator(),
        TCPSocketWrapper(),
      )..connectionSettings = ConnectionSettings(
          jid: JID.fromString('testuser@no-sasl.badxmpp.eu'),
          password: 'abc123',
        );
      await connection.registerFeatureNegotiators([
        StartTlsNegotiator(),
      ]);
      connection.asBroadcastStream().listen((event) {
        if (event is ConnectionStateChangedEvent) {
          if (event.state == XmppConnectionState.error) {
            errors++;
          }
        }
      });

      final result = await connection.connect(
        shouldReconnect: false,
        waitUntilLogin: true,
        enableReconnectOnSuccess: false,
      );
      log.info('Connection failed as expected');
      expect(result.isType<XmppError>(), false);
      expect(errors, 1);

      log.info('Waiting 20 seconds for unexpected reconnections');
      await Future<void>.delayed(const Duration(seconds: 20));
      expect(errors, 1);
    },
    timeout: const Timeout.factor(2),
  );
}
