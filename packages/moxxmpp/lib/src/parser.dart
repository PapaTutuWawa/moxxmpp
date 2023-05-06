import 'dart:async';
import 'dart:convert';
import 'package:moxxmpp/src/stringxml.dart';
// ignore: implementation_imports
import 'package:xml/src/xml_events/utils/conversion_sink.dart';
import 'package:xml/xml.dart';
import 'package:xml/xml_events.dart';

/// A result object for XmlStreamBuffer.
abstract class XMPPStreamObject {}

/// A complete XML element returned by the stream buffer.
class XMPPStreamElement extends XMPPStreamObject {
  XMPPStreamElement(this.node);

  /// The actual [XMLNode].
  final XMLNode node;
}

/// Just the stream header of a new XML stream.
class XMPPStreamHeader extends XMPPStreamObject {
  XMPPStreamHeader(this.attributes);

  /// The headers of the stream header.
  final Map<String, String> attributes;
}

/// A wrapper around a [Converter]'s [Converter.startChunkedConversion] method.
class _ChunkedConversionBuffer<S, T> {
  /// Use the converter [converter].
  _ChunkedConversionBuffer(Converter<S, List<T>> converter) {
    _outputSink = ConversionSink<List<T>>(_results.addAll);
    _inputSink = converter.startChunkedConversion(_outputSink);
  }

  /// The results of the converter.
  final List<T> _results = List<T>.empty(growable: true);

  /// The sink that outputs to [_results].
  late ConversionSink<List<T>> _outputSink;

  /// The sink that we use for input.
  late Sink<S> _inputSink;

  /// Close all opened sinks.
  void close() {
    _inputSink.close();
    _outputSink.close();
  }

  /// Turn the input [input] into a list of [T] according to the initial converter.
  List<T> convert(S input) {
    _results.clear();
    _inputSink.add(input);
    return _results;
  }
}

/// A buffer to put between a socket's input and a full XML stream.
class XMPPStreamParser extends StreamTransformerBase<String, XMPPStreamObject> {
  final StreamController<XMPPStreamObject> _streamController =
      StreamController<XMPPStreamObject>();

  /// Turns a String into a list of [XmlEvent]s in a chunked fashion.
  _ChunkedConversionBuffer<String, XmlEvent> _eventBuffer =
      _ChunkedConversionBuffer<String, XmlEvent>(XmlEventDecoder());

  /// Turns a list of [XmlEvent]s into a list of [XmlNode]s in a chunked fashion.
  _ChunkedConversionBuffer<List<XmlEvent>, XmlNode> _childBuffer =
      _ChunkedConversionBuffer<List<XmlEvent>, XmlNode>(const XmlNodeDecoder());

  void reset() {
    try {
      _eventBuffer.close();
    } catch (_) {
      // Do nothing. A crash here may indicate that we end on invalid XML, which is fine
      // since we're not going to use the buffer's output anymore.
    }
    try {
      _childBuffer.close();
    } catch (_) {
      // Do nothing.
    }

    // Recreate the buffers.
    _eventBuffer =
        _ChunkedConversionBuffer<String, XmlEvent>(XmlEventDecoder());
    _childBuffer = _ChunkedConversionBuffer<List<XmlEvent>, XmlNode>(
      const XmlNodeDecoder(),
    );
  }

  @override
  Stream<XMPPStreamObject> bind(Stream<String> stream) {
    // We do not want to use xml's toXmlEvents and toSubtreeEvents methods as they
    // create streams we cannot close. We need to be able to destroy and recreate an
    // XML parser whenever we start a new connection.
    final childSelector =
        XmlSubtreeSelector((event) => event.qualifiedName != 'stream:stream');
    final streamHeaderSelector =
        XmlSubtreeSelector((event) => event.qualifiedName == 'stream:stream');

    stream.listen((input) {
      final events = _eventBuffer.convert(input);
      final streamHeaderEvents = streamHeaderSelector.convert(events);

      // Process the stream header separately.
      for (final event in streamHeaderEvents) {
        if (event is! XmlStartElementEvent) {
          continue;
        }

        if (event.name != 'stream:stream') {
          continue;
        }

        _streamController.add(
          XMPPStreamHeader(
            Map<String, String>.fromEntries(
              event.attributes.map((attr) {
                return MapEntry(attr.name, attr.value);
              }),
            ),
          ),
        );
      }

      // Process the children of the <stream:stream> element.
      final childEvents = childSelector.convert(events);
      final children = _childBuffer.convert(childEvents);
      for (final node in children) {
        if (node.nodeType == XmlNodeType.ELEMENT) {
          _streamController.add(
            XMPPStreamElement(
              XMLNode.fromXmlElement(node as XmlElement),
            ),
          );
        }
      }
    });

    return _streamController.stream;
  }
}
