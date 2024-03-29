import 'package:meta/meta.dart';
import 'package:moxlib/moxlib.dart';
import 'package:moxxmpp/src/events.dart';
import 'package:moxxmpp/src/jid.dart';
import 'package:moxxmpp/src/managers/base.dart';
import 'package:moxxmpp/src/managers/data.dart';
import 'package:moxxmpp/src/managers/handlers.dart';
import 'package:moxxmpp/src/managers/namespaces.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/stanza.dart';
import 'package:moxxmpp/src/stringxml.dart';
import 'package:moxxmpp/src/xeps/xep_0004.dart';
import 'package:moxxmpp/src/xeps/xep_0030/errors.dart';
import 'package:moxxmpp/src/xeps/xep_0030/types.dart';
import 'package:moxxmpp/src/xeps/xep_0030/xep_0030.dart';
import 'package:moxxmpp/src/xeps/xep_0060/errors.dart';
import 'package:moxxmpp/src/xeps/xep_0060/helpers.dart';

class PubSubPublishOptions {
  const PubSubPublishOptions({
    this.accessModel,
    this.maxItems,
  });
  final String? accessModel;
  final String? maxItems;

  XMLNode toXml() {
    return DataForm(
      type: 'submit',
      instructions: [],
      reported: [],
      items: [],
      fields: [
        const DataFormField(
          options: [],
          isRequired: false,
          values: [pubsubPublishOptionsXmlns],
          varAttr: 'FORM_TYPE',
          type: 'hidden',
        ),
        if (accessModel != null)
          DataFormField(
            options: [],
            isRequired: false,
            values: [accessModel!],
            varAttr: 'pubsub#access_model',
          ),
        if (maxItems != null)
          DataFormField(
            options: [],
            isRequired: false,
            values: [maxItems!],
            varAttr: 'pubsub#max_items',
          ),
      ],
    ).toXml();
  }
}

class PubSubItem {
  const PubSubItem({
    required this.id,
    required this.node,
    required this.payload,
  });
  final String id;
  final String node;
  final XMLNode payload;

  @override
  String toString() => '$id: ${payload.toXml()}';
}

class PubSubManager extends XmppManagerBase {
  PubSubManager() : super(pubsubManager);

  @override
  List<StanzaHandler> getIncomingStanzaHandlers() => [
        StanzaHandler(
          stanzaTag: 'message',
          tagName: 'event',
          tagXmlns: pubsubEventXmlns,
          callback: _onPubsubMessage,
        ),
      ];

  @override
  Future<bool> isSupported() async => true;

  Future<StanzaHandlerData> _onPubsubMessage(
    Stanza message,
    StanzaHandlerData state,
  ) async {
    logger.finest('Received PubSub event');
    final event = message.firstTag('event', xmlns: pubsubEventXmlns)!;
    final items = event.firstTag('items')!;
    final item = items.firstTag('item')!;

    getAttributes().sendEvent(
      PubSubNotificationEvent(
        item: PubSubItem(
          id: item.attributes['id']! as String,
          node: items.attributes['node']! as String,
          payload: item.children[0],
        ),
        from: message.attributes['from']! as String,
      ),
    );

    return state..done = true;
  }

  Future<int> _getNodeItemCount(JID jid, String node) async {
    final dm = getAttributes().getManagerById<DiscoManager>(discoManager)!;
    final response = await dm.discoItemsQuery(jid, node: node);
    var count = 0;
    if (response.isType<DiscoError>()) {
      logger.warning(
        '_getNodeItemCount: disco#items query failed. Assuming no items.',
      );
    } else {
      count = response.get<List<DiscoItem>>().length;
    }

    return count;
  }

