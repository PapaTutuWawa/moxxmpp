import 'package:args/args.dart';
import 'package:chalkdart/chalk.dart';
import 'package:cli_repl/cli_repl.dart';
import 'package:logging/logging.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxmpp_socket_tcp/moxxmpp_socket_tcp.dart';
import 'package:omemo_dart/omemo_dart.dart' as omemo;

class TestingOmemoManager extends BaseOmemoManager {
  TestingOmemoManager(this._encryptToJid);

  final JID _encryptToJid;

  late omemo.OmemoManager manager;

  @override
  Future<omemo.OmemoManager> getOmemoManager() async {
    return manager;
  }

  @override
  Future<bool> shouldEncryptStanza(JID toJid, Stanza stanza) async {
    return toJid.toBare() == _encryptToJid;
  }
}

class TestingTCPSocketWrapper extends TCPSocketWrapper {
  @override
  bool onBadCertificate(dynamic certificate, String domain) {
    return true;
  }
}

void main(List<String> args) async {
  // Set up logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print(
      '[${record.level.name}] (${record.loggerName}) ${record.time}: ${record.message}',
    );
  });

  final parser = ArgParser()
    ..addOption('jid')
    ..addOption('password')
    ..addOption('host')
    ..addOption('port')
    ..addOption('to');
  final options = parser.parse(args);

  // Connect
  final jid = JID.fromString(options['jid']! as String);
  final to = JID.fromString(options['to']! as String).toBare();
  final portString = options['port'] as String?;
  final connection = XmppConnection(
    TestingReconnectionPolicy(),
    AlwaysConnectedConnectivityManager(),
    ClientToServerNegotiator(),
    TestingTCPSocketWrapper(),
  )..connectionSettings = ConnectionSettings(
    jid: jid,
    password: options['password']! as String,
    host: options['host'] as String?,
    port: portString != null ? int.parse(portString) : null,
  );

  // Generate OMEMO data
  final moxxmppOmemo = TestingOmemoManager(to);
  final omemoManager = omemo.OmemoManager(
    await omemo.OmemoDevice.generateNewDevice(jid.toString(), opkAmount: 5),
    omemo.BlindTrustBeforeVerificationTrustManager(),
    moxxmppOmemo.sendEmptyMessageImpl,
    moxxmppOmemo.fetchDeviceList,
    moxxmppOmemo.fetchDeviceBundle,
    moxxmppOmemo.subscribeToDeviceListImpl,
  );
  moxxmppOmemo.manager = omemoManager;
  final deviceId = await omemoManager.getDeviceId();
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
      print('[${event.from.toString()}] ' + body);
    }
  });

  // Connect
  Logger.root.info('Connecting...');
  final result = await connection.connect(shouldReconnect: false, waitUntilLogin: true);
  if (!result.isType<bool>()) {
    Logger.root.severe('Authentication failed!');
    return;
  }
  Logger.root.info('Connected.');

  // Publish our bundle
  Logger.root.info('Publishing bundle');
  final device = await moxxmppOmemo.manager.getDevice();
  final omemoResult = await moxxmppOmemo.publishBundle(await device.toBundle());
  if (!omemoResult.isType<bool>()) {
    Logger.root.severe('Failed to publish OMEMO bundle: ${omemoResult.get<OmemoError>()}');
    return;
  }

  final repl = Repl(prompt: '> ');
  await for (final line in repl.runAsync()) {
    await connection.getManagerById<MessageManager>(messageManager)!.sendMessage(
      to,
      TypedMap<StanzaHandlerExtension>.fromList([
        MessageBodyData(line),
      ]),
    );
  }

  // Disconnect
  await connection.disconnect();
}
