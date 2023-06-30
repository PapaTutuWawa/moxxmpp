import 'dart:async';
import 'dart:collection';
import 'package:meta/meta.dart';
import 'package:moxxmpp/src/stanza.dart';
import 'package:moxxmpp/src/stringxml.dart';
import 'package:synchronized/synchronized.dart';

class StanzaQueueEntry {
  const StanzaQueueEntry(
    this.details,
    this.completer,
  );

  /// The actual data to send.
  final StanzaDetails details;

  /// The [Completer] to resolve when the response is received.
  final Completer<XMLNode>? completer;
}

/// A function that is executed when a job is popped from the queue.
typedef SendStanzaFunction = Future<void> Function(StanzaQueueEntry);

/// A function that is called before popping a queue item. Should return true when
/// the [SendStanzaFunction] can be executed.
typedef CanSendCallback = Future<bool> Function();

/// A (hopefully) async-safe queue that attempts to force
/// in-order execution of its jobs.
class AsyncStanzaQueue {
  AsyncStanzaQueue(
    this._sendStanzaFunction,
    this._canSendCallback,
  );

  /// The lock for accessing [AsyncStanzaQueue._queue].
  final Lock _lock = Lock();

  /// The actual job queue.
  final Queue<StanzaQueueEntry> _queue = Queue<StanzaQueueEntry>();

  /// Sends the stanza when we can pop from the queue.
  final SendStanzaFunction _sendStanzaFunction;

  final CanSendCallback _canSendCallback;

  @visibleForTesting
  Queue<StanzaQueueEntry> get queue => _queue;

  /// Adds a job [entry] to the queue.
  Future<void> enqueueStanza(StanzaQueueEntry entry) async {
    await _lock.synchronized(() async {
      _queue.add(entry);

      if (_queue.isNotEmpty && await _canSendCallback()) {
        unawaited(
          _runJob(_queue.removeFirst()),
        );
      }
    });
  }

  Future<void> clear() async {
    await _lock.synchronized(_queue.clear);
  }

  Future<void> _runJob(StanzaQueueEntry details) async {
    await _sendStanzaFunction(details);

    await _lock.synchronized(() async {
      if (_queue.isNotEmpty && await _canSendCallback()) {
        unawaited(
          _runJob(_queue.removeFirst()),
        );
      }
    });
  }

  Future<void> restart() async {
    if (!(await _canSendCallback())) return;

    await _lock.synchronized(() {
      if (_queue.isNotEmpty) {
        unawaited(
          _runJob(_queue.removeFirst()),
        );
      }
    });
  }
}
