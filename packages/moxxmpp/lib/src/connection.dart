import 'dart:async';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:moxlib/moxlib.dart';
import 'package:moxxmpp/src/awaiter.dart';
import 'package:moxxmpp/src/connection_errors.dart';
import 'package:moxxmpp/src/connectivity.dart';
import 'package:moxxmpp/src/errors.dart';
import 'package:moxxmpp/src/events.dart';
import 'package:moxxmpp/src/handlers/base.dart';
import 'package:moxxmpp/src/iq.dart';
import 'package:moxxmpp/src/jid.dart';
import 'package:moxxmpp/src/managers/attributes.dart';
import 'package:moxxmpp/src/managers/base.dart';
import 'package:moxxmpp/src/managers/data.dart';
import 'package:moxxmpp/src/managers/handlers.dart';
import 'package:moxxmpp/src/managers/namespaces.dart';
import 'package:moxxmpp/src/negotiators/negotiator.dart';
import 'package:moxxmpp/src/parser.dart';
import 'package:moxxmpp/src/presence.dart';
import 'package:moxxmpp/src/reconnect.dart';
import 'package:moxxmpp/src/roster/roster.dart';
import 'package:moxxmpp/src/routing.dart';
import 'package:moxxmpp/src/settings.dart';
import 'package:moxxmpp/src/socket.dart';
import 'package:moxxmpp/src/stanza.dart';
import 'package:moxxmpp/src/stringxml.dart';
import 'package:moxxmpp/src/types/result.dart';
import 'package:moxxmpp/src/util/queue.dart';
import 'package:moxxmpp/src/util/typed_map.dart';
import 'package:moxxmpp/src/xeps/xep_0030/xep_0030.dart';
import 'package:moxxmpp/src/xeps/xep_0198/types.dart';
import 'package:moxxmpp/src/xeps/xep_0198/xep_0198.dart';
import 'package:moxxmpp/src/xeps/xep_0352.dart';
import 'package:synchronized/synchronized.dart';
import 'package:uuid/uuid.dart';

/// The states the XmppConnection can be in
enum XmppConnectionState {
  /// The XmppConnection instance is not connected to the server. This is either the
  /// case before connecting or after disconnecting.
  notConnected,

  /// We are currently trying to connect to the server.
  connecting,

  /// We are currently connected to the server.
  connected,

  /// We have received an unrecoverable error and the server killed the connection
  error
}

/// This class is a connection to the server.
class XmppConnection {
  XmppConnection(
    ReconnectionPolicy reconnectionPolicy,
    ConnectivityManager connectivityManager,
    this._negotiationsHandler,
    this._socket, {
    this.connectingTimeout = const Duration(minutes: 2),
  })  : _reconnectionPolicy = reconnectionPolicy,
        _connectivityManager = connectivityManager {
    // Allow the reconnection policy to perform reconnections by itself
    _reconnectionPolicy.register(
      _attemptReconnection,
    );

    // Register the negotiations handler
    _negotiationsHandler.register(
      _onNegotiationsDone,
      handleError,
      () => _isAuthenticated,
      sendRawXML,
      () => connectionSettings,
      () {
        _log.finest('Resetting stream parser');
        _streamParser.reset();
      },
    );

    _socketStream = _socket.getDataStream();
    // TODO(Unknown): Handle on done
    _socketStream.transform(_streamParser).forEach(handleXmlStream);
    _socket.getEventStream().listen(handleSocketEvent);

    _stanzaQueue = AsyncStanzaQueue(
      _sendStanzaImpl,
      _canSendData,
    );
  }

  /// The state that the connection is currently in
  XmppConnectionState _connectionState = XmppConnectionState.notConnected;

  /// The socket that we are using for the connection and its data stream
  final BaseSocketWrapper _socket;

  /// The data stream of the socket
  late final Stream<String> _socketStream;

  /// Connection settings
  late ConnectionSettings connectionSettings;

