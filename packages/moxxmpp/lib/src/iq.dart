import 'package:moxxmpp/src/connection.dart';
import 'package:moxxmpp/src/stanza.dart';

bool handleUnhandledStanza(XmppConnection conn, Stanza stanza) {
  if (stanza.type != 'error' && stanza.type != 'result') {
    conn.sendStanza(stanza.errorReply('cancel', 'feature-not-implemented'));
  }

  return true;
}
