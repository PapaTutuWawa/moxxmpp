import 'package:moxxmpp/moxxmpp.dart';
import 'package:test/test.dart';

void main() {
  test('Test building a singleline quote', () {
    final quote = QuoteData.fromBodies('Hallo Welt', 'Hello Earth!');

    expect(quote.body, '> Hallo Welt\nHello Earth!');
    expect(quote.fallbackLength, 13);
  });

  test('Test building a multiline quote', () {
    final quote = QuoteData.fromBodies('Hallo Welt\nHallo Erde', 'How are you?');

    expect(quote.body, '> Hallo Welt\n> Hallo Erde\nHow are you?');
    expect(quote.fallbackLength, 26);
  });

  test('Applying a singleline quote', () {
    final body = '> Hallo Welt\nHello right back!';
    final reply = ReplyData(
      to: '',
      id: '',
      start: 0,
      end: 13,
    );

    final bodyWithoutFallback = reply.removeFallback(body);
    expect(bodyWithoutFallback, 'Hello right back!');
  });

  test('Applying a multiline quote', () {
    final body = "> Hallo Welt\n> How are you?\nI'm fine.\nThank you!";
    final reply = ReplyData(
      to: '',
      id: '',
      start: 0,
      end: 28,
    );

    final bodyWithoutFallback = reply.removeFallback(body);
    expect(bodyWithoutFallback, "I'm fine.\nThank you!");
  });
}
