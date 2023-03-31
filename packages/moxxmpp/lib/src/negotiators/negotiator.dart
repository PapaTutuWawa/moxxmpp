import 'package:meta/meta.dart';
import 'package:moxlib/moxlib.dart';
import 'package:moxxmpp/src/errors.dart';
import 'package:moxxmpp/src/events.dart';
import 'package:moxxmpp/src/jid.dart';
import 'package:moxxmpp/src/managers/base.dart';
import 'package:moxxmpp/src/settings.dart';
import 'package:moxxmpp/src/socket.dart';
import 'package:moxxmpp/src/stringxml.dart';
import 'package:moxxmpp/src/types/result.dart';

/// The state a negotiator is currently in
enum NegotiatorState {
  // Ready to negotiate the feature
  ready,
  // Feature negotiated; negotiator must not be used again
  done,
  // Cancel the current attempt but we are not done
  retryLater,
  // Skip the rest of the negotiation and assume the stream ready. Only use this when
  // using stream restoration XEPs, like Stream Management.
  skipRest,
}

/// A base class for all errors that may occur during feature negotiation
abstract class NegotiatorError extends XmppError {}

class NegotiatorAttributes {
  const NegotiatorAttributes(
    this.sendNonza,
    this.getConnectionSettings,
    this.sendEvent,
    this.getNegotiatorById,
    this.getManagerById,
    this.getFullJID,
    this.getSocket,
    this.isAuthenticated,
    this.setAuthenticated,
    this.removeNegotiatingFeature,
  );

  /// Sends the nonza nonza and optionally redacts it in logs if redact is not null.
  final void Function(XMLNode nonza, {String? redact}) sendNonza;

  /// Returns the connection settings.
  final ConnectionSettings Function() getConnectionSettings;

  /// Send an event event to the connection's event bus
  final Future<void> Function(XmppEvent event) sendEvent;

  /// Returns the negotiator with id id of the connection or null.
  final T? Function<T extends XmppFeatureNegotiatorBase>(String)
      getNegotiatorById;

  /// Returns the manager with id id of the connection or null.
  final T? Function<T extends XmppManagerBase>(String) getManagerById;

  /// Returns the full JID of the current account
  final JID Function() getFullJID;

  /// Returns the socket the negotiator is attached to
  final BaseSocketWrapper Function() getSocket;

  /// Returns true if the stream is authenticated. Returns false if not.
  final bool Function() isAuthenticated;

  /// Sets the authentication state of the connection to true.
  final void Function() setAuthenticated;

  /// Remove a stream feature from our internal cache. This is useful for when you
  /// negotiated a feature for another negotiator, like SASL2.
  final void Function(String) removeNegotiatingFeature;
}

abstract class XmppFeatureNegotiatorBase {
  XmppFeatureNegotiatorBase(
    this.priority,
    this.sendStreamHeaderWhenDone,
    this.negotiatingXmlns,
    this.id,
  ) : state = NegotiatorState.ready;

  /// The priority regarding other negotiators. The higher, the earlier will the
  /// negotiator be used
  final int priority;

  /// If true, then a new stream header will be sent when the negotiator switches its
  /// state to done. If false, no stream header will be sent.
  final bool sendStreamHeaderWhenDone;

  /// The XMLNS the negotiator will negotiate
  final String negotiatingXmlns;

  /// The Id of the negotiator
  final String id;

  /// The state the negotiator is currently in
  NegotiatorState state;

  late NegotiatorAttributes _attributes;

  /// Register the negotiator against a connection class by means of [attributes].
  void register(NegotiatorAttributes attributes) {
    _attributes = attributes;
  }

  /// Returns true if a feature in [features], which are the children of the
  /// <stream:features /> nonza, can be negotiated. Otherwise, returns false.
  bool matchesFeature(List<XMLNode> features) {
    return firstWhereOrNull(
          features,
          (XMLNode feature) => feature.attributes['xmlns'] == negotiatingXmlns,
        ) !=
        null;
  }

  /// Called with the currently received nonza [nonza] when the negotiator is active.
  /// If the negotiator is just elected to be the next one, then [nonza] is equal to
  /// the <stream:features /> nonza.
  ///
  /// Returns the next state of the negotiator. If done or retryLater is selected, then
  /// negotiator won't be called again. If retryLater is returned, then the negotiator
  /// must switch some internal state to prevent getting matched immediately again.
  /// If ready is returned, then the negotiator indicates that it is not done with
  /// negotiation.
  Future<Result<NegotiatorState, NegotiatorError>> negotiate(XMLNode nonza);

  /// Reset the negotiator to a state that negotation can happen again.
  void reset() {
    state = NegotiatorState.ready;
  }

  @protected
  NegotiatorAttributes get attributes => _attributes;

  /// Run after all negotiators are registered. Useful for registering callbacks against
  /// other negotiators.
  @visibleForOverriding
  Future<void> postRegisterCallback() async {}
}
