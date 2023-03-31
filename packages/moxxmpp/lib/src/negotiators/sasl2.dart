import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/negotiators/namespaces.dart';
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
  Future<List<XMLNode>> onSasl2FeaturesReceived(XMLNode sasl2Features);

  /// Called by the SASL2 negotiator when the SASL2 negotiations are done. [response]
  /// is the entire response nonza.
  Future<Result<bool, NegotiatorError>> onSasl2Success(XMLNode response);
}

/// A special type of [SaslNegotiator] that is aware of SASL2.
abstract class Sasl2AuthenticationNegotiator extends SaslNegotiator
    implements Sasl2FeatureNegotiator {
  Sasl2AuthenticationNegotiator(super.priority, super.id, super.mechanismName);

  /// Perform a SASL step with [input] as the already parsed input data. Returns
  /// the base64-encoded response data.
  Future<String> getRawStep(String input);
}

class NoSASLMechanismSelectedError extends NegotiatorError {
  @override
  bool isRecoverable() => false;
}

/// A data class describing the user agent. See https://dyn.eightysoft.de/final/xep-0388.html#initiation
class UserAgent {
  const UserAgent({
    this.id,
    this.software,
    this.device,
  });

  /// The identifier of the software/device combo connecting. SHOULD be a UUIDv4.
  final String? id;

  /// The software's name that's connecting at the moment.
  final String? software;

  /// The name of the device.
  final String? device;

  XMLNode toXml() {
    assert(
      id != null || software != null || device != null,
      'A completely empty user agent makes no sense',
    );
    return XMLNode(
      tag: 'user-agent',
      attributes: id != null
          ? {
              'id': id,
            }
          : {},
      children: [
        if (software != null)
          XMLNode(
            tag: 'software',
            text: software,
          ),
        if (device != null)
          XMLNode(
            tag: 'device',
            text: device,
          ),
      ],
    );
  }
}

enum Sasl2State {
  // No request has been sent yet.
  idle,
  // We have sent the <authenticate /> nonza.
  authenticateSent,
}

/// A negotiator that implements XEP-0388 SASL2. Alone, it does nothing. Has to be
/// registered with other negotiators that register themselves against this one.
class Sasl2Negotiator extends XmppFeatureNegotiatorBase {
  Sasl2Negotiator({
    this.userAgent,
  }) : super(100, false, sasl2Xmlns, sasl2Negotiator);

  /// The user agent data that will be sent to the server when authenticating.
  final UserAgent? userAgent;

  /// List of callbacks that are registered against us. Will be called once we get
  /// SASL2 features.
  final List<Sasl2FeatureNegotiator> _featureNegotiators =
      List<Sasl2FeatureNegotiator>.empty(growable: true);

  /// List of SASL negotiators, sorted by their priority. The higher the priority, the
  /// lower its index.
  final List<Sasl2AuthenticationNegotiator> _saslNegotiators =
      List<Sasl2AuthenticationNegotiator>.empty(growable: true);

  /// The state the SASL2 negotiator is currently in.
  Sasl2State _sasl2State = Sasl2State.idle;

  /// The SASL negotiator that will negotiate authentication.
  Sasl2AuthenticationNegotiator? _currentSaslNegotiator;

  void registerSaslNegotiator(Sasl2AuthenticationNegotiator negotiator) {
    _featureNegotiators.add(negotiator);
    _saslNegotiators
      ..add(negotiator)
      ..sort((a, b) => b.priority.compareTo(a.priority));
  }

  void registerNegotiator(Sasl2FeatureNegotiator negotiator) {
    _featureNegotiators.add(negotiator);
  }

  @override
  Future<Result<NegotiatorState, NegotiatorError>> negotiate(
    XMLNode nonza,
  ) async {
    switch (_sasl2State) {
      case Sasl2State.idle:
        final sasl2 = nonza.firstTag('authentication', xmlns: sasl2Xmlns)!;
        final mechanisms = XMLNode.xmlns(
          tag: 'mechanisms',
          xmlns: saslXmlns,
          children: sasl2.children.where((c) => c.tag == 'mechanism').toList(),
        );
        for (final negotiator in _saslNegotiators) {
          if (negotiator.matchesFeature([mechanisms])) {
            _currentSaslNegotiator = negotiator;
            break;
          }
        }

        // We must have a SASL negotiator by now
        if (_currentSaslNegotiator == null) {
          return Result(NoSASLMechanismSelectedError());
        }

        // Collect additional data by interested negotiators
        final children = List<XMLNode>.empty(growable: true);
        for (final negotiator in _featureNegotiators) {
          children.addAll(
            await negotiator.onSasl2FeaturesReceived(sasl2),
          );
        }

        // Build the authenticate nonza
        final authenticate = XMLNode.xmlns(
          tag: 'authenticate',
          xmlns: sasl2Xmlns,
          attributes: {
            'mechanism': _currentSaslNegotiator!.mechanismName,
          },
          children: [
            if (userAgent != null) userAgent!.toXml(),
            XMLNode(
              tag: 'initial-response',
              text: await _currentSaslNegotiator!.getRawStep(''),
            ),
            ...children,
          ],
        );

        _sasl2State = Sasl2State.authenticateSent;
        attributes.sendNonza(authenticate);
        return const Result(NegotiatorState.ready);
      case Sasl2State.authenticateSent:
        if (nonza.tag == 'success') {
          // Tell the dependent negotiators about the result
          for (final negotiator in _featureNegotiators) {
            final result = await negotiator.onSasl2Success(nonza);
            if (!result.isType<bool>()) {
              return Result(result.get<NegotiatorError>());
            }
          }

          // We're done
          attributes.setAuthenticated();
          attributes.removeNegotiatingFeature(saslXmlns);
          return const Result(NegotiatorState.done);
        } else if (nonza.tag == 'challenge') {
          // We still have to negotiate
          final challenge = nonza.innerText();
          final response = XMLNode.xmlns(
            tag: 'response',
            xmlns: sasl2Xmlns,
            text: await _currentSaslNegotiator!.getRawStep(challenge),
          );
          attributes.sendNonza(response);
        }
    }

    return const Result(NegotiatorState.ready);
  }

  @override
  void reset() {
    _currentSaslNegotiator = null;
    _sasl2State = Sasl2State.idle;

    super.reset();
  }
}
