import 'dart:async';
import 'dart:math';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
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

  final Lock _lock = Lock();
  
  /// Indicate if a reconnection attempt is currently running.
  bool _isReconnecting = false;

  /// Indicate if should try to reconnect.
  bool _shouldAttemptReconnection = false;

  @protected
  Future<bool> canTryReconnecting() async => _lock.synchronized(() => !_isReconnecting);

  @protected
  Future<bool> getIsReconnecting() async => _lock.synchronized(() => _isReconnecting);

  Future<void> _resetIsReconnecting() async {
    await _lock.synchronized(() {
      _isReconnecting = false;
    });
  }
  
  /// Called by XmppConnection to register the policy.
  void register(
    PerformReconnectFunction performReconnect,
  ) {
    this.performReconnect = performReconnect;
  }

  /// In case the policy depends on some internal state, this state must be reset
  /// to an initial state when reset is called. In case timers run, they must be
  /// terminated.
  @mustCallSuper
  Future<void> reset() async {
    await _resetIsReconnecting();
  }

  @mustCallSuper
  Future<bool> canTriggerFailure() async {
    return _lock.synchronized(() {
      if (_shouldAttemptReconnection && !_isReconnecting) {
        _isReconnecting = true;
        return true;
      }

      return false;
    });
  }
  
  /// Called by the XmppConnection when the reconnection failed.
  Future<void> onFailure() async {}
  
  /// Caled by the XmppConnection when the reconnection was successful.
  Future<void> onSuccess();

  Future<bool> getShouldReconnect() async {
    return _lock.synchronized(() => _shouldAttemptReconnection);
  }

  /// Set whether a reconnection attempt should be made.
  Future<void> setShouldReconnect(bool value) async {
    return _lock
        .synchronized(() => _shouldAttemptReconnection = value);
  }
}

/// A simple reconnection strategy: Make the reconnection delays exponentially longer
/// for every failed attempt.
/// NOTE: This ReconnectionPolicy may be broken
class RandomBackoffReconnectionPolicy extends ReconnectionPolicy {
  RandomBackoffReconnectionPolicy(
    this._minBackoffTime,
    this._maxBackoffTime,
  )   : assert(
          _minBackoffTime < _maxBackoffTime,
          '_minBackoffTime must be smaller than _maxBackoffTime',
        ),
        super();

  /// The maximum time in seconds that a backoff should be.
  final int _maxBackoffTime;

  /// The minimum time in seconds that a backoff should be.
  final int _minBackoffTime;

  /// Backoff timer.
  Timer? _timer;

  /// Logger.
  final Logger _log = Logger('RandomBackoffReconnectionPolicy');

  final Lock _timerLock = Lock();
  
  /// Called when the backoff expired
  @visibleForTesting
  Future<void> onTimerElapsed() async {
    _log.fine('Timer elapsed. Waiting for lock...');
    await _timerLock.synchronized(() async {
      if (!(await getIsReconnecting())) {
        return;
      }

      if (!(await getShouldReconnect())) {
        _log.fine(
            'Should not reconnect. Stopping here.',
        );
        return;
      }

      _log.fine('Triggering reconnect');
      _timer?.cancel();
      _timer = null;
      await performReconnect!();
    });
  }

  @override
  Future<void> reset() async {
    _log.finest('Resetting internal state');
    _timer?.cancel();
    _timer = null;
    await super.reset();
  }

  @override
  Future<void> onFailure() async {
    final seconds =
        Random().nextInt(_maxBackoffTime - _minBackoffTime) + _minBackoffTime;
    _log.finest('Failure occured. Starting random backoff with ${seconds}s');
    _timer?.cancel();

    _timer = Timer(Duration(seconds: seconds), onTimerElapsed);
  }
 
  @override
  Future<void> onSuccess() async {
    await reset();
  }

  @visibleForTesting
  bool isTimerRunning() => _timer != null;
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
  Future<void> reset() async {
    await super.reset();
  }
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
  Future<void> reset() async {
    await super.reset();
  }
}
