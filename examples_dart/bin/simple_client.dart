import 'package:logging/logging.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxmpp_socket_tcp/moxxmpp_socket_tcp.dart';

/// The JID we want to authenticate as.
final xmppUser = JID.fromString('jane@example.com');

/// The password to authenticate with.
const xmppPass = 'secret';

/// The [xmppHost]:[xmppPort] server address to connect to.
/// In a real application, one might prefer to use [TCPSocketWrapper]
/// with a custom DNS implementation to let moxxmpp resolve the XMPP
/// server's address automatically. However, if we just provide a host
/// and a port, then [TCPSocketWrapper] will just skip the resolution and
/// immediately use the provided connection details.
const xmppHost = 'localhost';
const xmppPort = 5222;

void main(List<String> args) async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}|${record.time}: ${record.message}');
  });

  // This class manages every aspect of handling the XMPP stream.
  final connection = XmppConnection(
    // A reconnection policy tells the connection how to handle an error
    // while or after connecting to the server. The [TestingReconnectionPolicy]
    // immediately triggers a reconnection. In a real implementation, one might
    // prefer to use a smarter strategy, like using an exponential backoff.
    TestingReconnectionPolicy(),

    // A connectivity manager tells the connection when it can connect. This is to
    // ensure that we're not constantly trying to reconnect because we have no
    // Internet connection. [AlwaysConnectedConnectivityManager] always says that
    // we're connected. In a real application, one might prefer to use a smarter
    // strategy, like using connectivity_plus to query the system's network connectivity
    // state.
    AlwaysConnectedConnectivityManager(),

    // This kind of negotiator tells the connection how to handle the stream
    // negotiations. The [ClientToServerNegotiator] allows to connect to the server
    // as a regular client. Another negotiator would be the [ComponentToServerNegotiator] that
    // allows for connections to the server where we're acting as a component.
    ClientToServerNegotiator(),

    // A wrapper around any kind of connection. In this case, we use the [TCPSocketWrapper], which
    // uses a dart:io Socket/SecureSocket to connect to the server. If you want, you can also
    // provide your own socket to use, for example, WebSockets or any other connection
    // mechanism.
    TCPSocketWrapper(false),
  )..connectionSettings = ConnectionSettings(
      jid: xmppUser,
      password: xmppPass,
      host: xmppHost,
      port: xmppPort,
    );

  // Register a set of "managers" that provide you with implementations of various
  // XEPs. Some have interdependencies, which need to be met. However, this example keeps
  // it simple and just registers a [MessageManager], which has no required dependencies.
  await connection.registerManagers([
    // The [MessageManager] handles receiving and sending <message /> stanzas.
    MessageManager(),
  ]);

  // Feature negotiators are objects that tell the connection negotiator what stream features
  // we can negotiate and enable. moxxmpp negotiators always try to enable their features.
  await connection.registerFeatureNegotiators([
    // This negotiator authenticates to the server using SASL PLAIN with the provided
    // credentials.
    SaslPlainNegotiator(),
    // This negotiator attempts to bind a resource. By default, it's always a random one.
    ResourceBindingNegotiator(),
    // This negotiator attempts to do StartTLS before authenticating.
    StartTlsNegotiator(),
  ]);

  // Set up a stream handler for the connection's event stream. Managers and negotiators
  // may trigger certain events. The [MessageManager], for example, triggers a [MessageEvent]
  // whenever a message is received. If other managers are registered that parse a message's
  // contents, then they can add their data to the event.
  connection.asBroadcastStream().listen((event) {
    if (event is! MessageEvent) {
      return;
    }

    // The text body (contents of the <body /> element) are returned as a
    // [MessageBodyData] object. However, a message does not have to contain a
    // body, so it is nullable.
    final body = event.extensions.get<MessageBodyData>()?.body;
    print('[<-- ${event.from}] $body');
  });

  // Connect to the server.
  final result = await connection.connect(
    // This flag indicates that we want to reconnect in case something happens.
    shouldReconnect: true,
    // This flag indicates that we want the returned Future to only resolve
    // once the stream negotiations are done and no negotiator has any feature left
    // to negotiate.
    waitUntilLogin: true,
  );

  // Check if the connection was successful. [connection.connect] can return a boolean
  // to indicate success or a [XmppError] in case the connection attempt failed.
  if (!result.isType<bool>()) {
    print('Failed to connect to server');
    return;
  }
}
