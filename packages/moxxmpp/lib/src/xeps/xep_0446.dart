import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/stringxml.dart';
import 'package:moxxmpp/src/xeps/xep_0264.dart';
import 'package:moxxmpp/src/xeps/xep_0300.dart';

class FileMetadataData {
  const FileMetadataData({
    this.mediaType,
    this.width,
    this.height,
    this.desc,
    this.length,
    this.name,
    this.size,
    required this.thumbnails,
    Map<HashFunction, String>? hashes,
  }) : hashes = hashes ?? const {};

  /// Parse [node] as a FileMetadataData element.
  factory FileMetadataData.fromXML(XMLNode node) {
    assert(
      node.attributes['xmlns'] == fileMetadataXmlns,
      'Invalid element xmlns',
    );
    assert(node.tag == 'file', 'Invalid element anme');

    final lengthElement = node.firstTag('length');
    final length =
        lengthElement != null ? int.parse(lengthElement.innerText()) : null;
    final sizeElement = node.firstTag('size');
    final size =
        sizeElement != null ? int.parse(sizeElement.innerText()) : null;

    final hashes = <HashFunction, String>{};
    for (final e in node.findTags('hash')) {
      final hashFunction =
          HashFunction.fromName(e.attributes['algo']! as String);
      hashes[hashFunction] = e.innerText();
    }

    // Thumbnails
    final thumbnails = List<JingleContentThumbnail>.empty(growable: true);
    for (final i
        in node.findTags('thumbnail', xmlns: jingleContentThumbnailXmlns)) {
      thumbnails.add(JingleContentThumbnail.fromXML(i));
    }

    // Length and height
    final widthString = node.firstTag('length');
    final heightString = node.firstTag('height');
    int? width;
    int? height;
    if (widthString != null) {
      width = int.parse(widthString.innerText());
    }
    if (heightString != null) {
      height = int.parse(heightString.innerText());
    }

    return FileMetadataData(
      mediaType: node.firstTag('media-type')?.innerText(),
      width: width,
      height: height,
      desc: node.firstTag('desc')?.innerText(),
      hashes: hashes,
      length: length,
      name: node.firstTag('name')?.innerText(),
      size: size,
      thumbnails: thumbnails,
    );
  }

  final String? mediaType;
  final int? width;
  final int? height;
  final List<JingleContentThumbnail> thumbnails;
  final String? desc;
  final Map<HashFunction, String> hashes;
  final int? length;
  final String? name;
  final int? size;

  XMLNode toXML() {
    final node = XMLNode.xmlns(
      tag: 'file',
      xmlns: fileMetadataXmlns,
      children: List.empty(growable: true),
    );

    if (mediaType != null) {
      node.addChild(XMLNode(tag: 'media-type', text: mediaType));
    }
    if (width != null) {
      node.addChild(XMLNode(tag: 'width', text: '$width'));
    }
    if (height != null) {
      node.addChild(XMLNode(tag: 'height', text: '$height'));
    }
    if (desc != null) {
      node.addChild(XMLNode(tag: 'desc', text: desc));
    }
    if (length != null) {
      node.addChild(XMLNode(tag: 'length', text: length.toString()));
    }
    if (name != null) {
      node.addChild(XMLNode(tag: 'name', text: name));
    }
    if (size != null) {
      node.addChild(XMLNode(tag: 'size', text: size.toString()));
    }

    for (final hash in hashes.entries) {
      node.addChild(
        constructHashElement(hash.key, hash.value),
      );
    }

    for (final thumbnail in thumbnails) {
      node.addChild(
        thumbnail.toXML(),
      );
    }

    return node;
  }
}