  /// A policy on how to reconnect
  final ReconnectionPolicy _reconnectionPolicy;
  ReconnectionPolicy get reconnectionPolicy => _reconnectionPolicy;

  /// The class responsible for preventing errors on initial connection due
  /// to no network.
  final ConnectivityManager _connectivityManager;

  /// A helper for handling await semantics with stanzas
  final StanzaAwaiter _stanzaAwaiter = StanzaAwaiter();

  /// Sorted list of handlers that we call or incoming and outgoing stanzas
  final List<StanzaHandler> _incomingStanzaHandlers =
      List.empty(growable: true);
  final List<StanzaHandler> _incomingPreStanzaHandlers =
      List.empty(growable: true);
  final List<StanzaHandler> _outgoingPreStanzaHandlers =
      List.empty(growable: true);
  final List<StanzaHandler> _outgoingPostStanzaHandlers =
      List.empty(growable: true);
  final StreamController<XmppEvent> _eventStreamController =
      StreamController.broadcast();
  final Map<String, XmppManagerBase> _xmppManagers = {};

  /// The parser for the entire XMPP XML stream.
  final XMPPStreamParser _streamParser = XMPPStreamParser();

  /// UUID object to generate stanza and origin IDs
  final Uuid _uuid = const Uuid();

  /// The time that we may spent in the "connecting" state
  final Duration connectingTimeout;

  /// The current state of the connection handling state machine.
  RoutingState _routingState = RoutingState.preConnection;

  /// The currently bound resource or '' if none has been bound yet.
  /// NOTE: A Using the empty string is okay since RFC7622 says that
  ///       the resource MUST NOT be zero octets.
  String _resource = '';
  String get resource => _resource;

  /// True if we are authenticated. False if not.
  bool _isAuthenticated = false;

  /// Timer for the connecting timeout.
  Timer? _connectingTimeoutTimer;

  /// Completers for certain actions
  // ignore: use_late_for_private_fields_and_variables
  Completer<Result<bool, XmppError>>? _connectionCompleter;

  /// The handler for dealing with stream feature negotiations.
  final NegotiationsHandler _negotiationsHandler;
  T? getNegotiatorById<T extends XmppFeatureNegotiatorBase>(String id) =>
      _negotiationsHandler.getNegotiatorById<T>(id);

  /// Prevent data from being passed to _currentNegotiator.negotiator while the negotiator
  /// is still running.
  final Lock _negotiationLock = Lock();

  /// The logger for the class
  final Logger _log = Logger('XmppConnection');

  /// Flag indicating whether reconnection should be enabled after a successful connection.
  bool _enableReconnectOnSuccess = false;

  bool get isAuthenticated => _isAuthenticated;

  late final AsyncStanzaQueue _stanzaQueue;

  /// Returns the JID we authenticate with and add the resource that we have bound.
  JID _getJidWithResource() {
    assert(_resource.isNotEmpty, 'The resource must not be empty');

    return connectionSettings.jid.withResource(_resource);
  }

  /// Registers a list of [XmppManagerBase] sub-classes as managers on this connection.
  Future<void> registerManagers(List<XmppManagerBase> managers) async {
    for (final manager in managers) {
      _log.finest('Registering ${manager.id}');
      manager.register(
        XmppManagerAttributes(
          sendStanza: sendStanza,
          sendNonza: sendRawXML,
          sendEvent: _sendEvent,
          getConnectionSettings: () => connectionSettings,
          getManagerById: getManagerById,
          getFullJID: _getJidWithResource,
          getSocket: () => _socket,
          getConnection: () => this,
          getNegotiatorById: _negotiationsHandler.getNegotiatorById,
        ),
      );

      _xmppManagers[manager.id] = manager;

      _incomingStanzaHandlers.addAll(manager.getIncomingStanzaHandlers());
      _incomingPreStanzaHandlers.addAll(manager.getIncomingPreStanzaHandlers());
      _outgoingPreStanzaHandlers.addAll(manager.getOutgoingPreStanzaHandlers());
      _outgoingPostStanzaHandlers
          .addAll(manager.getOutgoingPostStanzaHandlers());
    }

    // Sort them
    _incomingStanzaHandlers.sort(stanzaHandlerSortComparator);
    _incomingPreStanzaHandlers.sort(stanzaHandlerSortComparator);
    _outgoingPreStanzaHandlers.sort(stanzaHandlerSortComparator);
    _outgoingPostStanzaHandlers.sort(stanzaHandlerSortComparator);

    // Run the post register callbacks
    for (final manager in _xmppManagers.values) {
      if (!manager.initialized) {
        _log.finest('Running post-registration callback for ${manager.name}');
        await manager.postRegisterCallback();
      }
    }
  }

