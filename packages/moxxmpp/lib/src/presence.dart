import 'dart:async';
import 'package:moxxmpp/src/events.dart';
import 'package:moxxmpp/src/jid.dart';
import 'package:moxxmpp/src/managers/base.dart';
import 'package:moxxmpp/src/managers/data.dart';
import 'package:moxxmpp/src/managers/handlers.dart';
import 'package:moxxmpp/src/managers/namespaces.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/negotiators/namespaces.dart';
import 'package:moxxmpp/src/negotiators/negotiator.dart';
import 'package:moxxmpp/src/stanza.dart';
import 'package:moxxmpp/src/stringxml.dart';
import 'package:moxxmpp/src/types/result.dart';

/// A function that will be called when presence, outside of subscription request
/// management, will be sent. Useful for managers that want to add [XMLNode]s to said
/// presence.
typedef PresencePreSendCallback = Future<List<XMLNode>> Function();

/// A pseudo-negotiator that does not really negotiate anything. Instead, its purpose
/// is to look for a stream feature indicating that we can pre-approve subscription
/// requests, shown by [PresenceNegotiator.preApprovalSupported].
class PresenceNegotiator extends XmppFeatureNegotiatorBase {
  PresenceNegotiator()
      : super(11, false, subscriptionPreApprovalXmlns, presenceNegotiator);

  /// Flag indicating whether presence subscription pre-approval is supported
  bool _supported = false;
  bool get preApprovalSupported => _supported;

  @override
  Future<Result<NegotiatorState, NegotiatorError>> negotiate(
    XMLNode nonza,
  ) async {
    _supported = true;
    return const Result(NegotiatorState.done);
  }

  @override
  void reset() {
    _supported = false;

    super.reset();
  }
}

/// A mandatory manager that handles initial presence sending, sending of subscription
/// request management requests and triggers events for incoming presence stanzas.
class PresenceManager extends XmppManagerBase {
  PresenceManager() : super(presenceManager);

  /// The list of pre-send callbacks.
  final List<PresencePreSendCallback> _presenceCallbacks =
      List.empty(growable: true);

  /// The priority of the presence handler. If a handler should run before this one,
  /// which terminates processing, make sure the handler has a priority greater than
  /// [presenceHandlerPriority].
  static int presenceHandlerPriority = -100;

  @override
  List<StanzaHandler> getIncomingStanzaHandlers() => [
        StanzaHandler(
          stanzaTag: 'presence',
          callback: _onPresence,
          priority: presenceHandlerPriority,
        )
      ];

  @override
  List<String> getDiscoFeatures() => [capsXmlns];

  @override
  Future<bool> isSupported() async => true;

  /// Register the pre-send callback [callback].
  void registerPreSendCallback(PresencePreSendCallback callback) {
    _presenceCallbacks.add(callback);
  }

  @override
  Future<void> onXmppEvent(XmppEvent event) async {
    if (event is StreamNegotiationsDoneEvent) {
      // Send initial presence only when we have not resumed the stream
      if (!event.resumed) {
        await sendInitialPresence();
      }
    }
  }

  Future<StanzaHandlerData> _onPresence(
    Stanza presence,
    StanzaHandlerData state,
  ) async {
    final attrs = getAttributes();
    switch (presence.type) {
      case 'subscribe':
      case 'subscribed':
        {
          attrs.sendEvent(
            SubscriptionRequestReceivedEvent(
              from: JID.fromString(presence.from!),
            ),
          );
          return state..done = true;
        }
      default:
        break;
    }

    if (presence.from != null) {
      logger.finest("Received presence from '${presence.from}'");

      return state..done = true;
    }

    return state;
  }

  /// Sends the initial presence to enable receiving messages.
  Future<void> sendInitialPresence() async {
    final children = List<XMLNode>.from([
      XMLNode(
        tag: 'show',
        text: 'chat',
      ),
    ]);

    for (final callback in _presenceCallbacks) {
      children.addAll(
        await callback(),
      );
    }

    final attrs = getAttributes();
    await attrs.sendStanza(
      StanzaDetails(
        Stanza.presence(
          children: children,
        ),
        awaitable: false,
        addId: false,
      ),
    );
  }

  /// Send an unavailable presence with no 'to' attribute.
  Future<void> sendUnavailablePresence() async {
    // Bypass the queue so that this get's sent immediately.
    // If we do it like this, we can also block the disconnection
    // until we're actually ready.
    await getAttributes().sendStanza(
      StanzaDetails(
        Stanza.presence(
          type: 'unavailable',
        ),
        awaitable: false,
        bypassQueue: true,
        excludeFromStreamManagement: true,
      ),
    );
  }

  /// Sends a subscription request to [to].
  // TODO(PapaTutuWawa): Check if we're allowed to pre-approve
  Future<void> requestSubscription(JID to, {bool preApprove = false}) async {
    await getAttributes().sendStanza(
      StanzaDetails(
        Stanza.presence(
          type: preApprove ? 'subscribed' : 'subscribe',
          to: to.toString(),
        ),
        awaitable: false,
      ),
    );
  }

  /// Accept a subscription request from [to].
  Future<void> acceptSubscriptionRequest(JID to) async {
    await requestSubscription(to, preApprove: true);
  }

  /// Send a subscription request rejection to [to].
  Future<void> rejectSubscriptionRequest(JID to) async {
    await getAttributes().sendStanza(
      StanzaDetails(
        Stanza.presence(
          type: 'unsubscribed',
          to: to.toString(),
        ),
        awaitable: false,
      ),
    );
  }

  /// Sends an unsubscription request to [to].
  Future<void> unsubscribe(JID to) async {
    await getAttributes().sendStanza(
      StanzaDetails(
        Stanza.presence(
          type: 'unsubscribe',
          to: to.toString(),
        ),
        awaitable: false,
      ),
    );
  }
}
