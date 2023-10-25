import 'dart:async';
import 'dart:convert';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:test/test.dart';

import 'xml.dart';

T? getNegotiatorNullStub<T extends XmppFeatureNegotiatorBase>(String id) {
  return null;
}

T? getManagerNullStub<T extends XmppManagerBase>(String id) {
  return null;
}

abstract class ExpectationBase {
  ExpectationBase(this.expectation, this.response);

  final String expectation;
  final String response;

  /// Return true if [input] matches the expectation
  bool matches(String input);
}

/// Literally compare the input with the expectation
class StringExpectation extends ExpectationBase {
  StringExpectation(super.expectation, super.response);

  @override
  bool matches(String input) => input == expectation;
}

///
class StanzaExpectation extends ExpectationBase {
  StanzaExpectation(
    super.expectation,
    super.response, {
    this.ignoreId = false,
    this.adjustId = false,
  });
  final bool ignoreId;
  final bool adjustId;

  @override
  bool matches(String input) {
    final ex = XMLNode.fromString(expectation);
    final recv = XMLNode.fromString(input);

    return compareXMLNodes(recv, ex, ignoreId: ignoreId);
  }
}

/// be set to true.
List<ExpectationBase> buildAuthenticatedPlay(ConnectionSettings settings) {
  final plain = base64.encode(
    utf8.encode('\u0000${settings.jid.local}\u0000${settings.password}'),
  );
  return [
    StringExpectation(
      "<stream:stream xmlns='jabber:client' version='1.0' xmlns:stream='http://etherx.jabber.org/streams' to='${settings.jid.domain}' from='${settings.jid.toBare()}' xml:lang='en'>",
      '''
<stream:stream
    xmlns="jabber:client"
    version="1.0"
    xmlns:stream="http://etherx.jabber.org/streams"
    from="${settings.jid.domain}"
    xml:lang="en">
  <stream:features xmlns="http://etherx.jabber.org/streams">
    <mechanisms xmlns="urn:ietf:params:xml:ns:xmpp-sasl">
      <mechanism>PLAIN</mechanism>
    </mechanisms>
  </stream:features>''',
    ),
    StringExpectation(
      "<auth xmlns='urn:ietf:params:xml:ns:xmpp-sasl' mechanism='PLAIN'>$plain</auth>",
      '<success xmlns="urn:ietf:params:xml:ns:xmpp-sasl" />',
    ),
    StringExpectation(
      "<stream:stream xmlns='jabber:client' version='1.0' xmlns:stream='http://etherx.jabber.org/streams' to='${settings.jid.domain}' from='${settings.jid.toBare()}' xml:lang='en'>",
      '''
<stream:stream
    xmlns="jabber:client"
    version="1.0"
    xmlns:stream="http://etherx.jabber.org/streams"
    from="test.server"
    xml:lang="en">
  <stream:features xmlns="http://etherx.jabber.org/streams">
    <bind xmlns="urn:ietf:params:xml:ns:xmpp-bind">
      <required/>
    </bind>
    <ver xmlns='urn:xmpp:features:rosterver'/>
  </stream:features>
''',
    ),
    StanzaExpectation(
      '<iq xmlns="jabber:client" type="set" id="a"><bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"/></iq>',
      '<iq xmlns="jabber:client" type="result" id="a"><bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"><jid>${settings.jid.toBare()}/MU29eEZn</jid></bind></iq>',
      ignoreId: true,
    ),
    StanzaExpectation(
      "<presence xmlns='jabber:client'><show>chat</show></presence>",
      '',
    ),
  ];
}

class StubTCPSocket extends BaseSocketWrapper {
  // Request -> Response(s)
  StubTCPSocket(this._play);

  StubTCPSocket.authenticated(
    ConnectionSettings settings,
    List<ExpectationBase> play,
  ) : _play = [
          ...buildAuthenticatedPlay(settings),
          ...play,
        ];

  int _state = 0;
  final StreamController<String> _dataStream =
      StreamController<String>.broadcast();
  final StreamController<XmppSocketEvent> _eventStream =
      StreamController<XmppSocketEvent>.broadcast();
  final List<ExpectationBase> _play;
  String? lastId;

  @override
  bool isSecure() => true;

  @override
  Future<bool> secure(String domain) async => true;

  @override
  Future<bool> connect(String domain, {String? host, int? port}) async => true;

  @override
  Stream<String> getDataStream() => _dataStream.stream.asBroadcastStream();
  @override
  Stream<XmppSocketEvent> getEventStream() =>
      _eventStream.stream.asBroadcastStream();

  /// "Closes" the socket unexpectedly
  void injectSocketFault() {
    _eventStream.add(XmppSocketClosureEvent(false));
  }

  /// Let the "connection" receive [data].
  void injectRawXml(String data) {
    // ignore: avoid_print
    print('<== $data');
    _dataStream.add(data);
  }

  @override
  void write(Object? object, {String? redact}) {
    var str = object! as String;
    // ignore: avoid_print
    print('==> $str');

    if (_state >= _play.length) {
      _state++;
      return;
    }

    final expectation = _play[_state];

    // TODO(Unknown): Implement an XML matcher
    if (str.startsWith("<?xml version='1.0'?>")) {
      str = str.substring(21);
    }

    if (str.endsWith('</stream:stream>')) {
      str = str.substring(0, str.length - 16);
    }

    expect(
      expectation.matches(str),
      true,
      reason: 'Expected ${expectation.expectation}, got $str',
    );

    // Make sure to only progress if everything passed so far
    _state++;

    var response = expectation.response;
    if (expectation is StanzaExpectation) {
      final inputNode = XMLNode.fromString(str);
      lastId = inputNode.attributes['id'] as String?;

      if (expectation.adjustId) {
        final outputNode = XMLNode.fromString(response);

        outputNode.attributes['id'] = inputNode.attributes['id'];
        response = outputNode.toXml();
      }
    }

    // ignore: avoid_print
    print('<== $response');
    _dataStream.add(response);
  }

  @override
  void close() {}

  int getState() => _state;
  void resetState() => _state = 0;

  @override
  bool whitespacePingAllowed() => true;

  @override
  bool managesKeepalives() => false;
}
