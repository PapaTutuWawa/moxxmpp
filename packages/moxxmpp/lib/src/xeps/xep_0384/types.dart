import 'package:moxxmpp/src/managers/data.dart';
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
  const OmemoEncryptionError(this.deviceEncryptionErrors);

  /// See omemo_dart's EncryptionResult for info on this field.
  final Map<String, List<EncryptToJidError>> deviceEncryptionErrors;
}

class OmemoData extends StanzaHandlerExtension {
  OmemoData(this.newRatchets, this.replacedRatchets);

  final Map<String, List<int>> newRatchets;

  final Map<String, List<int>> replacedRatchets;
}
