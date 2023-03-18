import 'package:moxxmpp/moxxmpp.dart';
import 'package:test/test.dart';
import '../helpers/xmpp.dart';

class MockedCSINegotiator extends CSINegotiator {
  MockedCSINegotiator(this._isSupported);

  final bool _isSupported;

  @override
  bool get isSupported => _isSupported;
}

T? getSupportedCSINegotiator<T extends XmppFeatureNegotiatorBase>(String id) {
  if (id == csiNegotiator) {
    return MockedCSINegotiator(true) as T;
  }

  return null;
}

T? getUnsupportedCSINegotiator<T extends XmppFeatureNegotiatorBase>(String id) {
  if (id == csiNegotiator) {
    return MockedCSINegotiator(false) as T;
  }

  return null;
}

void main() {
  group('Test the XEP-0352 implementation', () {
    test('Test setting the CSI state when CSI is unsupported', () {
      var nonzaSent = false;
      CSIManager()
        ..register(
          XmppManagerAttributes(
            sendStanza: (
              _, {
              StanzaFromType addFrom = StanzaFromType.full,
              bool addId = true,
              bool retransmitted = false,
              bool awaitable = true,
              bool encrypted = false,
              bool forceEncryption = false,
            }) async =>
                XMLNode(tag: 'hallo'),
            sendEvent: (event) {},
            sendNonza: (nonza) {
              nonzaSent = true;
            },
            getConnectionSettings: () => ConnectionSettings(
              jid: JID.fromString('some.user@example.server'),
              password: 'password',
              useDirectTLS: true,
            ),
            getManagerById: getManagerNullStub,
            getNegotiatorById: getUnsupportedCSINegotiator,
            isFeatureSupported: (_) => false,
            getFullJID: () => JID.fromString('some.user@example.server/aaaaa'),
            getSocket: () => StubTCPSocket([]),
            getConnection: () => XmppConnection(
              TestingReconnectionPolicy(),
              AlwaysConnectedConnectivityManager(),
              StubTCPSocket([]),
            ),
          ),
        )
        ..setActive()
        ..setInactive();

      expect(nonzaSent, false, reason: 'Expected that no nonza is sent');
    });
    test('Test setting the CSI state when CSI is supported', () {
      CSIManager()
        ..register(
          XmppManagerAttributes(
            sendStanza: (
              _, {
              StanzaFromType addFrom = StanzaFromType.full,
              bool addId = true,
              bool retransmitted = false,
              bool awaitable = true,
              bool encrypted = false,
              bool forceEncryption = false,
            }) async =>
                XMLNode(tag: 'hallo'),
            sendEvent: (event) {},
            sendNonza: (nonza) {
              expect(
                nonza.attributes['xmlns'] == csiXmlns,
                true,
                reason: "Expected only nonzas with XMLNS '$csiXmlns'",
              );
            },
            getConnectionSettings: () => ConnectionSettings(
              jid: JID.fromString('some.user@example.server'),
              password: 'password',
              useDirectTLS: true,
            ),
            getManagerById: getManagerNullStub,
            getNegotiatorById: getSupportedCSINegotiator,
            isFeatureSupported: (_) => false,
            getFullJID: () => JID.fromString('some.user@example.server/aaaaa'),
            getSocket: () => StubTCPSocket([]),
            getConnection: () => XmppConnection(
              TestingReconnectionPolicy(),
              AlwaysConnectedConnectivityManager(),
              StubTCPSocket([]),
            ),
          ),
        )
        ..setActive()
        ..setInactive();
    });
  });
}
