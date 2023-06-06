import 'dart:async';
import 'package:moxxmpp/src/connection.dart';
import 'package:moxxmpp/src/connectivity.dart';
import 'package:moxxmpp/src/events.dart';
import 'package:moxxmpp/src/handlers/client.dart';
import 'package:moxxmpp/src/jid.dart';
import 'package:moxxmpp/src/managers/attributes.dart';
import 'package:moxxmpp/src/managers/base.dart';
import 'package:moxxmpp/src/reconnect.dart';
import 'package:moxxmpp/src/settings.dart';
import 'package:moxxmpp/src/stanza.dart';
import 'package:moxxmpp/src/stringxml.dart';

import '../helpers/xmpp.dart';

/// This class allows registering managers for easier testing.
class TestingManagerHolder {
  TestingManagerHolder({
    StubTCPSocket? stubSocket,
  }) : socket = stubSocket ?? StubTCPSocket([]);

  final StubTCPSocket socket;

  final Map<String, XmppManagerBase> _managers = {};

  /// A list of events that were triggered.
  final List<XmppEvent> sentEvents = List.empty(growable: true);

  static final JID jid = JID.fromString('testuser@example.org/abc123');
  static final ConnectionSettings settings = ConnectionSettings(
    jid: jid,
    password: 'abc123',
  );

  Future<XMLNode?> _sendStanza(StanzaDetails details) async {
    socket.write(details.stanza.toXml());
    return null;
  }

  T? _getManagerById<T extends XmppManagerBase>(String id) {
    return _managers[id] as T?;
  }

  Future<void> register(XmppManagerBase manager) async {
    manager.register(
      XmppManagerAttributes(
        sendStanza: _sendStanza,
        getConnection: () => XmppConnection(
          TestingReconnectionPolicy(),
          AlwaysConnectedConnectivityManager(),
          ClientToServerNegotiator(),
          socket,
        ),
        getConnectionSettings: () => settings,
        sendNonza: (_) {},
        sendEvent: sentEvents.add,
        getSocket: () => socket,
        getNegotiatorById: getNegotiatorNullStub,
        getFullJID: () => jid,
        getManagerById: _getManagerById,
      ),
    );

    await manager.postRegisterCallback();
    _managers[manager.id] = manager;
  }
}
