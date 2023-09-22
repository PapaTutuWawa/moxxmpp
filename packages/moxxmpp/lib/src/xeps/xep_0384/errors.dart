abstract class OmemoError {}

class UnknownOmemoError extends OmemoError {}

class InvalidAffixElementsException implements Exception {}

class OmemoNotSupportedForContactException extends OmemoError {}

class EncryptionFailedException implements Exception {}

class InvalidEnvelopePayloadException implements Exception {}
