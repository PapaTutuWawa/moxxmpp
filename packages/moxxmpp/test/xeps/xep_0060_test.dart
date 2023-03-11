import 'package:moxxmpp/moxxmpp.dart';
import 'package:test/test.dart';

import '../helpers/logging.dart';
import '../helpers/xmpp.dart';

class StubbedDiscoManager extends DiscoManager {
  StubbedDiscoManager() : super([]);

  @override
  Future<Result<DiscoError, DiscoInfo>> discoInfoQuery(String entity, { String? node, bool shouldEncrypt = true }) async {
    final result = DiscoInfo.fromQuery(
      XMLNode.fromString(
        '''<query xmlns='http://jabber.org/protocol/disco#info'>
<identity category='account' type='registered'/>
<identity type='service' category='pubsub' name='PubSub acs-clustered'/>
<feature var='http://jabber.org/protocol/pubsub#retrieve-default'/>
<feature var='http://jabber.org/protocol/pubsub#purge-nodes'/>
<feature var='http://jabber.org/protocol/pubsub#subscribe'/>
<feature var='http://jabber.org/protocol/pubsub#member-affiliation'/>
<feature var='http://jabber.org/protocol/pubsub#subscription-notifications'/>
<feature var='http://jabber.org/protocol/pubsub#create-nodes'/>
<feature var='http://jabber.org/protocol/pubsub#outcast-affiliation'/>
<feature var='http://jabber.org/protocol/pubsub#get-pending'/>
<feature var='http://jabber.org/protocol/pubsub#presence-notifications'/>
<feature var='urn:xmpp:ping'/>
<feature var='http://jabber.org/protocol/pubsub#delete-nodes'/>
<feature var='http://jabber.org/protocol/pubsub#config-node'/>
<feature var='http://jabber.org/protocol/pubsub#retrieve-items'/>
<feature var='http://jabber.org/protocol/pubsub#access-whitelist'/>
<feature var='http://jabber.org/protocol/pubsub#access-presence'/>
<feature var='http://jabber.org/protocol/disco#items'/>
<feature var='http://jabber.org/protocol/pubsub#meta-data'/>
<feature var='http://jabber.org/protocol/pubsub#multi-items'/>
<feature var='http://jabber.org/protocol/pubsub#item-ids'/>
<feature var='urn:xmpp:mam:1'/>
<feature var='http://jabber.org/protocol/pubsub#instant-nodes'/>
<feature var='urn:xmpp:mam:2'/>
<feature var='urn:xmpp:mam:2#extended'/>
<feature var='http://jabber.org/protocol/pubsub#modify-affiliations'/>
<feature var='http://jabber.org/protocol/pubsub#multi-collection'/>
<feature var='http://jabber.org/protocol/pubsub#persistent-items'/>
<feature var='http://jabber.org/protocol/pubsub#create-and-configure'/>
<feature var='http://jabber.org/protocol/pubsub#publisher-affiliation'/>
<feature var='http://jabber.org/protocol/pubsub#access-open'/>
<feature var='http://jabber.org/protocol/pubsub#retrieve-affiliations'/>
<feature var='http://jabber.org/protocol/pubsub#access-authorize'/>
<feature var='jabber:iq:version'/>
<feature var='http://jabber.org/protocol/pubsub#retract-items'/>
<feature var='http://jabber.org/protocol/pubsub#manage-subscriptions'/>
<feature var='http://jabber.org/protocol/commands'/>
<feature var='http://jabber.org/protocol/pubsub#auto-subscribe'/>
<feature var='http://jabber.org/protocol/pubsub#publish-options'/>
<feature var='http://jabber.org/protocol/pubsub#access-roster'/>
<feature var='http://jabber.org/protocol/pubsub#publish'/>
<feature var='http://jabber.org/protocol/pubsub#collections'/>
<feature var='http://jabber.org/protocol/pubsub#retrieve-subscriptions'/>
<feature var='http://jabber.org/protocol/disco#info'/>
<x type='result' xmlns='jabber:x:data'>
<field type='hidden' var='FORM_TYPE'>
<value>http://jabber.org/network/serverinfo</value>
</field>
<field type='list-multi' var='abuse-addresses'>
<value>mailto:support@tigase.net</value>
<value>xmpp:tigase@mix.tigase.im</value>
<value>xmpp:tigase@muc.tigase.org</value>
<value>https://tigase.net/technical-support</value>
</field>
</x>
<feature var='http://jabber.org/protocol/pubsub#auto-create'/>
<feature var='http://jabber.org/protocol/pubsub#auto-subscribe'/>
<feature var='urn:xmpp:mix:pam:2'/>
<feature var='urn:xmpp:carbons:2'/>
<feature var='urn:xmpp:carbons:rules:0'/>
<feature var='jabber:iq:auth'/>
<feature var='vcard-temp'/>
<feature var='http://jabber.org/protocol/amp'/>
<feature var='msgoffline'/>
<feature var='http://jabber.org/protocol/disco#info'/>
<feature var='http://jabber.org/protocol/disco#items'/>
<feature var='urn:xmpp:blocking'/>
<feature var='urn:xmpp:reporting:0'/>
<feature var='urn:xmpp:reporting:abuse:0'/>
<feature var='urn:xmpp:reporting:spam:0'/>
<feature var='urn:xmpp:reporting:1'/>
<feature var='urn:xmpp:ping'/>
<feature var='urn:ietf:params:xml:ns:xmpp-sasl'/>
<feature var='http://jabber.org/protocol/pubsub'/>
<feature var='http://jabber.org/protocol/pubsub#owner'/>
<feature var='http://jabber.org/protocol/pubsub#publish'/>
<identity type='pep' category='pubsub'/>
<feature var='urn:xmpp:pep-vcard-conversion:0'/>
<feature var='urn:xmpp:bookmarks-conversion:0'/>
<feature var='urn:xmpp:archive:auto'/>
<feature var='urn:xmpp:archive:manage'/>
<feature var='urn:xmpp:push:0'/>
<feature var='tigase:push:away:0'/>
<feature var='tigase:push:encrypt:0'/>
<feature var='tigase:push:encrypt:aes-128-gcm'/>
<feature var='tigase:push:filter:ignore-unknown:0'/>
<feature var='tigase:push:filter:groupchat:0'/>
<feature var='tigase:push:filter:muted:0'/>
<feature var='tigase:push:priority:0'/>
<feature var='tigase:push:jingle:0'/>
<feature var='jabber:iq:roster'/>
<feature var='jabber:iq:roster-dynamic'/>
<feature var='urn:xmpp:mam:1'/>
<feature var='urn:xmpp:mam:2'/>
<feature var='urn:xmpp:mam:2#extended'/>
<feature var='urn:xmpp:mix:pam:2#archive'/>
<feature var='jabber:iq:version'/>
<feature var='urn:xmpp:time'/>
<feature var='jabber:iq:privacy'/>
<feature var='urn:ietf:params:xml:ns:xmpp-bind'/>
<feature var='urn:xmpp:extdisco:2'/>
<feature var='http://jabber.org/protocol/commands'/>
<feature var='urn:ietf:params:xml:ns:vcard-4.0'/>
<feature var='jabber:iq:private'/>
<feature var='urn:ietf:params:xml:ns:xmpp-session'/>
</query>'''
      ),
      JID.fromString('pubsub.server.example.org'),
    );

    return Result(result);
  }
}

