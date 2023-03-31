import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/negotiators/namespaces.dart';
import 'package:moxxmpp/src/negotiators/negotiator.dart';
import 'package:moxxmpp/src/negotiators/sasl/negotiator.dart';
import 'package:moxxmpp/src/stringxml.dart';
import 'package:moxxmpp/src/types/result.dart';

typedef Sasl2FeaturesReceivedCallback = Future<List<XMLNode>> Function(XMLNode);

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
    assert(id != null || software != null || device != null,
        'A completely empty user agent makes no sense');
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
  final List<Sasl2FeaturesReceivedCallback> _featureCallbacks =
      List<Sasl2FeaturesReceivedCallback>.empty(growable: true);

  /// List of SASL negotiators, sorted by their priority. The higher the priority, the
  /// lower its index.
  final List<SaslNegotiator> _saslNegotiators =
      List<SaslNegotiator>.empty(growable: true);

  /// The state the SASL2 negotiator is currently in.
  Sasl2State _sasl2State = Sasl2State.idle;

  /// The SASL negotiator that will negotiate authentication.
  SaslNegotiator? _currentSaslNegotiator;

  void registerSaslNegotiator(SaslNegotiator negotiator) {
    _saslNegotiators
      ..add(negotiator)
      ..sort((a, b) => b.priority.compareTo(a.priority));
  }

  void registerFeaturesCallback(Sasl2FeaturesReceivedCallback callback) {
    _featureCallbacks.add(callback);
  }

  @override
  Future<Result<NegotiatorState, NegotiatorError>> negotiate(
      XMLNode nonza) async {
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
        for (final callback in _featureCallbacks) {
          children.addAll(
            await callback(sasl2),
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

            // TODO: Get the initial response
            XMLNode(
              tag: 'initial-response',
            ),
            ...children,
          ],
        );
        attributes.sendNonza(authenticate);
        return const Result(NegotiatorState.ready);
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
