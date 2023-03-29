import 'dart:async';
import 'package:meta/meta.dart';
import 'package:moxxmpp/src/events.dart';
import 'package:moxxmpp/src/managers/base.dart';
import 'package:moxxmpp/src/managers/namespaces.dart';
import 'package:moxxmpp/src/xeps/xep_0198/xep_0198.dart';
import 'package:synchronized/synchronized.dart';

/// This manager class is responsible to sending periodic pings, if required, using
/// either whitespaces or Stream Management. Keep in mind, that without
/// Stream Management, a stale connection cannot be detected.
class PingManager extends XmppManagerBase {
  PingManager(this._pingDuration) : super(pingManager);

  /// The time between pings, when connected.
  final Duration _pingDuration;

  /// The actual timer.
  Timer? _pingTimer;
  final Lock _timerLock = Lock();

  @override
  Future<bool> isSupported() async => true;

  void _logWarning() {
    logger.warning(
      'Cannot send keepalives as SM is not available, the socket disallows whitespace pings and does not manage its own keepalives. Cannot guarantee that the connection survives.',
    );
  }

  /// Cancel a potentially scheduled ping timer. Can be overriden to cancel a custom timing mechanism.
  /// By default, cancels a [Timer.periodic] that was set up prior.
  @visibleForOverriding
  Future<void> cancelPing() async {
    await _timerLock.synchronized(() {
      logger.finest('Cancelling timer');
      _pingTimer?.cancel();
      _pingTimer = null;
    });
  }

  /// Schedule a ping to be sent after a given amount of time. Can be overriden for custom timing mechanisms.
  /// By default, uses a [Timer.periodic] timer to trigger a ping.
  /// NOTE: This function is called whenever the connection is re-established. Custom
  ///       implementations should thus guard against multiple timers being started.
  @visibleForOverriding
  Future<void> schedulePing() async {
    await _timerLock.synchronized(() {
      logger.finest('Scheduling new timer? ${_pingTimer != null}');

      _pingTimer ??= Timer.periodic(
        _pingDuration,
        _sendPing,
      );
    });
  }

  Future<void> _sendPing(Timer _) async {
    logger.finest('Attempting to send ping');
    final attrs = getAttributes();
    final socket = attrs.getSocket();

    if (socket.managesKeepalives()) {
      logger.finest('Not sending ping as the socket manages it.');
      return;
    }

    final stream = attrs.getManagerById(smManager) as StreamManagementManager?;
    if (stream != null) {
      if (stream
          .isStreamManagementEnabled() /*&& stream.getUnackedStanzaCount() > 0*/) {
        logger.finest('Sending an ack ping as Stream Management is enabled');
        stream.sendAckRequestPing();
      } else if (attrs.getSocket().whitespacePingAllowed()) {
        logger.finest(
          'Sending a whitespace ping as Stream Management is not enabled',
        );
        attrs.getConnection().sendWhitespacePing();
      } else {
        _logWarning();
      }
    } else {
      if (attrs.getSocket().whitespacePingAllowed()) {
        attrs.getConnection().sendWhitespacePing();
      } else {
        _logWarning();
      }
    }
  }

  @override
  Future<void> onXmppEvent(XmppEvent event) async {
    if (event is ConnectionStateChangedEvent) {
      if (event.connectionEstablished) {
        await schedulePing();
      } else {
        await cancelPing();
      }
    }
  }
}
