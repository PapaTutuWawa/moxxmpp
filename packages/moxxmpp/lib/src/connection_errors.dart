import 'package:moxxmpp/src/errors.dart';
import 'package:moxxmpp/src/negotiators/negotiator.dart';

/// The reason a call to `XmppConnection.connect` failed.
abstract class XmppConnectionError {}

/// Returned by `XmppConnection.connect` when a connection is already active.
class ConnectionAlreadyRunningError extends XmppConnectionError {}

/// Returned by `XmppConnection.connect` when a negotiator returned an unrecoverable
/// error. Only returned when waitUntilLogin is true.
class NegotiatorReturnedError extends XmppConnectionError {
  NegotiatorReturnedError(this.error);

  /// The error returned by the negotiator.
  final NegotiatorError error;
}

class StreamFailureError extends XmppConnectionError {
  StreamFailureError(this.error);

  /// The error that causes a connection failure.
  final XmppError error;
}

/// Returned by `XmppConnection.connect` when no connection could
/// be established.
class NoConnectionPossibleError extends XmppConnectionError {}
