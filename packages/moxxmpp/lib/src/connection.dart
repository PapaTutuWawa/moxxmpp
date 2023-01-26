import 'dart:async';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:moxlib/moxlib.dart';
import 'package:moxxmpp/src/awaiter.dart';
import 'package:moxxmpp/src/buffer.dart';
import 'package:moxxmpp/src/connectivity.dart';
import 'package:moxxmpp/src/errors.dart';
import 'package:moxxmpp/src/events.dart';
import 'package:moxxmpp/src/iq.dart';
import 'package:moxxmpp/src/managers/attributes.dart';
import 'package:moxxmpp/src/managers/base.dart';
import 'package:moxxmpp/src/managers/data.dart';
import 'package:moxxmpp/src/managers/handlers.dart';
import 'package:moxxmpp/src/managers/namespaces.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/negotiators/namespaces.dart';
import 'package:moxxmpp/src/negotiators/negotiator.dart';
import 'package:moxxmpp/src/presence.dart';
import 'package:moxxmpp/src/reconnect.dart';
import 'package:moxxmpp/src/roster/roster.dart';
import 'package:moxxmpp/src/routing.dart';
import 'package:moxxmpp/src/settings.dart';
import 'package:moxxmpp/src/socket.dart';
import 'package:moxxmpp/src/stanza.dart';
import 'package:moxxmpp/src/stringxml.dart';
import 'package:moxxmpp/src/xeps/xep_0030/xep_0030.dart';
import 'package:moxxmpp/src/xeps/xep_0198/negotiator.dart';
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

/// Metadata for [XmppConnection.sendStanza].
enum StanzaFromType {
  /// Add the full JID to the stanza as the from attribute
  full,

  /// Add the bare JID to the stanza as the from attribute
  bare,

  /// Add no JID as the from attribute
  none,
}

/// Nonza describing the XMPP stream header.
class StreamHeaderNonza extends XMLNode {
  StreamHeaderNonza(String serverDomain) : super(
      tag: 'stream:stream',
      attributes: <String, String>{
        'xmlns': stanzaXmlns,
        'version': '1.0',
        'xmlns:stream': streamXmlns,
        'to': serverDomain,
        'xml:lang': 'en',
      },
      closeTag: false,
    );
}

/// The result of an awaited connection.
class XmppConnectionResult {
  const XmppConnectionResult(
    this.success,
    {
      this.error,
    }
  );

  /// True if the connection was successful. False if it failed for any reason.
  final bool success;

  // If a connection attempt fails, i.e. success is false, then this indicates the
  // reason the connection failed.
  final XmppError? error;
}

/// This class is a connection to the server.
class XmppConnection {
  XmppConnection(
    ReconnectionPolicy reconnectionPolicy,
    ConnectivityManager connectivityManager,
    this._socket,
    {
      this.connectionPingDuration = const Duration(minutes: 3),
      this.connectingTimeout = const Duration(minutes: 2),
    }
  ) : _reconnectionPolicy = reconnectionPolicy,
      _connectivityManager = connectivityManager {
    // Allow the reconnection policy to perform reconnections by itself
    _reconnectionPolicy.register(
      _attemptReconnection,
      _onNetworkConnectionLost,
    );

    _socketStream = _socket.getDataStream();
    // TODO(Unknown): Handle on done
    _socketStream.transform(_streamBuffer).forEach(handleXmlStream);
    _socket.getEventStream().listen(_handleSocketEvent);
  }


  /// The state that the connection is currently in
  XmppConnectionState _connectionState = XmppConnectionState.notConnected;

  /// The socket that we are using for the connection and its data stream
  final BaseSocketWrapper _socket;

  /// The data stream of the socket
  late final Stream<String> _socketStream;

  /// Connection settings
  late ConnectionSettings _connectionSettings;

  /// A policy on how to reconnect 
  final ReconnectionPolicy _reconnectionPolicy;

  /// The class responsible for preventing errors on initial connection due
  /// to no network.
  final ConnectivityManager _connectivityManager;

  /// A helper for handling await semantics with stanzas
  final StanzaAwaiter _stanzaAwaiter = StanzaAwaiter();
  
