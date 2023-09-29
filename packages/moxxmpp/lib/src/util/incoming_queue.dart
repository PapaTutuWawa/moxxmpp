import 'dart:async';
import 'dart:collection';
import 'package:logging/logging.dart';
import 'package:moxxmpp/src/awaiter.dart';
import 'package:moxxmpp/src/parser.dart';
import 'package:synchronized/synchronized.dart';

/// A queue for incoming [XMPPStreamObject]s to ensure "in order"
/// processing (except for stanzas that are awaited).
class IncomingStanzaQueue {
  IncomingStanzaQueue(this._callback, this._stanzaAwaiter);

  /// The queue for storing the completer of each
  /// incoming stanza (or stream object to be precise).
  /// Only access while holding the lock [_lock].
  final Queue<Completer<void>> _queue = Queue();

  /// Flag indicating whether a callback is already running (true)
  /// or not. "a callback" and not "the callback" because awaited stanzas
  /// are allowed to bypass the queue.
  /// Only access while holding the lock [_lock].
  bool _isRunning = false;

  /// The function to call to process an incoming stream object.
  final Future<void> Function(XMPPStreamObject) _callback;

  /// Lock guarding both [_queue] and [_isRunning].
  final Lock _lock = Lock();

  /// Logger.
  final Logger _log = Logger('IncomingStanzaQueue');

  final StanzaAwaiter _stanzaAwaiter;

  Future<void> _processStreamObject(
    Future<void>? future,
    XMPPStreamObject object,
  ) async {
    if (future == null) {
      if (object is XMPPStreamElement) {
        _log.finest(
          'Bypassing queue for ${object.node.tag} (${object.node.attributes["id"]})',
        );
      }
      return _callback(object);
    }

    // Wait for our turn.
    await future;

    // Run the callback.
    await _callback(object);

    // Run the next entry.
    await _lock.synchronized(() {
      if (_queue.isNotEmpty) {
        _queue.removeFirst().complete();
      } else {
        _isRunning = false;
      }
    });
  }

  Future<void> addStanza(List<XMPPStreamObject> objects) async {
    await _lock.synchronized(() async {
      for (final object in objects) {
        if (await canBypassQueue(object)) {
          unawaited(
            _processStreamObject(null, object),
          );
          continue;
        }

        final completer = Completer<void>();
        if (_isRunning) {
          _queue.add(completer);
        } else {
          _isRunning = true;
          completer.complete();
        }

        unawaited(
          _processStreamObject(completer.future, object),
        );
      }
    });
  }

  Future<bool> canBypassQueue(XMPPStreamObject object) async {
    if (object is XMPPStreamHeader) {
      return false;
    }

    object as XMPPStreamElement;
    // TODO: Check the from attribute to ensure that it is matched correctly.
    return _stanzaAwaiter.isAwaited(object.node);
  }
}
