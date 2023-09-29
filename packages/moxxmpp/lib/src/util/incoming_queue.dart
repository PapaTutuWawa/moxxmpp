import 'dart:async';
import 'dart:collection';
import 'package:logging/logging.dart';
import 'package:moxxmpp/src/parser.dart';
import 'package:synchronized/synchronized.dart';

typedef LockResult = (Completer<void>?, XMPPStreamObject);

class IncomingStanzaQueue {
  IncomingStanzaQueue(this._callback);

  final Queue<Completer<void>> _queue = Queue();

  final Future<void> Function(XMPPStreamObject) _callback;
  bool _isRunning = false;

  final Lock _lock = Lock();

  final Logger _log = Logger('IncomingStanzaQueue');

  bool negotiationsDone = false;

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
    if (object is XMPPStreamElement) {
      _log.finest('Running callback for ${object.node.toXml()}');
    }
    await _callback(object);
    if (object is XMPPStreamElement) {
      _log.finest(
        'Callback for ${object.node.tag} (${object.node.attributes["id"]}) done',
      );
    }

    // Run the next entry.
    _log.finest('Entering second lock...');
    await _lock.synchronized(() {
      _log.finest('Second lock entered...');
      if (_queue.isNotEmpty) {
        _log.finest('New queue size: ${_queue.length - 1}');
        _queue.removeFirst().complete();
      } else {
        _isRunning = false;
        _log.finest('New queue size: 0');
      }
    });
  }

  Future<void> addStanza(List<XMPPStreamObject> objects) async {
    _log.finest('Entering initial lock...');
    await _lock.synchronized(() {
      _log.finest('Lock entered...');

      for (final object in objects) {
        if (canBypassQueue(object)) {
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

  bool canBypassQueue(XMPPStreamObject object) {
    // TODO: Ask the StanzaAwaiter if the stanza is awaited
    return object is XMPPStreamElement &&
        negotiationsDone &&
        object.node.tag == 'iq' &&
        ['result', 'error'].contains(object.node.attributes['type'] as String?);
  }
}
