import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/stringxml.dart';

enum MessageProcessingHint {
  noPermanentStore,
  noStore,
  noCopies,
  store;

  factory MessageProcessingHint.fromName(String name) {
    switch (name) {
      case 'no-permanent-store':
        return MessageProcessingHint.noPermanentStore;
      case 'no-store':
        return MessageProcessingHint.noStore;
      case 'no-copy':
        return MessageProcessingHint.noCopies;
      case 'store':
        return MessageProcessingHint.store;
    }

    assert(false, 'Invalid Message Processing Hint: $name');
    return MessageProcessingHint.noStore;
  }

  XMLNode toXML() {
    String tag;
    switch (this) {
      case MessageProcessingHint.noPermanentStore:
        tag = 'no-permanent-store';
        break;
      case MessageProcessingHint.noStore:
        tag = 'no-store';
        break;
      case MessageProcessingHint.noCopies:
        tag = 'no-copy';
        break;
      case MessageProcessingHint.store:
        tag = 'store';
        break;
    }

    return XMLNode.xmlns(
      tag: tag,
      xmlns: messageProcessingHintsXmlns,
    );
  }
}
