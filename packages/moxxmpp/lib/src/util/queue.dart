import 'dart:async';
import 'dart:collection';
import 'package:meta/meta.dart';
import 'package:moxxmpp/src/connection.dart';
import 'package:moxxmpp/src/stanza.dart';
import 'package:moxxmpp/src/stringxml.dart';
import 'package:synchronized/synchronized.dart';

class StanzaDetails {
  const StanzaDetails(
    this.stanza, {
    this.addFrom = StanzaFromType.full,
    this.addId = true,
    this.awaitable = true,
    this.encrypted = false,
    this.forceEncryption = false,
  });

  /// The stanza to send.
  final Stanza stanza;

  /// How to set the "from" attribute of the stanza.
  final StanzaFromType addFrom;

  /// Flag indicating whether a stanza id should be added before sending.
  final bool addId;

  /// Track the stanza to allow awaiting its response.
  final bool awaitable;

  final bool encrypted;

  final bool forceEncryption;
}

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

  /// The lock for accessing [AsyncStanzaQueue._lock] and [AsyncStanzaQueue._running].
  final Lock _lock = Lock();

  /// The actual job queue.
  final Queue<StanzaQueueEntry> _queue = Queue<StanzaQueueEntry>();

  /// Sends the stanza when we can pop from the queue.
  final SendStanzaFunction _sendStanzaFunction;

  final CanSendCallback _canSendCallback;

  /// Indicates whether we are currently executing a job.
  bool _running = false;

  @visibleForTesting
  Queue<StanzaQueueEntry> get queue => _queue;

  @visibleForTesting
  bool get isRunning => _running;

  /// Adds a job [entry] to the queue.
  Future<void> enqueueStanza(StanzaQueueEntry entry) async {
    await _lock.synchronized(() async {
      _queue.add(entry);

      if (!_running && _queue.isNotEmpty && await _canSendCallback()) {
        _running = true;
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
      } else {
        _running = false;
      }
    });
  }

  Future<void> restart() async {
    if (!(await _canSendCallback())) return;

    await _lock.synchronized(() {
      if (_queue.isNotEmpty) {
        _running = true;
        unawaited(
          _runJob(_queue.removeFirst()),
        );
      }
    });
  }
}