  // TODO(PapaTutuWawa): This should return a Result<T> in case we cannot proceed
  //                     with the requested configuration.
  @visibleForTesting
  Future<PubSubPublishOptions> preprocessPublishOptions(
    JID jid,
    String node,
    PubSubPublishOptions options,
  ) async {
    if (options.maxItems != null) {
      final dm = getAttributes().getManagerById<DiscoManager>(discoManager)!;
      final result = await dm.discoInfoQuery(jid);
      if (result.isType<DiscoError>()) {
        if (options.maxItems == 'max') {
          logger.severe(
            'disco#info query failed and options.maxItems is set to "max".',
          );
          return options;
        }
      }

      final nodeMultiItemsSupported = result.isType<DiscoInfo>() &&
          result.get<DiscoInfo>().features.contains(pubsubNodeConfigMultiItems);
      final nodeMaxSupported = result.isType<DiscoInfo>() &&
          result.get<DiscoInfo>().features.contains(pubsubNodeConfigMax);
      if (options.maxItems != null && !nodeMultiItemsSupported) {
        // TODO(PapaTutuWawa): Here, we need to admit defeat
        logger.finest('PubSub host does not support multi-items!');

        return PubSubPublishOptions(
          accessModel: options.accessModel,
        );
      } else if (options.maxItems == 'max' && !nodeMaxSupported) {
        logger.finest(
          'PubSub host does not support node-config-max. Working around it',
        );
        final count = await _getNodeItemCount(jid, node) + 1;

        return PubSubPublishOptions(
          accessModel: options.accessModel,
          maxItems: '$count',
        );
      }
    }

    return options;
  }

  Future<Result<PubSubError, bool>> subscribe(JID jid, String node) async {
    final attrs = getAttributes();
    final result = (await attrs.sendStanza(
      StanzaDetails(
        Stanza.iq(
          type: 'set',
          to: jid.toString(),
          children: [
            XMLNode.xmlns(
              tag: 'pubsub',
              xmlns: pubsubXmlns,
              children: [
                XMLNode(
                  tag: 'subscribe',
                  attributes: <String, String>{
                    'node': node,
                    'jid': attrs.getFullJID().toBare().toString(),
                  },
                ),
              ],
            ),
          ],
        ),
        shouldEncrypt: false,
      ),
    ))!;

    if (result.attributes['type'] != 'result') {
      return Result(UnknownPubSubError());
    }

    final pubsub = result.firstTag('pubsub', xmlns: pubsubXmlns);
    if (pubsub == null) {
      return Result(UnknownPubSubError());
    }

    final subscription = pubsub.firstTag('subscription');
    if (subscription == null) {
      return Result(UnknownPubSubError());
    }

    return Result(subscription.attributes['subscription'] == 'subscribed');
  }

  Future<Result<PubSubError, bool>> unsubscribe(JID jid, String node) async {
    final attrs = getAttributes();
    final result = (await attrs.sendStanza(
      StanzaDetails(
        Stanza.iq(
          type: 'set',
          to: jid.toString(),
          children: [
            XMLNode.xmlns(
              tag: 'pubsub',
              xmlns: pubsubXmlns,
              children: [
                XMLNode(
                  tag: 'unsubscribe',
                  attributes: <String, String>{
                    'node': node,
                    'jid': attrs.getFullJID().toBare().toString(),
                  },
                ),
              ],
            ),
          ],
        ),
        shouldEncrypt: false,
      ),
    ))!;

    if (result.attributes['type'] != 'result') {
      return Result(UnknownPubSubError());
    }

    final pubsub = result.firstTag('pubsub', xmlns: pubsubXmlns);
    if (pubsub == null) {
      return Result(UnknownPubSubError());
    }

    final subscription = pubsub.firstTag('subscription');
    if (subscription == null) {
      return Result(UnknownPubSubError());
    }

    return Result(subscription.attributes['subscription'] == 'none');
  }

  /// Publish [payload] to the PubSub node [node] on JID [jid]. Returns true if it
  /// was successful. False otherwise.
  Future<Result<PubSubError, bool>> publish(
    JID jid,
    String node,
    XMLNode payload, {
    String? id,
    PubSubPublishOptions? options,
  }) async {
    return _publish(
      jid,
      node,
      payload,
      id: id,
      options: options,
    );
  }

