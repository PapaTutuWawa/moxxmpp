import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxmpp_socket_tcp/moxxmpp_socket_tcp.dart';
import 'package:test/test.dart';

void main() async {
  final conn = XmppConnection(
    TestingReconnectionPolicy(),
    AlwaysConnectedConnectivityManager(),
    TCPSocketWrapper(),
  )..setConnectionSettings(
      ConnectionSettings(
        jid: JID.fromString('testuser@localhost'),
        password: 'abc123',
        useDirectTLS: false,
      ),
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
    Sasl2Negotiator(
      userAgent: const UserAgent(
        id: 'd4565fa7-4d72-4749-b3d3-740edbf87770',
        software: 'moxxmpp',
        device: "PapaTutuWawa's awesome device",
      ),
    ),
  ]);

  final result = await conn.connect(
    waitUntilLogin: true,
    shouldReconnect: false,
    enableReconnectOnSuccess: false,
  );
  expect(result.isType<NegotiatorError>(), false);
}
