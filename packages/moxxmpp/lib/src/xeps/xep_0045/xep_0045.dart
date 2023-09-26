import 'dart:async';
import 'package:moxlib/moxlib.dart';
import 'package:moxxmpp/src/events.dart';
import 'package:moxxmpp/src/jid.dart';
import 'package:moxxmpp/src/managers/base.dart';
import 'package:moxxmpp/src/managers/data.dart';
import 'package:moxxmpp/src/managers/handlers.dart';
import 'package:moxxmpp/src/managers/namespaces.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/presence.dart';
import 'package:moxxmpp/src/stanza.dart';
import 'package:moxxmpp/src/stringxml.dart';
import 'package:moxxmpp/src/xeps/xep_0030/types.dart';
import 'package:moxxmpp/src/xeps/xep_0030/xep_0030.dart';
import 'package:moxxmpp/src/xeps/xep_0045/errors.dart';
import 'package:moxxmpp/src/xeps/xep_0045/events.dart';
import 'package:moxxmpp/src/xeps/xep_0045/types.dart';
import 'package:moxxmpp/src/xeps/xep_0359.dart';
import 'package:synchronized/extension.dart';
import 'package:synchronized/synchronized.dart';

/// (Room JID, nickname)
typedef MUCRoomJoin = (JID, String);

class MUCManager extends XmppManagerBase {
  MUCManager() : super(mucManager);

  @override
  Future<bool> isSupported() async => true;

  /// Map a room's JID to its RoomState
  final Map<JID, RoomState> _mucRoomCache = {};

  /// Mapp a room's JID to a completer waiting for the completion of the join process.
  final Map<JID, Completer<Result<bool, MUCError>>> _mucRoomJoinCompleter = {};

  /// Cache lock
  final Lock _cacheLock = Lock();

  /// Flag indicating whether we joined the rooms added to the room list with
  /// [prepareRoomList].
  bool _joinedPreparedRooms = true;

  @override
  List<StanzaHandler> getIncomingStanzaHandlers() => [
        StanzaHandler(
          stanzaTag: 'message',
          callback: _onMessage,
          // Before the message handler
          priority: -99,
        ),
        StanzaHandler(
          stanzaTag: 'presence',
          callback: _onPresence,
          tagName: 'x',
          tagXmlns: mucUserXmlns,
          // Before the PresenceManager
          priority: PresenceManager.presenceHandlerPriority + 1,
        ),
      ];

  @override
  List<StanzaHandler> getOutgoingPreStanzaHandlers() => [
        StanzaHandler(
          stanzaTag: 'message',
          callback: _onMessageSent,
        ),
      ];

  @override
  Future<void> onXmppEvent(XmppEvent event) async {
    if (event is! StreamNegotiationsDoneEvent) {
      return;
    }

    // Only attempt rejoining if we did not resume the stream and all
    // prepared rooms are already joined.
    if (event.resumed && _joinedPreparedRooms) {
      return;
    }

    final mucJoins = List<MUCRoomJoin>.empty(growable: true);
    await _cacheLock.synchronized(() async {
      // Mark all groupchats as not joined.
      for (final jid in _mucRoomCache.keys) {
        _mucRoomCache[jid]!.joined = false;
        _mucRoomJoinCompleter[jid] = Completer();

        // Re-join all MUCs.
        final state = _mucRoomCache[jid]!;
        mucJoins.add((jid, state.nick!));
      }
    });

    for (final join in mucJoins) {
      final (jid, nick) = join;
      await _sendMucJoin(
        jid,
        nick,
        0,
      );
    }
    _joinedPreparedRooms = true;
  }

  /// Prepares the internal room list to ensure that the rooms
  /// [rooms] are joined once we are connected.
  Future<void> prepareRoomList(List<MUCRoomJoin> rooms) async {
    assert(
      rooms.isNotEmpty,
      'The room list should not be empty',
    );

    await _cacheLock.synchronized(() {
      _joinedPreparedRooms = false;
      for (final room in rooms) {
        final (roomJid, nick) = room;
        _mucRoomCache[roomJid] = RoomState(
          roomJid: roomJid,
          nick: nick,
          joined: false,
        );
      }
    });
  }

