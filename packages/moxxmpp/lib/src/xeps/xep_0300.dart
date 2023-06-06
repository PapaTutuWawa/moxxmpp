import 'package:cryptography/cryptography.dart';
import 'package:moxxmpp/src/managers/base.dart';
import 'package:moxxmpp/src/managers/namespaces.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/stringxml.dart';

/// Hash names
const _hashSha1 = 'sha-1';
const _hashSha256 = 'sha-256';
const _hashSha512 = 'sha-512';
const _hashSha3256 = 'sha3-256';
const _hashSha3512 = 'sha3-512';
const _hashBlake2b256 = 'blake2b-256';
const _hashBlake2b512 = 'blake2b-512';

/// Helper method for building a <hash /> element according to XEP-0300.
XMLNode constructHashElement(HashFunction hash, String value) {
  return XMLNode.xmlns(
    tag: 'hash',
    xmlns: hashXmlns,
    attributes: {'algo': hash.toName()},
    text: value,
  );
}

enum HashFunction {
  /// SHA-1
  sha1,

  /// SHA-256
  sha256,

  /// SHA-256
  sha512,

  /// SHA3-256
  sha3_256,

  /// SHA3-512
  sha3_512,

  /// BLAKE2b-256
  blake2b256,

  /// BLAKE2b-512
  blake2b512;

  /// Get a HashFunction from its name [name] according to either
  /// - IANA's hash name register (http://www.iana.org/assignments/hash-function-text-names/hash-function-text-names.xhtml)
  /// - XEP-0300
  factory HashFunction.fromName(String name) {
    switch (name) {
      case _hashSha1:
        return HashFunction.sha1;
      case _hashSha256:
        return HashFunction.sha256;
      case _hashSha512:
        return HashFunction.sha512;
      case _hashSha3256:
        return HashFunction.sha3_256;
      case _hashSha3512:
        return HashFunction.sha3_512;
      case _hashBlake2b256:
        return HashFunction.blake2b256;
      case _hashBlake2b512:
        return HashFunction.blake2b512;
    }

    throw Exception('Invalid hash function $name');
  }

  /// Like [HashFunction.fromName], but returns null if the hash function is unknown
  static HashFunction? maybeFromName(String name) {
    switch (name) {
      case _hashSha1:
        return HashFunction.sha1;
      case _hashSha256:
        return HashFunction.sha256;
      case _hashSha512:
        return HashFunction.sha512;
      case _hashSha3256:
        return HashFunction.sha3_256;
      case _hashSha3512:
        return HashFunction.sha3_512;
      case _hashBlake2b256:
        return HashFunction.blake2b256;
      case _hashBlake2b512:
        return HashFunction.blake2b512;
    }

    return null;
  }

  /// Return the hash function's name according to IANA's hash name register or XEP-0300.
  String toName() {
    switch (this) {
      case HashFunction.sha1:
        return _hashSha1;
      case HashFunction.sha256:
        return _hashSha256;
      case HashFunction.sha512:
        return _hashSha512;
      case HashFunction.sha3_256:
        return _hashSha3512;
      case HashFunction.sha3_512:
        return _hashSha3512;
      case HashFunction.blake2b256:
        return _hashBlake2b256;
      case HashFunction.blake2b512:
        return _hashBlake2b512;
    }
  }
}

class CryptographicHashManager extends XmppManagerBase {
  CryptographicHashManager() : super(cryptographicHashManager);

  @override
  Future<bool> isSupported() async => true;

  /// NOTE: We intentionally do not advertise support for SHA-1, as it is marked as
  ///       MUST NOT. Sha-1 support is only for providing a wrapper over its hash
  ///       function, for example for XEP-0115.
  @override
  List<String> getDiscoFeatures() => [
        '$hashFunctionNameBaseXmlns:$_hashSha256',
        '$hashFunctionNameBaseXmlns:$_hashSha512',
        //'$hashFunctionNameBaseXmlns:$_hashSha3256',
        //'$hashFunctionNameBaseXmlns:$_hashSha3512',
        //'$hashFunctionNameBaseXmlns:$_hashBlake2b256',
        '$hashFunctionNameBaseXmlns:$_hashBlake2b512',
      ];

  /// Compute the raw hash value of [data] using the algorithm specified by [function].
  /// If the function is not supported, an exception will be thrown.
  static Future<List<int>> hashFromData(
    HashFunction function,
    List<int> data,
  ) async {
    // TODO(PapaTutuWawa): Implement the others as well
    HashAlgorithm algo;
    switch (function) {
      case HashFunction.sha1:
        algo = Sha1();
        break;
      case HashFunction.sha256:
        algo = Sha256();
        break;
      case HashFunction.sha512:
        algo = Sha512();
        break;
      case HashFunction.blake2b512:
        algo = Blake2b();
        break;
      // ignore: no_default_cases
      default:
        throw Exception();
    }

    final digest = await algo.hash(data);
    return digest.bytes;
  }
}
