import 'package:moxxmpp/src/events.dart';
import 'package:moxxmpp/src/managers/namespaces.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/negotiators/namespaces.dart';
import 'package:moxxmpp/src/negotiators/negotiator.dart';
import 'package:moxxmpp/src/stringxml.dart';
import 'package:moxxmpp/src/types/result.dart';
import 'package:moxxmpp/src/xeps/xep_0198/xep_0198.dart';
import 'package:uuid/uuid.dart';

class ResourceBindingFailedError extends NegotiatorError {
  @override
  bool isRecoverable() => true;
}

/// A negotiator that implements resource binding against a random server-provided
/// resource.
class ResourceBindingNegotiator extends XmppFeatureNegotiatorBase {
  ResourceBindingNegotiator() : super(0, false, bindXmlns, resourceBindingNegotiator);

  /// Flag indicating the state of the negotiator:
  /// - True: We sent a binding request
  /// - False: We have not yet sent the binding request
  bool _requestSent = false;

  @override
  bool matchesFeature(List<XMLNode> features) {
    final sm = attributes.getManagerById<StreamManagementManager>(smManager);
    if (sm != null) {
      return super.matchesFeature(features) && !sm.streamResumed && attributes.isAuthenticated();
    }

    return super.matchesFeature(features) && attributes.isAuthenticated();
  }
  
  @override
  Future<Result<NegotiatorState, NegotiatorError>> negotiate(XMLNode nonza) async {
    if (!_requestSent) {
      final stanza = XMLNode.xmlns(
        tag: 'iq',
        xmlns: stanzaXmlns,
        attributes: {
          'type': 'set',
          'id': const Uuid().v4(),
        },
        children: [
          XMLNode.xmlns(
            tag: 'bind',
            xmlns: bindXmlns,
          ),
        ],
      );

      _requestSent = true;
      attributes.sendNonza(stanza);
      return const Result(NegotiatorState.ready);
    } else {
      if (nonza.tag != 'iq' || nonza.attributes['type'] != 'result') {
        return Result(ResourceBindingFailedError());
      }

      final bind = nonza.firstTag('bind')!;
      final jid = bind.firstTag('jid')!;
      final resource = jid.innerText().split('/')[1];

      await attributes.sendEvent(ResourceBindingSuccessEvent(resource: resource));
      return const Result(NegotiatorState.done);
    }
  }
  
  @override
  void reset() {
    _requestSent = false;

    super.reset();
  }
}
