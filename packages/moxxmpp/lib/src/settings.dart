import 'package:moxxmpp/src/jid.dart';

class ConnectionSettings {
  ConnectionSettings({
    required this.jid,
    required this.password,
    required this.useDirectTLS,
    this.host,
    this.port,
  });
  final JID jid;
  final String password;
  final bool useDirectTLS;

  final String? host;
  final int? port;
}
