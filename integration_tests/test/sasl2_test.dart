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

  test('Test authenticating against Prosody with SASL2, Bind2, and FAST',
      () async {
    final conn = XmppConnection(
      TestingReconnectionPolicy(),
      AlwaysConnectedConnectivityManager(),
      ClientToServerNegotiator(),
      TestingTCPSocketWrapper(),
    )..connectionSettings = ConnectionSettings(
        jid: JID.fromString('testuser@localhost'),
        password: 'abc123',
        host: '127.0.0.1',
        port: 5222,
      );
    final csi = CSIManager();
    await csi.setInactive(sendNonza: false);
    await conn.registerManagers([
      RosterManager(TestingRosterStateManager('', [])),
      DiscoManager([]),
    ]);
    await conn.registerFeatureNegotiators([
      SaslPlainNegotiator(),
      ResourceBindingNegotiator(),
      FASTSaslNegotiator(),
      Bind2Negotiator(),
      StartTlsNegotiator(),
      Sasl2Negotiator()
        ..userAgent = const UserAgent(
          id: 'd4565fa7-4d72-4749-b3d3-740edbf87770',
          software: 'moxxmpp',
          device: "PapaTutuWawa's awesome device",
        ),
    ]);

    final result = await conn.connect(
      waitUntilLogin: true,
      shouldReconnect: false,
      enableReconnectOnSuccess: false,
    );
    expect(result.isType<bool>(), true);
    expect(
      conn.getNegotiatorById<Sasl2Negotiator>(sasl2Negotiator)!.state,
      NegotiatorState.done,
    );
    expect(
      conn
              .getNegotiatorById<FASTSaslNegotiator>(saslFASTNegotiator)!
              .fastToken !=
          null,
      true,
    );
  });
}