  /// Sorted list of handlers that we call or incoming and outgoing stanzas
  final List<StanzaHandler> _incomingStanzaHandlers = List.empty(growable: true);
  final List<StanzaHandler> _incomingPreStanzaHandlers = List.empty(growable: true);
  final List<StanzaHandler> _outgoingPreStanzaHandlers = List.empty(growable: true);
  final List<StanzaHandler> _outgoingPostStanzaHandlers = List.empty(growable: true);
  final StreamController<XmppEvent> _eventStreamController = StreamController.broadcast();
  final Map<String, XmppManagerBase> _xmppManagers = {};
  
  /// Disco info we got after binding a resource (xmlns)
  final List<String> _serverFeatures = List.empty(growable: true);

  /// The buffer object to keep split up stanzas together
  final XmlStreamBuffer _streamBuffer = XmlStreamBuffer();

  /// UUID object to generate stanza and origin IDs
  final Uuid _uuid = const Uuid();

  /// The time between sending a ping to keep the connection open
  // TODO(Unknown): Only start the timer if we did not send a stanza after n seconds
  final Duration connectionPingDuration;

  /// The time that we may spent in the "connecting" state
  final Duration connectingTimeout;

  /// The current state of the connection handling state machine.
  RoutingState _routingState = RoutingState.preConnection;

  /// The currently bound resource or '' if none has been bound yet.
  String _resource = '';

  /// True if we are authenticated. False if not.
  bool _isAuthenticated = false;

  /// Timer for the keep-alive ping.
  Timer? _connectionPingTimer;

  /// Timer for the connecting timeout
  Timer? _connectingTimeoutTimer;

  /// Completers for certain actions
  // ignore: use_late_for_private_fields_and_variables
  Completer<XmppConnectionResult>? _connectionCompleter;

  /// Negotiators
  final Map<String, XmppFeatureNegotiatorBase> _featureNegotiators = {};
  XmppFeatureNegotiatorBase? _currentNegotiator;
  final List<XMLNode> _streamFeatures = List.empty(growable: true);
  /// Prevent data from being passed to _currentNegotiator.negotiator while the negotiator
  /// is still running.
  final Lock _negotiationLock = Lock();
  
  /// The logger for the class
  final Logger _log = Logger('XmppConnection');

  /// A value indicating whether a connection attempt is currently running or not
  bool _isConnectionRunning = false;
  final Lock _connectionRunningLock = Lock();

  /// Enters the critical section for accessing [XmppConnection._isConnectionRunning]
  /// and does the following:
  /// - if _isConnectionRunning is false, set it to true and return false.
  /// - if _isConnectionRunning is true, return true.
  Future<bool> _testAndSetIsConnectionRunning() async => _connectionRunningLock.synchronized(() {
    if (!_isConnectionRunning) {
      _isConnectionRunning = true;
      return false;
    }

    return true;
  });

  /// Enters the critical section for accessing [XmppConnection._isConnectionRunning]
  /// and sets it to false.
  Future<void> _resetIsConnectionRunning() async => _connectionRunningLock.synchronized(() => _isConnectionRunning = false);
  
  ReconnectionPolicy get reconnectionPolicy => _reconnectionPolicy;
  
  List<String> get serverFeatures => _serverFeatures;

  bool get isAuthenticated => _isAuthenticated;
  
  /// Return the registered feature negotiator that has id [id]. Returns null if
  /// none can be found.
  T? getNegotiatorById<T extends XmppFeatureNegotiatorBase>(String id) => _featureNegotiators[id] as T?;
  
