import 'dart:convert';
import 'package:moxxmpp/src/jid.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/negotiators/namespaces.dart';
import 'package:moxxmpp/src/negotiators/negotiator.dart';
import 'package:moxxmpp/src/negotiators/sasl/errors.dart';
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

  /// The SASL2 <authentication /> element we received with the stream features.
  XMLNode? _sasl2Data;
  final List<String> _activeSasl2Negotiators =
      List<String>.empty(growable: true);

  /// Register a SASL negotiator so that we can use that SASL implementation during
  /// SASL2.
  void registerSaslNegotiator(Sasl2AuthenticationNegotiator negotiator) {
    _featureNegotiators.add(negotiator);
    _saslNegotiators
      ..add(negotiator)
      ..sort((a, b) => b.priority.compareTo(a.priority));
  }

  /// Register a feature negotiator so that we can negotitate that feature inline with
  /// the SASL authentication.
  void registerNegotiator(Sasl2FeatureNegotiator negotiator) {
    _featureNegotiators.add(negotiator);
  }

  @override
  bool matchesFeature(List<XMLNode> features) {
    // Only do SASL2 when the socket is secure
    return attributes.getSocket().isSecure() && super.matchesFeature(features);
  }

  @override
  Future<Result<NegotiatorState, NegotiatorError>> negotiate(
    XMLNode nonza,
  ) async {
    switch (_sasl2State) {
      case Sasl2State.idle:
        _sasl2Data = nonza.firstTag('authentication', xmlns: sasl2Xmlns);
        final mechanisms = XMLNode.xmlns(
          tag: 'mechanisms',
          xmlns: saslXmlns,
          children:
              _sasl2Data!.children.where((c) => c.tag == 'mechanism').toList(),
        );
        for (final negotiator in _saslNegotiators) {
          if (negotiator.matchesFeature([mechanisms])) {
            _currentSaslNegotiator = negotiator;
            _currentSaslNegotiator!.pickForSasl2();
            break;
          }
        }

        // We must have a SASL negotiator by now
        if (_currentSaslNegotiator == null) {
          return Result(NoSASLMechanismSelectedError());
        }

        // Collect additional data by interested negotiators
        final inline = _sasl2Data!.firstTag('inline');
        final children = List<XMLNode>.empty(growable: true);
        if (inline != null && inline.children.isNotEmpty) {
          for (final negotiator in _featureNegotiators) {
            if (negotiator.canInlineFeature(inline.children)) {
              _activeSasl2Negotiators.add(negotiator.id);
              children.addAll(
                await negotiator.onSasl2FeaturesReceived(_sasl2Data!),
              );
            }
          }
        }

        // Build the authenticate nonza
        final authenticate = XMLNode.xmlns(
          tag: 'authenticate',
          xmlns: sasl2Xmlns,
          attributes: {
            'mechanism': _currentSaslNegotiator!.mechanismName,
          },
          children: [
            XMLNode(
              tag: 'initial-response',
              text: await _currentSaslNegotiator!.getRawStep(''),
            ),
            if (userAgent != null) userAgent!.toXml(),
            ...children,
          ],
        );

        _sasl2State = Sasl2State.authenticateSent;
        attributes.sendNonza(authenticate);
        return const Result(NegotiatorState.ready);
      case Sasl2State.authenticateSent:
        if (nonza.tag == 'success') {
          // Tell the dependent negotiators about the result
          final negotiators = _featureNegotiators
              .where(
                (negotiator) => _activeSasl2Negotiators.contains(negotiator.id),
              )
              .toList()
            ..add(_currentSaslNegotiator!);
          for (final negotiator in negotiators) {
            final result = await negotiator.onSasl2Success(nonza);
            if (!result.isType<bool>()) {
              return Result(result.get<NegotiatorError>());
            }
          }

          // We're done
          attributes.setAuthenticated();
          attributes.removeNegotiatingFeature(saslXmlns);

          // Check if we also received a resource with the SASL2 success
          final jid = JID.fromString(
            nonza.firstTag('authorization-identifier')!.innerText(),
          );
          if (!jid.isBare()) {
            attributes.setResource(jid.resource);
          }

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
        } else if (nonza.tag == 'failure') {
          final negotiators = _featureNegotiators
              .where(
                (negotiator) => _activeSasl2Negotiators.contains(negotiator.id),
              )
              .toList()
            ..add(_currentSaslNegotiator!);
          for (final negotiator in negotiators) {
            await negotiator.onSasl2Failure(nonza);
          }

          // Check if we should retry and, if we should, reset the current
          // negotiator, this negotiator, and retry.
          if (_currentSaslNegotiator!.shouldRetrySasl()) {
            _currentSaslNegotiator!.reset();
            reset();
            return const Result(
              NegotiatorState.retryLater,
            );
          }

          return Result(
            SaslError.fromFailure(nonza),
          );
        }
    }

    return const Result(NegotiatorState.ready);
  }

  @override
  void reset() {
    _currentSaslNegotiator = null;
    _sasl2State = Sasl2State.idle;
    _sasl2Data = null;
    _activeSasl2Negotiators.clear();

    super.reset();
  }
}
