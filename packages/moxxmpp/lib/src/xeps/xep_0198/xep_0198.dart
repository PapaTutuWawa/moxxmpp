import 'dart:async';
import 'dart:math';
import 'package:meta/meta.dart';
import 'package:moxxmpp/src/connection.dart';
import 'package:moxxmpp/src/events.dart';
import 'package:moxxmpp/src/managers/base.dart';
import 'package:moxxmpp/src/managers/data.dart';
import 'package:moxxmpp/src/managers/handlers.dart';
import 'package:moxxmpp/src/managers/namespaces.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/negotiators/namespaces.dart';
import 'package:moxxmpp/src/stanza.dart';
import 'package:moxxmpp/src/stringxml.dart';
import 'package:moxxmpp/src/util/typed_map.dart';
import 'package:moxxmpp/src/xeps/xep_0198/errors.dart';
import 'package:moxxmpp/src/xeps/xep_0198/negotiator.dart';
import 'package:moxxmpp/src/xeps/xep_0198/nonzas.dart';
import 'package:moxxmpp/src/xeps/xep_0198/state.dart';
import 'package:moxxmpp/src/xeps/xep_0198/types.dart';
import 'package:synchronized/synchronized.dart';

const xmlUintMax = 4294967296; // 2**32

typedef StanzaAckedCallback = bool Function(Stanza stanza);

class StreamManagementManager extends XmppManagerBase {
  StreamManagementManager({
    this.ackTimeout = const Duration(seconds: 30),
  }) : super(smManager);

  /// The queue of stanzas that are not (yet) acked
  final Map<int, SMQueueEntry> _unackedStanzas = {};

  /// Commitable state of the StreamManagementManager
  StreamManagementState _state = const StreamManagementState(0, 0);

  /// Mutex lock for _state
  final Lock _stateLock = Lock();

  /// If the have enabled SM on the stream yet
  bool _streamManagementEnabled = false;

  /// If the current stream has been resumed;
  bool _streamResumed = false;

  /// The time in which the response to an ack is still valid. Counts as a timeout
  /// otherwise
  @internal
  final Duration ackTimeout;

  /// The time at which the last ack has been received
  int _lastAckTimestamp = -1;

  /// The timer to see if the connection timed out
  Timer? _ackTimer;

  /// Counts how many acks we're waiting for
  int _pendingAcks = 0;

  /// Lock for both [_lastAckTimestamp] and [_pendingAcks].
  final Lock _ackLock = Lock();

  /// Functions for testing
  @visibleForTesting
  Map<int, SMQueueEntry> getUnackedStanzas() => _unackedStanzas;

  @visibleForTesting
  Future<int> getPendingAcks() async {
    var acks = 0;

    await _ackLock.synchronized(() async {
      acks = _pendingAcks;
    });

    return acks;
  }

  @override
  Future<void> onData() async {
    // The ack timer does not matter if we are currently in the middle of receiving
    // data.
    await _ackLock.synchronized(() {
      if (_pendingAcks > 0) {
        _resetAckTimer();
      }
    });
  }

  /// Called when a stanza has been acked to decide whether we should trigger a
  /// StanzaAckedEvent.
  ///
  /// Return true when the stanza should trigger this event. Return false if not.
  @visibleForOverriding
  bool shouldTriggerAckedEvent(Stanza stanza) {
    return false;
  }

  @override
  Future<bool> isSupported() async {
    return getAttributes()
        .getNegotiatorById<StreamManagementNegotiator>(
          streamManagementNegotiator,
        )!
        .isSupported;
  }

  /// Returns the amount of stanzas waiting to get acked
  int getUnackedStanzaCount() => _unackedStanzas.length;

  /// May be overwritten by a subclass. Should save [state] so that it can be loaded again
  /// with [this.loadState].
  Future<void> commitState() async {}
  Future<void> loadState() async {}

  Future<void> setState(StreamManagementState state) async {
    await _stateLock.synchronized(() async {
      _state = state;
      await commitState();
    });
  }

  /// Resets the state such that a resumption is no longer possible without creating
  /// a new session. Primarily useful for clearing the state after disconnecting
  Future<void> resetState() async {
    await setState(
      _state.copyWith(
        c2s: 0,
        s2c: 0,
        streamResumptionLocation: null,
        streamResumptionId: null,
      ),
    );

    await _ackLock.synchronized(() async {
      _pendingAcks = 0;
    });
  }

  StreamManagementState get state => _state;

  bool get streamResumed => _streamResumed;

  @override
  List<NonzaHandler> getNonzaHandlers() => [
        NonzaHandler(
          nonzaTag: 'r',
          nonzaXmlns: smXmlns,
          callback: _handleAckRequest,
        ),
        NonzaHandler(
          nonzaTag: 'a',
          nonzaXmlns: smXmlns,
          callback: _handleAckResponse,
        ),
      ];

  @override
  List<StanzaHandler> getIncomingPreStanzaHandlers() => [
        StanzaHandler(
          callback: _onServerStanzaReceived,
          priority: 9999,
        ),
      ];

