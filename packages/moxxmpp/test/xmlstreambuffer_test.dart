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
      controller.stream.transform(buffer).forEach((node) {
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
      controller.stream.transform(buffer).forEach((node) {
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
      controller.stream.transform(buffer).forEach((node) {
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
}
