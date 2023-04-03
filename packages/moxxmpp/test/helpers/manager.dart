import 'dart:async';
import 'package:moxxmpp/src/connection.dart';
import 'package:moxxmpp/src/connectivity.dart';
import 'package:moxxmpp/src/jid.dart';
import 'package:moxxmpp/src/managers/attributes.dart';
import 'package:moxxmpp/src/managers/base.dart';
import 'package:moxxmpp/src/negotiators/handler.dart';
import 'package:moxxmpp/src/reconnect.dart';
import 'package:moxxmpp/src/settings.dart';
import 'package:moxxmpp/src/socket.dart';
import 'package:moxxmpp/src/stringxml.dart';

import '../helpers/xmpp.dart';

/// This class allows registering managers for easier testing.
class TestingManagerHolder {
  TestingManagerHolder({
    BaseSocketWrapper? socket,
  }) : _socket = socket ?? StubTCPSocket([]);

  final BaseSocketWrapper _socket;

  final Map<String, XmppManagerBase> _managers = {};

  static final JID jid = JID.fromString('testuser@example.org/abc123');
  static final ConnectionSettings settings = ConnectionSettings(
    jid: jid,
    password: 'abc123',
    useDirectTLS: true,
  );

  Future<XMLNode> _sendStanza(
    stanza, {
    StanzaFromType addFrom = StanzaFromType.full,
    bool addId = true,
    bool awaitable = true,
    bool encrypted = false,
    bool forceEncryption = false,
  }) async {
    return XMLNode.fromString('<iq />');
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
          _socket,
        ),
        getConnectionSettings: () => settings,
        sendNonza: (_) {},
        sendEvent: (_) {},
        getSocket: () => _socket,
        getNegotiatorById: getNegotiatorNullStub,
        getFullJID: () => jid,
        getManagerById: _getManagerById,
      ),
    );

    await manager.postRegisterCallback();
    _managers[manager.id] = manager;
  }
}
