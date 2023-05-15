import 'package:cryptography/cryptography.dart';
import 'package:moxxmpp/src/managers/base.dart';
import 'package:moxxmpp/src/managers/namespaces.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/stringxml.dart';

XMLNode constructHashElement(HashFunction hash, String value) {
  return XMLNode.xmlns(
    tag: 'hash',
    xmlns: hashXmlns,
    attributes: {'algo': hash.toName()},
    text: value,
  );
}

enum HashFunction {
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
      case hashSha256:
        return HashFunction.sha256;
      case hashSha512:
        return HashFunction.sha512;
      case hashSha3256:
        return HashFunction.sha3_256;
      case hashSha3512:
        return HashFunction.sha3_512;
      case hashBlake2b256:
        return HashFunction.blake2b256;
      case hashBlake2b512:
        return HashFunction.blake2b512;
    }

    throw Exception();
  }

  /// Return the hash function's name according to IANA's hash name register or XEP-0300.
  String toName() {
    switch (this) {
      case HashFunction.sha256:
        return hashSha256;
      case HashFunction.sha512:
        return hashSha512;
      case HashFunction.sha3_256:
        return hashSha3512;
      case HashFunction.sha3_512:
        return hashSha3512;
      case HashFunction.blake2b256:
        return hashBlake2b256;
      case HashFunction.blake2b512:
        return hashBlake2b512;
    }
  }
}

class CryptographicHashManager extends XmppManagerBase {
  CryptographicHashManager() : super(cryptographicHashManager);

  @override
  Future<bool> isSupported() async => true;

  @override
  List<String> getDiscoFeatures() => [
        '$hashFunctionNameBaseXmlns:$hashSha256',
        '$hashFunctionNameBaseXmlns:$hashSha512',
        //'$hashFunctionNameBaseXmlns:$hashSha3256',
        //'$hashFunctionNameBaseXmlns:$hashSha3512',
        //'$hashFunctionNameBaseXmlns:$hashBlake2b256',
        '$hashFunctionNameBaseXmlns:$hashBlake2b512',
      ];

  static Future<List<int>> hashFromData(
    List<int> data,
    HashFunction function,
  ) async {
    // TODO(PapaTutuWawa): Implement the others as well
    HashAlgorithm algo;
    switch (function) {
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
