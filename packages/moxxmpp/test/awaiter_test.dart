import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxmpp/src/awaiter.dart';
import 'package:test/test.dart';

void main() {
  test('Test awaiting an awaited stanza with a from attribute', () async {
    final awaiter = StanzaAwaiter();

    // "Send" a stanza
    final future = await awaiter.addPending(
      'user1@server.example',
      'abc123',
      'iq',
    );

    // Receive the wrong answer
    final result1 = await awaiter.onData(
      XMLNode.fromString(
        '<iq from="user3@server.example" id="abc123" type="result" />',
      ),
    );
    expect(result1, false);
    final result2 = await awaiter.onData(
      XMLNode.fromString(
        '<iq from="user1@server.example" id="lol" type="result" />',
      ),
    );
    expect(result2, false);

    // Receive the correct answer
    final stanza = XMLNode.fromString(
      '<iq from="user1@server.example" id="abc123" type="result" />',
    );
    final result3 = await awaiter.onData(
      stanza,
    );
    expect(result3, true);
    expect(await future, stanza);
  });

  test('Test awaiting an awaited stanza without a from attribute', () async {
    final awaiter = StanzaAwaiter();

    // "Send" a stanza
    final future = await awaiter.addPending(null, 'abc123', 'iq');

    // Receive the wrong answer
    final result1 = await awaiter.onData(
      XMLNode.fromString('<iq id="lol" type="result" />'),
    );
    expect(result1, false);

    // Receive the correct answer
    final stanza = XMLNode.fromString('<iq id="abc123" type="result" />');
    final result2 = await awaiter.onData(
      stanza,
    );
    expect(result2, true);
    expect(await future, stanza);
  });

  test('Test awaiting a stanza that was already awaited', () async {
    final awaiter = StanzaAwaiter();

    // "Send" a stanza
    final future = await awaiter.addPending(null, 'abc123', 'iq');

    // Receive the correct answer
    final stanza = XMLNode.fromString('<iq id="abc123" type="result" />');
    final result1 = await awaiter.onData(
      stanza,
    );
    expect(result1, true);
    expect(await future, stanza);

    // Receive it again
    final result2 = await awaiter.onData(
      stanza,
    );
    expect(result2, false);
  });

  test('Test ignoring a stanza that has the wrong tag', () async {
    final awaiter = StanzaAwaiter();

    // "Send" a stanza
    final future = await awaiter.addPending(null, 'abc123', 'iq');

    // Receive the wrong answer
    final stanza = XMLNode.fromString('<iq id="abc123" type="result" />');
    final result1 = await awaiter.onData(
      XMLNode.fromString('<message id="abc123" type="result" />'),
    );
    expect(result1, false);

    // Receive the correct answer
    final result2 = await awaiter.onData(
      stanza,
    );
    expect(result2, true);
    expect(await future, stanza);
  });
}
