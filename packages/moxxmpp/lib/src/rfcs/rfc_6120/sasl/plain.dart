import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:moxxmpp/src/events.dart';
import 'package:moxxmpp/src/negotiators/namespaces.dart';
import 'package:moxxmpp/src/negotiators/negotiator.dart';
import 'package:moxxmpp/src/rfcs/rfc_6120/sasl/errors.dart';
import 'package:moxxmpp/src/rfcs/rfc_6120/sasl/nonza.dart';
import 'package:moxxmpp/src/stringxml.dart';
import 'package:moxxmpp/src/types/result.dart';
import 'package:moxxmpp/src/xeps/xep_0388/negotiators.dart';
import 'package:moxxmpp/src/xeps/xep_0388/xep_0388.dart';
import 'package:saslprep/saslprep.dart';

class SaslPlainAuthNonza extends SaslAuthNonza {
  SaslPlainAuthNonza(String data)
      : super(
          'PLAIN',
          data,
        );
}

class SaslPlainNegotiator extends Sasl2AuthenticationNegotiator {
  SaslPlainNegotiator()
      : _authSent = false,
        _log = Logger('SaslPlainNegotiator'),
        super(0, saslPlainNegotiator, 'PLAIN');
  bool _authSent;

  final Logger _log;

  @override
  bool matchesFeature(List<XMLNode> features) {
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
  Future<Result<NegotiatorState, NegotiatorError>> negotiate(
    XMLNode nonza,
  ) async {
    if (!_authSent) {
      final data = await getRawStep('');
      attributes.sendNonza(
        SaslPlainAuthNonza(data),
      );
      _authSent = true;
      return const Result(NegotiatorState.ready);
    } else {
      final tag = nonza.tag;
      if (tag == 'success') {
        attributes.setAuthenticated();
        return const Result(NegotiatorState.done);
      } else {
        // We assume it's a <failure/>
        final error = nonza.children.first.tag;
        await attributes.sendEvent(AuthenticationFailedEvent(error));
        return Result(
          SaslError.fromFailure(nonza),
        );
      }
    }
  }

  @override
  void reset() {
    _authSent = false;

    super.reset();
  }

  @override
  Future<void> postRegisterCallback() async {
    attributes
        .getNegotiatorById<Sasl2Negotiator>(sasl2Negotiator)
        ?.registerSaslNegotiator(this);
  }

  @override
  Future<String> getRawStep(String input) async {
    final settings = attributes.getConnectionSettings();
    final prep = Saslprep.saslprep(settings.password);
    return base64.encode(
      utf8.encode('\u0000${settings.jid.local}\u0000$prep'),
    );
  }

  @override
  Future<Result<bool, NegotiatorError>> onSasl2Success(XMLNode response) async {
    state = NegotiatorState.done;
    return const Result(true);
  }

  @override
  Future<void> onSasl2Failure(XMLNode response) async {}

  @override
  Future<List<XMLNode>> onSasl2FeaturesReceived(XMLNode sasl2Features) async {
    return [];
  }
}
