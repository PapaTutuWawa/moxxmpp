import 'package:moxxmpp/src/events.dart';
import 'package:moxxmpp/src/managers/base.dart';
import 'package:moxxmpp/src/managers/namespaces.dart';
import 'package:moxxmpp/src/xeps/xep_0198/xep_0198.dart';

class PingManager extends XmppManagerBase {
  @override
  String getId() => pingManager;

  @override
  String getName() => 'PingManager';

  @override
  Future<bool> isSupported() async => true;
  
  void _logWarning() {
    logger.warning('Cannot send keepalives as SM is not available, the socket disallows whitespace pings and does not manage its own keepalives. Cannot guarantee that the connection survives.');
  }
  
  @override
  Future<void> onXmppEvent(XmppEvent event) async {
    if (event is SendPingEvent) {
      logger.finest('Received ping event.');
      final attrs = getAttributes();
      final socket = attrs.getSocket();

      if (socket.managesKeepalives()) {
        logger.finest('Not sending ping as the socket manages it.');
        return;
      }
      
      final stream = attrs.getManagerById(smManager) as StreamManagementManager?;
      if (stream != null) {
        if (stream.isStreamManagementEnabled() /*&& stream.getUnackedStanzaCount() > 0*/) {
          logger.finest('Sending an ack ping as Stream Management is enabled');
          stream.sendAckRequestPing();
        } else if (attrs.getSocket().whitespacePingAllowed()) {
          logger.finest('Sending a whitespace ping as Stream Management is not enabled');
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
  }
}
