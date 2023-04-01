import 'dart:async';
import 'package:moxxmpp/src/connection.dart';
import 'package:moxxmpp/src/events.dart';
import 'package:moxxmpp/src/jid.dart';
import 'package:moxxmpp/src/managers/base.dart';
import 'package:moxxmpp/src/negotiators/negotiator.dart';
import 'package:moxxmpp/src/settings.dart';
import 'package:moxxmpp/src/socket.dart';
import 'package:moxxmpp/src/stanza.dart';
import 'package:moxxmpp/src/stringxml.dart';

class XmppManagerAttributes {
  XmppManagerAttributes({
    required this.sendStanza,
    required this.sendNonza,
    required this.getManagerById,
    required this.sendEvent,
    required this.getConnectionSettings,
    required this.getFullJID,
    required this.getSocket,
    required this.getConnection,
    required this.getNegotiatorById,
  });

  /// Send a stanza whose response can be awaited.
  final Future<XMLNode> Function(
    Stanza stanza, {
    StanzaFromType addFrom,
    bool addId,
    bool awaitable,
    bool encrypted,
    bool forceEncryption,
  }) sendStanza;

  /// Send a nonza.
  final void Function(XMLNode) sendNonza;

  /// Send an event to the connection's event channel.
  final void Function(XmppEvent) sendEvent;

  /// Get the connection settings of the attached connection.
  final ConnectionSettings Function() getConnectionSettings;

  /// (Maybe) Get a Manager attached to the connection by its Id.
  final T? Function<T extends XmppManagerBase>(String) getManagerById;

  /// Returns the full JID of the current account
  final JID Function() getFullJID;

  /// Returns the current socket. MUST NOT be used to send data.
  final BaseSocketWrapper Function() getSocket;

  /// Return the [XmppConnection] the manager is registered against.
  final XmppConnection Function() getConnection;

  final T? Function<T extends XmppFeatureNegotiatorBase>(String)
      getNegotiatorById;
}
