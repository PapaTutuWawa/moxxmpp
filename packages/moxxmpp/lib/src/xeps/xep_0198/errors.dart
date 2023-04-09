import 'package:moxxmpp/src/errors.dart';

/// Triggered by the StreamManagementManager when an ack request times out.
class StreamManagementAckTimeoutError extends XmppError {
  @override
  bool isRecoverable() => true;
}
