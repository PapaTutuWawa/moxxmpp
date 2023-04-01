import 'package:collection/collection.dart';
import 'package:logging/logging.dart';
import 'package:moxxmpp/src/events.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/negotiators/namespaces.dart';
import 'package:moxxmpp/src/negotiators/negotiator.dart';
import 'package:moxxmpp/src/negotiators/sasl2.dart';
import 'package:moxxmpp/src/stringxml.dart';
import 'package:moxxmpp/src/types/result.dart';

/// This event is triggered whenever a new FAST token is received.
class NewFASTTokenReceivedEvent extends XmppEvent {
  NewFASTTokenReceivedEvent(this.token);

  /// The token.
  final FASTToken token;
}

/// This event is triggered whenever a new FAST token is invalidated because it's
/// invalid.
class InvalidateFASTTokenEvent extends XmppEvent {
  InvalidateFASTTokenEvent();
}

/// The description of a token for FAST authentication.
class FASTToken {
  const FASTToken(
    this.token,
    this.expiry,
  );

  factory FASTToken.fromXml(XMLNode token) {
    assert(
      token.tag == 'token',
      'Token can only be deserialised from a <token /> element',
    );
    assert(
      token.xmlns == fastXmlns,
      'Token can only be deserialised from a <token /> element',
    );

    return FASTToken(
      token.attributes['token']! as String,
      token.attributes['expiry']! as String,
    );
  }

  /// The actual token.
  final String token;

  /// The token's expiry.
  final String expiry;
}

// TODO(Unknown): Implement multiple hash functions, similar to how we do SCRAM
class FASTSaslNegotiator extends Sasl2AuthenticationNegotiator {
  FASTSaslNegotiator() : super(20, saslFASTNegotiator, 'HT-SHA-256-NONE');

  final Logger _log = Logger('FASTSaslNegotiator');

  /// The token, if non-null, to use for authentication.
  FASTToken? fastToken;

  @override
  bool matchesFeature(List<XMLNode> features) {
    if (fastToken == null) {
      return false;
    }

    if (super.matchesFeature(features)) {
      if (!attributes.getSocket().isSecure()) {
        _log.warning(
          'Refusing to match SASL feature due to unsecured connection',
        );
        return false;
      }

      return true;
    }

    return false;
  }

  @override
  bool canInlineFeature(List<XMLNode> features) {
    return features.firstWhereOrNull(
          (child) => child.tag == 'fast' && child.xmlns == fastXmlns,
        ) !=
        null;
  }

  @override
  Future<Result<NegotiatorState, NegotiatorError>> negotiate(
    XMLNode nonza,
  ) async {
    // TODO(Unknown): Is FAST supposed to work without SASL2?
    return const Result(NegotiatorState.done);
  }

  @override
  Future<Result<bool, NegotiatorError>> onSasl2Success(XMLNode response) async {
    final token = response.firstTag('token', xmlns: fastXmlns);
    if (token != null) {
      fastToken = FASTToken.fromXml(token);
      await attributes.sendEvent(
        NewFASTTokenReceivedEvent(fastToken!),
      );
    }

    state = NegotiatorState.done;
    return const Result(true);
  }

  @override
  Future<void> onSasl2Failure(XMLNode response) async {
    fastToken = null;
    await attributes.sendEvent(
      InvalidateFASTTokenEvent(),
    );
  }

  @override
  bool shouldRetrySasl() => true;

  @override
  Future<List<XMLNode>> onSasl2FeaturesReceived(XMLNode sasl2Features) async {
    if (fastToken != null && pickedForSasl2) {
      // Specify that we are using a token
      return [
        // As we don't do TLS 0-RTT, we don't have to specify `count`.
        XMLNode.xmlns(
          tag: 'fast',
          xmlns: fastXmlns,
        ),
      ];
    }

    // Only request a new token when we don't already have one and we are not picked
    // for SASL
    if (!pickedForSasl2) {
      return [
        XMLNode.xmlns(
          tag: 'request-token',
          xmlns: fastXmlns,
          attributes: {
            'mechanism': 'HT-SHA-256-NONE',
          },
        ),
      ];
    } else {
      return [];
    }
  }

  @override
  Future<String> getRawStep(String input) async {
    return fastToken!.token;
  }

  @override
  Future<void> postRegisterCallback() async {
    attributes
        .getNegotiatorById<Sasl2Negotiator>(sasl2Negotiator)
        ?.registerSaslNegotiator(this);
  }
}
