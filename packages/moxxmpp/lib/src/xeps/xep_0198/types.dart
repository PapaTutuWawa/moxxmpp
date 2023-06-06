import 'package:moxxmpp/src/managers/data.dart';

class StreamManagementData implements StanzaHandlerExtension {
  const StreamManagementData(this.exclude);

  /// Whether the stanza should be exluded from the StreamManagement's resend queue.
  final bool exclude;
}
