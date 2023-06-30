import 'package:moxxmpp/src/stanza.dart';

/// Base type for disco-related errors.
abstract class DiscoError extends StanzaError {}

/// An unspecified error that is not covered by another [DiscoError].
class UnknownDiscoError extends DiscoError {}

/// The received disco response is invalid in some shape or form.
class InvalidResponseDiscoError extends DiscoError {}
