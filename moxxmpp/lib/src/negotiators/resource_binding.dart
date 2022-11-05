import 'package:moxxmpp/src/events.dart';
import 'package:moxxmpp/src/managers/namespaces.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/negotiators/namespaces.dart';
import 'package:moxxmpp/src/negotiators/negotiator.dart';
import 'package:moxxmpp/src/stringxml.dart';
import 'package:moxxmpp/src/xeps/xep_0198/xep_0198.dart';
import 'package:uuid/uuid.dart';

class ResourceBindingNegotiator extends XmppFeatureNegotiatorBase {

  ResourceBindingNegotiator() : _requestSent = false, super(0, false, bindXmlns, resourceBindingNegotiator);
  bool _requestSent;

  @override
  bool matchesFeature(List<XMLNode> features) {
    final sm = attributes.getManagerById<StreamManagementManager>(smManager);
    if (sm != null) {
      return super.matchesFeature(features) && !sm.streamResumed && attributes.isAuthenticated();
    }

    return super.matchesFeature(features) && attributes.isAuthenticated();
  }
  
  @override
  Future<void> negotiate(XMLNode nonza) async {
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
    } else {
      if (nonza.tag != 'iq' || nonza.attributes['type'] != 'result') {
        state = NegotiatorState.error;
        return;
      }

      final bind = nonza.firstTag('bind')!;
      final jid = bind.firstTag('jid')!;
      final resource = jid.innerText().split('/')[1];

      await attributes.sendEvent(ResourceBindingSuccessEvent(resource: resource));
      state = NegotiatorState.done;
    }
  }
  
  @override
  void reset() {
    _requestSent = false;

    super.reset();
  }
}
