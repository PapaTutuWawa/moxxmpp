import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:hex/hex.dart';
import 'package:moxxmpp/src/connection_errors.dart';
import 'package:moxxmpp/src/handlers/base.dart';
import 'package:moxxmpp/src/jid.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/negotiators/negotiator.dart';
import 'package:moxxmpp/src/parser.dart';
import 'package:moxxmpp/src/stringxml.dart';

/// Nonza describing the XMPP stream header.
class ComponentStreamHeaderNonza extends XMLNode {
  ComponentStreamHeaderNonza(JID jid)
      : assert(jid.isBare(), 'Component JID must be bare'),
        super(
          tag: 'stream:stream',
          attributes: <String, String>{
            'xmlns': componentAcceptXmlns,
            'xmlns:stream': streamXmlns,
            'to': jid.domain,
          },
          closeTag: false,
        );
}

/// The states the ComponentToServerNegotiator can be in.
enum ComponentToServerState {
  /// No data has been sent or received yet
  idle,

  /// Handshake has been sent
  handshakeSent,
}

/// The ComponentToServerNegotiator is a NegotiationsHandler that allows writing
/// components that adhere to XEP-0114.
class ComponentToServerNegotiator extends NegotiationsHandler {
  ComponentToServerNegotiator();

  /// The state the negotiation handler is currently in
  ComponentToServerState _state = ComponentToServerState.idle;

  @override
  String getStanzaNamespace() => componentAcceptXmlns;

  @override
  void registerNegotiator(XmppFeatureNegotiatorBase negotiator) {}

  @override
  void sendStreamHeader() {
    resetStreamParser();
    sendNonza(
      XMLNode(
        tag: 'xml',
        attributes: {'version': '1.0'},
        closeTag: false,
        isDeclaration: true,
        children: [
          ComponentStreamHeaderNonza(getConnectionSettings().jid),
        ],
      ),
    );
  }

  Future<String> _computeHandshake(String id) async {
    final secret = getConnectionSettings().password;
    return HEX.encode(
      (await Sha1().hash(utf8.encode('$streamId$secret'))).bytes,
    );
  }

  @override
  Future<void> negotiate(XMPPStreamObject event) async {
    switch (_state) {
      case ComponentToServerState.idle:
        if (event is XMPPStreamHeader) {
          streamId = event.attributes['id'];
          assert(
            streamId != null,
            'The server must respond with a stream header that contains an id',
          );

          _state = ComponentToServerState.handshakeSent;
          sendNonza(
            XMLNode(
              tag: 'handshake',
              text: await _computeHandshake(streamId!),
            ),
          );
        } else {
          log.severe('Unexpected data received');
          await handleError(UnexpectedDataError());
        }
        break;
      case ComponentToServerState.handshakeSent:
        if (event is XMPPStreamElement) {
          if (event.node.tag == 'handshake' &&
              event.node.children.isEmpty &&
              event.node.attributes.isEmpty) {
            log.info('Successfully authenticated as component');
            await onNegotiationsDone();
          } else {
            log.warning('Handshake failed');
            await handleError(InvalidHandshakeCredentialsError());
          }
        } else {
          log.severe('Unexpected data received');
          await handleError(UnexpectedDataError());
        }
        break;
    }
  }

  @override
  void reset() {
    _state = ComponentToServerState.idle;

    super.reset();
  }
}
