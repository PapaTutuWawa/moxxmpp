import 'package:logging/logging.dart';
import 'package:moxlib/moxlib.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/negotiators/namespaces.dart';
import 'package:moxxmpp/src/negotiators/negotiator.dart';
import 'package:moxxmpp/src/stringxml.dart';

enum _StartTlsState { ready, requested }

class StartTLSFailedError extends NegotiatorError {
  @override
  bool isRecoverable() => true;
}

class StartTLSNonza extends XMLNode {
  StartTLSNonza()
      : super.xmlns(
          tag: 'starttls',
          xmlns: startTlsXmlns,
        );
}

/// A negotiator implementing StartTLS.
class StartTlsNegotiator extends XmppFeatureNegotiatorBase {
  StartTlsNegotiator() : super(10, true, startTlsXmlns, startTlsNegotiator);

  /// The state of the negotiator.
  _StartTlsState _state = _StartTlsState.ready;

  /// Logger.
  final Logger _log = Logger('StartTlsNegotiator');

  @override
  Future<Result<NegotiatorState, NegotiatorError>> negotiate(
    XMLNode nonza,
  ) async {
    switch (_state) {
      case _StartTlsState.ready:
        _log.fine('StartTLS is available. Performing StartTLS upgrade...');
        _state = _StartTlsState.requested;
        attributes.sendNonza(StartTLSNonza());
        return const Result(NegotiatorState.ready);
      case _StartTlsState.requested:
        if (nonza.tag != 'proceed' ||
            nonza.attributes['xmlns'] != startTlsXmlns) {
          _log.severe('Failed to perform StartTLS negotiation');
          return Result(StartTLSFailedError());
        }

        _log.fine('Securing socket');
        final result = await attributes
            .getSocket()
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
