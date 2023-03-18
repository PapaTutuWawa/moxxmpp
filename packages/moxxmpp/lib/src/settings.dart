import 'package:moxxmpp/src/jid.dart';

class ConnectionSettings {
  ConnectionSettings({
    required this.jid,
    required this.password,
    required this.useDirectTLS,
  });
  final JID jid;
  final String password;
  final bool useDirectTLS;
}
