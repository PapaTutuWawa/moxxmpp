import 'package:logging/logging.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/negotiators/namespaces.dart';
import 'package:moxxmpp/src/negotiators/negotiator.dart';
import 'package:moxxmpp/src/stringxml.dart';
import 'package:moxxmpp/src/types/result.dart';

enum _StartTlsState {
  ready,
  requested
}

class StartTLSFailedError extends NegotiatorError {}

class StartTLSNonza extends XMLNode {
  StartTLSNonza() : super.xmlns(
    tag: 'starttls',
    xmlns: startTlsXmlns,
  );
}

class StartTlsNegotiator extends XmppFeatureNegotiatorBase {
  
  StartTlsNegotiator()
    : _state = _StartTlsState.ready,
      _log = Logger('StartTlsNegotiator'),
      super(10, true, startTlsXmlns, startTlsNegotiator);
  _StartTlsState _state;

  final Logger _log;

  @override
  Future<Result<NegotiatorState, NegotiatorError>> negotiate(XMLNode nonza) async {
    switch (_state) {
      case _StartTlsState.ready:
        _log.fine('StartTLS is available. Performing StartTLS upgrade...');
        _state = _StartTlsState.requested;
        attributes.sendNonza(StartTLSNonza());
        return const Result(NegotiatorState.ready);
      case _StartTlsState.requested:
        if (nonza.tag != 'proceed' || nonza.attributes['xmlns'] != startTlsXmlns) {
          _log.severe('Failed to perform StartTLS negotiation');
          return Result(StartTLSFailedError());
        }

        _log.fine('Securing socket');
        final result = await attributes.getSocket()
          .secure(attributes.getConnectionSettings().jid.domain);
        if (!result) {
          _log.severe('Failed to secure stream');
          return Result(StartTLSFailedError());
        }

        _log.fine('Stream is now TLS secured');
        return const Result(NegotiatorState.done);
    }
  }

  @override
  void reset() {
    _state = _StartTlsState.ready;

    super.reset();
  }
}