  Future<Result<PubSubError, bool>> _publish(
    JID jid,
    String node,
    XMLNode payload, {
    String? id,
    PubSubPublishOptions? options,
    // Should, if publishing fails, try to reconfigure and publish again?
    bool tryConfigureAndPublish = true,
  }) async {
    PubSubPublishOptions? pubOptions;
    if (options != null) {
      pubOptions = await preprocessPublishOptions(jid, node, options);
    }

    final result = (await getAttributes().sendStanza(
      StanzaDetails(
        Stanza.iq(
          type: 'set',
          to: jid.toString(),
          children: [
            XMLNode.xmlns(
              tag: 'pubsub',
              xmlns: pubsubXmlns,
              children: [
                XMLNode(
                  tag: 'publish',
                  attributes: <String, String>{'node': node},
                  children: [
                    XMLNode(
                      tag: 'item',
                      attributes: {
                        if (id != null) 'id': id,
                      },
                      children: [payload],
                    ),
                  ],
                ),
                if (pubOptions != null)
                  XMLNode(
                    tag: 'publish-options',
                    children: [pubOptions.toXml()],
                  ),
              ],
            ),
          ],
        ),
        shouldEncrypt: false,
      ),
    ))!;
    if (result.attributes['type'] != 'result') {
      final error = getPubSubError(result);

      // If preconditions are not met, configure the node
      if (error is PreconditionsNotMetError && tryConfigureAndPublish) {
        final configureResult = await configure(jid, node, pubOptions!);
        if (configureResult.isType<PubSubError>()) {
          return Result(configureResult.get<PubSubError>());
        }

        final publishResult = await _publish(
          jid,
          node,
          payload,
          id: id,
          options: options,
          tryConfigureAndPublish: false,
        );
        if (publishResult.isType<PubSubError>()) {
          return publishResult;
        }
      } else if (error is EjabberdMaxItemsError &&
          tryConfigureAndPublish &&
          options != null) {
        // TODO(Unknown): Remove once ejabberd fixes the bug. See errors.dart for more info.
        logger.warning(
          'Publish failed due to the server rejecting the usage of "max" for "max_items" in publish options. Configuring...',
        );
        final count = await _getNodeItemCount(jid, node) + 1;
        return publish(
          jid,
          node,
          payload,
          id: id,
          options: PubSubPublishOptions(
            accessModel: options.accessModel,
            maxItems: '$count',
          ),
        );
      } else {
        return Result(error);
      }
    }

    final pubsubElement = result.firstTag('pubsub', xmlns: pubsubXmlns);
    if (pubsubElement == null) {
      return Result(MalformedResponseError());
    }

    final publishElement = pubsubElement.firstTag('publish');
    if (publishElement == null) {
      return Result(MalformedResponseError());
    }

    final item = publishElement.firstTag('item');
    if (item == null) {
      return Result(MalformedResponseError());
    }

    if (id != null) {
      return Result(item.attributes['id'] == id);
    }

    return const Result(true);
  }

  Future<Result<PubSubError, List<PubSubItem>>> getItems(
    JID jid,
    String node, {
    int? maxItems,
  }) async {
    final result = (await getAttributes().sendStanza(
      StanzaDetails(
        Stanza.iq(
          type: 'get',
          to: jid.toString(),
          children: [
            XMLNode.xmlns(
              tag: 'pubsub',
              xmlns: pubsubXmlns,
              children: [
                XMLNode(
                  tag: 'items',
                  attributes: {
                    'node': node,
                    if (maxItems != null) 'max_items': maxItems.toString(),
                  },
                ),
              ],
            ),
          ],
        ),
        shouldEncrypt: false,
      ),
    ))!;

    if (result.attributes['type'] != 'result') {
      return Result(getPubSubError(result));
    }

    final pubsub = result.firstTag('pubsub', xmlns: pubsubXmlns);
    if (pubsub == null) {
      return Result(getPubSubError(result));
    }

    final items = pubsub.firstTag('items')!.children.map((item) {
      return PubSubItem(
        id: item.attributes['id']! as String,
        payload: item.children[0],
        node: node,
      );
    }).toList();

    return Result(items);
  }