  // Mark the current connection as authenticated.
  void _setAuthenticated() {
    _sendEvent(AuthenticationSuccessEvent());
    _isAuthenticated = true;
  }

  /// Register a list of negotiator with the connection.
  Future<void> registerFeatureNegotiators(
    List<XmppFeatureNegotiatorBase> negotiators,
  ) async {
    for (final negotiator in negotiators) {
      _log.finest('Registering ${negotiator.id}');
      negotiator.register(
        NegotiatorAttributes(
          sendRawXML,
          () => this,
          () => connectionSettings,
          _sendEvent,
          _negotiationsHandler.getNegotiatorById,
          getManagerById,
          _getJidWithResource,
          () => _socket,
          () => _isAuthenticated,
          _setAuthenticated,
          setResource,
          _negotiationsHandler.removeNegotiatingFeature,
        ),
      );
      _negotiationsHandler.registerNegotiator(negotiator);
    }

    _log.finest('Negotiators registered');
    await _negotiationsHandler.runPostRegisterCallback();
  }

  /// Generate an Id suitable for an origin-id or stanza id
  String generateId() {
    return _uuid.v4();
  }

  /// Returns the Manager with id [id] or null if such a manager is not registered.
  T? getManagerById<T extends XmppManagerBase>(String id) =>
      _xmppManagers[id] as T?;

  /// A [PresenceManager] is required, so have a wrapper for getting it.
  /// Returns the registered [PresenceManager].
  PresenceManager? getPresenceManager() {
    return getManagerById(presenceManager);
  }

  /// Returns the registered [DiscoManager].
  DiscoManager? getDiscoManager() {
    return getManagerById<DiscoManager>(discoManager);
  }

  /// Returns the registered [RosterManager].
  RosterManager? getRosterManager() {
    return getManagerById<RosterManager>(rosterManager);
  }

  /// Returns the registered [StreamManagementManager], if one is registered.
  StreamManagementManager? getStreamManagementManager() {
    return getManagerById(smManager);
  }

  /// Returns the registered [CSIManager], if one is registered.
  CSIManager? getCSIManager() {
    return getManagerById(csiManager);
  }

  /// Attempts to reconnect to the server by following an exponential backoff.
  Future<void> _attemptReconnection() async {
    _log.finest('_attemptReconnection: Setting state to notConnected');
    await _setConnectionState(XmppConnectionState.notConnected);
    _log.finest('_attemptReconnection: Done');

    // Prevent the reconnection triggering another reconnection
    _socket.close();
    _log.finest('_attemptReconnection: Socket closed');

    // Connect again
    // ignore: cascade_invocations
    _log.finest('Calling _connectImpl() from _attemptReconnection');
    unawaited(
      _connectImpl(
        waitForConnection: true,
      ),
    );
  }

