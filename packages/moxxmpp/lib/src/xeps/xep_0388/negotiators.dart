import 'package:moxxmpp/src/negotiators/negotiator.dart';
import 'package:moxxmpp/src/negotiators/sasl/negotiator.dart';
import 'package:moxxmpp/src/stringxml.dart';
import 'package:moxxmpp/src/types/result.dart';

/// A special type of [XmppFeatureNegotiatorBase] that is aware of SASL2.
abstract class Sasl2FeatureNegotiator extends XmppFeatureNegotiatorBase {
  Sasl2FeatureNegotiator(
    super.priority,
    super.sendStreamHeaderWhenDone,
    super.negotiatingXmlns,
    super.id,
  );

  /// Called by the SASL2 negotiator when we received the SASL2 stream features
  /// [sasl2Features]. The return value is a list of XML elements that should be
  /// added to the SASL2 <authenticate /> nonza.
  /// This method is only called when the <inline /> element contains an item with
  /// xmlns equal to [negotiatingXmlns].
  Future<List<XMLNode>> onSasl2FeaturesReceived(XMLNode sasl2Features);

  /// Called by the SASL2 negotiator when the SASL2 negotiations are done. [response]
  /// is the entire response nonza.
  /// This method is only called when the previous <inline /> element contains an
  /// item with xmlns equal to [negotiatingXmlns].
  Future<Result<bool, NegotiatorError>> onSasl2Success(XMLNode response);

  /// Called by the SASL2 negotiator when the SASL2 negotiations have failed. [response]
  /// is the entire response nonza.
  Future<void> onSasl2Failure(XMLNode response) async {}

  /// Called by the SASL2 negotiator to find out whether the negotiator is willing
  /// to inline a feature. [features] is the list of elements inside the <inline />
  /// element.
  bool canInlineFeature(List<XMLNode> features);
}

/// A special type of [SaslNegotiator] that is aware of SASL2.
abstract class Sasl2AuthenticationNegotiator extends SaslNegotiator
    implements Sasl2FeatureNegotiator {
  Sasl2AuthenticationNegotiator(super.priority, super.id, super.mechanismName);

  /// Flag indicating whether this negotiator was chosen during SASL2 as the SASL
  /// negotiator to use.
  bool _pickedForSasl2 = false;
  bool get pickedForSasl2 => _pickedForSasl2;

  /// Perform a SASL step with [input] as the already parsed input data. Returns
  /// the base64-encoded response data.
  Future<String> getRawStep(String input);

  /// Tells the negotiator that it has been selected as the SASL negotiator for SASL2.
  void pickForSasl2() {
    _pickedForSasl2 = true;
  }

  /// When SASL2 fails, should we retry (true) or just fail (false).
  /// Defaults to just returning false.
  bool shouldRetrySasl() => false;

  @override
  void reset() {
    _pickedForSasl2 = false;

    super.reset();
  }

  @override
  bool canInlineFeature(List<XMLNode> features) {
    return true;
  }
}