  @override
  List<StanzaHandler> getOutgoingPostStanzaHandlers() => [
        StanzaHandler(
          callback: _onClientStanzaSent,
        ),
      ];

  @override
  Future<void> onXmppEvent(XmppEvent event) async {
    if (event is StreamResumedEvent) {
      _enableStreamManagement();

      await _ackLock.synchronized(() async {
        _pendingAcks = 0;
      });

      await onStreamResumed(event.h);
    } else if (event is StreamManagementEnabledEvent) {
      _enableStreamManagement();

      await _ackLock.synchronized(() async {
        _pendingAcks = 0;
      });

      await setState(
        StreamManagementState(
          0,
          0,
          streamResumptionId: event.id,
          streamResumptionLocation: event.location,
        ),
      );
    } else if (event is ConnectingEvent) {
      _disableStreamManagement();
      _streamResumed = false;
    } else if (event is ConnectionStateChangedEvent) {
      switch (event.state) {
        case XmppConnectionState.connected:
          // Push out all pending stanzas
          if (!_streamResumed) {
            await _resendStanzas();
          }
          break;
        case XmppConnectionState.error:
        case XmppConnectionState.notConnected:
          _stopAckTimer();
          break;
        case XmppConnectionState.connecting:
          _stopAckTimer();
          // NOOP
          break;
      }
    }
  }

  /// Starts the timer to detect timeouts based on ack responses, if the timer
  /// is not already running.
  void _startAckTimer() {
    if (_ackTimer != null) return;

    logger.fine('Starting ack timer');
    _ackTimer = Timer.periodic(
      ackTimeout,
      _ackTimerCallback,
    );
  }

  /// Stops the timer, if it is running.
  void _stopAckTimer() {
    logger.fine('Stopping ack timer');
    _ackTimer?.cancel();
    _ackTimer = null;
  }

  /// Resets the ack timer.
  void _resetAckTimer() {
    _stopAckTimer();
    _startAckTimer();
  }

  @visibleForTesting
  Future<void> handleAckTimeout() async {
    _stopAckTimer();
    await getAttributes()
        .getConnection()
        .handleError(StreamManagementAckTimeoutError());
  }

  /// Timer callback that checks if all acks have been answered. If not and the last
  /// response has been more that [ackTimeout] in the past, declare the session dead.
  Future<void> _ackTimerCallback(Timer timer) async {
    logger.finest('Ack timer callback called');
    final shouldTimeout = await _ackLock.synchronized(() {
      final now = DateTime.now().millisecondsSinceEpoch;

      return now - _lastAckTimestamp >= ackTimeout.inMilliseconds &&
          _pendingAcks > 0;
    });

    logger.finest('Should timeout: $shouldTimeout');
    if (shouldTimeout) {
      await handleAckTimeout();
    }
  }

  /// Wrapper around sending an <r /> nonza that starts the ack timeout timer.
  Future<void> _sendAckRequest() async {
    logger.fine('_sendAckRequest: Waiting to acquire lock...');
    await _ackLock.synchronized(() async {
      logger.fine('_sendAckRequest: Done...');

      _pendingAcks++;
      _startAckTimer();

      logger.fine('_pendingAcks is now at $_pendingAcks (caused by <r/>)');

      getAttributes().sendNonza(StreamManagementRequestNonza());

      logger.fine('_sendAckRequest: Releasing lock...');
    });
  }

  /// Resets the enablement of stream management, but __NOT__ the internal state.
  /// This is to prevent ack requests being sent before we resume or re-enable
  /// stream management.
  void _disableStreamManagement() {
    _streamManagementEnabled = false;
    logger.finest('Stream Management disabled');
  }

  /// Enables support for XEP-0198 stream management
  void _enableStreamManagement() {
    _streamManagementEnabled = true;
    logger.finest('Stream Management enabled');
  }

  /// Returns whether XEP-0198 stream management is enabled
  bool isStreamManagementEnabled() => _streamManagementEnabled;

  /// To be called when receiving a <a /> nonza.
  Future<bool> _handleAckRequest(XMLNode nonza) async {
    final attrs = getAttributes();
    logger.finest('Sending ack response');
    await _stateLock.synchronized(() async {
      attrs.sendNonza(StreamManagementAckNonza(_state.s2c));
    });

    return true;
  }

