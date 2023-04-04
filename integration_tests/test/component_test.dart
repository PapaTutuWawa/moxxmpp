import 'package:logging/logging.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxmpp_socket_tcp/moxxmpp_socket_tcp.dart';
import 'package:test/test.dart';

class TestingTCPSocketWrapper extends TCPSocketWrapper {
  @override
  bool onBadCertificate(dynamic certificate, String domain) {
    return true;
  }
}

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print(
      '[${record.level.name}] (${record.loggerName}) ${record.time}: ${record.message}',
    );
  });

  test('Test connecting to prosody as a component', () async {
    final conn = XmppConnection(
      TestingReconnectionPolicy(),
      AlwaysConnectedConnectivityManager(),
      ComponentToServerNegotiator(),
      TestingTCPSocketWrapper(),
    )..connectionSettings = ConnectionSettings(
        jid: JID.fromString('component.localhost'),
        password: 'abc123',
        host: '127.0.0.1',
        port: 8888,
      );
    await conn.registerManagers([
      RosterManager(TestingRosterStateManager('', [])),
      DiscoManager([]),
    ]);

    final result = await conn.connect(
      waitUntilLogin: true,
      shouldReconnect: false,
      enableReconnectOnSuccess: false,
    );
    expect(result.isType<bool>(), true);
  });
}
