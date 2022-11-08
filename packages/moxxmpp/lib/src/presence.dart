import 'package:moxxmpp/src/connection.dart';
import 'package:moxxmpp/src/events.dart';
import 'package:moxxmpp/src/jid.dart';
import 'package:moxxmpp/src/managers/base.dart';
import 'package:moxxmpp/src/managers/data.dart';
import 'package:moxxmpp/src/managers/handlers.dart';
import 'package:moxxmpp/src/managers/namespaces.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/stanza.dart';
import 'package:moxxmpp/src/stringxml.dart';
import 'package:moxxmpp/src/xeps/xep_0030/types.dart';
import 'package:moxxmpp/src/xeps/xep_0030/xep_0030.dart';
import 'package:moxxmpp/src/xeps/xep_0115.dart';
import 'package:moxxmpp/src/xeps/xep_0414.dart';

class PresenceManager extends XmppManagerBase {

  PresenceManager() : _capabilityHash = null, super();
  String? _capabilityHash;
  
  @override
  String getId() => presenceManager;

  @override
  String getName() => 'PresenceManager';

  @override
  List<StanzaHandler> getIncomingStanzaHandlers() => [
    StanzaHandler(
      stanzaTag: 'presence',
      callback: _onPresence,
    )
  ];

  @override
  List<String> getDiscoFeatures() => [ capsXmlns ];

  @override
  Future<bool> isSupported() async => true;
  
  Future<StanzaHandlerData> _onPresence(Stanza presence, StanzaHandlerData state) async {
    final attrs = getAttributes();
    switch (presence.type) {
      case 'subscribe':
      case 'subscribed': {
        attrs.sendEvent(
          SubscriptionRequestReceivedEvent(from: JID.fromString(presence.from!)),
        );
        return state.copyWith(done: true);
      }
      default: break;
    }

    if (presence.from != null) {
      logger.finest("Received presence from '${presence.from}'");

      getAttributes().sendEvent(PresenceReceivedEvent(JID.fromString(presence.from!), presence));
      return state.copyWith(done: true);
    } 

    return state;
  }

  /// Returns the capability hash.
  Future<String> getCapabilityHash() async {
    final manager = getAttributes().getManagerById(discoManager)! as DiscoManager;
    _capabilityHash ??= await calculateCapabilityHash(
      DiscoInfo(
        manager.getRegisteredDiscoFeatures(),
        manager.getIdentities(),
        [],
        getAttributes().getFullJID(),
      ),
      getHashByName('sha-1')!,
    );

    return _capabilityHash!;
  }
  
  /// Sends the initial presence to enable receiving messages.
  Future<void> sendInitialPresence() async {
    final attrs = getAttributes();
    attrs.sendNonza(
      Stanza.presence(
        from: attrs.getFullJID().toString(),
        children: [
          XMLNode(
            tag: 'show',
            text: 'chat',
          ),
          XMLNode.xmlns(
            tag: 'c',
            xmlns: capsXmlns,
            attributes: {
              'hash': 'sha-1',
              'node': 'http://moxxy.im',
              'ver': await getCapabilityHash()
            },
          )
        ],
      ),
    );
  }

  /// Send an unavailable presence with no 'to' attribute.
  void sendUnavailablePresence() {
    getAttributes().sendStanza(
      Stanza.presence(
        type: 'unavailable',
      ),
      addFrom: StanzaFromType.full,
    );
  }
  
  /// Sends a subscription request to [to].
  void sendSubscriptionRequest(String to) {
    getAttributes().sendStanza(
      Stanza.presence(
        type: 'subscribe',
        to: to,
      ),
      addFrom: StanzaFromType.none,
    );
  }

  /// Sends an unsubscription request to [to].
  void sendUnsubscriptionRequest(String to) {
    getAttributes().sendStanza(
      Stanza.presence(
        type: 'unsubscribe',
        to: to,
      ),
      addFrom: StanzaFromType.none,
    );
  }

  /// Accept a presence subscription request for [to].
  void sendSubscriptionRequestApproval(String to) {
    getAttributes().sendStanza(
      Stanza.presence(
        type: 'subscribed',
        to: to,
      ),
      addFrom: StanzaFromType.none,
    );
  }

  /// Reject a presence subscription request for [to].
  void sendSubscriptionRequestRejection(String to) {
    getAttributes().sendStanza(
      Stanza.presence(
        type: 'unsubscribed',
        to: to,
      ),
      addFrom: StanzaFromType.none,
    );
  }
}
