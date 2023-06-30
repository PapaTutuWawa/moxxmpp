import 'package:collection/collection.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/negotiators/negotiator.dart';
import 'package:moxxmpp/src/stringxml.dart';

abstract class SaslNegotiator extends XmppFeatureNegotiatorBase {
  SaslNegotiator(int priority, String id, this.mechanismName)
      : super(priority, true, saslXmlns, id);

  /// The name inside the <mechanism /> element
  final String mechanismName;

  @override
  bool matchesFeature(List<XMLNode> features) {
    // Is SASL advertised?
    final mechanisms = features.firstWhereOrNull(
      (XMLNode feature) => feature.attributes['xmlns'] == saslXmlns,
    );
    if (mechanisms == null) return false;

    // Is SASL PLAIN advertised?
    return mechanisms.children.firstWhereOrNull(
          (XMLNode mechanism) => mechanism.text == mechanismName,
        ) !=
        null;
  }
}
