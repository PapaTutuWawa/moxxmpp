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
    ..parser.addOption('muc', help: 'The MUC to send messages to')
    ..parser.addOption('nick', help: 'The nickname with which to join the MUC');
  final options = parser.handleArguments(args);
  if (options == null) {
    return;
  }

  // Connect
  final muc = JID.fromString(options['muc']! as String).toBare();
  final nick = options['nick']! as String;
  final connection = XmppConnection(
    TestingReconnectionPolicy(),
    AlwaysConnectedConnectivityManager(),
    ClientToServerNegotiator(),
    ExampleTCPSocketWrapper(parser.srvRecord),
  )..connectionSettings = parser.connectionSettings;

  // Register the managers and negotiators
  await connection.registerManagers([
    PresenceManager(),
    DiscoManager([]),
    PubSubManager(),
    MessageManager(),
    StableIdManager(),
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

  // Print received messages.
  connection
      .asBroadcastStream()
      .where((event) => event is MessageEvent)
      .listen((event) {
    event as MessageEvent;

    // Ignore messages with no <body />
    final body = event.get<MessageBodyData>()?.body;
    if (body == null) {
      return;
    }

    print('=====> [${event.from}] $body');
  });

  // Join room
  final mm = connection.getManagerById<MUCManager>(mucManager)!;
  await mm.joinRoom(
    muc,
    nick,
    maxHistoryStanzas: 0,
  );
  final state = (await mm.getRoomState(muc))!;

  print('=====> ${state.members.length} users in room');
  print('=====> ${state.members.values.map((m) => m.nick).join(", ")}');

  final repl = Repl(prompt: '> ');
  await for (final line in repl.runAsync()) {
    await connection
        .getManagerById<MessageManager>(messageManager)!
        .sendMessage(
            muc,
            TypedMap<StanzaHandlerExtension>.fromList([
              MessageBodyData(line),
              StableIdData(
                // NOTE: Don't do this. Use a UUID.
                DateTime.now().millisecondsSinceEpoch.toString(),
                null,
              ),
            ]),
            type: 'groupchat');
  }

  // Leave room
  await connection.getManagerById<MUCManager>(mucManager)!.leaveRoom(muc);

  // Disconnect
  await connection.disconnect();
}
