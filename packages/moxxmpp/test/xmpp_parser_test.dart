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
      controller.stream.transform(parser).forEach((events) {
        for (final event in events) {
          if (event is! XMPPStreamElement) continue;
          final node = event.node;

          if (node.tag == 'childa') {
            childa = true;
          } else if (node.tag == 'childb') {
            childb = true;
          }
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
      controller.stream.transform(parser).forEach((events) {
        for (final event in events) {
          if (event is! XMPPStreamElement) continue;
          final node = event.node;

          if (node.tag == 'childa') {
            childa = true;
          } else if (node.tag == 'childb') {
            childb = true;
          }
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
      controller.stream.transform(parser).forEach((events) {
        for (final event in events) {
          if (event is! XMPPStreamElement) continue;
          final node = event.node;

          if (node.tag == 'childa') {
            childa = true;
          } else if (node.tag == 'childb') {
            childb = true;
          }
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
      controller.stream.transform(parser).forEach((events) {
        for (final event in events) {
          if (event is XMPPStreamElement) {
            if (event.node.tag == 'childa') {
              childa = true;
            }
          } else if (event is XMPPStreamHeader) {
            attrs = event.attributes;
          }
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
        (events) {
          for (final event in events) {
            if (event is! XMPPStreamElement) continue;

            if (event.node.tag == 'stream:features') {
              gotFeatures = true;
            }
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

  test('Test the order of concatenated stanzas', () async {
    // NOTE: This seems weird, but it turns out that not keeping this order leads to
    //       MUC joins (on Moxxy) not catching every bit of presence before marking the
    //       MUC as joined.
    final parser = XMPPStreamParser();
    final controller = StreamController<String>();
    var called = false;

    unawaited(
      controller.stream.transform(parser).forEach((events) {
        expect(events.isNotEmpty, true);
        expect((events[0] as XMPPStreamElement).node.tag, 'childa');
        expect((events[1] as XMPPStreamElement).node.tag, 'childb');
        expect((events[2] as XMPPStreamElement).node.tag, 'childc');
        called = true;
      }),
    );
    controller.add('<childa /><childb /><childc />');

    await Future<void>.delayed(const Duration(seconds: 2));
    expect(called, true);
  });
}
