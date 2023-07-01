import 'package:cli_repl/cli_repl.dart';
import 'package:example_dart/arguments.dart';
import 'package:example_dart/socket.dart';
import 'package:logging/logging.dart';
import 'package:moxxmpp/moxxmpp.dart';

void main(List<String> args) async {
  // Set up logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print(
      '[${record.level.name}] (${record.loggerName}) ${record.time}: ${record.message}',
    );
  });

  final parser = ArgumentParser()
    ..parser.addOption('to', help: 'The JID to send messages to')
    ..parser.addOption('nick', help: 'The nickname with which to join the MUC');
  final options = parser.handleArguments(args);
  if (options == null) {
    return;
  }

  // Connect
  final jid = parser.jid;
  final to = JID.fromString(options['to']! as String).toBare();
  final nick = options['nick']! as String;
  print(parser.connectionSettings);
  final connection = XmppConnection(
    TestingReconnectionPolicy(),
    AlwaysConnectedConnectivityManager(),
    ClientToServerNegotiator(),
    ExampleTCPSocketWrapper(parser.srvRecord),
  )..connectionSettings = parser.connectionSettings;

  print(parser.connectionSettings.host);
  print(parser.connectionSettings.jid);
  print(parser.connectionSettings.password);
  print(parser.connectionSettings.port);

  // Register the managers and negotiators
  await connection.registerManagers([
    PresenceManager(),
    DiscoManager([]),
    PubSubManager(),
    MessageManager(),
    MUCManager(),
  ]);
  await connection.registerFeatureNegotiators([
    SaslPlainNegotiator(),
    ResourceBindingNegotiator(),
    StartTlsNegotiator(),
    SaslScramNegotiator(10, '', '', ScramHashType.sha1),
  ]);

  // Connect
  Logger.root.info('Connecting...');
  final result =
      await connection.connect(shouldReconnect: false, waitUntilLogin: true);
  if (!result.isType<bool>()) {
    Logger.root.severe('Authentication failed!');
    return;
  }
  Logger.root.info('Connected.');

  // Join room
  await connection.getManagerById<MUCManager>(mucManager)!.joinRoom(to, nick);

  final repl = Repl(prompt: '> ');
  await for (final line in repl.runAsync()) {
    await connection
        .getManagerById<MessageManager>(messageManager)!
        .sendMessage(
            to,
            TypedMap<StanzaHandlerExtension>.fromList([
              MessageBodyData(line),
            ]),
            type: 'groupchat');
  }

  // Leave room
  await connection.getManagerById<MUCManager>(mucManager)!.leaveRoom(to);

  // Disconnect
  await connection.disconnect();
}