  /// Registers an [XmppManagerBase] sub-class as a manager on this connection.
  /// [sortHandlers] should NOT be touched. It specified if the handler priorities
  /// should be set up. The only time this should be false is when called via
  /// [registerManagers].
  void registerManager(XmppManagerBase manager, { bool sortHandlers = true }) {
    _log.finest('Registering ${manager.getId()}');
    manager.register(
      XmppManagerAttributes(
        sendStanza: sendStanza,
        sendNonza: sendRawXML,
        sendEvent: _sendEvent,
        getConnectionSettings: () => _connectionSettings,
        getManagerById: getManagerById,
        isFeatureSupported: _serverFeatures.contains,
        getFullJID: () => _connectionSettings.jid.withResource(_resource),
        getSocket: () => _socket,
        getConnection: () => this,
        getNegotiatorById: getNegotiatorById,
      ),
    );

    final id = manager.getId();
    _xmppManagers[id] = manager;

    if (id == discoManager) {
      // NOTE: It is intentional that we do not exclude the [DiscoManager] from this
      //       loop. It may also register features.
      for (final registeredManager in _xmppManagers.values) {
        (manager as DiscoManager).addDiscoFeatures(registeredManager.getDiscoFeatures());
      }
    } else if (_xmppManagers.containsKey(discoManager)) {
      (_xmppManagers[discoManager]! as DiscoManager).addDiscoFeatures(manager.getDiscoFeatures());
    }

    _incomingStanzaHandlers.addAll(manager.getIncomingStanzaHandlers());
    _incomingPreStanzaHandlers.addAll(manager.getIncomingPreStanzaHandlers());
    _outgoingPreStanzaHandlers.addAll(manager.getOutgoingPreStanzaHandlers());
    _outgoingPostStanzaHandlers.addAll(manager.getOutgoingPostStanzaHandlers());
    
    if (sortHandlers) {
      _incomingStanzaHandlers.sort(stanzaHandlerSortComparator);
      _incomingPreStanzaHandlers.sort(stanzaHandlerSortComparator);
      _outgoingPreStanzaHandlers.sort(stanzaHandlerSortComparator);
      _outgoingPostStanzaHandlers.sort(stanzaHandlerSortComparator);
    }
  }

  /// Like [registerManager], but for a list of managers.
  void registerManagers(List<XmppManagerBase> managers) {
    for (final manager in managers) {
      registerManager(manager, sortHandlers: false);
    }

    // Sort them
    _incomingStanzaHandlers.sort(stanzaHandlerSortComparator);
    _outgoingPreStanzaHandlers.sort(stanzaHandlerSortComparator);
    _outgoingPostStanzaHandlers.sort(stanzaHandlerSortComparator);
  }
  
  /// Register a list of negotiator with the connection.
  void registerFeatureNegotiators(List<XmppFeatureNegotiatorBase> negotiators) {
    for (final negotiator in negotiators) {
      _log.finest('Registering ${negotiator.id}');
      negotiator.register(
        NegotiatorAttributes(
          sendRawXML,
          () => _connectionSettings,
          _sendEvent,
          getNegotiatorById,
          getManagerById,
          () => _connectionSettings.jid.withResource(_resource),
          () => _socket,
          () => _isAuthenticated,
        ),
      );
      _featureNegotiators[negotiator.id] = negotiator;
    }

    _log.finest('Negotiators registered');
  }

  /// Reset all registered negotiators.
  void _resetNegotiators() {
    for (final negotiator in _featureNegotiators.values) {
      negotiator.reset();
    }

    // Prevent leaking the last active negotiator
    _currentNegotiator = null;
  }
  
  /// Generate an Id suitable for an origin-id or stanza id
  String generateId() {
    return _uuid.v4();
  }
  
  /// Returns the Manager with id [id] or null if such a manager is not registered.
  T? getManagerById<T extends XmppManagerBase>(String id) => _xmppManagers[id] as T?;

  /// A [PresenceManager] is required, so have a wrapper for getting it.
  /// Returns the registered [PresenceManager].
  PresenceManager getPresenceManager() {
    assert(_xmppManagers.containsKey(presenceManager), 'A PresenceManager is mandatory');

    return getManagerById(presenceManager)!;
  }

  /// A [DiscoManager] is required so, have a wrapper for getting it.
  /// Returns the registered [DiscoManager].
  DiscoManager getDiscoManager() {
    assert(_xmppManagers.containsKey(discoManager), 'A DiscoManager is mandatory');

    return getManagerById(discoManager)!;
  }

  /// A [RosterManager] is required, so have a wrapper for getting it.
  /// Returns the registered [RosterManager].
  RosterManager getRosterManager() {
    assert(_xmppManagers.containsKey(rosterManager), 'A RosterManager is mandatory');

    return getManagerById(rosterManager)!;
  }
  
  /// Returns the registered [StreamManagementManager], if one is registered.
  StreamManagementManager? getStreamManagementManager() {
    return getManagerById(smManager);
  }

  /// Returns the registered [CSIManager], if one is registered.
  CSIManager? getCSIManager() {
    return getManagerById(csiManager);
  }
  
  /// Set the connection settings of this connection.
  void setConnectionSettings(ConnectionSettings settings) {
    _connectionSettings = settings;
  }

