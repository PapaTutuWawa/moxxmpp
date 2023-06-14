import 'package:moxxmpp/moxxmpp.dart';
import 'package:test/test.dart';
import '../helpers/logging.dart';
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
  initLogger();

  group('Test the XEP-0352 implementation', () {
    test('Test setting the CSI state when CSI is unsupported', () {
      var nonzaSent = false;
      CSIManager()
        ..register(
          XmppManagerAttributes(
            sendStanza: (
              _, {
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
            ),
            getManagerById: getManagerNullStub,
            getNegotiatorById: getUnsupportedCSINegotiator,
            getFullJID: () => JID.fromString('some.user@example.server/aaaaa'),
            getSocket: () => StubTCPSocket([]),
            getConnection: () => XmppConnection(
              TestingReconnectionPolicy(),
              AlwaysConnectedConnectivityManager(),
              ClientToServerNegotiator(),
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
            ),
            getManagerById: getManagerNullStub,
            getNegotiatorById: getSupportedCSINegotiator,
            getFullJID: () => JID.fromString('some.user@example.server/aaaaa'),
            getSocket: () => StubTCPSocket([]),
            getConnection: () => XmppConnection(
              TestingReconnectionPolicy(),
              AlwaysConnectedConnectivityManager(),
              ClientToServerNegotiator(),
              StubTCPSocket([]),
            ),
          ),
        )
        ..setActive()
        ..setInactive();
    });
  });

  test('Test CSI with Bind2', () async {
    final fakeSocket = StubTCPSocket([
      StringExpectation(
        "<stream:stream xmlns='jabber:client' version='1.0' xmlns:stream='http://etherx.jabber.org/streams' to='test.server' from='polynomdivision@test.server' xml:lang='en'>",
        '''
<stream:stream
    xmlns="jabber:client"
    version="1.0"
    xmlns:stream="http://etherx.jabber.org/streams"
    from="test.server"
    xml:lang="en">
  <stream:features xmlns="http://etherx.jabber.org/streams">
    <mechanisms xmlns="urn:ietf:params:xml:ns:xmpp-sasl">
      <mechanism>PLAIN</mechanism>
    </mechanisms>
    <authentication xmlns='urn:xmpp:sasl:2'>
      <mechanism>PLAIN</mechanism>
      <inline>
        <bind xmlns="urn:xmpp:bind:0">
          <inline>
            <feature var="urn:xmpp:csi:0" />
          </inline>
        </bind>
      </inline>
    </authentication>
    <bind xmlns="urn:ietf:params:xml:ns:xmpp-bind">
      <required/>
    </bind>
  </stream:features>''',
      ),
      StanzaExpectation(
        '''
<authenticate xmlns='urn:xmpp:sasl:2' mechanism='PLAIN'>
  <user-agent id='d4565fa7-4d72-4749-b3d3-740edbf87770'>
    <software>moxxmpp</software>
    <device>PapaTutuWawa's awesome device</device>
  </user-agent>
  <initial-response>AHBvbHlub21kaXZpc2lvbgBhYWFh</initial-response>
  <bind xmlns='urn:xmpp:bind:0'>
    <inactive xmlns='urn:xmpp:csi:0' />
  </bind>
</authenticate>''',
        '''
<success xmlns='urn:xmpp:sasl:2'>
  <authorization-identifier>polynomdivision@test.server/test-resource</authorization-identifier>
</success>
        ''',
      ),
    ]);
    final conn = XmppConnection(
      TestingReconnectionPolicy(),
      AlwaysConnectedConnectivityManager(),
      ClientToServerNegotiator(),
      fakeSocket,
    )..connectionSettings = ConnectionSettings(
        jid: JID.fromString('polynomdivision@test.server'),
        password: 'aaaa',
      );
    final csi = CSIManager();
    await csi.setInactive(sendNonza: false);
    await conn.registerManagers([
      RosterManager(TestingRosterStateManager('', [])),
      DiscoManager([]),
      csi,
    ]);
    await conn.registerFeatureNegotiators([
      SaslPlainNegotiator(),
      ResourceBindingNegotiator(),
      FASTSaslNegotiator(),
      Bind2Negotiator(),
      CSINegotiator(),
      Sasl2Negotiator()
        ..userAgent = const UserAgent(
          id: 'd4565fa7-4d72-4749-b3d3-740edbf87770',
          software: 'moxxmpp',
          device: "PapaTutuWawa's awesome device",
        ),
    ]);

    final result = await conn.connect(
      waitUntilLogin: true,
      shouldReconnect: false,
      enableReconnectOnSuccess: false,
    );
    expect(result.isType<NegotiatorError>(), false);
    expect(fakeSocket.getState(), 2);
    expect(
      conn.getNegotiatorById<CSINegotiator>(csiNegotiator)!.isSupported,
      true,
    );
  });
}
