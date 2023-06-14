import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxmpp/src/xeps/xep_0045/errors.dart';
import 'package:moxxmpp/src/xeps/xep_0045/types.dart';

enum ConversationType { chat, groupchat, groupchatprivate }

class ConversationTypeData extends StanzaHandlerExtension {
  ConversationTypeData(this.conversationType);
  final ConversationType conversationType;
}

class MUCManager extends XmppManagerBase {
  MUCManager() : super(mucManager);

  @override
  Future<bool> isSupported() async => true;

  Future<Result<RoomInformation, MUCError>> queryRoomInformation(
    JID roomJID,
  ) async {
    try {
      final attrs = getAttributes();
      final result = await attrs
          .getManagerById<DiscoManager>(discoManager)
          ?.discoInfoQuery(roomJID);
      if (result!.isType<DiscoError>()) {
        return Result(InvalidStanzaFormat());
      }
      final roomInformation = RoomInformation.fromDiscoInfo(
        discoInfo: result.get(),
      );
      return Result(roomInformation);
    } catch (e) {
      return Result(InvalidDiscoInfoResponse);
    }
  }

  Future<Result<bool, MUCError>> joinRoom(
    JID roomJIDWithNickname,
  ) async {
    if (roomJIDWithNickname.resource.isEmpty) {
      return Result(NoNicknameSpecified());
    }
    final attrs = getAttributes();
    try {
      await attrs.sendStanza(
        StanzaDetails(
          Stanza.presence(
            to: roomJIDWithNickname.toString(),
            children: [
              XMLNode.xmlns(
                tag: 'x',
                xmlns: mucXmlns,
              )
            ],
          ),
        ),
      );
      return const Result(true);
    } catch (e) {
      return Result(InvalidStanzaFormat());
    }
  }

  Future<Result<bool, MUCError>> leaveRoom(
    JID roomJIDWithNickname,
  ) async {
    if (roomJIDWithNickname.resource.isEmpty) {
      return Result(NoNicknameSpecified());
    }
    final attrs = getAttributes();
    try {
      await attrs.sendStanza(
        StanzaDetails(
          Stanza.presence(
            to: roomJIDWithNickname.toString(),
            type: 'unavailable',
          ),
        ),
      );
      return const Result(true);
    } catch (e) {
      return Result(InvalidStanzaFormat());
    }
  }
}
