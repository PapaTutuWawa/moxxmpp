import 'dart:convert';
import 'package:moxlib/moxlib.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/stringxml.dart';
import 'package:moxxmpp/src/xeps/xep_0300.dart';
import 'package:moxxmpp/src/xeps/xep_0447.dart';

enum SFSEncryptionType {
  aes128GcmNoPadding,
  aes256GcmNoPadding,
  aes256CbcPkcs7;

  factory SFSEncryptionType.fromNamespace(String xmlns) {
    switch (xmlns) {
      case sfsEncryptionAes128GcmNoPaddingXmlns:
        return SFSEncryptionType.aes128GcmNoPadding;
      case sfsEncryptionAes256GcmNoPaddingXmlns:
        return SFSEncryptionType.aes256GcmNoPadding;
      case sfsEncryptionAes256CbcPkcs7Xmlns:
        return SFSEncryptionType.aes256CbcPkcs7;
    }

    throw Exception();
  }

  String toNamespace() {
    switch (this) {
      case SFSEncryptionType.aes128GcmNoPadding:
        return sfsEncryptionAes128GcmNoPaddingXmlns;
      case SFSEncryptionType.aes256GcmNoPadding:
        return sfsEncryptionAes256GcmNoPaddingXmlns;
      case SFSEncryptionType.aes256CbcPkcs7:
        return sfsEncryptionAes256CbcPkcs7Xmlns;
    }
  }
}

class StatelessFileSharingEncryptedSource extends StatelessFileSharingSource {
  StatelessFileSharingEncryptedSource(
    this.encryption,
    this.key,
    this.iv,
    this.hashes,
    this.source,
  );
  factory StatelessFileSharingEncryptedSource.fromXml(XMLNode element) {
    assert(
      element.attributes['xmlns'] == sfsEncryptionXmlns,
      'Element has invalid xmlns',
    );

    final key = base64Decode(element.firstTag('key')!.text!);
    final iv = base64Decode(element.firstTag('iv')!.text!);
    final sources = element.firstTag('sources', xmlns: sfsXmlns)!.children;

    // Find the first URL source
    final source = firstWhereOrNull(
      sources,
      (XMLNode child) =>
          child.tag == 'url-data' && child.attributes['xmlns'] == urlDataXmlns,
    )!;

    // Find hashes
    final hashes = <HashFunction, String>{};
    for (final hash in element.findTags('hash', xmlns: hashXmlns)) {
      final hashFunction =
          HashFunction.fromName(hash.attributes['algo']! as String);
      hashes[hashFunction] = hash.text!;
    }

    return StatelessFileSharingEncryptedSource(
      SFSEncryptionType.fromNamespace(element.attributes['cipher']! as String),
      key,
      iv,
      hashes,
      StatelessFileSharingUrlSource.fromXml(source),
    );
  }

  final List<int> key;
  final List<int> iv;
  final SFSEncryptionType encryption;
  final Map<HashFunction, String> hashes;
  final StatelessFileSharingUrlSource source;

  @override
  XMLNode toXml() {
    return XMLNode.xmlns(
      tag: 'encrypted',
      xmlns: sfsEncryptionXmlns,
      attributes: <String, String>{
        'cipher': encryption.toNamespace(),
      },
      children: [
        XMLNode(
          tag: 'key',
          text: base64Encode(key),
        ),
        XMLNode(
          tag: 'iv',
          text: base64Encode(iv),
        ),
        ...hashes.entries
            .map((hash) => constructHashElement(hash.key, hash.value)),
        XMLNode.xmlns(
          tag: 'sources',
          xmlns: sfsXmlns,
          children: [source.toXml()],
        ),
      ],
    );
  }
}
