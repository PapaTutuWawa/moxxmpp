import 'package:collection/collection.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:moxxmpp/src/events.dart';
import 'package:moxxmpp/src/managers/namespaces.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/negotiators/namespaces.dart';
import 'package:moxxmpp/src/negotiators/negotiator.dart';
import 'package:moxxmpp/src/stringxml.dart';
import 'package:moxxmpp/src/types/result.dart';
import 'package:moxxmpp/src/xeps/xep_0198/nonzas.dart';
import 'package:moxxmpp/src/xeps/xep_0198/state.dart';
import 'package:moxxmpp/src/xeps/xep_0198/xep_0198.dart';
import 'package:moxxmpp/src/xeps/xep_0352.dart';
import 'package:moxxmpp/src/xeps/xep_0386.dart';
import 'package:moxxmpp/src/xeps/xep_0388/negotiators.dart';
import 'package:moxxmpp/src/xeps/xep_0388/xep_0388.dart';

enum _StreamManagementNegotiatorState {
  // We have not done anything yet
  ready,
  // The SM resume has been requested
  resumeRequested,
  // The SM enablement has been requested
  enableRequested,
}

/// NOTE: The stream management negotiator requires that loadState has been called on the
///       StreamManagementManager at least once before connecting, if stream resumption
///       is wanted.
class StreamManagementNegotiator extends Sasl2FeatureNegotiator
    implements Bind2FeatureNegotiatorInterface {
  StreamManagementNegotiator()
      : super(10, false, smXmlns, streamManagementNegotiator);

  /// Stream Management negotiation state.
  _StreamManagementNegotiatorState _state =
      _StreamManagementNegotiatorState.ready;

  /// Flag indicating whether the resume failed (true) or succeeded (false).
  bool _resumeFailed = false;
  bool get resumeFailed => _resumeFailed;

  /// Flag indicating whether the current stream is resumed (true) or not (false).
  bool _isResumed = false;
  bool get isResumed => _isResumed;

  /// Flag indicating that stream enablement failed
  bool _streamEnablementFailed = false;
  bool get streamEnablementFailed => _streamEnablementFailed;

  /// Logger
  final Logger _log = Logger('StreamManagementNegotiator');

  /// True if Stream Management is supported on this stream.
  bool _supported = false;
  bool get isSupported => _supported;

  /// True if we requested stream enablement inline
  bool _inlineStreamEnablementRequested = false;

  /// Cached resource for stream resumption
  String _resource = '';
  @visibleForTesting
  void setResource(String resource) {
    _resource = resource;
  }

  @override
  bool canInlineFeature(List<XMLNode> features) {
    final sm = attributes.getManagerById<StreamManagementManager>(smManager)!;

    // We do not check here for authentication as enabling/resuming happens inline
    // with the authentication.
    if (sm.state.streamResumptionId != null && !_resumeFailed) {
      // We can try to resume the stream or enable the stream
      return features.firstWhereOrNull(
            (child) => child.xmlns == smXmlns,
          ) !=
          null;
    } else {
      // We can try to enable SM
      return features.firstWhereOrNull(
            (child) => child.tag == 'enable' && child.xmlns == smXmlns,
          ) !=
          null;
    }
  }

  @override
  Future<void> onXmppEvent(XmppEvent event) async {
    if (event is ResourceBoundEvent) {
      _resource = event.resource;
    }
  }

  @override
  bool matchesFeature(List<XMLNode> features) {
    final sm = attributes.getManagerById<StreamManagementManager>(smManager)!;

    if (sm.state.streamResumptionId != null && !_resumeFailed) {
      // We could do Stream resumption
      return super.matchesFeature(features) && attributes.isAuthenticated();
    } else {
      // We cannot do a stream resumption
      return super.matchesFeature(features) &&
          attributes.getConnection().resource.isNotEmpty &&
          attributes.isAuthenticated();
    }
  }

  Future<void> _onStreamResumptionFailed() async {
    await attributes.sendEvent(StreamResumeFailedEvent());
    final sm = attributes.getManagerById<StreamManagementManager>(smManager)!;

    // We have to do this because we otherwise get a stanza stuck in the queue,
    // thus spamming the server on every <a /> nonza we receive.
    // ignore: cascade_invocations
    await sm.setState(StreamManagementState(0, 0));
    await sm.commitState();

    _resumeFailed = true;
    _isResumed = false;
    _state = _StreamManagementNegotiatorState.ready;
  }

  Future<void> _onStreamResumptionSuccessful(XMLNode resumed) async {
    assert(resumed.tag == 'resumed', 'The correct element must be passed');

    final h = int.parse(resumed.attributes['h']! as String);
    await attributes.sendEvent(StreamResumedEvent(h: h));

    _resumeFailed = false;
    _isResumed = true;

    if (attributes.getConnection().resource.isEmpty && _resource.isNotEmpty) {
      attributes.setResource(_resource);
    } else if (attributes.getConnection().resource.isNotEmpty &&
        _resource.isEmpty) {
      _resource = attributes.getConnection().resource;
    }
  }

  Future<void> _onStreamEnablementSuccessful(XMLNode enabled) async {
    assert(enabled.tag == 'enabled', 'The correct element must be used');
    assert(enabled.xmlns == smXmlns, 'The correct element must be used');

    final id = enabled.attributes['id'] as String?;
    if (id != null && ['true', '1'].contains(enabled.attributes['resume'])) {
      _log.info('Stream Resumption available');
    }

    await attributes.sendEvent(
      StreamManagementEnabledEvent(
        resource: attributes.getFullJID().resource,
        id: id,
        location: enabled.attributes['location'] as String?,
      ),
    );
  }

  void _onStreamEnablementFailed() {
    _streamEnablementFailed = true;
  }

  @override
  Future<Result<NegotiatorState, NegotiatorError>> negotiate(
    XMLNode nonza,
  ) async {
    // negotiate is only called when we matched the stream feature, so we know
    // that the server advertises it.
    _supported = true;

    switch (_state) {
      case _StreamManagementNegotiatorState.ready:
        final sm =
            attributes.getManagerById<StreamManagementManager>(smManager)!;
        final srid = sm.state.streamResumptionId;
        final h = sm.state.s2c;

        // Attempt stream resumption first
        if (srid != null) {
          _log.finest(
            'Found stream resumption Id. Attempting to perform stream resumption',
          );
          _state = _StreamManagementNegotiatorState.resumeRequested;
          attributes.sendNonza(StreamManagementResumeNonza(srid, h));
        } else {
          _log.finest('Attempting to enable stream management');
          _state = _StreamManagementNegotiatorState.enableRequested;
          attributes.sendNonza(StreamManagementEnableNonza());
        }

        return const Result(NegotiatorState.ready);
      case _StreamManagementNegotiatorState.resumeRequested:
        if (nonza.tag == 'resumed') {
          _log.finest('Stream Management resumption successful');

          assert(
            attributes.getFullJID().resource != '',
            'Resume only works when we already have a resource bound and know about it',
          );

          final csi = attributes.getManagerById(csiManager) as CSIManager?;
          if (csi != null) {
            csi.restoreCSIState();
          }

          await _onStreamResumptionSuccessful(nonza);
          return const Result(NegotiatorState.skipRest);
        } else {
          // We assume it is <failed />
          _log.info(
            'Stream resumption failed. Expected <resumed />, got ${nonza.tag}, Proceeding with new stream...',
          );
          await _onStreamResumptionFailed();
          return const Result(NegotiatorState.retryLater);
        }
      case _StreamManagementNegotiatorState.enableRequested:
        if (nonza.tag == 'enabled') {
          _log.finest('Stream Management enabled');
          await _onStreamEnablementSuccessful(nonza);

          return const Result(NegotiatorState.done);
        } else {
          // We assume a <failed />
          _log.warning('Stream Management enablement failed');
          _onStreamEnablementFailed();
          return const Result(NegotiatorState.done);
        }
    }
  }

  @override
  void reset() {
    _state = _StreamManagementNegotiatorState.ready;
    _supported = false;
    _resumeFailed = false;
    _isResumed = false;
    _inlineStreamEnablementRequested = false;
    _streamEnablementFailed = false;

    super.reset();
  }

  @override
  Future<List<XMLNode>> onBind2FeaturesReceived(
    List<String> bind2Features,
  ) async {
    if (!bind2Features.contains(smXmlns)) {
      return [];
    }

    _inlineStreamEnablementRequested = true;
    return [
      StreamManagementEnableNonza(),
    ];
  }

  @override
  Future<void> onBind2Success(XMLNode response) async {}

  @override
  Future<List<XMLNode>> onSasl2FeaturesReceived(XMLNode sasl2Features) async {
    final inline = sasl2Features.firstTag('inline')!;
    final resume = inline.firstTag('resume', xmlns: smXmlns);

    if (resume == null) {
      return [];
    }

    final sm = attributes.getManagerById<StreamManagementManager>(smManager)!;
    final srid = sm.state.streamResumptionId;
    final h = sm.state.s2c;
    if (srid == null) {
      _log.finest('No srid');
      return [];
    }

    return [
      StreamManagementResumeNonza(
        srid,
        h,
      ),
    ];
  }

  @override
  Future<Result<bool, NegotiatorError>> onSasl2Success(XMLNode response) async {
    final enabled = response
        .firstTag('bound', xmlns: bind2Xmlns)
        ?.firstTag('enabled', xmlns: smXmlns);
    final resumed = response.firstTag('resumed', xmlns: smXmlns);
    // We can only enable or resume->fail->enable. Thus, we check for enablement first
    // and then exit.
    if (_inlineStreamEnablementRequested) {
      if (enabled != null) {
        _log.finest('Inline stream enablement successful');
        await _onStreamEnablementSuccessful(enabled);
        return const Result(true);
      } else {
        _log.warning('Inline stream enablement failed');
        _onStreamEnablementFailed();
      }
    }

    if (resumed == null) {
      _log.warning('Inline stream resumption failed');
      await _onStreamResumptionFailed();
      state = NegotiatorState.done;
      return const Result(true);
    }

    _log.finest('Inline stream resumption successful');
    await _onStreamResumptionSuccessful(resumed);
    state = NegotiatorState.skipRest;

    attributes.removeNegotiatingFeature(smXmlns);
    attributes.removeNegotiatingFeature(bindXmlns);

    return const Result(true);
  }

  @override
  Future<void> postRegisterCallback() async {
    attributes
        .getNegotiatorById<Sasl2Negotiator>(sasl2Negotiator)
        ?.registerNegotiator(this);
    attributes
        .getNegotiatorById<Bind2Negotiator>(bind2Negotiator)
        ?.registerNegotiator(this);
  }
}
