import 'dart:async';
import 'package:moxxmpp/src/stringxml.dart';
import 'package:xml/xml.dart';
import 'package:xml/xml_events.dart';

/// A result object for XmlStreamBuffer.
abstract class XmlStreamBufferObject {}

/// A complete XML element returned by the stream buffer.
class XmlStreamBufferElement extends XmlStreamBufferObject {
  XmlStreamBufferElement(this.node);

  /// The actual [XMLNode].
  final XMLNode node;
}

/// Just the stream header of a new XML stream.
class XmlStreamBufferHeader extends XmlStreamBufferObject {
  XmlStreamBufferHeader(this.attributes);

  /// The headers of the stream header.
  final Map<String, String> attributes;
}

/// A buffer to put between a socket's input and a full XML stream.
class XmlStreamBuffer
    extends StreamTransformerBase<String, XmlStreamBufferObject> {
  final StreamController<XmlStreamBufferObject> _streamController =
      StreamController<XmlStreamBufferObject>();

  @override
  Stream<XmlStreamBufferObject> bind(Stream<String> stream) {
    final events = stream.toXmlEvents().asBroadcastStream();
    events.transform(
      StreamTransformer<List<XmlEvent>, XmlStartElementEvent>.fromHandlers(
        handleData: (events, sink) {
          for (final event in events) {
            if (event is! XmlStartElementEvent) {
              continue;
            }
            if (event.name != 'stream:stream') {
              continue;
            }

            sink.add(event);
          }
        },
      ),
    ).listen((event) {
      _streamController.add(
        XmlStreamBufferHeader(
          Map<String, String>.fromEntries(
            event.attributes.map((attr) {
              return MapEntry(attr.name, attr.value);
            }),
          ),
        ),
      );
    });

    events
        .selectSubtreeEvents((event) {
          return event.qualifiedName != 'stream:stream';
        })
        .transform(const XmlNodeDecoder())
        .listen((nodes) {
          for (final node in nodes) {
            if (node.nodeType == XmlNodeType.ELEMENT) {
              _streamController.add(
                XmlStreamBufferElement(
                  XMLNode.fromXmlElement(node as XmlElement),
                ),
              );
            }
          }
        });
    return _streamController.stream;
  }
}
