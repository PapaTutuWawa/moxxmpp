import 'package:moxxmpp/src/managers/base.dart';
import 'package:moxxmpp/src/managers/namespaces.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/negotiators/namespaces.dart';
import 'package:moxxmpp/src/negotiators/negotiator.dart';
import 'package:moxxmpp/src/stringxml.dart';
import 'package:moxxmpp/src/types/result.dart';

class CSIActiveNonza extends XMLNode {
  CSIActiveNonza() : super(
    tag: 'active',
    attributes: <String, String>{
      'xmlns': csiXmlns
    },
  );
}

class CSIInactiveNonza extends XMLNode {
  CSIInactiveNonza() : super(
    tag: 'inactive',
    attributes: <String, String>{
      'xmlns': csiXmlns
    },
  );
}

/// A Stub negotiator that is just for "intercepting" the stream feature.
class CSINegotiator extends XmppFeatureNegotiatorBase {
  CSINegotiator() : _supported = false, super(11, false, csiXmlns, csiNegotiator);

  /// True if CSI is supported. False otherwise.
  bool _supported;
  bool get isSupported => _supported;
  
  @override
  Future<Result<NegotiatorState, NegotiatorError>> negotiate(XMLNode nonza) async {
    // negotiate is only called when the negotiator matched, meaning the server
    // advertises CSI.
    _supported = true;
    return const Result(NegotiatorState.done);
  }

  @override
  void reset() {
    _supported = false;

    super.reset();
  }
}

/// The manager requires a CSINegotiator to be registered as a feature negotiator.
class CSIManager extends XmppManagerBase {

  CSIManager() : _isActive = true, super();
  bool _isActive; 

  @override
  String getId() => csiManager;

  @override
  String getName() => 'CSIManager';

  @override
  Future<bool> isSupported() async {
    return getAttributes().getNegotiatorById<CSINegotiator>(csiNegotiator)!.isSupported;
  }
  
  /// To be called after a stream has been resumed as CSI does not
  /// survive a stream resumption.
  void restoreCSIState() {
    if (_isActive) {
      setActive();
    } else {
      setInactive();
    }
  }
  
  /// Tells the server to top optimizing traffic
  Future<void> setActive() async {
    _isActive = true;

    final attrs = getAttributes();
    if (await isSupported()) {
      attrs.sendNonza(CSIActiveNonza());
    }
  }

  /// Tells the server to optimize traffic following XEP-0352
  Future<void> setInactive() async {
    _isActive = false;

    final attrs = getAttributes();
    if (await isSupported()) {
      attrs.sendNonza(CSIInactiveNonza());
    }
  }
}
