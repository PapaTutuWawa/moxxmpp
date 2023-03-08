import 'dart:async';
import 'package:meta/meta.dart';
import 'package:synchronized/synchronized.dart';

/// This class allows for multiple asynchronous code places to wait on the
/// same computation of type [V], indentified by a key of type [K].
class WaitForTracker<K, V> {
  /// The mapping of key -> Completer for the pending tasks.
  final Map<K, List<Completer<V>>> _tracker = {};

  /// The lock for accessing _tracker.
  final Lock _lock = Lock();

  /// Wait for a task with key [key]. If there was no such task already
  /// present, returns null. If one or more tasks were already present, returns
  /// a future that will resolve to the result of the first task.
  Future<Future<V>?> waitFor(K key) async {
    final result = await _lock.synchronized(() {
      if (_tracker.containsKey(key)) {
        // The task already exists. Just append outselves
        final completer = Completer<V>();
        _tracker[key]!.add(completer);
        return completer;
      }

      // The task does not exist yet
      _tracker[key] = List<Completer<V>>.empty(growable: true);
      return null;
    });

    return result?.future;
  }

  /// Resolve a task with key [key] to [value].
  Future<void> resolve(K key, V value) async {
    await _lock.synchronized(() {
      if (!_tracker.containsKey(key)) return;

      for (final completer in _tracker[key]!) {
        completer.complete(value);
      }

      _tracker.remove(key);
    });
  }

  Future<void> resolveAll(V value) async {
    await _lock.synchronized(() {
      for (final key in _tracker.keys) {
        for (final completer in _tracker[key]!) {
          completer.complete(value);
        }
      }
    });
  }

  /// Remove all tasks from the tracker.
  Future<void> clear() async {
    await _lock.synchronized(_tracker.clear);
  }

  @visibleForTesting
  bool hasTasksRunning() => _tracker.isNotEmpty;

  @visibleForTesting
  List<Completer<V>> getRunningTasks(K key) => _tracker[key]!;
}
