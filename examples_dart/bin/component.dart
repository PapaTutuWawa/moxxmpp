import 'package:logging/logging.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxmpp_socket_tcp/moxxmpp_socket_tcp.dart';

class TestingTCPSocketWrapper extends TCPSocketWrapper {
  @override
  bool onBadCertificate(dynamic certificate, String domain) {
    return true;
  }
}

class EchoMessageManager extends XmppManagerBase {
  EchoMessageManager() : super('org.moxxy.example.message');

  @override
  Future<bool> isSupported() async => true;

  @override
  List<StanzaHandler> getIncomingStanzaHandlers() => [
        StanzaHandler(
          stanzaTag: 'message',
          callback: _onMessage,
          priority: -100,
          xmlns: null,
        )
      ];

  Future<StanzaHandlerData> _onMessage(
    Stanza stanza,
    StanzaHandlerData state,
  ) async {
    final body = stanza.firstTag('body');
    if (body == null) return state.copyWith(done: true);

    final bodyText = body.innerText();

    await getAttributes().sendStanza(
      Stanza.message(
        to: stanza.from,
        children: [
          XMLNode(
            tag: 'body',
            text: 'Hello, ${stanza.from}! You said "$bodyText"',
          ),
        ],
      ),
      awaitable: false,
    );

    return state.copyWith(done: true);
  }
}

void main(List<String> arguments) async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print(
      '[${record.level.name}] (${record.loggerName}) ${record.time}: ${record.message}',
    );
  });

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
    EchoMessageManager(),
  ]);

  final result = await conn.connect(
    waitUntilLogin: true,
    shouldReconnect: false,
    enableReconnectOnSuccess: false,
  );
  if (result.isType<XmppError>()) {
    print('Failed to connect as component');
    return;
  }

  // Just block for some time to test the connection
  await Future<void>.delayed(const Duration(seconds: 9999));
}
