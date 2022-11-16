import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:moxdns/moxdns.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxmpp_socket_tcp/moxxmpp_socket_tcp.dart';

class ExampleTcpSocketWrapper extends TCPSocketWrapper {
  ExampleTcpSocketWrapper() : super(false);

  @override
  Future<List<MoxSrvRecord>> srvQuery(String domain, bool dnssec) async {
    final records = await MoxdnsPlugin.srvQuery(domain, false);
    return records
      .map((record) => MoxSrvRecord(
        record.priority,
        record.weight,
        record.target,
        record.port,
      ),)
      .toList();
  }
}

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
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
  final XmppConnection connection = XmppConnection(
    ExponentialBackoffReconnectionPolicy(),
    ExampleTcpSocketWrapper(),
  );
  TextEditingController jidController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  _MyHomePageState() : super() {
    connection
      ..registerManagers([
        StreamManagementManager(),
        DiscoManager(),
        RosterManager(),
        PingManager(),
        MessageManager(),
        PresenceManager('http://moxxmpp.example'),
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
    connection.setConnectionSettings(
      ConnectionSettings(
        jid: JID.fromString(jidController.text),
        password: passwordController.text,
        useDirectTLS: true,
        allowPlainAuth: false,
      ),
    );
    await connection.connect();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: jidController,
              decoration: InputDecoration(
                labelText: 'JID',
              ),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
              ),
              obscureText: true,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _buttonPressed,
        tooltip: 'Connect',
        child: const Icon(Icons.add),
      ),
    );
  }
}