  /// Called when a stream ending error has occurred
  Future<void> handleError(XmppError error) async {
    _log.severe('handleError called with ${error.toString()}');

    // Whenever we encounter an error that would trigger a reconnection attempt while
    // the connection result is being awaited, don't attempt a reconnection but instead
    // try to gracefully disconnect.
    if (_connectionCompleter != null) {
      _log.info(
        'Not triggering reconnection since connection result is being awaited',
      );
      await _disconnect(
        triggeredByUser: false,
        state: XmppConnectionState.error,
      );
      _connectionCompleter?.complete(
        Result(
          error,
        ),
      );
      _connectionCompleter = null;
      return;
    }

    // Close the socket
    _socket.close();

    if (!error.isRecoverable()) {
      // We cannot recover this error
      _log.severe(
        'Since a $error is not recoverable, not attempting a reconnection',
      );
      await _setConnectionState(XmppConnectionState.error);
      await _sendEvent(
        NonRecoverableErrorEvent(error),
      );
      return;
    }

    // The error is recoverable
    await _setConnectionState(XmppConnectionState.notConnected);

    if (await _reconnectionPolicy.canTriggerFailure()) {
      await _reconnectionPolicy.onFailure();
    } else {
      _log.info(
        'Not passing connection failure to reconnection policy as it indicates that we should not reconnect',
      );
    }
  }

  /// Called whenever the socket creates an event
  @visibleForTesting
  Future<void> handleSocketEvent(XmppSocketEvent event) async {
    if (event is XmppSocketErrorEvent) {
      await handleError(SocketError(event));
    } else if (event is XmppSocketClosureEvent) {
      if (!event.expected) {
        _log.fine(
          'Received unexpected XmppSocketClosureEvent. Reconnecting...',
        );
        await handleError(SocketError(XmppSocketErrorEvent(event)));
      } else {
        _log.fine(
          'Received XmppSocketClosureEvent. No reconnection attempt since _socketClosureTriggersReconnect is false...',
        );
      }
    }
  }

  /// NOTE: For debugging purposes only
  /// Returns the internal state of the state machine
  RoutingState getRoutingState() {
    return _routingState;
  }

  /// Returns the ConnectionState of the connection
  Future<XmppConnectionState> getConnectionState() async {
    return _connectionState;
  }

  /// Sends an [XMLNode] without any further processing to the server.
  void sendRawXML(XMLNode node) {
    final string = node.toXml();
    _log.finest('==> $string');
    _socket.write(string);
  }

  /// Sends [raw] to the server.
  void sendRawString(String raw) {
    _socket.write(raw);
  }

  /// Returns true if we can send data through the socket.
  Future<bool> _canSendData() async {
    return await getConnectionState() == XmppConnectionState.connected;
  }

  /// Sends a stanza described by [details] to the server. Until sent, the stanza is
  /// kept in a queue, that is flushed after going online again. If Stream Management
  /// is active, stanza's acknowledgement is tracked.
  // TODO(Unknown): if addId = false, the function crashes.
  Future<XMLNode?> sendStanza(StanzaDetails details) async {
    assert(
      implies(
        details.awaitable,
        details.stanza.id != null && details.stanza.id!.isNotEmpty ||
            details.addId,
      ),
      'An awaitable stanza must have an id',
    );

    final completer = details.awaitable ? Completer<XMLNode>() : null;
    final entry = StanzaQueueEntry(
      details,
      completer,
    );

    if (details.bypassQueue) {
      await _sendStanzaImpl(entry);
    } else {
      await _stanzaQueue.enqueueStanza(entry);
    }

    return completer?.future;
  }