  /// Queries the information of a Multi-User Chat room.
  ///
  /// Retrieves the information about the specified MUC room by performing a
  /// disco info query. Returns a [Result] with the [RoomInformation] on success
  /// or an appropriate [MUCError] on failure.
  Future<Result<RoomInformation, MUCError>> queryRoomInformation(
    JID roomJID,
  ) async {
    final result = await getAttributes()
        .getManagerById<DiscoManager>(discoManager)!
        .discoInfoQuery(roomJID);
    if (result.isType<StanzaError>()) {
      return Result(InvalidStanzaFormat());
    }
    try {
      final roomInformation = RoomInformation.fromDiscoInfo(
        discoInfo: result.get<DiscoInfo>(),
      );
      return Result(roomInformation);
    } catch (e) {
      logger.warning('Invalid disco information: $e');
      return Result(InvalidDiscoInfoResponse());
    }
  }

  /// Joins a Multi-User Chat room.
  ///
  /// Joins the specified MUC room using the provided nickname. Sends a presence
  /// stanza with the appropriate attributes to join the room. Returns a [Result]
  /// with a boolean value indicating success or failure, or an [MUCError]
  /// if applicable.
  Future<Result<bool, MUCError>> joinRoom(
    JID roomJid,
    String nick, {
    int? maxHistoryStanzas,
  }) async {
    if (nick.isEmpty) {
      return Result(NoNicknameSpecified());
    }

    final completer =
        await _cacheLock.synchronized<Completer<Result<bool, MUCError>>>(
      () {
        _mucRoomCache[roomJid] = RoomState(
          roomJid: roomJid,
          nick: nick,
          joined: false,
        );

        final completer = Completer<Result<bool, MUCError>>();
        _mucRoomJoinCompleter[roomJid] = completer;
        return completer;
      },
    );

    await _sendMucJoin(roomJid, nick, maxHistoryStanzas);
    return completer.future;
  }

  Future<void> _sendMucJoin(
    JID roomJid,
    String nick,
    int? maxHistoryStanzas,
  ) async {
    await getAttributes().sendStanza(
      StanzaDetails(
        Stanza.presence(
          to: roomJid.withResource(nick).toString(),
          children: [
            XMLNode.xmlns(
              tag: 'x',
              xmlns: mucXmlns,
              children: [
                if (maxHistoryStanzas != null)
                  XMLNode(
                    tag: 'history',
                    attributes: {
                      'maxstanzas': maxHistoryStanzas.toString(),
                    },
                  ),
              ],
            ),
          ],
        ),
        awaitable: false,
      ),
    );
  }

  /// Leaves a Multi-User Chat room.
  ///
  /// Leaves the specified MUC room by sending an 'unavailable' presence stanza.
  /// Removes the corresponding room entry from the cache. Returns a [Result]
  /// with a boolean value indicating success or failure, or an [MUCError]
  /// if applicable.
  Future<Result<bool, MUCError>> leaveRoom(
    JID roomJid,
  ) async {
    final nick = await _cacheLock.synchronized(() {
      final nick = _mucRoomCache[roomJid]?.nick;
      _mucRoomCache.remove(roomJid);
      return nick;
    });
    if (nick == null) {
      return Result(RoomNotJoinedError());
    }
    await getAttributes().sendStanza(
      StanzaDetails(
        Stanza.presence(
          to: roomJid.withResource(nick).toString(),
          type: 'unavailable',
        ),
        awaitable: false,
      ),
    );
    return const Result(true);
  }

  Future<RoomState?> getRoomState(JID roomJid) async {
    return _cacheLock.synchronized(() => _mucRoomCache[roomJid]);
  }

