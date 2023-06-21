import 'package:moxxmpp/src/jid.dart';
import 'package:moxxmpp/src/managers/base.dart';
import 'package:moxxmpp/src/managers/data.dart';
import 'package:moxxmpp/src/managers/namespaces.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/stanza.dart';
import 'package:moxxmpp/src/stringxml.dart';
import 'package:moxxmpp/src/types/result.dart';
import 'package:moxxmpp/src/xeps/xep_0030/errors.dart';
import 'package:moxxmpp/src/xeps/xep_0030/types.dart';
import 'package:moxxmpp/src/xeps/xep_0030/xep_0030.dart';
import 'package:moxxmpp/src/xeps/xep_0045/errors.dart';
import 'package:moxxmpp/src/xeps/xep_0045/types.dart';
import 'package:synchronized/synchronized.dart';

class MUCManager extends XmppManagerBase {
  MUCManager() : super(mucManager);

  @override
  Future<bool> isSupported() async => true;

  /// Map full JID to RoomState
  final Map<JID, RoomState> _mucRoomCache = {};

  /// Cache lock
  final Lock _cacheLock = Lock();

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
    if (result.isType<DiscoError>()) {
      return Result(InvalidStanzaFormat());
    }
    try {
      final roomInformation = RoomInformation.fromDiscoInfo(
        discoInfo: result.get<DiscoInfo>(),
      );
      return Result(roomInformation);
    } catch (e) {
      return Result(InvalidDiscoInfoResponse);
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
    String nick,
  ) async {
    if (nick.isEmpty) {
      return Result(NoNicknameSpecified());
    }
    await getAttributes().sendStanza(
      StanzaDetails(
        Stanza.presence(
          to: roomJid.withResource(nick).toString(),
          children: [
            XMLNode.xmlns(
              tag: 'x',
              xmlns: mucXmlns,
            )
          ],
        ),
      ),
    );
    await _cacheLock.synchronized(
      () {
        _mucRoomCache[roomJid] = RoomState(roomJid: roomJid, nick: nick);
      },
    );
    return const Result(true);
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
      return Result(RoomNotJoinedError);
    }
    await getAttributes().sendStanza(
      StanzaDetails(
        Stanza.presence(
          to: roomJid.withResource(nick!).toString(),
          type: 'unavailable',
        ),
      ),
    );
    return const Result(true);
  }
}
