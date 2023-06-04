import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxmpp/src/util/typed_map.dart';
import 'package:test/test.dart';

final stanza1 = Stanza.iq(
  children: [XMLNode.xmlns(tag: 'tag', xmlns: 'owo')],
  xmlns: stanzaXmlns,
);
final stanza2 = Stanza.message(
  children: [XMLNode.xmlns(tag: 'some-other-tag', xmlns: 'owo')],
  xmlns: stanzaXmlns,
);

void main() {
  test('match all', () {
    final handler = StanzaHandler(
      callback: (stanza, _) async => StanzaHandlerData(
        true,
        false,
        stanza,
        TypedMap(),
      ),
    );

    expect(handler.matches(Stanza.iq(xmlns: stanzaXmlns)), true);
    expect(handler.matches(Stanza.message(xmlns: stanzaXmlns)), true);
    expect(handler.matches(Stanza.presence(xmlns: stanzaXmlns)), true);
    expect(handler.matches(stanza1), true);
    expect(handler.matches(stanza2), true);
    expect(
      handler.matches(
        XMLNode.xmlns(tag: 'active', xmlns: csiXmlns),
      ),
      false,
    );
  });
  test('xmlns matching', () {
    final handler = StanzaHandler(
      callback: (stanza, _) async => StanzaHandlerData(
        true,
        false,
        stanza,
        TypedMap(),
      ),
      tagXmlns: 'owo',
    );

    expect(handler.matches(Stanza.iq(xmlns: stanzaXmlns)), false);
    expect(handler.matches(Stanza.message(xmlns: stanzaXmlns)), false);
    expect(handler.matches(Stanza.presence(xmlns: stanzaXmlns)), false);
    expect(handler.matches(stanza1), true);
    expect(handler.matches(stanza2), true);
  });

  test('stanzaTag matching', () {
    var run = false;
    final handler = StanzaHandler(
      callback: (stanza, _) async {
        run = true;
        return StanzaHandlerData(
          true,
          false,
          stanza,
          TypedMap(),
        );
      },
      stanzaTag: 'iq',
    );

    expect(handler.matches(Stanza.iq(xmlns: stanzaXmlns)), true);
    expect(handler.matches(Stanza.message(xmlns: stanzaXmlns)), false);
    expect(handler.matches(Stanza.presence(xmlns: stanzaXmlns)), false);
    expect(handler.matches(stanza1), true);
    expect(handler.matches(stanza2), false);

    handler.callback(
      stanza2,
      StanzaHandlerData(
        false,
        false,
        stanza2,
        TypedMap(),
      ),
    );
    expect(run, true);
  });

  test('tagName matching', () {
    final handler = StanzaHandler(
      callback: (stanza, _) async => StanzaHandlerData(
        true,
        false,
        stanza,
        TypedMap(),
      ),
      tagName: 'tag',
    );

    expect(handler.matches(Stanza.iq(xmlns: stanzaXmlns)), false);
    expect(handler.matches(Stanza.message(xmlns: stanzaXmlns)), false);
    expect(handler.matches(Stanza.presence(xmlns: stanzaXmlns)), false);
    expect(handler.matches(stanza1), true);
    expect(handler.matches(stanza2), false);
  });

  test('combined matching', () {
    final handler = StanzaHandler(
      callback: (stanza, _) async => StanzaHandlerData(
        true,
        false,
        stanza,
        TypedMap(),
      ),
      tagName: 'tag',
      stanzaTag: 'iq',
      tagXmlns: 'owo',
    );

    expect(handler.matches(Stanza.iq(xmlns: stanzaXmlns)), false);
    expect(handler.matches(Stanza.message(xmlns: stanzaXmlns)), false);
    expect(handler.matches(Stanza.presence(xmlns: stanzaXmlns)), false);
    expect(handler.matches(stanza1), true);
    expect(handler.matches(stanza2), false);
  });

  test('Test matching stanzas with a different xmlns', () {
    final handler = StanzaHandler(
      callback: (stanza, _) async => StanzaHandlerData(
        true,
        false,
        stanza,
        TypedMap(),
      ),
      xmlns: componentAcceptXmlns,
    );

    expect(handler.matches(Stanza.iq(xmlns: stanzaXmlns)), false);
    expect(handler.matches(Stanza.message(xmlns: stanzaXmlns)), false);
    expect(handler.matches(Stanza.presence(xmlns: stanzaXmlns)), false);
    expect(handler.matches(Stanza.iq(xmlns: componentAcceptXmlns)), true);
    expect(handler.matches(stanza1), false);
    expect(handler.matches(stanza2), false);
  });

  test('sorting', () {
    final handlerList = [
      StanzaHandler(
        callback: (stanza, _) async => StanzaHandlerData(
          true,
          false,
          stanza,
          TypedMap(),
        ),
        tagName: '1',
        priority: 100,
      ),
      StanzaHandler(
        callback: (stanza, _) async => StanzaHandlerData(
          true,
          false,
          stanza,
          TypedMap(),
        ),
        tagName: '2',
      ),
      StanzaHandler(
        callback: (stanza, _) async => StanzaHandlerData(
          true,
          false,
          stanza,
          TypedMap(),
        ),
        tagName: '3',
        priority: 50,
      )
    ]..sort(stanzaHandlerSortComparator);

    expect(handlerList[0].tagName, '1');
    expect(handlerList[1].tagName, '3');
    expect(handlerList[2].tagName, '2');
  });
}
