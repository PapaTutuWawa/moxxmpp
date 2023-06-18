import 'package:moxlib/moxlib.dart';
import 'package:moxxmpp/src/managers/base.dart';
import 'package:moxxmpp/src/managers/namespaces.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/negotiators/namespaces.dart';
import 'package:moxxmpp/src/negotiators/negotiator.dart';
import 'package:moxxmpp/src/stringxml.dart';
import 'package:moxxmpp/src/xeps/xep_0386.dart';

class CSIActiveNonza extends XMLNode {
  CSIActiveNonza()
      : super(
          tag: 'active',
          attributes: <String, String>{'xmlns': csiXmlns},
        );
}

class CSIInactiveNonza extends XMLNode {
  CSIInactiveNonza()
      : super(
          tag: 'inactive',
          attributes: <String, String>{'xmlns': csiXmlns},
        );
}

/// A Stub negotiator that is just for "intercepting" the stream feature.
class CSINegotiator extends XmppFeatureNegotiatorBase
    implements Bind2FeatureNegotiatorInterface {
  CSINegotiator() : super(11, false, csiXmlns, csiNegotiator);

  /// True if CSI is supported. False otherwise.
  bool _supported = false;
  bool get isSupported => _supported;

  @override
  Future<Result<NegotiatorState, NegotiatorError>> negotiate(
    XMLNode nonza,
  ) async {
    // negotiate is only called when the negotiator matched, meaning the server
    // advertises CSI.
    _supported = true;
    return const Result(NegotiatorState.done);
  }

  @override
  Future<List<XMLNode>> onBind2FeaturesReceived(
    List<String> bind2Features,
  ) async {
    if (!bind2Features.contains(csiXmlns)) {
      return [];
    }

    _supported = true;
    final active = attributes.getManagerById<CSIManager>(csiManager)!.isActive;
    return [
      if (active) CSIActiveNonza() else CSIInactiveNonza(),
    ];
  }

  @override
  Future<void> onBind2Success(XMLNode response) async {}

  @override
  void reset() {
    _supported = false;

    super.reset();
  }

  @override
  Future<void> postRegisterCallback() async {
    attributes
        .getNegotiatorById<Bind2Negotiator>(bind2Negotiator)
        ?.registerNegotiator(this);
  }
}

/// The manager requires a CSINegotiator to be registered as a feature negotiator.
class CSIManager extends XmppManagerBase {
  CSIManager() : super(csiManager);

  /// Flag indicating whether the application is currently active and the CSI
  /// traffic optimisation should be disabled (true).
  bool _isActive = true;
  bool get isActive => _isActive;

  @override
  Future<bool> isSupported() async {
    return getAttributes()
        .getNegotiatorById<CSINegotiator>(csiNegotiator)!
        .isSupported;
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

  /// Tells the server to stop optimizing traffic.
  /// If [sendNonza] is false, then no nonza is sent. This is useful
  /// for setting up the CSI manager for Bind2.
  Future<void> setActive({bool sendNonza = true}) async {
    _isActive = true;

    if (sendNonza) {
      final attrs = getAttributes();
      if (await isSupported()) {
        attrs.sendNonza(CSIActiveNonza());
      }
    }
  }

  /// Tells the server to optimize traffic following XEP-0352
  /// If [sendNonza] is false, then no nonza is sent. This is useful
  /// for setting up the CSI manager for Bind2.
  Future<void> setInactive({bool sendNonza = true}) async {
    _isActive = false;

    if (sendNonza) {
      final attrs = getAttributes();
      if (await isSupported()) {
        attrs.sendNonza(CSIInactiveNonza());
      }
    }
  }
}
