import 'package:moxxmpp/src/negotiators/negotiator.dart';

/// Triggered by the SASL2 negotiator when no SASL mechanism was chosen during
/// negotiation.
class NoSASLMechanismSelectedError extends NegotiatorError {
  @override
  bool isRecoverable() => false;
}