  Future<void> _sendStanzaImpl(StanzaQueueEntry entry) async {
    final details = entry.details;
    var newStanza = details.stanza;

    // Generate an id, if requested
    if (details.addId && (newStanza.id == null || newStanza.id == '')) {
      newStanza = newStanza.copyWith(id: generateId());
    }

    // NOTE: Originally, we handled adding a "from" attribute to the stanza here.
    //       However, this is not neccessary as RFC 6120 states:
    //
    //       > When a server receives an XML stanza from a connected client, the
    //       > server MUST add a 'from' attribute to the stanza or override the
    //       > 'from' attribute specified by the client, where the value of the
    //       > 'from' attribute MUST be the full JID
    //       > (<localpart@domainpart/resource>) determined by the server for
    //       > the connected resource that generated the stanza (see
    //       > Section 4.3.6), or the bare JID (<localpart@domainpart>) in the
    //       > case of subscription-related presence stanzas (see [XMPP-IM]).
    //
    //       This means that even if we add a "from" attribute, the server will discard
    //       it. If we don't specify it, then the server will add the correct value
    //       itself.

    // Add the correct stanza namespace
    newStanza = newStanza.copyWith(
      xmlns: _negotiationsHandler.getStanzaNamespace(),
    );

    // Run pre-send handlers
    _log.fine('Running pre stanza handlers..');
    final data = await _runOutgoingPreStanzaHandlers(
      newStanza,
      initial: StanzaHandlerData(
        false,
        false,
        newStanza,
        TypedMap(),
        encrypted: details.encrypted,
        forceEncryption: details.forceEncryption,
      ),
    );
    _log.fine('Done');

    // Cancel sending, if the pre-send handlers indicated it.
    if (data.cancel) {
      _log.fine('A stanza handler indicated that it wants to cancel sending.');
      await _sendEvent(StanzaSendingCancelledEvent(data));

      // Resolve the future, if one was given.
      if (details.awaitable) {
        entry.completer!.complete(
          Stanza(
            tag: data.stanza.tag,
            to: data.stanza.from,
            from: data.stanza.to,
            attributes: <String, String>{
              'type': 'error',
              if (data.stanza.id != null) 'id': data.stanza.id!,
            },
          ),
        );
      }
      return;
    }

    // Log the (raw) stanza
    final prefix = data.encrypted ? '(Encrypted) ' : '';
    _log.finest('==> $prefix${newStanza.toXml()}');

    if (details.awaitable) {
      await _stanzaAwaiter
          .addPending(
        // A stanza with no to attribute is for direct processing by the server. As such,
        // we can correlate it by just *assuming* we have that attribute
        // (RFC 6120 Section 8.1.1.1)
        data.stanza.to ?? connectionSettings.jid.toBare().toString(),
        data.stanza.id!,
        data.stanza.tag,
      )
          .then((result) {
        entry.completer!.complete(result);
      });
    }

    if (await _canSendData()) {
      _socket.write(data.stanza.toXml());
    } else {
      _log.fine('Not sending data as _canSendData() returned false.');
    }

    // Run post-send handlers
    _log.fine('Running post stanza handlers..');
    final extensions = TypedMap<StanzaHandlerExtension>()
      ..set(StreamManagementData(details.excludeFromStreamManagement));
    await _runOutgoingPostStanzaHandlers(
      newStanza,
      initial: StanzaHandlerData(
        false,
        false,
        newStanza,
        extensions,
      ),
    );
    _log.fine('Done');
  }

  /// Called when we timeout during connecting
  Future<void> _onConnectingTimeout() async {
    _log.severe('Connection stuck in "connecting". Causing a reconnection...');
    await handleError(TimeoutError());
  }

  void _destroyConnectingTimer() {
    if (_connectingTimeoutTimer != null) {
      _connectingTimeoutTimer!.cancel();
      _connectingTimeoutTimer = null;

      _log.finest('Destroying connecting timeout timer...');
    }
  }

  /// Called once all negotiations are done. Sends the initial presence, performs
  /// a disco sweep among other things.
  Future<void> _onNegotiationsDone() async {
    // Set the new routing state
    _updateRoutingState(RoutingState.handleStanzas);

    // Enable reconnections
    if (_enableReconnectOnSuccess) {
      await _reconnectionPolicy.setShouldReconnect(true);
    }

    // Tell consumers of the event stream that we're done with stream feature
    // negotiations
    await _sendEvent(
      StreamNegotiationsDoneEvent(
        getManagerById<StreamManagementManager>(smManager)?.streamResumed ??
            false,
      ),
    );

    // Set the connection state
    await _setConnectionState(XmppConnectionState.connected);

    // Resolve the connection completion future
    _connectionCompleter?.complete(const Result(true));
    _connectionCompleter = null;

    // Flush the stanza send queue
    await _stanzaQueue.restart();
  }

