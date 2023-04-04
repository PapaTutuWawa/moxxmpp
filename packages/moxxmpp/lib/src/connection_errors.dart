import 'package:moxxmpp/src/errors.dart';
import 'package:moxxmpp/src/negotiators/negotiator.dart';

/// The reason a call to `XmppConnection.connect` failed.
abstract class XmppConnectionError extends XmppError {}

/// Returned by `XmppConnection.connect` when a negotiator returned an unrecoverable
/// error. Only returned when waitUntilLogin is true.
class NegotiatorReturnedError extends XmppConnectionError {
  NegotiatorReturnedError(this.error);

  @override
  bool isRecoverable() => error.isRecoverable();

  /// The error returned by the negotiator.
  final NegotiatorError error;
}

class StreamFailureError extends XmppConnectionError {
  StreamFailureError(this.error);

  @override
  bool isRecoverable() => error.isRecoverable();

  /// The error that causes a connection failure.
  final XmppError error;
}

/// Returned by `XmppConnection.connect` when no connection could
/// be established.
class NoConnectionPossibleError extends XmppConnectionError {
  @override
  bool isRecoverable() => true;
}

/// Returned if no matching authentication mechanism has been presented
class NoMatchingAuthenticationMechanismAvailableError
    extends XmppConnectionError {
  @override
  bool isRecoverable() => false;
}

/// Returned if no negotiator was picked, even though negotiations are not done
/// yet.
class NoAuthenticatorAvailableError extends XmppConnectionError {
  @override
  bool isRecoverable() => false;
}

/// Returned by the negotiation handler if unexpected data has been received
class UnexpectedDataError extends XmppConnectionError {
  @override
  bool isRecoverable() => false;
}

/// Returned by the ComponentToServerNegotiator if the handshake is not successful.
class InvalidHandshakeCredentialsError extends XmppConnectionError {
  @override
  bool isRecoverable() => false;
}
