import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/stringxml.dart';

extension _StringToInt on String {
  int toInt() => int.parse(this);
}

class JingleContentThumbnail {
  const JingleContentThumbnail(
    this.uri,
    this.mediaType,
    this.width,
    this.height,
  );

  factory JingleContentThumbnail.fromXML(XMLNode thumbnail) {
    assert(
      thumbnail.tag == 'thumbnail',
      'thumbnail must be Jingle Content Thumbnail',
    );
    assert(
      thumbnail.attributes['xmlns'] == jingleContentThumbnailXmlns,
      'thumbnail must be Jingle Content Thumbnail',
    );

    return JingleContentThumbnail(
      Uri.parse(thumbnail.attributes['uri']! as String),
      thumbnail.attributes['media-type'] as String?,
      (thumbnail.attributes['width'] as String?)?.toInt(),
      (thumbnail.attributes['height'] as String?)?.toInt(),
    );
  }

  /// The URI of the thumbnail data.
  final Uri uri;

  /// The MIME type of the thumbnail
  final String? mediaType;

  /// The width of the thumbnail.
  final int? width;

  /// The height of the thumbnail.
  final int? height;

  /// Convert the thumbnail to its XML representation.
  XMLNode toXML() {
    return XMLNode.xmlns(
      tag: 'thumbnail',
      xmlns: jingleContentThumbnailXmlns,
      attributes: {
        'uri': uri.toString(),
        if (mediaType != null) 'media-type': mediaType!,
        if (width != null) 'width': width.toString(),
        if (height != null) 'height': height.toString(),
      },
    );
  }
}
