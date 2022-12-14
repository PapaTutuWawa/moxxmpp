import 'dart:async';
import 'dart:math';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:synchronized/synchronized.dart';

abstract class ReconnectionPolicy {

  ReconnectionPolicy()
    : _shouldAttemptReconnection = false,
      _isReconnecting = false,
      _isReconnectingLock = Lock();
  /// Function provided by XmppConnection that allows the policy
  /// to perform a reconnection.
  Future<void> Function()? performReconnect;
  /// Function provided by XmppConnection that allows the policy
  /// to say that we lost the connection.
  void Function()? triggerConnectionLost;
  /// Indicate if should try to reconnect.
  bool _shouldAttemptReconnection;
  /// Indicate if a reconnection attempt is currently running.
  bool _isReconnecting;
  /// And the corresponding lock
  final Lock _isReconnectingLock;
  
  /// Called by XmppConnection to register the policy.
  void register(Future<void> Function() performReconnect, void Function() triggerConnectionLost) {
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

  bool get shouldReconnect => _shouldAttemptReconnection;

  /// Set whether a reconnection attempt should be made.
  void setShouldReconnect(bool value) {
    _shouldAttemptReconnection = value;
  }

  /// Returns true if the manager is currently triggering a reconnection. If not, returns
  /// false.
  Future<bool> isReconnectionRunning() async {
    return _isReconnectingLock.synchronized(() => _isReconnecting);
  }

  /// Set the _isReconnecting state to [value].
  @protected
  Future<void> setIsReconnecting(bool value) async {
    await _isReconnectingLock.synchronized(() async {
      _isReconnecting = value;
    });
  }

  @protected
  Future<bool> testAndSetIsReconnecting() async {
    return _isReconnectingLock.synchronized(() {
      if (_isReconnecting) {
        return false;
      } else {
        _isReconnecting = true;
        return true;
      }
    });
  }
}

/// A simple reconnection strategy: Make the reconnection delays exponentially longer
/// for every failed attempt.
class ExponentialBackoffReconnectionPolicy extends ReconnectionPolicy {

  ExponentialBackoffReconnectionPolicy(this._maxBackoffTime)
  : _counter = 0,
    _log = Logger('ExponentialBackoffReconnectionPolicy'),
    super();
  final int _maxBackoffTime;
  int _counter;
  Timer? _timer;
  final Logger _log;

  /// Called when the backoff expired
  Future<void> _onTimerElapsed() async {
    final isReconnecting = await isReconnectionRunning();
    if (shouldReconnect) {
      if (!isReconnecting) {
        await setIsReconnecting(true);
        await performReconnect!();
      } else {
        // Should never happen.
        _log.fine('Backoff timer expired but reconnection is running, so doing nothing.');
      }
    }
  }
  
  @override
  Future<void> reset() async {
    _log.finest('Resetting internal state');
    _counter = 0;
    await setIsReconnecting(false);

    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
    }
  }

  @override
  Future<void> onFailure() async {
    _log.finest('Failure occured. Starting exponential backoff');
    _counter++;

    if (_timer != null) {
      _timer!.cancel();
    }

    // Wait at max 80 seconds.
    final seconds = min(min(pow(2, _counter).toInt(), 80), _maxBackoffTime);
    _timer = Timer(Duration(seconds: seconds), _onTimerElapsed);
  }

  @override
  Future<void> onSuccess() async {
    await reset();
  }
}

/// A stub reconnection policy for tests
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