T? getDiscoManagerStub<T extends XmppManagerBase>(String id) {
  return StubbedDiscoManager() as T;
}
  
void main() {
  initLogger();

  test('Test publishing with pubsub#max_items when the server does not support it', () async {
    XMLNode? sent;
    final manager = PubSubManager();
    manager.register(
      XmppManagerAttributes(
        sendStanza: (stanza, { StanzaFromType addFrom = StanzaFromType.full, bool addId = true, bool awaitable = true, bool encrypted = false, bool forceEncryption = false, }) async {
          sent = stanza;

          return XMLNode.fromString('<iq />');
        },
        sendNonza: (_) {},
        sendEvent: (_) {},
        getManagerById: getDiscoManagerStub,
        getConnectionSettings: () => ConnectionSettings(
          jid: JID.fromString('hallo@example.server'),
          password: 'password',
          useDirectTLS: true,
          allowPlainAuth: false,
        ),
        isFeatureSupported: (_) => false,
        getFullJID: () => JID.fromString('hallo@example.server/uwu'),
        getSocket: () => StubTCPSocket(play: []),
        getConnection: () => XmppConnection(TestingReconnectionPolicy(), AlwaysConnectedConnectivityManager(), StubTCPSocket(play: [])),
        getNegotiatorById: getNegotiatorNullStub,
      ),
    );

  // final result = await manager.preprocessPublishOptions(
  //   'pubsub.server.example.org',
  //   'example:node',
  //   PubSubPublishOptions(
  //     maxItems: 'max', 
  //   ),
  // );

  });
}
