abstract class OmemoError {}

class UnknownOmemoError extends OmemoError {}

class InvalidAffixElementsException implements Exception {}

/// Internal exception that is returned when the device list cannot be
/// fetched because the returned list is empty.
class EmptyDeviceListException implements OmemoError {}

class OmemoNotSupportedForContactException extends OmemoError {}

class EncryptionFailedException implements Exception {}

class InvalidEnvelopePayloadException implements Exception {}
