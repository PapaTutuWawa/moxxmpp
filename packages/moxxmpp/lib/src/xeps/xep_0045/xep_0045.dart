import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxmpp/src/xeps/xep_0045/errors.dart';
import 'package:moxxmpp/src/xeps/xep_0045/types.dart';

class MUCManager extends XmppManagerBase {
  MUCManager() : super(mucManager);

  @override
  Future<bool> isSupported() async => true;

  Future<Result<RoomInformation, MUCError>> queryRoomInformation({
    required JID roomJID,
  }) async {
    final attrs = getAttributes();
    try {
      final result = await attrs.sendStanza(
        StanzaDetails(
          Stanza.iq(
            type: 'get',
            to: roomJID.toString(),
            children: [
              XMLNode.xmlns(
                tag: 'query',
                xmlns: discoInfoXmlns,
              )
            ],
          ),
        ),
      );
      final roomInformation =
          RoomInformation.fromStanza(roomJID: roomJID, stanza: result!);
      return Result(roomInformation);
    } catch (e) {
      return Result(InvalidStanzaFormat());
    }
  }

  Future<Result<bool, MUCError>> joinRoom({
    required JID roomJIDWithNickname,
  }) async {
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

  Future<Result<bool, MUCError>> leaveRoom({
    required JID roomJIDWithNickname,
  }) async {
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
