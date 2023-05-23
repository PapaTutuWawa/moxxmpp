import 'package:meta/meta.dart';

@internal
@immutable
class DiscoCacheKey {
  const DiscoCacheKey(this.jid, this.node);

  /// The JID we're requesting disco data from.
  // TODO(Unknown): Replace with JID
  final String jid;

  /// Optionally the node we are requesting from.
  final String? node;

  @override
  bool operator ==(Object other) {
    return other is DiscoCacheKey && jid == other.jid && node == other.node;
  }

  @override
  int get hashCode => jid.hashCode ^ node.hashCode;
}
