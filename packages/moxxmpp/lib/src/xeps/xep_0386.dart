import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/negotiators/namespaces.dart';
import 'package:moxxmpp/src/negotiators/negotiator.dart';
import 'package:moxxmpp/src/stringxml.dart';
import 'package:moxxmpp/src/types/result.dart';
import 'package:moxxmpp/src/xeps/xep_0388/negotiators.dart';
import 'package:moxxmpp/src/xeps/xep_0388/xep_0388.dart';

/// An interface that allows registering against Bind2's feature list in order to
/// negotiate features inline with Bind2.
// ignore: one_member_abstracts
abstract class Bind2FeatureNegotiatorInterface {
  /// Called by the Bind2 negotiator when Bind2 features are received. The returned
  /// [XMLNode]s are added to Bind2's bind request.
  Future<List<XMLNode>> onBind2FeaturesReceived(List<String> bind2Features);

  /// Called by the Bind2 negotiator when Bind2 results are received.
  Future<void> onBind2Success(XMLNode result);
}

/// A class that allows for simple negotiators that only registers itself against
/// the Bind2 negotiator. You only have to implement the functions required by
/// [Bind2FeatureNegotiatorInterface].
abstract class Bind2FeatureNegotiator extends XmppFeatureNegotiatorBase
    implements Bind2FeatureNegotiatorInterface {
  Bind2FeatureNegotiator(
    int priority,
    String negotiatingXmlns,
    String id,
  ) : super(priority, false, negotiatingXmlns, id);

  @override
  bool matchesFeature(List<XMLNode> features) => false;

  @override
  Future<Result<NegotiatorState, NegotiatorError>> negotiate(
    XMLNode nonza,
  ) async {
    return const Result(NegotiatorState.done);
  }

  @mustCallSuper
  @override
  Future<void> postRegisterCallback() async {
    attributes
        .getNegotiatorById<Bind2Negotiator>(bind2Negotiator)!
        .registerNegotiator(this);
  }
}

/// A negotiator implementing XEP-0386. This negotiator is useless on its own
/// and requires a [Sasl2Negotiator] to be registered.
class Bind2Negotiator extends Sasl2FeatureNegotiator {
  Bind2Negotiator() : super(0, false, bind2Xmlns, bind2Negotiator);

  /// A list of negotiators that can work with Bind2.
  final List<Bind2FeatureNegotiatorInterface> _negotiators =
      List<Bind2FeatureNegotiatorInterface>.empty(growable: true);

  /// A tag to sent to the server when requesting Bind2.
  String? tag;

  /// Register [negotiator] against the Bind2 negotiator to append data to the Bind2
  /// negotiation.
  void registerNegotiator(Bind2FeatureNegotiatorInterface negotiator) {
    _negotiators.add(negotiator);
  }

  @override
  Future<Result<NegotiatorState, NegotiatorError>> negotiate(
    XMLNode nonza,
  ) async {
    return const Result(NegotiatorState.done);
  }

  @override
  Future<List<XMLNode>> onSasl2FeaturesReceived(XMLNode sasl2Features) async {
    final children = List<XMLNode>.empty(growable: true);
    if (_negotiators.isNotEmpty) {
      final inline = sasl2Features
          .firstTag('inline')!
          .firstTag('bind', xmlns: bind2Xmlns)!
          .firstTag('inline');
      if (inline != null) {
        final features = inline.children
            .where((child) => child.tag == 'feature')
            .map((child) => child.attributes['var']! as String)
            .toList();

        // Only call the negotiators if Bind2 allows doing stuff inline
        for (final negotiator in _negotiators) {
          children.addAll(await negotiator.onBind2FeaturesReceived(features));
        }
      }
    }

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
          ...children,
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
    final bound = response.firstTag('bound', xmlns: bind2Xmlns);
    if (bound != null) {
      for (final negotiator in _negotiators) {
        await negotiator.onBind2Success(bound);
      }
    }

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
