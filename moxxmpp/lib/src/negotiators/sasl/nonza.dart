import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/stringxml.dart';

class SaslAuthNonza extends XMLNode {
  SaslAuthNonza(String mechanism, String body) : super(
    tag: 'auth',
    attributes: <String, String>{
      'xmlns': saslXmlns,
      'mechanism': mechanism ,
    },
    text: body,
  );
}