  /// Sets the connection state to [state] and triggers an event of type
  /// [ConnectionStateChangedEvent].
  Future<void> _setConnectionState(XmppConnectionState state) async {
    // Ignore changes that are not really changes.
    if (state == _connectionState) return;

    _log.finest('Updating _connectionState from $_connectionState to $state');
    final oldState = _connectionState;
    _connectionState = state;

    if (state == XmppConnectionState.connected) {
      // We are connected, so the timer can stop.
      _destroyConnectingTimer();
    } else if (state == XmppConnectionState.connecting) {
      // Make sure it is not running...
      _destroyConnectingTimer();

      // ...and start it.
      _log.finest('Starting connecting timeout timer...');
      _connectingTimeoutTimer = Timer(connectingTimeout, _onConnectingTimeout);
    } else {
      // Just make sure the connecting timeout timer is not running
      _destroyConnectingTimer();
    }

    await _sendEvent(
      ConnectionStateChangedEvent(
        state,
        oldState,
      ),
    );
  }

  /// Sets the routing state and logs the change
  void _updateRoutingState(RoutingState state) {
    _log.finest('Updating _routingState from $_routingState to $state');
    _routingState = state;
  }

  /// Sets the resource of the connection
  @visibleForTesting
  void setResource(String resource, {bool triggerEvent = true}) {
    _log.finest('Updating _resource to $resource');
    _resource = resource;

    if (triggerEvent) {
      _sendEvent(ResourceBoundEvent(resource));
    }
  }

  /// Returns the connection's events as a stream.
  Stream<XmppEvent> asBroadcastStream() {
    return _eventStreamController.stream.asBroadcastStream();
  }

  /// Iterate over [handlers] and check if the handler matches [stanza]. If it does,
  /// call its callback and end the processing if the callback returned true; continue
  /// if it returned false.
  Future<StanzaHandlerData> _runStanzaHandlers(
    List<StanzaHandler> handlers,
    Stanza stanza, {
    StanzaHandlerData? initial,
  }) async {
    var state = initial ?? StanzaHandlerData(false, false, stanza, TypedMap());
    for (final handler in handlers) {
      if (handler.matches(state.stanza)) {
        state = await handler.callback(state.stanza, state);
        if (state.done || state.cancel) return state;
      }
    }

    return state;
  }

  Future<StanzaHandlerData> _runIncomingStanzaHandlers(
    Stanza stanza, {
    StanzaHandlerData? initial,
  }) async {
    return _runStanzaHandlers(
      _incomingStanzaHandlers,
      stanza,
      initial: initial,
    );
  }

  Future<StanzaHandlerData> _runIncomingPreStanzaHandlers(Stanza stanza) async {
    return _runStanzaHandlers(_incomingPreStanzaHandlers, stanza);
  }

  Future<StanzaHandlerData> _runOutgoingPreStanzaHandlers(
    Stanza stanza, {
    StanzaHandlerData? initial,
  }) async {
    return _runStanzaHandlers(
      _outgoingPreStanzaHandlers,
      stanza,
      initial: initial,
    );
  }

  Future<bool> _runOutgoingPostStanzaHandlers(
    Stanza stanza, {
    StanzaHandlerData? initial,
  }) async {
    final data = await _runStanzaHandlers(
      _outgoingPostStanzaHandlers,
      stanza,
      initial: initial,
    );
    return data.done;
  }

