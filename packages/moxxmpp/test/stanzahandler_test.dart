import 'package:moxxmpp/moxxmpp.dart';
import 'package:test/test.dart';

final stanza1 = Stanza.iq(children: [
    XMLNode.xmlns(tag: 'tag', xmlns: 'owo')
],);
final stanza2 = Stanza.message(children: [
    XMLNode.xmlns(tag: 'some-other-tag', xmlns: 'owo')
],);

void main() {
  test('match all', () {
      final handler = StanzaHandler(callback: (stanza, _) async => StanzaHandlerData(true, false, null, stanza));

      expect(handler.matches(Stanza.iq()), true);
      expect(handler.matches(Stanza.message()), true);
      expect(handler.matches(Stanza.presence()), true);
      expect(handler.matches(stanza1), true);
      expect(handler.matches(stanza2), true);
  });
  test('xmlns matching', () {
      final handler = StanzaHandler(
        callback: (stanza, _) async => StanzaHandlerData(true, false, null, stanza),
        tagXmlns: 'owo',
      );

      expect(handler.matches(Stanza.iq()), false);
      expect(handler.matches(Stanza.message()), false);
      expect(handler.matches(Stanza.presence()), false);
      expect(handler.matches(stanza1), true);
      expect(handler.matches(stanza2), true);
  });
  test('stanzaTag matching', () {
      var run = false;
      final handler = StanzaHandler(callback: (stanza, _) async {
          run = true;
          return StanzaHandlerData(true, false, null, stanza);
      }, stanzaTag: 'iq',);

      expect(handler.matches(Stanza.iq()), true);
      expect(handler.matches(Stanza.message()), false);
      expect(handler.matches(Stanza.presence()), false);
      expect(handler.matches(stanza1), true);
      expect(handler.matches(stanza2), false);

      handler.callback(stanza2, StanzaHandlerData(false, false, null, stanza2));
      expect(run, true);
  });
  test('tagName matching', () {
      final handler = StanzaHandler(
        callback: (stanza, _) async => StanzaHandlerData(true, false, null, stanza),
        tagName: 'tag',
      );

      expect(handler.matches(Stanza.iq()), false);
      expect(handler.matches(Stanza.message()), false);
      expect(handler.matches(Stanza.presence()), false);
      expect(handler.matches(stanza1), true);
      expect(handler.matches(stanza2), false);
  });
  test('combined matching', () {
      final handler = StanzaHandler(
        callback: (stanza, _) async => StanzaHandlerData(true, false, null, stanza),
        tagName: 'tag',
        stanzaTag: 'iq',
        tagXmlns: 'owo',
      );

      expect(handler.matches(Stanza.iq()), false);
      expect(handler.matches(Stanza.message()), false);
      expect(handler.matches(Stanza.presence()), false);
      expect(handler.matches(stanza1), true);
      expect(handler.matches(stanza2), false);
  });

  test('sorting', () {
      final handlerList = [
        StanzaHandler(callback: (stanza, _) async => StanzaHandlerData(true, false, null, stanza), tagName: '1', priority: 100),
        StanzaHandler(callback: (stanza, _) async => StanzaHandlerData(true, false, null, stanza), tagName: '2'),
        StanzaHandler(callback: (stanza, _) async => StanzaHandlerData(true, false, null, stanza), tagName: '3', priority: 50)
      ];

      handlerList.sort(stanzaHandlerSortComparator);

      expect(handlerList[0].tagName, '1');
      expect(handlerList[1].tagName, '3');
      expect(handlerList[2].tagName, '2');
  });
}
