import 'package:moxxmpp/src/socket.dart';

/// An internal error class
// ignore: one_member_abstracts
abstract class XmppError {
  /// Return true if we can recover from the error by attempting a reconnection.
  bool isRecoverable();
}

/// Returned if we could not establish a TCP connection
/// to the server.
class NoConnectionError extends XmppError {
  @override
  bool isRecoverable() => true;
}

/// Returned if a socket error occured
class SocketError extends XmppError {
  SocketError(this.event);
  final XmppSocketErrorEvent event;

  @override
  bool isRecoverable() => true;
}

/// Returned if we time out
class TimeoutError extends XmppError {
  @override
  bool isRecoverable() => true;
}

/// Returned if we received a stream error
class StreamError extends XmppError {
  // TODO(PapaTutuWawa): Be more precise
  @override
  bool isRecoverable() => true;
}
