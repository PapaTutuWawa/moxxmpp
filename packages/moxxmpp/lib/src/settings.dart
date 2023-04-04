import 'package:moxxmpp/src/jid.dart';

class ConnectionSettings {
  ConnectionSettings({
    required this.jid,
    required this.password,
    required this.useDirectTLS,
    this.host,
    this.port,
  });

  /// The JID to authenticate as.
  final JID jid;

  /// The password to use during authentication.
  final String password;

  /// Directly use TLS while connecting. Only effective if [host] and [port] are null.
  final bool useDirectTLS;

  /// The host to connect to. Skips DNS resolution if specified.
  final String? host;

  /// The port to connect to. Skips DNS resolution if specified.
  final int? port;
}
