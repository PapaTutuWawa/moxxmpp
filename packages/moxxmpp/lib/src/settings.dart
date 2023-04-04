import 'package:moxxmpp/src/jid.dart';

class ConnectionSettings {
  ConnectionSettings({
    required this.jid,
    required this.password,
    this.host,
    this.port,
  });

  /// The JID to authenticate as.
  final JID jid;

  /// The password to use during authentication.
  final String password;

  /// The host to connect to. Skips DNS resolution if specified.
  final String? host;

  /// The port to connect to. Skips DNS resolution if specified.
  final int? port;
}