  Future<StanzaHandlerData> _onPresence(
    Stanza presence,
    StanzaHandlerData state,
  ) async {
    if (presence.from == null) {
      return state;
    }

    final from = JID.fromString(presence.from!);
    final bareFrom = from.toBare();
    return _cacheLock.synchronized(() {
      final room = _mucRoomCache[bareFrom];
      if (room == null) {
        return state;
      }

      if (from.resource.isEmpty) {
        // TODO(Unknown): Handle presence from the room itself.
        return state;
      }

      if (presence.type == 'error') {
        final errorTag = presence.firstTag('error')!;
        final error = errorTag.firstTagByXmlns(fullStanzaXmlns)!;
        Result<bool, MUCError> result;
        if (error.tag == 'forbidden') {
          result = Result(JoinForbiddenError());
        } else {
          result = Result(MUCUnspecificError());
        }

        _mucRoomCache.remove(bareFrom);
        _mucRoomJoinCompleter[bareFrom]!.complete(result);
        _mucRoomJoinCompleter.remove(bareFrom);
        return StanzaHandlerData(
          true,
          false,
          presence,
          state.extensions,
        );
      }

      final x = presence.firstTag('x', xmlns: mucUserXmlns)!;
      final item = x.firstTag('item')!;
      final statuses = x
          .findTags('status')
          .map((s) => s.attributes['code']! as String)
          .toList();
      final role = Role.fromString(
        item.attributes['role']! as String,
      );

      if (statuses.contains('110')) {
        if (room.nick != from.resource) {
          // Notify us of the changed nick.
          getAttributes().sendEvent(
            NickChangedByMUCEvent(
              bareFrom,
              from.resource,
            ),
          );
        }

        // Set the nick to make sure we're in sync with the MUC.
        room.nick = from.resource;
        return StanzaHandlerData(
          true,
          false,
          presence,
          state.extensions,
        );
      }

      if (presence.attributes['type'] == 'unavailable' && role == Role.none) {
        // Cannot happen while joining, so we assume we are joined
        assert(
          room.joined,
          'Should not receive unavailable with role="none" while joining',
        );
        room.members.remove(from.resource);
      } else {
        final member = RoomMember(
          from.resource,
          Affiliation.fromString(
            item.attributes['affiliation']! as String,
          ),
          role,
        );
        logger.finest('Got presence from ${from.resource} in $bareFrom');
        if (room.joined) {
          if (room.members.containsKey(from.resource)) {
            getAttributes().sendEvent(
              MemberJoinedEvent(
                bareFrom,
                member,
              ),
            );
          } else {
            getAttributes().sendEvent(
              MemberChangedEvent(
                bareFrom,
                member,
              ),
            );
          }
        }

        room.members[from.resource] = member;
      }

      return StanzaHandlerData(
        true,
        false,
        presence,
        state.extensions,
      );
    });
  }

  Future<StanzaHandlerData> _onMessageSent(
    Stanza message,
    StanzaHandlerData state,
  ) async {
    if (message.to == null) {
      return state;
    }
    final toJid = JID.fromString(message.to!);

    return _cacheLock.synchronized(() {
      if (!_mucRoomCache.containsKey(toJid)) {
        return state;
      }

      _mucRoomCache[toJid]!.pendingMessages.add(
        (message.id!, state.extensions.get<StableIdData>()?.originId),
      );
      return state;
    });
  }

  Future<StanzaHandlerData> _onMessage(
    Stanza message,
    StanzaHandlerData state,
  ) async {
    final fromJid = JID.fromString(message.from!);
    final roomJid = fromJid.toBare();
    return _mucRoomCache.synchronized(() {
      final roomState = _mucRoomCache[roomJid];
      if (roomState == null) {
        return state;
      }

      if (message.type == 'groupchat' && message.firstTag('subject') != null) {
        // The room subject marks the end of the join flow.
        if (!roomState.joined) {
          // Mark the room as joined.
          _mucRoomCache[roomJid]!.joined = true;
          _mucRoomJoinCompleter[roomJid]!.complete(
            const Result(true),
          );
          _mucRoomJoinCompleter.remove(roomJid);
          logger.finest('$roomJid is now joined');
        }

        // TODO(Unknown): Signal the subject?

        return StanzaHandlerData(
          true,
          false,
          message,
          state.extensions,
        );
      } else {
        if (!roomState.joined) {
          // Ignore the discussion history.
          return StanzaHandlerData(
            true,
            false,
            message,
            state.extensions,
          );
        }

        // Check if this is the message reflection.
        if (message.id == null) {
          return state;
        }
        final pending =
            (message.id!, state.extensions.get<StableIdData>()?.originId);
        if (fromJid.resource == roomState.nick &&
            roomState.pendingMessages.contains(pending)) {
          // Silently drop the message.
          roomState.pendingMessages.remove(pending);

          // TODO(Unknown): Maybe send an event stating that we received the reflection.
          return StanzaHandlerData(
            true,
            false,
            message,
            state.extensions,
          );
        }
      }

      return state;
    });
  }
}
