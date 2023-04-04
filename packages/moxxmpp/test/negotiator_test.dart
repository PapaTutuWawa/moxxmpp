import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxmpp/src/buffer.dart';
import 'package:test/test.dart';
import 'helpers/logging.dart';

const exampleXmlns1 = 'im:moxxmpp:example1';
const exampleNamespace1 = 'im.moxxmpp.test.example1';
const exampleXmlns2 = 'im:moxxmpp:example2';
const exampleNamespace2 = 'im.moxxmpp.test.example2';

class StubNegotiator1 extends XmppFeatureNegotiatorBase {
  StubNegotiator1()
      : called = false,
        super(1, false, exampleXmlns1, exampleNamespace1);

  bool called;

  @override
  Future<Result<NegotiatorState, NegotiatorError>> negotiate(
    XMLNode nonza,
  ) async {
    called = true;
    return const Result(NegotiatorState.done);
  }
}

class StubNegotiator2 extends XmppFeatureNegotiatorBase {
  StubNegotiator2()
      : called = false,
        super(10, false, exampleXmlns2, exampleNamespace2);

  bool called;

  @override
  Future<Result<NegotiatorState, NegotiatorError>> negotiate(
    XMLNode nonza,
  ) async {
    called = true;
    return const Result(NegotiatorState.done);
  }
}

void main() {
  initLogger();

  test('Test the priority system', () async {
    final features = [
      XMLNode.xmlns(tag: 'example1', xmlns: exampleXmlns1),
      XMLNode.xmlns(tag: 'example2', xmlns: exampleXmlns2),
    ];

    final negotiator = ClientToServerNegotiator()
      ..register(
        () async {},
        (_) async {},
        () => false,
        (_) {},
        () => ConnectionSettings(
          jid: JID.fromString('test'),
          password: 'abc123',
          useDirectTLS: false,
        ),
      )
      ..registerNegotiator(StubNegotiator1())
      ..registerNegotiator(StubNegotiator2());
    await negotiator.runPostRegisterCallback();
    expect(negotiator.getNextNegotiator(features)?.id, exampleNamespace2);
  });

  test('Test negotiating features with no stream restarts', () async {
    final negotiator = ClientToServerNegotiator()
      ..register(
        () async {},
        (_) async {},
        () => false,
        (_) {},
        () => ConnectionSettings(
          jid: JID.fromString('test'),
          password: 'abc123',
          useDirectTLS: false,
        ),
      )
      ..registerNegotiator(StubNegotiator1())
      ..registerNegotiator(StubNegotiator2());
    await negotiator.runPostRegisterCallback();

    await negotiator.negotiate(
      XmlStreamBufferElement(
        XMLNode.fromString(
          '''
<stream:features xmlns="http://etherx.jabber.org/streams">
  <example1 xmlns="im:moxxmpp:example1" />
  <example2 xmlns="im:moxxmpp:example2" />
</stream:features>''',
        ),
      ),
    );

    expect(
      negotiator.getNegotiatorById<StubNegotiator1>(exampleNamespace1)!.called,
      true,
    );
    expect(
      negotiator.getNegotiatorById<StubNegotiator2>(exampleNamespace2)!.called,
      true,
    );
  });
}
