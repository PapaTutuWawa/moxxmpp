import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:moxxmpp/src/connection_errors.dart';
import 'package:moxxmpp/src/errors.dart';
import 'package:moxxmpp/src/events.dart';
import 'package:moxxmpp/src/negotiators/negotiator.dart';
import 'package:moxxmpp/src/stringxml.dart';

/// A callback for when the [NegotiationsHandler] is done.
typedef NegotiationsDoneCallback = Future<void> Function();

/// A callback for the case that an error occurs while negotiating.
typedef ErrorCallback = Future<void> Function(XmppError);

/// Trigger stream headers to be sent
typedef SendStreamHeadersFunction = void Function();

/// Return true if the current connection is authenticated. If not, return false.
typedef IsAuthenticatedFunction = bool Function();

/// This class implements the stream feature negotiation for XmppConnection.
abstract class NegotiationsHandler {
  @protected
  late final Logger log;

  /// Map of all negotiators registered against the handler.
  @protected
  final Map<String, XmppFeatureNegotiatorBase> negotiators = {};

  /// Function that is called once the negotiator is done with its stream negotiations.
  @protected
  late final NegotiationsDoneCallback onNegotiationsDone;

  /// XmppConnection's handleError method.
  @protected
  late final ErrorCallback handleError;

  /// Sends stream headers in the stream.
  @protected
  late final SendStreamHeadersFunction sendStreamHeaders;

  /// Returns true if the connection is authenticated. If not, returns false.
  @protected
  late final IsAuthenticatedFunction isAuthenticated;

  /// The id included in the last stream header.
  @protected
  String? streamId;

  /// Set the id of the last stream header.
  void setStreamHeaderId(String? id) {
    streamId = id;
  }

  /// Returns, if registered, a negotiator with id [id].
  T? getNegotiatorById<T extends XmppFeatureNegotiatorBase>(String id) =>
      negotiators[id] as T?;

  /// Register the parameters as the corresponding methods in this class. Also
  /// initializes the logger.
  void register(
    NegotiationsDoneCallback onNegotiationsDone,
    ErrorCallback handleError,
    SendStreamHeadersFunction sendStreamHeaders,
    IsAuthenticatedFunction isAuthenticated,
  ) {
    this.onNegotiationsDone = onNegotiationsDone;
    this.handleError = handleError;
    this.sendStreamHeaders = sendStreamHeaders;
    this.isAuthenticated = isAuthenticated;
    log = Logger(toString());
  }

  /// Registers the negotiator [negotiator] against this negotiations handler.
  void registerNegotiator(XmppFeatureNegotiatorBase negotiator);

  /// Runs the post-register callback of all negotiators.
  Future<void> runPostRegisterCallback() async {
    for (final negotiator in negotiators.values) {
      await negotiator.postRegisterCallback();
    }
  }

  Future<void> sendEventToNegotiators(XmppEvent event) async {
    for (final negotiator in negotiators.values) {
      await negotiator.onXmppEvent(event);
    }
  }

  /// Remove [feature] from the stream features we are currently negotiating.
  void removeNegotiatingFeature(String feature) {}

  /// Resets all registered negotiators and the negotiation handler.
  @mustCallSuper
  void reset() {
    streamId = null;
    for (final negotiator in negotiators.values) {
      negotiator.reset();
    }
  }

  /// Called whenever a new nonza [nonza] is received while negotiating.
  Future<void> negotiate(XMLNode nonza);
}

/// This class implements the stream feature negotiation for usage in client to server
/// connections.
class ClientToServerNegotiator extends NegotiationsHandler {
  ClientToServerNegotiator() : super();

  /// Cached list of stream features.
  final List<XMLNode> _streamFeatures = List.empty(growable: true);

  /// The currently active negotiator.
  XmppFeatureNegotiatorBase? _currentNegotiator;

  @override
  void registerNegotiator(XmppFeatureNegotiatorBase negotiator) {
    negotiators[negotiator.id] = negotiator;
  }

  @override
  void reset() {
    super.reset();

    // Prevent leaking the last active negotiator
    _currentNegotiator = null;
  }

  @override
  void removeNegotiatingFeature(String feature) {
    _streamFeatures.removeWhere((node) {
      return node.attributes['xmlns'] == feature;
    });
  }

  /// Returns true if all mandatory features in [features] have been negotiated.
  /// Otherwise returns false.
  bool _isMandatoryNegotiationDone(List<XMLNode> features) {
    return features.every((XMLNode feature) {
      return feature.firstTag('required') == null &&
          feature.tag != 'mechanisms';
    });
  }

