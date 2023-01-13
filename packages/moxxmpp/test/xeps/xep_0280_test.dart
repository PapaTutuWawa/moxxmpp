import 'package:moxxmpp/moxxmpp.dart';
import 'package:test/test.dart';
import '../helpers/xmpp.dart';

void main() {
  test("Test if we're vulnerable against CVE-2020-26547 style vulnerabilities", () async {
    final attributes = XmppManagerAttributes(
      sendStanza: (stanza, { StanzaFromType addFrom = StanzaFromType.full, bool addId = true, bool retransmitted = false, bool awaitable = true, bool encrypted = false }) async {
        // ignore: avoid_print
        print('==> ${stanza.toXml()}');
        return XMLNode(tag: 'iq', attributes: { 'type': 'result' });
      },
      sendNonza: (nonza) {},
      sendEvent: (event) {},
      getManagerById: getManagerNullStub,
      getConnectionSettings: () => ConnectionSettings(
        jid: JID.fromString('bob@xmpp.example'),
        password: 'password',
        useDirectTLS: true,
        allowPlainAuth: false,
      ),
      isFeatureSupported: (_) => false,
      getFullJID: () => JID.fromString('bob@xmpp.example/uwu'),
      getSocket: () => StubTCPSocket(play: []),
      getConnection: () => XmppConnection(TestingReconnectionPolicy(), StubTCPSocket(play: [])),
      getNegotiatorById: getNegotiatorNullStub,
    );
    final manager = CarbonsManager();
    manager.register(attributes);
    await manager.enableCarbons();

    expect(manager.isCarbonValid(JID.fromString('mallory@evil.example')), false);
    expect(manager.isCarbonValid(JID.fromString('bob@xmpp.example')), true);
    expect(manager.isCarbonValid(JID.fromString('bob@xmpp.example/abc')), false);
  });
}
