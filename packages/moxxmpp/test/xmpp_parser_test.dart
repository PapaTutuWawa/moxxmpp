import 'dart:async';
import 'package:moxxmpp/src/parser.dart';
import 'package:test/test.dart';

void main() {
  test('Test non-broken up Xml data', () async {
    var childa = false;
    var childb = false;

    final parser = XMPPStreamParser();
    final controller = StreamController<String>();

    unawaited(
      controller.stream.transform(parser).forEach((event) {
        if (event is! XMPPStreamElement) return;
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

    final parser = XMPPStreamParser();
    final controller = StreamController<String>();

    unawaited(
      controller.stream.transform(parser).forEach((event) {
        if (event is! XMPPStreamElement) return;
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

    final parser = XMPPStreamParser();
    final controller = StreamController<String>();

    unawaited(
      controller.stream.transform(parser).forEach((event) {
        if (event is! XMPPStreamElement) return;
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

    final parser = XMPPStreamParser();
    final controller = StreamController<String>();

    unawaited(
      controller.stream.transform(parser).forEach((node) {
        if (node is XMPPStreamElement) {
          if (node.node.tag == 'childa') {
            childa = true;
          }
        } else if (node is XMPPStreamHeader) {
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

  test('Test restarting a broken XML stream', () async {
    final parser = XMPPStreamParser();
    final controller = StreamController<String>();
    var gotFeatures = false;
    unawaited(
      controller.stream.transform(parser).forEach(
        (event) {
          if (event is! XMPPStreamElement) return;

          if (event.node.tag == 'stream:features') {
            gotFeatures = true;
          }
        },
      ),
    );

    // Begin the stream with invalid XML
    controller.add('<stream:stream xmlns="jabber:client');

    // Let it marinate
    await Future<void>.delayed(const Duration(seconds: 1));
    expect(gotFeatures, false);

    // Start a new stream
    parser.reset();
    controller.add(
      '''
<stream:stream
    xmlns="jabber:client"
    version="1.0"
    xmlns:stream="http://etherx.jabber.org/streams"
    from="test.server"
    xml:lang="en">
  <stream:features xmlns="http://etherx.jabber.org/streams">
    <mechanisms xmlns="urn:ietf:params:xml:ns:xmpp-sasl">
      <mechanism>PLAIN</mechanism>
    </mechanisms>
  </stream:features>
      ''',
    );

    // Let it marinate
    await Future<void>.delayed(const Duration(seconds: 1));
    expect(gotFeatures, true);
  });
}
