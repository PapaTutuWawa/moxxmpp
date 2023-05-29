import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxmpp/src/xeps/xep_0045/errors.dart';
import 'package:moxxmpp/src/xeps/xep_0045/types.dart';

class MUCManager extends XmppManagerBase {
  MUCManager() : super(mucManager);

  @override
  Future<bool> isSupported() async => true;

  Future<Result<RoomInformation, MUCError>> queryRoomInformation(
      String roomJID) async {
    final attrs = getAttributes();
    try {
      final result = await attrs.sendStanza(
        StanzaDetails(
          Stanza.iq(
            type: 'get',
            to: roomJID,
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
}