  Future<Result<PubSubError, PubSubItem>> getItem(
    JID jid,
    String node,
    String id,
  ) async {
    final result = (await getAttributes().sendStanza(
      StanzaDetails(
        Stanza.iq(
          type: 'get',
          to: jid.toString(),
          children: [
            XMLNode.xmlns(
              tag: 'pubsub',
              xmlns: pubsubXmlns,
              children: [
                XMLNode(
                  tag: 'items',
                  attributes: <String, String>{'node': node},
                  children: [
                    XMLNode(
                      tag: 'item',
                      attributes: <String, String>{'id': id},
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        shouldEncrypt: false,
      ),
    ))!;

    if (result.attributes['type'] != 'result') {
      return Result(getPubSubError(result));
    }

    final pubsub = result.firstTag('pubsub', xmlns: pubsubXmlns);
    if (pubsub == null) return Result(getPubSubError(result));

    final itemElement = pubsub.firstTag('items')?.firstTag('item');
    if (itemElement == null) return Result(NoItemReturnedError());

    final item = PubSubItem(
      id: itemElement.attributes['id']! as String,
      payload: itemElement.children[0],
      node: node,
    );

    return Result(item);
  }

  Future<Result<PubSubError, bool>> configure(
    JID jid,
    String node,
    PubSubPublishOptions options,
  ) async {
    final attrs = getAttributes();

    // Request the form
    final form = (await attrs.sendStanza(
      StanzaDetails(
        Stanza.iq(
          type: 'get',
          to: jid.toString(),
          children: [
            XMLNode.xmlns(
              tag: 'pubsub',
              xmlns: pubsubOwnerXmlns,
              children: [
                XMLNode(
                  tag: 'configure',
                  attributes: <String, String>{
                    'node': node,
                  },
                ),
              ],
            ),
          ],
        ),
        shouldEncrypt: false,
      ),
    ))!;
    if (form.attributes['type'] != 'result') {
      return Result(getPubSubError(form));
    }

    final submit = (await attrs.sendStanza(
      StanzaDetails(
        Stanza.iq(
          type: 'set',
          to: jid.toString(),
          children: [
            XMLNode.xmlns(
              tag: 'pubsub',
              xmlns: pubsubOwnerXmlns,
              children: [
                XMLNode(
                  tag: 'configure',
                  attributes: <String, String>{
                    'node': node,
                  },
                  children: [
                    options.toXml(),
                  ],
                ),
              ],
            ),
          ],
        ),
        shouldEncrypt: false,
      ),
    ))!;
    if (submit.attributes['type'] != 'result') {
      return Result(getPubSubError(form));
    }

    return const Result(true);
  }

  Future<Result<PubSubError, bool>> delete(JID host, String node) async {
    final request = (await getAttributes().sendStanza(
      StanzaDetails(
        Stanza.iq(
          type: 'set',
          to: host.toString(),
          children: [
            XMLNode.xmlns(
              tag: 'pubsub',
              xmlns: pubsubOwnerXmlns,
              children: [
                XMLNode(
                  tag: 'delete',
                  attributes: <String, String>{
                    'node': node,
                  },
                ),
              ],
            ),
          ],
        ),
        shouldEncrypt: false,
      ),
    ))!;

    if (request.attributes['type'] != 'result') {
      // TODO(Unknown): Be more specific
      return Result(UnknownPubSubError());
    }

    return const Result(true);
  }

  Future<Result<PubSubError, bool>> retract(
    JID host,
    String node,
    String itemId,
  ) async {
    final request = (await getAttributes().sendStanza(
      StanzaDetails(
        Stanza.iq(
          type: 'set',
          to: host.toString(),
          children: [
            XMLNode.xmlns(
              tag: 'pubsub',
              xmlns: pubsubXmlns,
              children: [
                XMLNode(
                  tag: 'retract',
                  attributes: <String, String>{
                    'node': node,
                  },
                  children: [
                    XMLNode(
                      tag: 'item',
                      attributes: <String, String>{
                        'id': itemId,
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        shouldEncrypt: false,
      ),
    ))!;

    if (request.attributes['type'] != 'result') {
      // TODO(Unknown): Be more specific
      return Result(UnknownPubSubError());
    }

    return const Result(true);
  }
}