  /// Returns the connection settings of this connection.
  ConnectionSettings getConnectionSettings() {
    return _connectionSettings;
  }

  /// Attempts to reconnect to the server by following an exponential backoff.
  Future<void> _attemptReconnection() async {
    if (await _testAndSetIsConnectionRunning()) {
      _log.warning('_attemptReconnection is called but connection attempt is already running. Ignoring...');
      return;
    }

    _log.finest('_attemptReconnection: Setting state to notConnected');
    await _setConnectionState(XmppConnectionState.notConnected);
    _log.finest('_attemptReconnection: Done');

    // Prevent the reconnection triggering another reconnection
    _socket.close();
    _log.finest('_attemptReconnection: Socket closed');

    // Connect again
    // ignore: cascade_invocations
    _log.finest('Calling connect() from _attemptReconnection');
    await connect(waitForConnection: true);
  }
  
  /// Called when a stream ending error has occurred
  Future<void> handleError(XmppError error) async {
    _log.severe('handleError called with ${error.toString()}');

    // Whenever we encounter an error that would trigger a reconnection attempt while
    // the connection result is being awaited, don't attempt a reconnection but instead
    // try to gracefully disconnect.
    if (_connectionCompleter != null) {
      _log.info('Not triggering reconnection since connection result is being awaited');
      await _disconnect(triggeredByUser: false, state: XmppConnectionState.error);
      _connectionCompleter?.complete(
        XmppConnectionResult(
          false,
          error: error,
        ),
      );
      _connectionCompleter = null;
      return;
    }

    if (await _connectivityManager.hasConnection()) {
      await _setConnectionState(XmppConnectionState.error);
    } else {
      await _setConnectionState(XmppConnectionState.notConnected);
    }
    await _reconnectionPolicy.onFailure();
  }