  /// Called whenever we receive a stanza after resource binding or stream resumption.
  Future<void> _handleStanza(XMLNode nonza) async {
    // Process nonzas separately
    if (!['message', 'iq', 'presence'].contains(nonza.tag)) {
      _log.finest('<== ${nonza.toXml()}');

      var nonzaHandled = false;
      await Future.forEach(_xmppManagers.values,
          (XmppManagerBase manager) async {
        final handled = await manager.runNonzaHandlers(nonza);

        if (!nonzaHandled && handled) nonzaHandled = true;
      });

      if (!nonzaHandled) {
        _log.warning('Unhandled nonza received: ${nonza.toXml()}');
      }
      return;
    }

    final stanza = Stanza.fromXMLNode(nonza);

    // Run the incoming stanza handlers and bounce with an error if no manager handled
    // it.
    final incomingPreHandlers = await _runIncomingPreStanzaHandlers(stanza);
    final prefix = incomingPreHandlers.encrypted &&
            incomingPreHandlers.encryptionError == null
        ? '(Encrypted) '
        : '';
    _log.finest('<== $prefix${incomingPreHandlers.stanza.toXml()}');

    final awaited = await _stanzaAwaiter.onData(
      incomingPreHandlers.stanza,
      connectionSettings.jid.toBare(),
    );
    if (awaited) {
      return;
    }

    // Only bounce if the stanza has neither been awaited, nor handled.
    final incomingHandlers = await _runIncomingStanzaHandlers(
      incomingPreHandlers.stanza,
      initial: StanzaHandlerData(
        false,
        incomingPreHandlers.cancel,
        incomingPreHandlers.stanza,
        incomingPreHandlers.extensions,
        encrypted: incomingPreHandlers.encrypted,
        cancelReason: incomingPreHandlers.cancelReason,
      ),
    );
    if (!incomingHandlers.done) {
      _log.warning(
        'Returning error for unhandled stanza ${incomingPreHandlers.stanza.tag}',
      );
      await handleUnhandledStanza(this, incomingPreHandlers);
    }
  }

  /// Called whenever we receive data that has been parsed as XML.
  Future<void> handleXmlStream(XMPPStreamObject event) async {
    if (event is XMPPStreamHeader) {
      await _negotiationsHandler.negotiate(event);
      return;
    }

    assert(
      event is XMPPStreamElement,
      'The event must be a XMPPStreamElement',
    );
    final node = (event as XMPPStreamElement).node;

    // Check if we received a stream error
    if (node.tag == 'stream:error') {
      _log
        ..finest('<== ${node.toXml()}')
        ..severe('Received a stream error! Attempting reconnection');
      await handleError(StreamError());

      return;
    }

    switch (_routingState) {
      case RoutingState.negotiating:
        _log.finest('<== ${node.toXml()}');

        // Why lock here? The problem is that if we do stream resumption, then we might
        // receive "<resumed .../><iq .../>...", which will all be fed into the negotiator,
        // causing (a) the negotiator to become confused and (b) the stanzas/nonzas to be
        // missed. This causes the data to wait while the negotiator is running and thus
        // prevent this issue.
        await _negotiationLock.synchronized(() async {
          if (_routingState != RoutingState.negotiating) {
            unawaited(handleXmlStream(event));
            return;
          }

          await _negotiationsHandler.negotiate(event);
        });
        break;
      case RoutingState.handleStanzas:
        await _handleStanza(node);
        break;
      case RoutingState.preConnection:
      case RoutingState.error:
        _log.warning('Received data while in non-receiving state');
        break;
    }
  }

  /// Sends an empty String over the socket.
  void sendWhitespacePing() {
    _socket.write('');
  }

  /// Sends an event to the connection's event stream.
  Future<void> _sendEvent(XmppEvent event) async {
    for (final manager in _xmppManagers.values) {
      await manager.onXmppEvent(event);
    }
    await _negotiationsHandler.sendEventToNegotiators(event);

    _eventStreamController.add(event);
  }

  /// Attempt to gracefully close the session
  Future<void> disconnect() async {
    await _disconnect(state: XmppConnectionState.notConnected);
  }

  Future<void> _disconnect({
    required XmppConnectionState state,
    bool triggeredByUser = true,
  }) async {
    await _reconnectionPolicy.setShouldReconnect(false);

    if (triggeredByUser) {
      await getPresenceManager()?.sendUnavailablePresence();
    }

    _socket.prepareDisconnect();

    if (triggeredByUser) {
      sendRawString('</stream:stream>');
    }

    await _setConnectionState(state);
    _socket.close();

    if (triggeredByUser) {
      // Clear Stream Management state, if available
      await getStreamManagementManager()?.resetState();
    }
  }

