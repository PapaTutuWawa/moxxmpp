import 'package:moxxmpp/moxxmpp.dart';
import 'package:test/test.dart';
import 'helpers/logging.dart';
import 'helpers/xmpp.dart';

const exampleXmlns1 = 'im:moxxmpp:example1';
const exampleNamespace1 = 'im.moxxmpp.test.example1';
const exampleXmlns2 = 'im:moxxmpp:example2';
const exampleNamespace2 = 'im.moxxmpp.test.example2';

class StubNegotiator1 extends XmppFeatureNegotiatorBase {
  StubNegotiator1() : called = false, super(1, false, exampleXmlns1, exampleNamespace1);

  bool called;
  
  @override
  Future<Result<NegotiatorState, NegotiatorError>> negotiate(XMLNode nonza) async {
    called = true;
    return const Result(NegotiatorState.done);
  }
}

class StubNegotiator2 extends XmppFeatureNegotiatorBase {
  StubNegotiator2() : called = false, super(10, false, exampleXmlns2, exampleNamespace2);

  bool called;
  
  @override
  Future<Result<NegotiatorState, NegotiatorError>> negotiate(XMLNode nonza) async {
    called = true;
    return const Result(NegotiatorState.done);
  }
}

void main() {
  initLogger();

  final stubSocket = StubTCPSocket(
    play: [
      StringExpectation(
        "<stream:stream xmlns='jabber:client' version='1.0' xmlns:stream='http://etherx.jabber.org/streams' to='test.server' xml:lang='en'>",
        '''
<stream:stream
    xmlns="jabber:client"
    version="1.0"
    xmlns:stream="http://etherx.jabber.org/streams"
    from="test.server"
    xml:lang="en">
  <stream:features xmlns="http://etherx.jabber.org/streams">
    <example1 xmlns="im:moxxmpp:example1" />
    <example2 xmlns="im:moxxmpp:example2" />
  </stream:features>''',
      ),
    ],
  );
  
  final connection = XmppConnection(TestingReconnectionPolicy(), stubSocket)
    ..registerFeatureNegotiators([
      StubNegotiator1(),
      StubNegotiator2(),
    ])
    ..registerManagers([
      PresenceManager('http://moxxmpp.example'),
      RosterManager(TestingRosterStateManager('', [])),
      DiscoManager(),
      PingManager(),
    ])
    ..setConnectionSettings(
      ConnectionSettings(
        jid: JID.fromString('user@test.server'),
        password: 'abc123',
        useDirectTLS: true,
        allowPlainAuth: false,
      ),
    );
  final features = [
    XMLNode.xmlns(tag: 'example1', xmlns: exampleXmlns1),
    XMLNode.xmlns(tag: 'example2', xmlns: exampleXmlns2),
  ];

  test('Test the priority system', () {
    expect(connection.getNextNegotiator(features)?.id, exampleNamespace2);
  });

  test('Test negotiating features with no stream restarts', () async {    
    await connection.connect();
    await Future.delayed(const Duration(seconds: 3), () {
      final negotiator1 = connection.getNegotiatorById<StubNegotiator1>(exampleNamespace1);
      final negotiator2 = connection.getNegotiatorById<StubNegotiator2>(exampleNamespace2);
      expect(negotiator1?.called, true);
      expect(negotiator2?.called, true);
    });
  });
}
