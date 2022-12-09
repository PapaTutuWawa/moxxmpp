import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/stringxml.dart';

enum MessageProcessingHint {
  noPermanentStore,
  noStore,
  noCopies,
  store,
}

MessageProcessingHint messageProcessingHintFromXml(XMLNode element) {
  switch (element.tag) {
    case 'no-permanent-store': return MessageProcessingHint.noPermanentStore;
    case 'no-store': return MessageProcessingHint.noStore;
    case 'no-copy': return MessageProcessingHint.noCopies;
    case 'store': return MessageProcessingHint.store;
  }
    
  assert(false, 'Invalid Message Processing Hint: ${element.tag}');
  return MessageProcessingHint.noStore;
}

extension XmlExtension on MessageProcessingHint {
  XMLNode toXml() {
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