  /// Returns true if we can still negotiate. Returns false if no negotiator is
  /// matching and ready.
  bool _isNegotiationPossible(List<XMLNode> features) {
    return getNextNegotiator(features, log: false) != null;
  }

  /// Returns the next negotiator that matches [features]. Returns null if none can be
  /// picked. If [log] is true, then the list of matching negotiators will be logged.
  @visibleForTesting
  XmppFeatureNegotiatorBase? getNextNegotiator(
    List<XMLNode> features, {
    bool log = true,
  }) {
    final matchingNegotiators =
        negotiators.values.where((XmppFeatureNegotiatorBase negotiator) {
      return negotiator.state == NegotiatorState.ready &&
          negotiator.matchesFeature(features);
    }).toList()
          ..sort((a, b) => b.priority.compareTo(a.priority));

    if (log) {
      this.log.finest(
            'List of matching negotiators: ${matchingNegotiators.map((a) => a.id)}',
          );
    }

    if (matchingNegotiators.isEmpty) return null;

    return matchingNegotiators.first;
  }

  Future<void> _executeCurrentNegotiator(XMLNode nonza) async {
    // If we don't have a negotiator, get one
    _currentNegotiator ??= getNextNegotiator(_streamFeatures);
    if (_currentNegotiator == null &&
        _isMandatoryNegotiationDone(_streamFeatures) &&
        !_isNegotiationPossible(_streamFeatures)) {
      log.finest('Negotiations done!');
      await onNegotiationsDone();
      return;
    }

    // If we don't have a next negotiator, we have to bail
    if (_currentNegotiator == null &&
        !_isMandatoryNegotiationDone(_streamFeatures) &&
        !_isNegotiationPossible(_streamFeatures)) {
      // We failed before authenticating
      if (!isAuthenticated()) {
        log.severe('No negotiator could be picked while unauthenticated');
        await handleError(NoMatchingAuthenticationMechanismAvailableError());
        return;
      } else {
        log.severe(
          'No negotiator could be picked while negotiations are not done',
        );
        await handleError(NoAuthenticatorAvailableError());
        return;
      }
    }

    final result = await _currentNegotiator!.negotiate(nonza);
    if (result.isType<NegotiatorError>()) {
      log.severe('Negotiator returned an error');
      await handleError(result.get<NegotiatorError>());
      return;
    }

    final state = result.get<NegotiatorState>();
    _currentNegotiator!.state = state;
    switch (state) {
      case NegotiatorState.ready:
        return;
      case NegotiatorState.done:
        if (_currentNegotiator!.sendStreamHeaderWhenDone) {
          _currentNegotiator = null;
          _streamFeatures.clear();
          sendStreamHeaders();
        } else {
          removeNegotiatingFeature(_currentNegotiator!.negotiatingXmlns);
          _currentNegotiator = null;

          if (_isMandatoryNegotiationDone(_streamFeatures) &&
              !_isNegotiationPossible(_streamFeatures)) {
            log.finest('Negotiations done!');
            await onNegotiationsDone();
          } else {
            _currentNegotiator = getNextNegotiator(_streamFeatures);
            log.finest('Chose ${_currentNegotiator!.id} as next negotiator');

            final fakeStanza = XMLNode(
              tag: 'stream:features',
              children: _streamFeatures,
            );

            await _executeCurrentNegotiator(fakeStanza);
          }
        }
        break;
      case NegotiatorState.retryLater:
        log.finest('Negotiator wants to continue later. Picking new one...');
        _currentNegotiator!.state = NegotiatorState.ready;

        if (_isMandatoryNegotiationDone(_streamFeatures) &&
            !_isNegotiationPossible(_streamFeatures)) {
          log.finest('Negotiations done!');

          await onNegotiationsDone();
        } else {
          log.finest('Picking new negotiator...');
          _currentNegotiator = getNextNegotiator(_streamFeatures);
          log.finest('Chose $_currentNegotiator as next negotiator');
          final fakeStanza = XMLNode(
            tag: 'stream:features',
            children: _streamFeatures,
          );
          await _executeCurrentNegotiator(fakeStanza);
        }
        break;
      case NegotiatorState.skipRest:
        log.finest(
          'Negotiator wants to skip the remaining negotiation... Negotiations (assumed) done!',
        );

        await onNegotiationsDone();
        break;
    }
  }

  @override
  Future<void> negotiate(XMLNode nonza) async {
    if (nonza.tag == 'stream:features') {
      // Store the received stream features
      _streamFeatures
        ..clear()
        ..addAll(nonza.children);
    }

    await _executeCurrentNegotiator(nonza);
  }
}
