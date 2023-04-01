import 'package:collection/collection.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/negotiators/namespaces.dart';
import 'package:moxxmpp/src/negotiators/negotiator.dart';
import 'package:moxxmpp/src/negotiators/sasl2.dart';
import 'package:moxxmpp/src/stringxml.dart';
import 'package:moxxmpp/src/types/result.dart';

/// A negotiator implementing XEP-0386. This negotiator is useless on its own
/// and requires a [Sasl2Negotiator] to be registered.
class Bind2Negotiator extends Sasl2FeatureNegotiator {
  Bind2Negotiator() : super(0, false, bind2Xmlns, bind2Negotiator);

  /// A tag to sent to the server when requesting Bind2.
  String? tag;

  @override
  Future<Result<NegotiatorState, NegotiatorError>> negotiate(
    XMLNode nonza,
  ) async {
    return const Result(NegotiatorState.done);
  }

  @override
  Future<List<XMLNode>> onSasl2FeaturesReceived(XMLNode sasl2Features) async {
    return [
      XMLNode.xmlns(
        tag: 'bind',
        xmlns: bind2Xmlns,
        children: [
          if (tag != null)
            XMLNode(
              tag: 'tag',
              text: tag,
            ),
        ],
      ),
    ];
  }

  @override
  bool canInlineFeature(List<XMLNode> features) {
    return features.firstWhereOrNull(
          (child) => child.tag == 'bind' && child.xmlns == bind2Xmlns,
        ) !=
        null;
  }

  @override
  Future<Result<bool, NegotiatorError>> onSasl2Success(XMLNode response) async {
    attributes.removeNegotiatingFeature(bindXmlns);

    return const Result(true);
  }

  @override
  Future<void> postRegisterCallback() async {
    attributes
        .getNegotiatorById<Sasl2Negotiator>(sasl2Negotiator)!
        .registerNegotiator(this);
  }
}
