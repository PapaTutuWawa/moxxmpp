import 'package:moxxmpp/src/connection.dart';
import 'package:moxxmpp/src/managers/data.dart';
import 'package:moxxmpp/src/stanza.dart';

/// Bounce a stanza if it was not handled by any manager. [conn] is the connection object
/// to use for sending the stanza. [data] is the StanzaHandlerData of the unhandled
/// stanza.
Future<void> handleUnhandledStanza(
  XmppConnection conn,
  StanzaHandlerData data,
) async {
  if (data.stanza.type != 'error' && data.stanza.type != 'result') {
    final stanza = data.stanza.copyWith(
      to: data.stanza.from,
      from: data.stanza.to,
      type: 'error',
      children: [
        buildErrorElement(
          'cancel',
          'feature-not-implemented',
        ),
      ],
    );

    await conn.sendStanza(
      stanza,
      awaitable: false,
      forceEncryption: data.encrypted,
    );
  }
}
