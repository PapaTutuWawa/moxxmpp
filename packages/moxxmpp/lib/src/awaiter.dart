import 'dart:async';
import 'package:moxxmpp/src/stringxml.dart';
import 'package:synchronized/synchronized.dart';

/// (JID we sent a stanza to, the id of the sent stanza, the tag of the sent stanza).
typedef _StanzaCompositeKey = (String?, String, String);

/// This class handles the await semantics for stanzas. Stanzas are given a "unique"
/// key equal to the tuple (to, id, tag) with which their response is identified.
///
/// That means that when sending ```<iq to="example@some.server.example" id="abc123" />```,
/// the response stanza must be from "example@some.server.example", have id "abc123" and
/// be an iq stanza.
///
/// This class also handles some "edge cases" of RFC 6120, like an empty "from" attribute.
class StanzaAwaiter {
  /// The pending stanzas, identified by their surrogate key.
  final Map<_StanzaCompositeKey, Completer<XMLNode>> _pending = {};

  /// The critical section for accessing [StanzaAwaiter._pending].
  final Lock _lock = Lock();

  /// Register a stanza as pending.
  /// [to] is the value of the stanza's "to" attribute.
  /// [id] is the value of the stanza's "id" attribute.
  /// [tag] is the stanza's tag name.
  ///
  /// Returns a future that might resolve to the response to the stanza.
  Future<Future<XMLNode>> addPending(String? to, String id, String tag) async {
    final completer = await _lock.synchronized(() {
      final completer = Completer<XMLNode>();
      _pending[(to, id, tag)] = completer;
      return completer;
    });

    return completer.future;
  }

  /// Checks if the stanza [stanza] is being awaited.
  /// If [stanza] is awaited, resolves the future and returns true. If not, returns
  /// false.
  Future<bool> onData(XMLNode stanza) async {
    final id = stanza.attributes['id'] as String?;
    if (id == null) return false;

    final key = (
      stanza.attributes['from'] as String?,
      id,
      stanza.tag,
    );

    return _lock.synchronized(() {
      final completer = _pending[key];
      if (completer != null) {
        _pending.remove(key);
        completer.complete(stanza);
        return true;
      }

      return false;
    });
  }

  /// Checks if [stanza] represents a stanza that is awaited. Returns true, if [stanza]
  /// is awaited. False, if not.
  Future<bool> isAwaited(XMLNode stanza) async {
    final id = stanza.attributes['id'] as String?;
    if (id == null) return false;

    final key = (
      stanza.attributes['from'] as String?,
      id,
      stanza.tag,
    );

    return _lock.synchronized(() => _pending.containsKey(key));
  }
}
