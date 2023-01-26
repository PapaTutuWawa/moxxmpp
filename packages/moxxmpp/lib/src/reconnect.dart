import 'dart:async';
import 'dart:math';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:moxxmpp/src/util/queue.dart';
import 'package:synchronized/synchronized.dart';

/// A callback function to be called when the connection to the server has been lost.
typedef ConnectionLostCallback = Future<void> Function();

/// A function that, when called, causes the XmppConnection to connect to the server, if
/// another reconnection is not already running.
typedef PerformReconnectFunction = Future<void> Function();

abstract class ReconnectionPolicy {
  /// Function provided by XmppConnection that allows the policy
  /// to perform a reconnection.
  PerformReconnectFunction? performReconnect;

  /// Function provided by XmppConnection that allows the policy
  /// to say that we lost the connection.
  ConnectionLostCallback? triggerConnectionLost;

  /// Indicate if should try to reconnect.
  bool _shouldAttemptReconnection = false;

  /// Indicate if a reconnection attempt is currently running.
  @protected
  bool isReconnecting = false;

  /// And the corresponding lock
  @protected
  final Lock lock = Lock();

  /// The lock for accessing [_shouldAttemptReconnection]
  @protected
  final Lock shouldReconnectLock = Lock();
  
  /// Called by XmppConnection to register the policy.
  void register(PerformReconnectFunction performReconnect, ConnectionLostCallback triggerConnectionLost) {
    this.performReconnect = performReconnect;
    this.triggerConnectionLost = triggerConnectionLost;

    unawaited(reset());
  }
  
  /// In case the policy depends on some internal state, this state must be reset
  /// to an initial state when reset is called. In case timers run, they must be
  /// terminated.
  Future<void> reset();

  /// Called by the XmppConnection when the reconnection failed.
  Future<void> onFailure() async {}

  /// Caled by the XmppConnection when the reconnection was successful.
  Future<void> onSuccess();

  Future<bool> getShouldReconnect() async {
    return shouldReconnectLock.synchronized(() => _shouldAttemptReconnection);
  }

  /// Set whether a reconnection attempt should be made.
  Future<void> setShouldReconnect(bool value) async {
    return shouldReconnectLock.synchronized(() => _shouldAttemptReconnection = value);
  }

  /// Returns true if the manager is currently triggering a reconnection. If not, returns
  /// false.
  Future<bool> isReconnectionRunning() async {
    return lock.synchronized(() => isReconnecting);
  }

  /// Set the isReconnecting state to [value].
  @protected
  Future<void> setIsReconnecting(bool value) async {
    await lock.synchronized(() async {
      isReconnecting = value;
    });
  }

}

/// A simple reconnection strategy: Make the reconnection delays exponentially longer
/// for every failed attempt.
/// NOTE: This ReconnectionPolicy may be broken
class RandomBackoffReconnectionPolicy extends ReconnectionPolicy {
  RandomBackoffReconnectionPolicy(
    this._minBackoffTime,
    this._maxBackoffTime,
  ) : assert(_minBackoffTime < _maxBackoffTime, '_minBackoffTime must be smaller than _maxBackoffTime'),
      super();

  /// The maximum time in seconds that a backoff should be.
  final int _maxBackoffTime;

  /// The minimum time in seconds that a backoff should be.
  final int _minBackoffTime;

  /// Backoff timer.
  Timer? _timer;

  final Lock _timerLock = Lock();

  /// Logger.
  final Logger _log = Logger('RandomBackoffReconnectionPolicy');

  /// Event queue
  final AsyncQueue _eventQueue = AsyncQueue();

  /// Called when the backoff expired
  Future<void> _onTimerElapsed() async {
    _log.fine('Timer elapsed. Waiting for lock');
    await lock.synchronized(() async {
      _log.fine('Lock aquired');
      if (!(await getShouldReconnect())) {
        _log.fine('Backoff timer expired but getShouldReconnect() returned false');
        return;
      }

      if (isReconnecting) {
        _log.fine('Backoff timer expired but a reconnection is running, so doing nothing.');
        return;
      }

      _log.fine('Triggering reconnect');
      isReconnecting = true;
      await performReconnect!();
    });

    await _timerLock.synchronized(() {
      _timer?.cancel();
      _timer = null;
    });
  }

  Future<void> _reset() async {
    _log.finest('Resetting internal state');

    await _timerLock.synchronized(() {
      _timer?.cancel();
      _timer = null;
    });

    await setIsReconnecting(false);
  }
  
  @override
  Future<void> reset() async {
    // ignore: unnecessary_lambdas
    await _eventQueue.addJob(() => _reset());
  }

  Future<void> _onFailure() async {
    final shouldContinue = await _timerLock.synchronized(() {
      return _timer == null;
    });
    if (!shouldContinue) {
      _log.finest('_onFailure: Not backing off since _timer is already running');
      return;
    }

    final seconds = Random().nextInt(_maxBackoffTime - _minBackoffTime) + _minBackoffTime;
    _log.finest('Failure occured. Starting random backoff with ${seconds}s');
    _timer?.cancel();

    _timer = Timer(Duration(seconds: seconds), _onTimerElapsed);
  }
  
  @override
  Future<void> onFailure() async {
    // ignore: unnecessary_lambdas
    await _eventQueue.addJob(() => _onFailure());
  }

  @override
  Future<void> onSuccess() async {
    await reset();
  }
}

/// A stub reconnection policy for tests.
@visibleForTesting
class TestingReconnectionPolicy extends ReconnectionPolicy {
  TestingReconnectionPolicy() : super();

  @override
  Future<void> onSuccess() async {}

  @override
  Future<void> onFailure() async {}

  @override
  Future<void> reset() async {}
}

/// A reconnection policy for tests that waits a constant number of seconds before
/// attempting a reconnection.
@visibleForTesting
class TestingSleepReconnectionPolicy extends ReconnectionPolicy {
  TestingSleepReconnectionPolicy(this._sleepAmount) : super();
  final int _sleepAmount;
  
  @override
  Future<void> onSuccess() async {}

  @override
  Future<void> onFailure() async {
    await Future<void>.delayed(Duration(seconds: _sleepAmount));
    await performReconnect!();
  }

  @override
  Future<void> reset() async {}
}
