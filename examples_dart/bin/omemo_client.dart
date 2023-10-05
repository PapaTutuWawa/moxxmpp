import 'package:chalkdart/chalk.dart';
import 'package:cli_repl/cli_repl.dart';
import 'package:example_dart/arguments.dart';
import 'package:example_dart/socket.dart';
import 'package:logging/logging.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:omemo_dart/omemo_dart.dart' as omemo;

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
    ..parser.addOption('to', help: 'The JID to send messages to');
  final options = parser.handleArguments(args);
  if (options == null) {
    return;
  }

  // Connect
  final jid = parser.jid;
  final to = JID.fromString(options['to']! as String).toBare();
  final connection = XmppConnection(
    TestingReconnectionPolicy(),
    AlwaysConnectedConnectivityManager(),
    ClientToServerNegotiator(),
    ExampleTCPSocketWrapper(parser.srvRecord, true),
  )..connectionSettings = parser.connectionSettings;

  // Generate OMEMO data
  omemo.OmemoManager? oom;
  final moxxmppOmemo = OmemoManager(
    () async => oom!,
    (toJid, _) async => toJid == to,
  );
  oom = omemo.OmemoManager(
    await omemo.OmemoDevice.generateNewDevice(jid.toString(), opkAmount: 5),
    omemo.BlindTrustBeforeVerificationTrustManager(),
    moxxmppOmemo.sendEmptyMessageImpl,
    moxxmppOmemo.fetchDeviceList,
    moxxmppOmemo.fetchDeviceBundle,
    moxxmppOmemo.subscribeToDeviceListImpl,
    moxxmppOmemo.publishDeviceImpl,
  );
  final deviceId = await oom.getDeviceId();
  Logger.root.info('Our device id: $deviceId');

  // Register the managers and negotiators
  await connection.registerManagers([
    PresenceManager(),
    DiscoManager([]),
    PubSubManager(),
    MessageManager(),
    moxxmppOmemo,
  ]);
  await connection.registerFeatureNegotiators([
    SaslPlainNegotiator(),
    ResourceBindingNegotiator(),
    StartTlsNegotiator(),
    SaslScramNegotiator(10, '', '', ScramHashType.sha1),
  ]);

  // Set up event handlers
  connection.asBroadcastStream().listen((event) {
    if (event is MessageEvent) {
      Logger.root.info(event.id);
      Logger.root.info(event.extensions.keys.toList());

      final body = event.encryptionError != null
          ? chalk.red('Failed to decrypt message: ${event.encryptionError}')
          : chalk.green(event.get<MessageBodyData>()?.body ?? '');
      print('[${event.from.toString()}] $body');
    }
  });

  // Connect
  Logger.root.info('Connecting...');
  final result =
      await connection.connect(shouldReconnect: false, waitUntilLogin: true);
  if (!result.isType<bool>()) {
    Logger.root.severe('Authentication failed!');
    return;
  }
  Logger.root.info('Connected.');

  // Publish our bundle
  Logger.root.info('Publishing bundle');
  final device = await oom.getDevice();
  final omemoResult = await moxxmppOmemo.publishBundle(await device.toBundle());
  if (!omemoResult.isType<bool>()) {
    Logger.root.severe(
        'Failed to publish OMEMO bundle: ${omemoResult.get<OmemoError>()}');
    return;
  }

  final repl = Repl(prompt: '> ');
  await for (final line in repl.runAsync()) {
    await connection
        .getManagerById<MessageManager>(messageManager)!
        .sendMessage(
          to,
          TypedMap<StanzaHandlerExtension>.fromList([
            MessageBodyData(line),
          ]),
        );
  }

  // Disconnect
  await connection.disconnect();
}
