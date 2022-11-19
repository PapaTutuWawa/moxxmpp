import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:moxxmpp/src/events.dart';
import 'package:moxxmpp/src/negotiators/namespaces.dart';
import 'package:moxxmpp/src/negotiators/negotiator.dart';
import 'package:moxxmpp/src/negotiators/sasl/errors.dart';
import 'package:moxxmpp/src/negotiators/sasl/negotiator.dart';
import 'package:moxxmpp/src/negotiators/sasl/nonza.dart';
import 'package:moxxmpp/src/stringxml.dart';
import 'package:moxxmpp/src/types/result.dart';

class SaslPlainAuthNonza extends SaslAuthNonza {
  SaslPlainAuthNonza(String username, String password) : super(
    'PLAIN', base64.encode(utf8.encode('\u0000$username\u0000$password')),
  );
}

class SaslPlainNegotiator extends SaslNegotiator {
  SaslPlainNegotiator()
    : _authSent = false,
      _log = Logger('SaslPlainNegotiator'),
      super(0, saslPlainNegotiator, 'PLAIN');
  bool _authSent;

  final Logger _log;

  @override
  bool matchesFeature(List<XMLNode> features) {
    if (!attributes.getConnectionSettings().allowPlainAuth) return false;
    
    if (super.matchesFeature(features)) {
      if (!attributes.getSocket().isSecure()) {
        _log.warning('Refusing to match SASL feature due to unsecured connection');
        return false;
      }

      return true;
    }

    return false;
  }

  @override
  Future<Result<NegotiatorState, NegotiatorError>> negotiate(XMLNode nonza) async {
    if (!_authSent) {
      final settings = attributes.getConnectionSettings();
      attributes.sendNonza(
        SaslPlainAuthNonza(settings.jid.local, settings.password),
        redact: SaslPlainAuthNonza('******', '******').toXml(),
      );
      _authSent = true;
      return const Result(NegotiatorState.ready);
    } else {
      final tag = nonza.tag;
      if (tag == 'success') {
        await attributes.sendEvent(AuthenticationSuccessEvent());
        return const Result(NegotiatorState.done);
      } else {
        // We assume it's a <failure/>
        final error = nonza.children.first.tag;
        await attributes.sendEvent(AuthenticationFailedEvent(error));
        return Result(SaslFailedError());
      }
    }
  }

  @override
  void reset() {
    _authSent = false;

    super.reset();
  }
}
