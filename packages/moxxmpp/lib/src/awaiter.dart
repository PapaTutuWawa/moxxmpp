import 'dart:async';
import 'package:meta/meta.dart';
import 'package:moxxmpp/src/jid.dart';
import 'package:moxxmpp/src/stringxml.dart';
import 'package:synchronized/synchronized.dart';

/// A surrogate key for awaiting stanzas.
@immutable
class _StanzaSurrogateKey {
  const _StanzaSurrogateKey(this.sentTo, this.id, this.tag);

  /// The JID the original stanza was sent to. We expect the result to come from the
  /// same JID.
  final String sentTo;

  /// The ID of the original stanza. We expect the result to have the same ID.
  final String id;

  /// The tag name of the stanza.
  final String tag;
  
  @override
  int get hashCode => sentTo.hashCode ^ id.hashCode ^ tag.hashCode;

  @override
  bool operator==(Object other) {
    return other is _StanzaSurrogateKey &&
           other.sentTo == sentTo &&
           other.id == id &&
           other.tag == tag;
  }
}

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
  final Map<_StanzaSurrogateKey, Completer<XMLNode>> _pending = {};

  /// The critical section for accessing [StanzaAwaiter._pending].
  final Lock _lock = Lock();

  /// Register a stanza as pending.
  /// [to] is the value of the stanza's "to" attribute.
  /// [id] is the value of the stanza's "id" attribute.
  /// [tag] is the stanza's tag name.
  ///
  /// Returns a future that might resolve to the response to the stanza.
  Future<Future<XMLNode>> addPending(String to, String id, String tag) async {
    final completer = await _lock.synchronized(() {
      final completer = Completer<XMLNode>();
      _pending[_StanzaSurrogateKey(to, id, tag)] = completer;
      return completer;
    });

    return completer.future;
  }

  /// Checks if the stanza [stanza] is being awaited. [bareJid] is the bare JID of
  /// the connection.
  /// If [stanza] is awaited, resolves the future and returns true. If not, returns
  /// false.
  Future<bool> onData(XMLNode stanza, JID bareJid) async {
    assert(bareJid.isBare(), 'bareJid must be bare');

    final id = stanza.attributes['id'] as String?;
    if (id == null) return false;
    
    final key = _StanzaSurrogateKey(
      // Section 8.1.2.1 § 3 of RFC 6120 says that an empty "from" indicates that the
      // attribute is implicitly from our own bare JID.
      stanza.attributes['from'] as String? ?? bareJid.toString(),
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
}
