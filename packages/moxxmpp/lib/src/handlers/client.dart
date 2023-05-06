import 'package:meta/meta.dart';
import 'package:moxxmpp/src/connection_errors.dart';
import 'package:moxxmpp/src/handlers/base.dart';
import 'package:moxxmpp/src/jid.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/negotiators/negotiator.dart';
import 'package:moxxmpp/src/parser.dart';
import 'package:moxxmpp/src/stringxml.dart';

/// "Nonza" describing the XMPP stream header of a client-to-server connection.
class ClientStreamHeaderNonza extends XMLNode {
  ClientStreamHeaderNonza(JID jid)
      : super(
          tag: 'stream:stream',
          attributes: <String, String>{
            'xmlns': stanzaXmlns,
            'version': '1.0',
            'xmlns:stream': streamXmlns,
            'to': jid.domain,
            'from': jid.toBare().toString(),
            'xml:lang': 'en',
          },
          closeTag: false,
        );
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
  String getStanzaNamespace() => stanzaXmlns;

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

  @override
  void sendStreamHeader() {
    resetStreamParser();
    sendNonza(
      XMLNode(
        tag: 'xml',
        attributes: {'version': '1.0'},
        closeTag: false,
        isDeclaration: true,
        children: [
          ClientStreamHeaderNonza(getConnectionSettings().jid),
        ],
      ),
    );
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
          sendStreamHeader();
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
  Future<void> negotiate(XMPPStreamObject event) async {
    if (event is XMPPStreamElement) {
      if (event.node.tag == 'stream:features') {
        // Store the received stream features
        _streamFeatures
          ..clear()
          ..addAll(event.node.children);
      }

      await _executeCurrentNegotiator(event.node);
    }
  }
}