  /// The private implementation for [XmppConnection.connect]. The parameters have
  /// the same meaning as with [XmppConnection.connect].
  Future<Result<bool, XmppError>> _connectImpl({
    bool waitForConnection = false,
    bool shouldReconnect = true,
    bool waitUntilLogin = false,
    bool enableReconnectOnSuccess = true,
  }) async {
    // Kill a possibly existing connection
    _socket.close();

    await _reconnectionPolicy.reset();
    _enableReconnectOnSuccess = enableReconnectOnSuccess;
    if (shouldReconnect) {
      await _reconnectionPolicy.setShouldReconnect(true);
    } else {
      await _reconnectionPolicy.setShouldReconnect(false);
    }
    await _sendEvent(ConnectingEvent());

    if (waitUntilLogin) {
      _log.finest('Setting up completer for awaiting completed login');
      _connectionCompleter = Completer();
    }

    // Reset the resource. If we use stream resumption from XEP-0198, then the
    // manager will set it on successful resumption.
    setResource('', triggerEvent: false);

    // If requested, wait until we have a network connection
    if (waitForConnection) {
      _log.info('Waiting for okay from connectivityManager');
      await _connectivityManager.waitForConnection();
      _log.info('Got okay from connectivityManager');
    }

    // Reset the stream parser
    _streamParser.reset();

    final smManager = getStreamManagementManager();
    var host = connectionSettings.host;
    var port = connectionSettings.port;
    if (smManager?.state.streamResumptionLocation != null) {
      // TODO(Unknown): Maybe wrap this in a try catch?
      final parsed = Uri.parse(smManager!.state.streamResumptionLocation!);
      host = parsed.host;
      port = parsed.port;
    }

    final result = await _socket.connect(
      connectionSettings.jid.domain,
      host: host,
      port: port,
    );
    if (!result) {
      await handleError(NoConnectionPossibleError());

      return Result(NoConnectionPossibleError());
    } else {
      await _reconnectionPolicy.onSuccess();
      _log.fine('Preparing the internal state for a connection attempt');
      _negotiationsHandler.reset();
      await _setConnectionState(XmppConnectionState.connecting);
      _updateRoutingState(RoutingState.negotiating);
      _isAuthenticated = false;
      _negotiationsHandler.sendStreamHeader();

      if (waitUntilLogin) {
        return _connectionCompleter!.future;
      } else {
        return const Result(true);
      }
    }
  }

  /// Start the connection process using the provided connection settings.
  ///
  /// [shouldReconnect] indicates whether the reconnection attempts should be
  /// automatically performed after a fatal failure of any kind occurs.
  ///
  /// [waitForConnection] indicates whether the connection should wait for the "go"
  /// signal from a registered connectivity manager.
  ///
  /// If [waitUntilLogin] is set to true, the future will resolve when either
  /// the connection has been successfully established (authentication included) or
  /// a failure occured. If set to false, then the future will immediately resolve
  /// to true.
  ///
  /// [enableReconnectOnSuccess] indicates that automatic reconnection is to be
  /// enabled once the connection has been successfully established.
  Future<Result<bool, XmppError>> connect({
    bool? shouldReconnect,
    bool waitForConnection = false,
    bool waitUntilLogin = false,
    bool enableReconnectOnSuccess = true,
  }) async {
    final result = _connectImpl(
      shouldReconnect: shouldReconnect ?? !waitUntilLogin,
      waitForConnection: waitForConnection,
      waitUntilLogin: waitUntilLogin,
      enableReconnectOnSuccess: enableReconnectOnSuccess,
    );
    if (waitUntilLogin) {
      return result;
    } else {
      return Future.value(
        const Result(
          true,
        ),
      );
    }
  }
}
