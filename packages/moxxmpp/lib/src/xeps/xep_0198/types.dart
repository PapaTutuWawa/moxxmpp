import 'package:meta/meta.dart';
import 'package:moxxmpp/src/managers/data.dart';
import 'package:moxxmpp/src/stanza.dart';

class StreamManagementData implements StanzaHandlerExtension {
  const StreamManagementData(this.exclude, this.queueId);

  /// Whether the stanza should be exluded from the StreamManagement's resend queue.
  final bool exclude;

  /// The ID to use when queuing the stanza.
  final int? queueId;

  /// If we resend a stanza, then we will have [queueId] set, so we should skip
  /// incrementing the C2S counter.
  bool get shouldCountStanza => queueId == null;
}

/// A queue element for keeping track of stanzas to (potentially) resend.
@immutable
class SMQueueEntry {
  const SMQueueEntry(this.stanza, this.encrypted);

  /// The actual stanza.
  final Stanza stanza;

  /// Flag indicating whether the stanza was encrypted before sending.
  final bool encrypted;

  @override
  bool operator ==(Object other) {
    return other is SMQueueEntry &&
        other.stanza == stanza &&
        other.encrypted == encrypted;
  }

  @override
  int get hashCode => stanza.hashCode ^ encrypted.hashCode;
}
