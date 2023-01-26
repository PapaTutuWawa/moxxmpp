/// This manager class is responsible to tell the moxxmpp XmppConnection
/// when a connection can be established or not, regarding the network availability.
abstract class ConnectivityManager {
  /// Returns true if a network connection is available. If not, returns false.
  Future<bool> hasConnection();

  /// Returns a future that resolves once we have a network connection.
  Future<void> waitForConnection();
}

/// An implementation of [ConnectivityManager] that is always connected.
class AlwaysConnectedConnectivityManager extends ConnectivityManager {
  @override
  Future<bool> hasConnection() async => true;

  @override
  Future<void> waitForConnection() async {}
}
