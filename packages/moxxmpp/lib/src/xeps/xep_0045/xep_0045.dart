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

enum ConversationType { chat, groupchat, groupchatprivate }

class ConversationTypeData extends StanzaHandlerExtension {
  ConversationTypeData(this.conversationType);
  final ConversationType conversationType;
}

class MUCManager extends XmppManagerBase {
  MUCManager() : super(mucManager);

  @override
  Future<bool> isSupported() async => true;

  /// Map full JID to RoomState
  final Map<JID, RoomState> _mucRoomCache = {};

  /// Cache lock
  final Lock _cacheLock = Lock();

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
      await _cacheLock.synchronized(
        () async {
          _mucRoomCache[roomJID] = RoomState(
            roomJid: roomJID,
            roomInformation: roomInformation,
          );
        },
      );
      return Result(roomInformation);
    } catch (e) {
      return Result(InvalidDiscoInfoResponse);
    }
  }

  Future<Result<bool, MUCError>> joinRoom(
    JID roomJID,
    String nick,
  ) async {
    if (nick.isEmpty) {
      return Result(NoNicknameSpecified());
    }
    await getAttributes().sendStanza(
      StanzaDetails(
        Stanza.presence(
          to: roomJID.withResource(nick).toString(),
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
      () async {
        _mucRoomCache[roomJID]!.nick = nick;
      },
    );
    return const Result(true);
  }

  Future<Result<bool, MUCError>> leaveRoom(
    JID roomJID,
  ) async {
    String? nick;
    await _cacheLock.synchronized(
      () async {
        nick = _mucRoomCache[roomJID]!.nick;
      },
    );
    if (nick!.isEmpty) {
      return Result(NoNicknameSpecified());
    }
    await getAttributes().sendStanza(
      StanzaDetails(
        Stanza.presence(
          to: roomJID.withResource(nick!).toString(),
          type: 'unavailable',
        ),
      ),
    );
    await _cacheLock.synchronized(
      () async {
        _mucRoomCache.remove(roomJID);
      },
    );
    return const Result(true);
  }
}
