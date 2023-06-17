import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxmpp/src/util/queue.dart';
import 'package:test/test.dart';

void main() {
  test('Test not sending', () async {
    final queue = AsyncStanzaQueue(
      (entry) async {
        assert(false, 'No stanza should be sent');
      },
      () async => false,
    );

    await queue.enqueueStanza(
      StanzaQueueEntry(
        StanzaDetails(
          Stanza.message(),
        ),
        null,
      ),
    );
    await queue.enqueueStanza(
      StanzaQueueEntry(
        StanzaDetails(
          Stanza.message(),
        ),
        null,
      ),
    );

    await Future<void>.delayed(const Duration(seconds: 1));
    expect(queue.queue.length, 2);
  });

  test('Test sending', () async {
    final queue = AsyncStanzaQueue(
      (entry) async {},
      () async => true,
    );

    await queue.enqueueStanza(
      StanzaQueueEntry(
        StanzaDetails(
          Stanza.message(),
        ),
        null,
      ),
    );
    await queue.enqueueStanza(
      StanzaQueueEntry(
        StanzaDetails(
          Stanza.message(),
        ),
        null,
      ),
    );

    await Future<void>.delayed(const Duration(seconds: 1));
    expect(queue.queue.length, 0);
  });

  test('Test partial sending and resuming', () async {
    var canRun = true;
    final queue = AsyncStanzaQueue(
      (entry) async {
        canRun = false;
      },
      () async => canRun,
    );

    await queue.enqueueStanza(
      StanzaQueueEntry(
        StanzaDetails(
          Stanza.message(),
        ),
        null,
      ),
    );
    await queue.enqueueStanza(
      StanzaQueueEntry(
        StanzaDetails(
          Stanza.message(),
        ),
        null,
      ),
    );

    await Future<void>.delayed(const Duration(seconds: 1));
    expect(queue.queue.length, 1);

    canRun = true;
    await queue.restart();
    await Future<void>.delayed(const Duration(seconds: 1));
    expect(queue.queue.length, 0);
  });
}
