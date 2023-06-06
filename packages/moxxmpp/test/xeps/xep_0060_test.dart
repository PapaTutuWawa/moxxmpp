import 'package:moxxmpp/moxxmpp.dart';
import 'package:test/test.dart';

import '../helpers/logging.dart';
import '../helpers/manager.dart';
import '../helpers/xmpp.dart';

class StubbedDiscoManager extends DiscoManager {
  StubbedDiscoManager(this._itemError) : super([]);

  final bool _itemError;

  @override
  Future<Result<DiscoError, DiscoInfo>> discoInfoQuery(
    JID entity, {
    String? node,
    bool shouldEncrypt = true,
    bool shouldCache = true,
  }) async {
    final result = DiscoInfo.fromQuery(
      XMLNode.fromString('''
<query xmlns='http://jabber.org/protocol/disco#info'>
  <identity category='pubsub' type='service' />
  <feature var="http://jabber.org/protocol/pubsub" />
  <feature var="http://jabber.org/protocol/pubsub#multi-items" />
</query>'''),
      JID.fromString('pubsub.server.example.org'),
    );

    return Result(result);
  }

  @override
  Future<Result<DiscoError, List<DiscoItem>>> discoItemsQuery(
    JID entity, {
    String? node,
    bool shouldEncrypt = true,
  }) async {
    if (_itemError) {
      return Result(
        UnknownDiscoError(),
      );
    }
    return const Result<DiscoError, List<DiscoItem>>(
      <DiscoItem>[],
    );
  }
}

void main() {
  initLogger();

  test(
      'Test pre-processing with pubsub#max_items when the server does not support it (1/2)',
      () async {
    final manager = PubSubManager();
    final tm = TestingManagerHolder();
    await tm.register(StubbedDiscoManager(false));
    await tm.register(manager);

    final result = await manager.preprocessPublishOptions(
      JID.fromString('pubsub.server.example.org'),
      'urn:xmpp:omemo:2:bundles',
      const PubSubPublishOptions(maxItems: 'max'),
    );

    expect(result.maxItems, '1');
  });

  test(
      'Test pre-processing with pubsub#max_items when the server does not support it (2/2)',
      () async {
    final manager = PubSubManager();
    final tm = TestingManagerHolder();
    await tm.register(StubbedDiscoManager(true));
    await tm.register(manager);

    final result = await manager.preprocessPublishOptions(
      JID.fromString('pubsub.server.example.org'),
      'urn:xmpp:omemo:2:bundles',
      const PubSubPublishOptions(maxItems: 'max'),
    );

    expect(result.maxItems, '1');
  });

  test(
      'Test publishing with pubsub#max_items when the server does not support it',
      () async {
    final socket = StubTCPSocket.authenticated(
      TestingManagerHolder.settings,
      [
        StanzaExpectation(
          '''
<iq type="get" to="pubsub.server.example.org" id="a" xmlns="jabber:client">
  <query xmlns="http://jabber.org/protocol/disco#info" />
</iq>
''',
          '''
<iq type="result" from="pubsub.server.example.org" id="a" xmlns="jabber:client">
  <query xmlns="http://jabber.org/protocol/disco#info">
    <identity category='pubsub' type='service' />
    <feature var="http://jabber.org/protocol/pubsub" />
    <feature var="http://jabber.org/protocol/pubsub#multi-items" />
  </query>
</iq>
''',
          ignoreId: true,
          adjustId: true,
        ),
        StanzaExpectation(
          '''
<iq type="get" to="pubsub.server.example.org" id="a" xmlns="jabber:client">
  <query xmlns="http://jabber.org/protocol/disco#items" node="princely_musings" />
</iq>
''',
          '''
<iq type="result" from="pubsub.server.example.org" id="a" xmlns="jabber:client">
  <query xmlns="http://jabber.org/protocol/disco#items" node="princely_musings" />
</iq>
''',
          ignoreId: true,
          adjustId: true,
        ),
        StanzaExpectation(
          '''
<iq type="set" to="pubsub.server.example.org" id="a" xmlns="jabber:client">
  <pubsub xmlns='http://jabber.org/protocol/pubsub'>
    <publish node='princely_musings'>
      <item id="current">
        <test-item />
      </item>
    </publish>
    <publish-options>
      <x xmlns='jabber:x:data' type='submit'>
        <field var='FORM_TYPE' type='hidden'>
          <value>http://jabber.org/protocol/pubsub#publish-options</value>
        </field>
        <field var='pubsub#max_items'>
          <value>1</value>
        </field>
      </x>
    </publish-options>
  </pubsub>
</iq>''',
          '''
<iq type="result" from="pubsub.server.example.org" id="a" xmlns="jabber:client">
  <pubsub xmlns='http://jabber.org/protocol/pubsub'>
    <publish node='princely_musings'>
      <item id='current'/>
    </publish>
  </pubsub>
</iq>''',
          ignoreId: true,
          adjustId: true,
        )
      ],
    );

    final connection = XmppConnection(
      TestingReconnectionPolicy(),
      AlwaysConnectedConnectivityManager(),
      ClientToServerNegotiator(),
      socket,
    )..connectionSettings = TestingManagerHolder.settings;

    await connection.registerManagers([
      PubSubManager(),
      DiscoManager([]),
      PresenceManager(),
      RosterManager(TestingRosterStateManager(null, [])),
    ]);
    await connection.registerFeatureNegotiators([
      SaslPlainNegotiator(),
      ResourceBindingNegotiator(),
    ]);
    await connection.connect(
      waitUntilLogin: true,
    );

    final item = XMLNode(tag: 'test-item');
    final result =
        await connection.getManagerById<PubSubManager>(pubsubManager)!.publish(
              JID.fromString('pubsub.server.example.org'),
              'princely_musings',
              item,
              id: 'current',
              options: const PubSubPublishOptions(maxItems: 'max'),
            );

    expect(result.isType<bool>(), true);
  });
}
