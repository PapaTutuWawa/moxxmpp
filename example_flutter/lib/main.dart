import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:moxdns/moxdns.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxmpp_socket_tcp/moxxmpp_socket_tcp.dart';

class ExampleTcpSocketWrapper extends TCPSocketWrapper {
  ExampleTcpSocketWrapper() : super();

  @override
  Future<List<MoxSrvRecord>> srvQuery(String domain, bool dnssec) async {
    final records = await MoxdnsPlugin.srvQuery(domain, false);
    return records
        .map(
          (record) => MoxSrvRecord(
            record.priority,
            record.weight,
            record.target,
            record.port,
          ),
        )
        .toList();
  }
}

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Moxxmpp Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MyHomePage(title: 'Moxxmpp Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final logger = Logger('MyHomePage');
  final XmppConnection connection = XmppConnection(
    RandomBackoffReconnectionPolicy(1, 60),
    AlwaysConnectedConnectivityManager(),
    ClientToServerNegotiator(),
    // The below causes the app to crash.
    //ExampleTcpSocketWrapper(),
    // In a production app, the below should be false.
    TCPSocketWrapper(),
  );
  TextEditingController jidController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool connected = false;
  bool loading = false;

  _MyHomePageState() : super() {
    connection
      ..registerManagers([
        StreamManagementManager(),
        DiscoManager([]),
        RosterManager(TestingRosterStateManager("", [])),
        PingManager(
          const Duration(minutes: 3),
        ),
        MessageManager(),
        PresenceManager(),
        OccupantIdManager(),
        MUCManager()
      ])
      ..registerFeatureNegotiators([
        ResourceBindingNegotiator(),
        StartTlsNegotiator(),
        StreamManagementNegotiator(),
        CSINegotiator(),
        RosterFeatureNegotiator(),
        SaslPlainNegotiator(),
        SaslScramNegotiator(10, '', '', ScramHashType.sha512),
        SaslScramNegotiator(9, '', '', ScramHashType.sha256),
        SaslScramNegotiator(8, '', '', ScramHashType.sha1),
      ]);
  }

  Future<void> _buttonPressed() async {
    if (connected) {
      await connection.disconnect();
      setState(() {
        connected = false;
      });
      return;
    }
    setState(() {
      loading = true;
    });
    connection.connectionSettings = ConnectionSettings(
      jid: JID.fromString(jidController.text),
      password: passwordController.text,
    );
    final result = await connection.connect(waitUntilLogin: true);
    setState(() {
      connected = result.isType<bool>() && result.get<bool>();
      loading = false;
    });
    if (result.isType<XmppError>()) {
      logger.severe(result.get<XmppError>());
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Error'),
            content: Text(result.get<XmppError>().toString()),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: connected ? Colors.green : Colors.deepPurple[800],
        foregroundColor: connected ? Colors.black : Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              enabled: !loading,
              controller: jidController,
              decoration: const InputDecoration(
                labelText: 'JID',
              ),
            ),
            TextField(
              enabled: !loading,
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
              ),
              obscureText: true,
            ),
            TextButton(
              onPressed: () async {
                // final muc = connection.getManagerById<MUCManager>(mucManager);
                // final roomInformationResult = await muc!.queryRoomInformation(
                //     JID.fromString('moxxmpp-muc-test@muc.moxxy.org'));
                // if (roomInformationResult.isType<RoomInformation>()) {
                //   print('Room information received');
                //   print(roomInformationResult.get<RoomInformation>().jid);
                //   print(roomInformationResult.get<RoomInformation>().name);
                //   print(roomInformationResult.get<RoomInformation>().features);
                // }

                // final muc = connection.getManagerById<MUCManager>(mucManager);
                // print('joining room');
                // final roomInformationResult = await muc!.joinRoom(
                //     JID.fromString('moxxmpp-muc-test@muc.moxxy.org/test_1'));
                // if (roomInformationResult.isType<MUCError>()) {
                //   print(roomInformationResult.get());
                // } else {
                //   print(roomInformationResult.get());
                // }

                print('HERE IS YOUR JID');
                print(connection.resource);
                final sid = connection.generateId();
                final originId = connection.generateId();
                final message =
                    connection.getManagerById<MessageManager>(messageManager);
                message!.sendMessage(
                  JID.fromString('moxxmpp-muc-test@muc.moxxy.org/ISD'),
                  TypedMap<StanzaHandlerExtension>.fromList([
                    const MessageBodyData('Testing'),
                    const MarkableData(true),
                    MessageIdData(sid),
                    StableIdData(originId, null),
                    ConversationTypeData(ConversationType.groupchatprivate)
                  ]),
                );
              },
              child: const Text('Test'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _buttonPressed,
        label: Text(connected ? 'Disconnect' : 'Connect'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        tooltip: 'Connect',
        icon: const Icon(Icons.power),
      ),
    );
  }
}