  /// Called when we receive an <a /> nonza from the server.
  /// This is a response to the question "How many of my stanzas have you handled".
  Future<bool> _handleAckResponse(XMLNode nonza) async {
    logger.finest('Received ack');
    final h = int.parse(nonza.attributes['h']! as String);

    _lastAckTimestamp = DateTime.now().millisecondsSinceEpoch;
    await _ackLock.synchronized(() async {
      await _stateLock.synchronized(() async {
        if (_pendingAcks > 0) {
          // Prevent diff from becoming negative
          final diff = max(_state.c2s - h, 0);

          logger.finest(
            'Setting _pendingAcks to $diff (was $_pendingAcks before): max(${_state.c2s} - $h, 0)',
          );
          _pendingAcks = diff;

          // Reset the timer
          if (_pendingAcks > 0) {
            _resetAckTimer();
          }
        }

        if (_pendingAcks == 0) {
          _stopAckTimer();
        }

        logger.fine('_pendingAcks is now at $_pendingAcks (caused by <a/>)');
      });
    });

    // Return early if we acked nothing.
    // Taken from slixmpp's stream management code
    logger.fine('_handleAckResponse: Waiting to aquire lock...');
    await _stateLock.synchronized(() async {
      logger.fine('_handleAckResponse: Done...');
      if (h == _state.c2s && _unackedStanzas.isEmpty) {
        logger.fine('_handleAckResponse: Releasing lock...');
        return;
      }

      final attrs = getAttributes();
      final sequences = _unackedStanzas.keys.toList()..sort();
      for (final height in sequences) {
        logger.finest('Unacked stanza: height $height, h $h');

        // Do nothing if the ack does not concern this stanza
        if (height > h) continue;

        logger.finest('Removing stanza with height $height');
        final entry = _unackedStanzas[height]!;
        _unackedStanzas.remove(height);

        // Create a StanzaAckedEvent if the stanza is correct
        if (shouldTriggerAckedEvent(entry.stanza)) {
          attrs.sendEvent(StanzaAckedEvent(entry.stanza));
        }
      }

      if (h > _state.c2s) {
        logger.info(
          'C2S height jumped from ${_state.c2s} (local) to $h (remote).',
        );
        // ignore: cascade_invocations
        logger.info('Proceeding with $h as local C2S counter.');

        _state = _state.copyWith(c2s: h);
        await commitState();
      }

      logger.fine('_handleAckResponse: Releasing lock...');
    });

    return true;
  }

  // Just a helper function to not increment the counters above xmlUintMax
  Future<void> _incrementC2S() async {
    logger.fine('_incrementC2S: Waiting to aquire lock...');
    await _stateLock.synchronized(() async {
      logger.fine('_incrementC2S: Done');
      _state = _state.copyWith(c2s: _state.c2s + 1 % xmlUintMax);
      await commitState();
      logger.fine('_incrementC2S: Releasing lock...');
    });
  }

  Future<void> _incrementS2C() async {
    logger.fine('_incrementS2C: Waiting to aquire lock...');
    await _stateLock.synchronized(() async {
      logger.fine('_incrementS2C: Done');
      _state = _state.copyWith(s2c: _state.s2c + 1 % xmlUintMax);
      await commitState();
      logger.fine('_incrementS2C: Releasing lock...');
    });
  }

  /// Called whenever we receive a stanza from the server.
  Future<StanzaHandlerData> _onServerStanzaReceived(
    Stanza stanza,
    StanzaHandlerData state,
  ) async {
    await _incrementS2C();
    return state;
  }

  /// Called whenever we send a stanza.
  Future<StanzaHandlerData> _onClientStanzaSent(
    Stanza stanza,
    StanzaHandlerData state,
  ) async {
    if (isStreamManagementEnabled()) {
      final smData = state.extensions.get<StreamManagementData>();
      logger.finest('Should count stanza: ${smData?.shouldCountStanza}');
      if (smData?.shouldCountStanza ?? true) {
        await _incrementC2S();
      }

      if (smData?.exclude ?? false) {
        return state;
      }

      int queueId;
      if (smData?.queueId != null) {
        logger.finest('Reusing queue id ${smData!.queueId}');
        queueId = smData.queueId!;
      } else {
        queueId = await _stateLock.synchronized(() => _state.c2s);
      }

      _unackedStanzas[queueId] = SMQueueEntry(
        stanza,
        // Prevent an E2EE message being encrypted again
        state.encrypted,
      );
      await _sendAckRequest();
    }

    return state;
  }

  Future<void> _resendStanzas() async {
    final queueCopy = _unackedStanzas.entries.toList();
    for (final entry in queueCopy) {
      logger.finest(
        'Resending ${entry.value.stanza.tag} with id ${entry.value.stanza.attributes["id"]}',
      );
      await getAttributes().sendStanza(
        StanzaDetails(
          entry.value.stanza,
          postSendExtensions: TypedMap<StanzaHandlerExtension>.fromList([
            StreamManagementData(
              false,
              entry.key,
            ),
          ]),
          awaitable: false,
          // Prevent an E2EE message being encrypted again
          encrypted: entry.value.encrypted,
        ),
      );
    }
  }

  /// To be called when the stream has been resumed
  @visibleForTesting
  Future<void> onStreamResumed(int h) async {
    _streamResumed = true;
    await _handleAckResponse(StreamManagementAckNonza(h));

    // Retransmit the rest of the queue
    await _resendStanzas();
  }

  /// Pings the connection open by send an ack request
  void sendAckRequestPing() {
    _sendAckRequest();
  }
}