  /// Called whenever the socket creates an event
  Future<void> _handleSocketEvent(XmppSocketEvent event) async {
    if (event is XmppSocketErrorEvent) {
      await handleError(SocketError(event));
    } else if (event is XmppSocketClosureEvent) {
      if (!event.expected) {
        _log.fine('Received unexpected XmppSocketClosureEvent. Reconnecting...');
        await handleError(SocketError(XmppSocketErrorEvent(event)));
      } else {
        _log.fine('Received XmppSocketClosureEvent. No reconnection attempt since _socketClosureTriggersReconnect is false...');
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
  void sendRawXML(XMLNode node, { String? redact }) {
    final string = node.toXml();
    _log.finest('==> $string');
    _socket.write(string, redact: redact);
  }

  /// Sends [raw] to the server.
  void sendRawString(String raw) {
    _socket.write(raw);
  }
  
  /// Returns true if we can send data through the socket.
  Future<bool> _canSendData() async {
    return [
      XmppConnectionState.connected,
      XmppConnectionState.connecting
    ].contains(await getConnectionState());
  }
  
  /// Sends a [stanza] to the server. If stream management is enabled, then keeping track
  /// of the stanza is taken care of. Returns a Future that resolves when we receive a
  /// response to the stanza.
  ///
  /// If addFrom is true, then a 'from' attribute will be added to the stanza if
  /// [stanza] has none.
  /// If addId is true, then an 'id' attribute will be added to the stanza if [stanza] has
  /// none.
  // TODO(Unknown): if addId = false, the function crashes.
  Future<XMLNode> sendStanza(Stanza stanza, { StanzaFromType addFrom = StanzaFromType.full, bool addId = true, bool awaitable = true, bool encrypted = false, bool forceEncryption = false, }) async {
    assert(implies(addId == false && stanza.id == null, !awaitable), 'Cannot await a stanza with no id');

    // Add extra data in case it was not set
    var stanza_ = stanza;
    if (addId && (stanza_.id == null || stanza_.id == '')) {
      stanza_ = stanza.copyWith(id: generateId());
    }
    if (addFrom != StanzaFromType.none && (stanza_.from == null || stanza_.from == '')) {
      switch (addFrom) {
        case StanzaFromType.full: {
          stanza_ = stanza_.copyWith(from: _connectionSettings.jid.withResource(_resource).toString());
        }
        break;
        case StanzaFromType.bare: {
          stanza_ = stanza_.copyWith(from: _connectionSettings.jid.toBare().toString());
        }
        break;
        case StanzaFromType.none: break;
      }
    }

    _log.fine('Running pre stanza handlers..');
    final data = await _runOutgoingPreStanzaHandlers(
      stanza_,
      initial: StanzaHandlerData(
        false,
        false,
        null,
        stanza_,
        encrypted: encrypted,
        forceEncryption: forceEncryption,
      ),
    );
    _log.fine('Done');

    if (data.cancel) {
      _log.fine('A stanza handler indicated that it wants to cancel sending.');
      await _sendEvent(StanzaSendingCancelledEvent(data));
      return Stanza(
        tag: data.stanza.tag,
        to: data.stanza.from,
        from: data.stanza.to,
        attributes: <String, String>{
          'type': 'error',
          ...data.stanza.id != null ? {
            'id': data.stanza.id!,
          } : {},
        },
      );
    }

    final prefix = data.encrypted ?
      '(Encrypted) ' :
      '';
    _log.finest('==> $prefix${stanza_.toXml()}');

    final stanzaString = data.stanza.toXml();

    // ignore: cascade_invocations
    _log.fine('Attempting to acquire lock for ${data.stanza.id}...');
    // TODO(PapaTutuWawa): Handle this much more graceful
    var future = Future.value(XMLNode(tag: 'not-used'));
    if (awaitable) {
      future = await _stanzaAwaiter.addPending(
        // A stanza with no to attribute is for direct processing by the server. As such,
        // we can correlate it by just *assuming* we have that attribute
        // (RFC 6120 Section 8.1.1.1)
        data.stanza.to ?? _connectionSettings.jid.toBare().toString(),
        data.stanza.id!,
        data.stanza.tag,
      );
    }

    // This uses the StreamManager to behave like a send queue
    if (await _canSendData()) {
      _socket.write(stanzaString);

      // Try to ack every stanza
      // NOTE: Here we have send an Ack request nonza. This is now done by StreamManagementManager when receiving the StanzaSentEvent
    } else {
      _log.fine('_canSendData() returned false.');
    }

    _log.fine('Running post stanza handlers..');
    await _runOutgoingPostStanzaHandlers(
      stanza_,
      initial: StanzaHandlerData(
        false,
        false,
        null,
        stanza_,
      ),
    );
    _log.fine('Done');

    return future;
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
  
  /// Sets the connection state to [state] and triggers an event of type
  /// [ConnectionStateChangedEvent].
  Future<void> _setConnectionState(XmppConnectionState state) async {
    // Ignore changes that are not really changes.
    if (state == _connectionState) return;
    
    _log.finest('Updating _connectionState from $_connectionState to $state');
    final oldState = _connectionState;
    _connectionState = state;

    final sm = getNegotiatorById<StreamManagementNegotiator>(streamManagementNegotiator);
    await _sendEvent(
      ConnectionStateChangedEvent(
        state,
        oldState,
        sm?.isResumed ?? false,
      ),
    );
    
    if (state == XmppConnectionState.connected) {
      _log.finest('Starting _pingConnectionTimer');
      _connectionPingTimer = Timer.periodic(connectionPingDuration, _pingConnectionOpen);

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

      // The ping timer makes no sense if we are not connected
      if (_connectionPingTimer != null) {
        _log.finest('Destroying _pingConnectionTimer');
        _connectionPingTimer!.cancel();
        _connectionPingTimer = null;
      }
    }
  }
  
  /// Sets the routing state and logs the change
  void _updateRoutingState(RoutingState state) {
    _log.finest('Updating _routingState from $_routingState to $state');
    _routingState = state;
  }

  /// Sets the resource of the connection
  void setResource(String resource) {
    _log.finest('Updating _resource to $resource');
    _resource = resource;
  }
  
  /// Returns the connection's events as a stream.
  Stream<XmppEvent> asBroadcastStream() {
    return _eventStreamController.stream.asBroadcastStream();
  }  
  
  /// Timer callback to prevent the connection from timing out.
  Future<void> _pingConnectionOpen(Timer timer) async {
    // Follow the recommendation of XEP-0198 and just request an ack. If SM is not enabled,
    // send a whitespace ping
    _log.finest('_pingConnectionTimer: Callback called.');

    if (_connectionState == XmppConnectionState.connected) {
      _log.finest('_pingConnectionTimer: Connected. Triggering a ping event.');
      unawaited(_sendEvent(SendPingEvent()));
    } else {
      _log.finest('_pingConnectionTimer: Not connected. Not triggering an event.');
    }
  }

  /// Iterate over [handlers] and check if the handler matches [stanza]. If it does,
  /// call its callback and end the processing if the callback returned true; continue
  /// if it returned false.
  Future<StanzaHandlerData> _runStanzaHandlers(List<StanzaHandler> handlers, Stanza stanza, { StanzaHandlerData? initial }) async {
    var state = initial ?? StanzaHandlerData(false, false, null, stanza);
    for (final handler in handlers) {
      if (handler.matches(state.stanza)) {
        state = await handler.callback(state.stanza, state);
        if (state.done || state.cancel) return state;
      }
    }

    return state;
  }

  Future<StanzaHandlerData> _runIncomingStanzaHandlers(Stanza stanza, { StanzaHandlerData? initial }) async {
    return _runStanzaHandlers(_incomingStanzaHandlers, stanza, initial: initial);
  }

  Future<StanzaHandlerData> _runIncomingPreStanzaHandlers(Stanza stanza) async {
    return _runStanzaHandlers(_incomingPreStanzaHandlers, stanza);
  }

  Future<StanzaHandlerData> _runOutgoingPreStanzaHandlers(Stanza stanza, { StanzaHandlerData? initial }) async {
    return _runStanzaHandlers(_outgoingPreStanzaHandlers, stanza, initial: initial);
  }

  Future<bool> _runOutgoingPostStanzaHandlers(Stanza stanza, { StanzaHandlerData? initial }) async {
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
      await Future.forEach(
        _xmppManagers.values,
        (XmppManagerBase manager) async {
          final handled = await manager.runNonzaHandlers(nonza);

          if (!nonzaHandled && handled) nonzaHandled = true;
        }
      );

      if (!nonzaHandled) {
        _log.warning('Unhandled nonza received: ${nonza.toXml()}');
      }
      return;
    }

    final stanza = Stanza.fromXMLNode(nonza);

    // Run the incoming stanza handlers and bounce with an error if no manager handled
    // it.
    final incomingPreHandlers = await _runIncomingPreStanzaHandlers(stanza);
    final prefix = incomingPreHandlers.encrypted && incomingPreHandlers.other['encryption_error'] == null ?
      '(Encrypted) ' :
      '';
    _log.finest('<== $prefix${incomingPreHandlers.stanza.toXml()}');

    final awaited = await _stanzaAwaiter.onData(
      incomingPreHandlers.stanza,
      _connectionSettings.jid.toBare(),
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
        incomingPreHandlers.cancelReason,
        incomingPreHandlers.stanza,
        encrypted: incomingPreHandlers.encrypted,
        other: incomingPreHandlers.other,
      ),
    );
    if (!incomingHandlers.done) {
      await handleUnhandledStanza(this, incomingPreHandlers);
    }
  }

  /// Returns true if all mandatory features in [features] have been negotiated.
  /// Otherwise returns false.
  bool _isMandatoryNegotiationDone(List<XMLNode> features) {
    return features.every(
      (XMLNode feature) {
        return feature.firstTag('required') == null && feature.tag != 'mechanisms';
      }
    );
  }

  /// Returns true if we can still negotiate. Returns false if no negotiator is
  /// matching and ready.
  bool _isNegotiationPossible(List<XMLNode> features) {
    return getNextNegotiator(features, log: false) != null;
  }

  /// Returns the next negotiator that matches [features]. Returns null if none can be
  /// picked. If [log] is true, then the list of matching negotiators will be logged.
  @visibleForTesting
  XmppFeatureNegotiatorBase? getNextNegotiator(List<XMLNode> features, {bool log = true}) {
    final matchingNegotiators = _featureNegotiators.values
      .where(
        (XmppFeatureNegotiatorBase negotiator) {
          return negotiator.state == NegotiatorState.ready && negotiator.matchesFeature(features);
        }
      )
      .toList()
      ..sort((a, b) => b.priority.compareTo(a.priority));

    if (log) {
      _log.finest('List of matching negotiators: ${matchingNegotiators.map((a) => a.id)}');
    }
    
    if (matchingNegotiators.isEmpty) return null;

    return matchingNegotiators.first;
  }

  /// Called once all negotiations are done. Sends the initial presence, performs
  /// a disco sweep among other things.
  Future<void> _onNegotiationsDone() async {
    // Set the connection state
    await _resetIsConnectionRunning();
    await _setConnectionState(XmppConnectionState.connected);

    // Resolve the connection completion future
    _connectionCompleter?.complete(const XmppConnectionResult(true));
    _connectionCompleter = null;
    
    // Send out initial presence
    await getPresenceManager().sendInitialPresence();
  }

  Future<void> _executeCurrentNegotiator(XMLNode nonza) async {
    // If we don't have a negotiator get one
    _currentNegotiator ??= getNextNegotiator(_streamFeatures);
    if (_currentNegotiator == null && _isMandatoryNegotiationDone(_streamFeatures) && !_isNegotiationPossible(_streamFeatures)) {
      _log.finest('Negotiations done!');
      _updateRoutingState(RoutingState.handleStanzas);
      await _onNegotiationsDone();
      return;
    }

    final result = await _currentNegotiator!.negotiate(nonza);
    if (result.isType<NegotiatorError>()) {
      _log.severe('Negotiator returned an error');
      await _resetIsConnectionRunning();
      await handleError(result.get<NegotiatorError>());
      return;
    }

    final state = result.get<NegotiatorState>();
    _currentNegotiator!.state = state;
    switch (state) {
      case NegotiatorState.ready: return;
      case NegotiatorState.done:
      if (_currentNegotiator!.sendStreamHeaderWhenDone) {
        _currentNegotiator = null;
        _streamFeatures.clear();
        _sendStreamHeader();
      } else {
        _streamFeatures
          .removeWhere((node) {
            return node.attributes['xmlns'] == _currentNegotiator!.negotiatingXmlns;
          });
        _currentNegotiator = null;

        if (_isMandatoryNegotiationDone(_streamFeatures) && !_isNegotiationPossible(_streamFeatures)) {
          _log.finest('Negotiations done!');
          _updateRoutingState(RoutingState.handleStanzas);
          await _resetIsConnectionRunning();
          await _onNegotiationsDone();
        } else {
          _currentNegotiator = getNextNegotiator(_streamFeatures);
          _log.finest('Chose ${_currentNegotiator!.id} as next negotiator');

          final fakeStanza = XMLNode(
            tag: 'stream:features',
            children: _streamFeatures,
          );

          await _executeCurrentNegotiator(fakeStanza);
        }
      }
      break;
      case NegotiatorState.retryLater:
      _log.finest('Negotiator wants to continue later. Picking new one...');
      _currentNegotiator!.state = NegotiatorState.ready;

      
      if (_isMandatoryNegotiationDone(_streamFeatures) && !_isNegotiationPossible(_streamFeatures)) {
        _log.finest('Negotiations done!');

        _updateRoutingState(RoutingState.handleStanzas);
        await _resetIsConnectionRunning();
        await _onNegotiationsDone();
      } else {
        _log.finest('Picking new negotiator...');
        _currentNegotiator = getNextNegotiator(_streamFeatures);
        _log.finest('Chose $_currentNegotiator as next negotiator');
        final fakeStanza = XMLNode(
          tag: 'stream:features',
          children: _streamFeatures,
        );
        await _executeCurrentNegotiator(fakeStanza);
      }
      break;
      case NegotiatorState.skipRest:
      _log.finest('Negotiator wants to skip the remaining negotiation... Negotiations (assumed) done!');

      _updateRoutingState(RoutingState.handleStanzas);
      await _resetIsConnectionRunning();
      await _onNegotiationsDone();
      break;
    }
  }
  
  /// Called whenever we receive data that has been parsed as XML.
  Future<void> handleXmlStream(XMLNode node) async {
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
            unawaited(handleXmlStream(node));
            return;
          }

          if (node.tag == 'stream:features') {
            // Store the received stream features
            _streamFeatures
              ..clear()
              ..addAll(node.children);
          }

          await _executeCurrentNegotiator(node);
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
    _log.finest('Event: ${event.toString()}');

    // Specific event handling
    if (event is ResourceBindingSuccessEvent) {
      _log.finest('Received ResourceBindingSuccessEvent. Setting _resource to ${event.resource}');
      setResource(event.resource);

      _log.finest('Resetting _serverFeatures');
      _serverFeatures.clear();
    } else if (event is AuthenticationSuccessEvent) {
      _log.finest('Received AuthenticationSuccessEvent. Setting _isAuthenticated to true');
      _isAuthenticated = true;
    }
    
    for (final manager in _xmppManagers.values) {
      await manager.onXmppEvent(event);
    }

    _eventStreamController.add(event);
  }

  /// Sends a stream header to the socket.
  void _sendStreamHeader() {
    _socket.write(
      XMLNode(
        tag: 'xml',
        attributes: <String, String>{
          'version': '1.0'
        },
        closeTag: false,
        isDeclaration: true,
        children: [
          StreamHeaderNonza(_connectionSettings.jid.domain),
        ],
      ).toXml(),
    );
  }

  /// To be called when we lost the network connection.
  Future<void> _onNetworkConnectionLost() async {
    _socket.close();
    await _resetIsConnectionRunning();
    await _setConnectionState(XmppConnectionState.notConnected);
  }

  /// Attempt to gracefully close the session
  Future<void> disconnect() async {
    await _disconnect(state: XmppConnectionState.notConnected);
  }

  Future<void> _disconnect({required XmppConnectionState state, bool triggeredByUser = true}) async {
    await _reconnectionPolicy.setShouldReconnect(false);

    if (triggeredByUser) {
      getPresenceManager().sendUnavailablePresence();
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
  
  /// Make sure that all required managers are registered
  void _runPreConnectionAssertions() {
    assert(_xmppManagers.containsKey(presenceManager), 'A PresenceManager is mandatory');
    assert(_xmppManagers.containsKey(rosterManager), 'A RosterManager is mandatory');
    assert(_xmppManagers.containsKey(discoManager), 'A DiscoManager is mandatory');
    assert(_xmppManagers.containsKey(pingManager), 'A PingManager is mandatory');
  }
  
  /// Like [connect] but the Future resolves when the resource binding is either done or
  /// SASL has failed.
  Future<XmppConnectionResult> connectAwaitable({ String? lastResource, bool waitForConnection = false }) async {
    _runPreConnectionAssertions();
    await _resetIsConnectionRunning();
    _connectionCompleter = Completer();
    _log.finest('Calling connect() from connectAwaitable');
    await connect(
      lastResource: lastResource,
      waitForConnection: waitForConnection,
      shouldReconnect: false,
    );
    return _connectionCompleter!.future;
  }
 
  /// Start the connection process using the provided connection settings.
  Future<void> connect({ String? lastResource, bool waitForConnection = false, bool shouldReconnect = true }) async {
    if (_connectionState != XmppConnectionState.notConnected && _connectionState != XmppConnectionState.error) {
      _log.fine('Cancelling this connection attempt as one appears to be already running.');
      return;
    }
    
    _runPreConnectionAssertions();
    await _resetIsConnectionRunning();
    
    if (lastResource != null) {
      setResource(lastResource);
    }

    if (shouldReconnect) {
      await _reconnectionPolicy.setShouldReconnect(true);
    }

    await _reconnectionPolicy.reset();
    await _sendEvent(ConnectingEvent());

    // If requested, wait until we have a network connection
    if (waitForConnection) {
      _log.info('Waiting for okay from connectivityManager');
      await _connectivityManager.waitForConnection();
      _log.info('Got okay from connectivityManager');
    }
    
    final smManager = getStreamManagementManager();
    String? host;
    int? port;
    if (smManager?.state.streamResumptionLocation != null) {
      // TODO(Unknown): Maybe wrap this in a try catch?
      final parsed = Uri.parse(smManager!.state.streamResumptionLocation!);
      host = parsed.host;
      port = parsed.port;
    }

    final result = await _socket.connect(
      _connectionSettings.jid.domain,
      host: host,
      port: port,
    );
    if (!result) {
      await handleError(NoConnectionError());
    } else {
      await _reconnectionPolicy.onSuccess();
      _log.fine('Preparing the internal state for a connection attempt');
      _resetNegotiators();
      await _setConnectionState(XmppConnectionState.connecting);
      _updateRoutingState(RoutingState.negotiating);
      _isAuthenticated = false;
      _sendStreamHeader();
    }
  }
}
