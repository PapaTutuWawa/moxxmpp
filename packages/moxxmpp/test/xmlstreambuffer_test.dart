import 'dart:async';
import 'package:moxxmpp/src/buffer.dart';
import 'package:test/test.dart';

void main() {
  test('Test non-broken up Xml data', () async {
    var childa = false;
    var childb = false;

    final buffer = XmlStreamBuffer();
    final controller = StreamController<String>();

    unawaited(
      controller.stream.transform(buffer).forEach((event) {
        if (event is! XmlStreamBufferElement) return;
        final node = event.node;

        if (node.tag == 'childa') {
          childa = true;
        } else if (node.tag == 'childb') {
          childb = true;
        }
      }),
    );
    controller.add('<childa /><childb />');

    await Future<void>.delayed(const Duration(seconds: 2));
    expect(childa, true);
    expect(childb, true);
  });
  test('Test broken up Xml data', () async {
    var childa = false;
    var childb = false;

    final buffer = XmlStreamBuffer();
    final controller = StreamController<String>();

    unawaited(
      controller.stream.transform(buffer).forEach((event) {
        if (event is! XmlStreamBufferElement) return;
        final node = event.node;

        if (node.tag == 'childa') {
          childa = true;
        } else if (node.tag == 'childb') {
          childb = true;
        }
      }),
    );
    controller
      ..add('<childa')
      ..add(' /><childb />');

    await Future<void>.delayed(const Duration(seconds: 2));
    expect(childa, true);
    expect(childb, true);
  });

  test('Test closing the stream', () async {
    var childa = false;
    var childb = false;

    final buffer = XmlStreamBuffer();
    final controller = StreamController<String>();

    unawaited(
      controller.stream.transform(buffer).forEach((event) {
        if (event is! XmlStreamBufferElement) return;
        final node = event.node;

        if (node.tag == 'childa') {
          childa = true;
        } else if (node.tag == 'childb') {
          childb = true;
        }
      }),
    );
    controller
      ..add('<childa')
      ..add(' /><childb />')
      ..add('</stream:stream>');

    await Future<void>.delayed(const Duration(seconds: 2));
    expect(childa, true);
    expect(childb, true);
  });

  test('Test opening the stream', () async {
    var childa = false;
    Map<String, String>? attrs;

    final buffer = XmlStreamBuffer();
    final controller = StreamController<String>();

    unawaited(
      controller.stream.transform(buffer).forEach((node) {
        if (node is XmlStreamBufferElement) {
          if (node.node.tag == 'childa') {
            childa = true;
          }
        } else if (node is XmlStreamBufferHeader) {
          attrs = node.attributes;
        }
      }),
    );
    controller
      ..add('<stream:stream id="abc123"><childa')
      ..add(' />');

    await Future<void>.delayed(const Duration(seconds: 2));
    expect(childa, true);
    expect(attrs!['id'], 'abc123');
  });
}
