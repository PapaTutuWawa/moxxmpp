import 'package:omemo_dart/omemo_dart.dart';

/// A simple wrapper class for defining elements that should not be encrypted.
class DoNotEncrypt {
  const DoNotEncrypt(this.tag, this.xmlns);

  /// The tag of the element.
  final String tag;

  /// The xmlns attribute of the element.
  final String xmlns;
}

/// An encryption error caused by OMEMO.
class OmemoEncryptionError {
  const OmemoEncryptionError(this.jids, this.devices);

  /// See omemo_dart's EncryptionResult for info on these fields.
  final Map<String, OmemoException> jids;
  final Map<RatchetMapKey, OmemoException> devices;
}
