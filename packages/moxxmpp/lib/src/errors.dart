import 'package:moxxmpp/src/socket.dart';

/// An internal error class
abstract class XmppError {}

/// Returned if we could not establish a TCP connection
/// to the server.
class NoConnectionError extends XmppError {}

/// Returned if a socket error occured
class SocketError extends XmppError {
  SocketError(this.event);
  final XmppSocketErrorEvent event;
}

/// Returned if we time out
class TimeoutError extends XmppError {}

/// Returned if we received a stream error
class StreamError extends XmppError {}
