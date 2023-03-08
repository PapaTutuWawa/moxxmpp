import 'dart:async';
import 'dart:collection';
import 'package:meta/meta.dart';
import 'package:synchronized/synchronized.dart';

/// A job to be submitted to an [AsyncQueue].
typedef AsyncQueueJob = Future<void> Function();

/// A (hopefully) async-safe queue that attempts to force
/// in-order execution of its jobs.
class AsyncQueue {
  /// The lock for accessing [AsyncQueue._lock] and [AsyncQueue._running].
  final Lock _lock = Lock();

  /// The actual job queue.
  final Queue<AsyncQueueJob> _queue = Queue<AsyncQueueJob>();

  /// Indicates whether we are currently executing a job.
  bool _running = false;

  @visibleForTesting
  Queue<AsyncQueueJob> get queue => _queue;

  @visibleForTesting
  bool get isRunning => _running;

  /// Adds a job [job] to the queue.
  Future<void> addJob(AsyncQueueJob job) async {
    await _lock.synchronized(() {
      _queue.add(job);

      if (!_running && _queue.isNotEmpty) {
        _running = true;
        unawaited(_popJob());
      }
    });
  }

  Future<void> clear() async {
    await _lock.synchronized(_queue.clear);
  }

  Future<void> _popJob() async {
    final job = _queue.removeFirst();
    final future = job();
    await future;

    await _lock.synchronized(() {
      if (_queue.isNotEmpty) {
        unawaited(_popJob());
      } else {
        _running = false;
      }
    });
  }
}
