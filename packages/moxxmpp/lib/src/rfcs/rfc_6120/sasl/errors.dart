import 'package:moxxmpp/src/negotiators/negotiator.dart';
import 'package:moxxmpp/src/stringxml.dart';

abstract class SaslError extends NegotiatorError {
  static SaslError fromFailure(XMLNode failure) {
    XMLNode? error;
    for (final child in failure.children) {
      if (child.tag == 'text') continue;

      error = child;
      break;
    }

    switch (error?.tag) {
      case 'credentials-expired':
        return SaslCredentialsExpiredError();
      case 'not-authorized':
        return SaslNotAuthorizedError();
      case 'account-disabled':
        return SaslAccountDisabledError();
    }

    return SaslUnspecifiedError();
  }
}

/// Triggered when the server returned us a <not-authorized /> failure during SASL
/// (https://xmpp.org/rfcs/rfc6120.html#sasl-errors-not-authorized).
class SaslNotAuthorizedError extends SaslError {
  @override
  bool isRecoverable() => false;
}

/// Triggered when the server returned us a <credentials-expired /> failure during SASL
/// (https://xmpp.org/rfcs/rfc6120.html#sasl-errors-credentials-expired).
class SaslCredentialsExpiredError extends SaslError {
  @override
  bool isRecoverable() => false;
}

/// Triggered when the server returned us a <account-disabled /> failure during SASL
/// (https://xmpp.org/rfcs/rfc6120.html#sasl-errors-account-disabled).
class SaslAccountDisabledError extends SaslError {
  @override
  bool isRecoverable() => false;
}

/// An unspecified SASL error, i.e. everything not matched by any more precise erorr
/// class.
class SaslUnspecifiedError extends SaslError {
  @override
  bool isRecoverable() => true;
}
