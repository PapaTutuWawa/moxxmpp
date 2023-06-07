import 'dart:async';
import 'package:meta/meta.dart';
import 'package:moxxmpp/src/events.dart';
import 'package:moxxmpp/src/jid.dart';
import 'package:moxxmpp/src/managers/base.dart';
import 'package:moxxmpp/src/managers/data.dart';
import 'package:moxxmpp/src/managers/handlers.dart';
import 'package:moxxmpp/src/managers/namespaces.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/stanza.dart';
import 'package:moxxmpp/src/stringxml.dart';
import 'package:moxxmpp/src/types/result.dart';
import 'package:moxxmpp/src/util/wait.dart';
import 'package:moxxmpp/src/xeps/xep_0030/cache.dart';
import 'package:moxxmpp/src/xeps/xep_0030/errors.dart';
import 'package:moxxmpp/src/xeps/xep_0030/helpers.dart';
import 'package:moxxmpp/src/xeps/xep_0030/types.dart';
import 'package:moxxmpp/src/xeps/xep_0115.dart';
import 'package:synchronized/synchronized.dart';

/// Callback that is called when a disco#info requests is received on a given node.
typedef DiscoInfoRequestCallback = Future<DiscoInfo> Function();

/// Callback that is called when a disco#items requests is received on a given node.
typedef DiscoItemsRequestCallback = Future<List<DiscoItem>> Function();

/// This manager implements XEP-0030 by providing a way of performing disco#info and
/// disco#items requests and answering those requests.
/// A caching mechanism is also provided.
class DiscoManager extends XmppManagerBase {
  /// [identities] is a list of disco identities that should be added by default
  /// to a disco#info response.
  DiscoManager(List<Identity> identities)
      : _identities = List<Identity>.from(identities),
        super(discoManager);

  /// Our features
  final List<String> _features = List.empty(growable: true);

  /// Disco identities that we advertise
  final List<Identity> _identities;

  /// Map full JID to Disco Info
  final Map<DiscoCacheKey, DiscoInfo> _discoInfoCache = {};

  /// The tracker for tracking disco#info queries that are in flight.
  final WaitForTracker<DiscoCacheKey, Result<DiscoError, DiscoInfo>>
      _discoInfoTracker = WaitForTracker();

  /// The tracker for tracking disco#info queries that are in flight.
  final WaitForTracker<DiscoCacheKey, Result<DiscoError, List<DiscoItem>>>
      _discoItemsTracker = WaitForTracker();

  /// Cache lock
  final Lock _cacheLock = Lock();

  /// disco#info callbacks: node -> Callback
  final Map<String, DiscoInfoRequestCallback> _discoInfoCallbacks = {};

  /// disco#items callbacks: node -> Callback
  final Map<String, DiscoItemsRequestCallback> _discoItemsCallbacks = {};

  /// The list of identities that are registered.
  List<Identity> get identities => _identities;

  /// The list of disco features that are registered.
  List<String> get features => _features;

  @visibleForTesting
  WaitForTracker<DiscoCacheKey, Result<DiscoError, DiscoInfo>>
      get infoTracker => _discoInfoTracker;

  @override
  List<StanzaHandler> getIncomingStanzaHandlers() => [
        StanzaHandler(
          tagName: 'query',
          tagXmlns: discoInfoXmlns,
          stanzaTag: 'iq',
          callback: _onDiscoInfoRequest,
        ),
        StanzaHandler(
          tagName: 'query',
          tagXmlns: discoItemsXmlns,
          stanzaTag: 'iq',
          callback: _onDiscoItemsRequest,
        ),
      ];

  @override
  List<String> getDiscoFeatures() => [discoInfoXmlns, discoItemsXmlns];

  @override
  Future<bool> isSupported() async => true;

  @override
  Future<void> onXmppEvent(XmppEvent event) async {
    if (event is StreamNegotiationsDoneEvent) {
      if (event.resumed) return;

      // Cancel all waiting requests
      await _discoInfoTracker.resolveAll(
        Result<DiscoError, DiscoInfo>(UnknownDiscoError()),
      );
      await _discoItemsTracker.resolveAll(
        Result<DiscoError, List<DiscoItem>>(UnknownDiscoError()),
      );

      await _cacheLock.synchronized(() async {
        // Clear the cache
        _discoInfoCache.clear();
      });
    }
  }

  /// Register a callback [callback] for a disco#info query on [node].
  void registerInfoCallback(String node, DiscoInfoRequestCallback callback) {
    _discoInfoCallbacks[node] = callback;
  }

  /// Register a callback [callback] for a disco#items query on [node].
  void registerItemsCallback(String node, DiscoItemsRequestCallback callback) {
    _discoItemsCallbacks[node] = callback;
  }

  /// Add a [DiscoCacheKey]-[DiscoInfo] pair [discoInfoEntry] to the internal cache.
  Future<void> addCachedDiscoInfo(
    MapEntry<DiscoCacheKey, DiscoInfo> discoInfoEntry,
  ) async {
    await _cacheLock.synchronized(() {
      _discoInfoCache[discoInfoEntry.key] = discoInfoEntry.value;
    });
  }

  /// Adds a list of features to the possible disco info response.
  /// This function only adds features that are not already present in the disco features.
  void addFeatures(List<String> features) {
    for (final feat in features) {
      if (!_features.contains(feat)) {
        _features.add(feat);
      }
    }
  }

  /// Adds a list of identities to the possible disco info response.
  /// This function only adds features that are not already present in the disco features.
  void addIdentities(List<Identity> identities) {
    for (final identity in identities) {
      if (!_identities.contains(identity)) {
        _identities.add(identity);
      }
    }
  }

  /// Returns the [DiscoInfo] object that would be used as the response to a disco#info
  /// query against our bare JID with no node. The results node attribute is set
  /// to [node].
  DiscoInfo getDiscoInfo(String? node) {
    return DiscoInfo(
      _features,
      _identities,
      const [],
      node,
      null,
    );
  }

  Future<StanzaHandlerData> _onDiscoInfoRequest(
    Stanza stanza,
    StanzaHandlerData state,
  ) async {
    if (stanza.type != 'get') return state;

    final query = stanza.firstTag('query', xmlns: discoInfoXmlns)!;
    final node = query.attributes['node'] as String?;

    if (_discoInfoCallbacks.containsKey(node)) {
      // We can now assume that node != null
      final result = await _discoInfoCallbacks[node]!();
      await reply(
        state,
        'result',
        [
          result.toXml(),
        ],
      );

      return state..done = true;
    }

    await reply(
      state,
      'result',
      [
        getDiscoInfo(node).toXml(),
      ],
    );

    return state..done = true;
  }

  Future<StanzaHandlerData> _onDiscoItemsRequest(
    Stanza stanza,
    StanzaHandlerData state,
  ) async {
    if (stanza.type != 'get') return state;

    final query = stanza.firstTag('query', xmlns: discoItemsXmlns)!;
    final node = query.attributes['node'] as String?;
    if (_discoItemsCallbacks.containsKey(node)) {
      final result = await _discoItemsCallbacks[node]!();
      await reply(
        state,
        'result',
        [
          XMLNode.xmlns(
            tag: 'query',
            xmlns: discoItemsXmlns,
            attributes: <String, String>{
              'node': node!,
            },
            children: result.map((item) => item.toXml()).toList(),
          ),
        ],
      );

      return state..done = true;
    }

    return state;
  }

  Future<void> _exitDiscoInfoCriticalSection(
    DiscoCacheKey key,
    Result<DiscoError, DiscoInfo> result,
    bool shouldCache,
  ) async {
    await _cacheLock.synchronized(() async {
      // Add to cache if it is a result
      if (result.isType<DiscoInfo>() && shouldCache) {
        _discoInfoCache[key] = result.get<DiscoInfo>();
      }
    });

    await _discoInfoTracker.resolve(key, result);
  }

  /// Send a disco#info query to [entity]. If [node] is specified, then the disco#info
  /// request will be directed against that one node of [entity].
  ///
  /// [shouldEncrypt] indicates to possible end-to-end encryption implementations whether
  /// the request should be encrypted (true) or not (false).
  ///
  /// [shouldCache] indicates whether the successful result of the disco#info query
  /// should be cached (true) or not(false).
  Future<Result<DiscoError, DiscoInfo>> discoInfoQuery(
    JID entity, {
    String? node,
    bool shouldEncrypt = true,
    bool shouldCache = true,
  }) async {
    DiscoInfo? info;
    final cacheKey = DiscoCacheKey(entity, node);
    final ecm = getAttributes()
        .getManagerById<EntityCapabilitiesManager>(entityCapabilitiesManager);
    final ffuture = await _cacheLock
        .synchronized<Future<Future<Result<DiscoError, DiscoInfo>>?>?>(
            () async {
      // Check if we already know what the JID supports
      if (_discoInfoCache.containsKey(cacheKey)) {
        info = _discoInfoCache[cacheKey];
        return null;
      } else {
        // Check if we know entity capabilities
        if (ecm != null && node == null) {
          info = await ecm.getCachedDiscoInfoFromJid(entity);
          if (info != null) {
            return null;
          }
        }

        return _discoInfoTracker.waitFor(cacheKey);
      }
    });

    if (info != null) {
      return Result<DiscoError, DiscoInfo>(info);
    } else {
      final future = await ffuture;
      if (future != null) {
        return future;
      }
    }

    final stanza = (await getAttributes().sendStanza(
      StanzaDetails(
        buildDiscoInfoQueryStanza(entity, node),
        encrypted: !shouldEncrypt,
      ),
    ))!;
    final query = stanza.firstTag('query');
    if (query == null) {
      final result = Result<DiscoError, DiscoInfo>(InvalidResponseDiscoError());
      await _exitDiscoInfoCriticalSection(cacheKey, result, shouldCache);
      return result;
    }

    if (stanza.attributes['type'] == 'error') {
      //final error = stanza.firstTag('error');
      final result = Result<DiscoError, DiscoInfo>(ErrorResponseDiscoError());
      await _exitDiscoInfoCriticalSection(cacheKey, result, shouldCache);
      return result;
    }

    final result = Result<DiscoError, DiscoInfo>(
      DiscoInfo.fromQuery(
        query,
        entity,
      ),
    );
    await _exitDiscoInfoCriticalSection(cacheKey, result, shouldCache);
    return result;
  }

  /// Sends a disco items query to the (full) jid [entity], optionally with node=[node].
  Future<Result<DiscoError, List<DiscoItem>>> discoItemsQuery(
    JID entity, {
    String? node,
    bool shouldEncrypt = true,
  }) async {
    final key = DiscoCacheKey(entity, node);
    final future = await _discoItemsTracker.waitFor(key);
    if (future != null) {
      return future;
    }

    final stanza = (await getAttributes().sendStanza(
      StanzaDetails(
        buildDiscoItemsQueryStanza(entity, node: node),
        encrypted: !shouldEncrypt,
      ),
    ))!;

    final query = stanza.firstTag('query');
    if (query == null) {
      final result =
          Result<DiscoError, List<DiscoItem>>(InvalidResponseDiscoError());
      await _discoItemsTracker.resolve(key, result);
      return result;
    }

    if (stanza.attributes['type'] == 'error') {
      //final error = stanza.firstTag('error');
      //print("Disco Items error: " + error.toXml());
      final result =
          Result<DiscoError, List<DiscoItem>>(ErrorResponseDiscoError());
      await _discoItemsTracker.resolve(key, result);
      return result;
    }

    final items = query
        .findTags('item')
        .map(
          (node) => DiscoItem(
            jid: JID.fromString(node.attributes['jid']! as String),
            node: node.attributes['node'] as String?,
            name: node.attributes['name'] as String?,
          ),
        )
        .toList();

    final result = Result<DiscoError, List<DiscoItem>>(items);
    await _discoItemsTracker.resolve(key, result);
    return result;
  }

  Future<Result<DiscoError, List<DiscoInfo>>> performDiscoSweep() async {
    final attrs = getAttributes();
    final serverJid = attrs.getConnectionSettings().jid.toDomain();
    final infoResults = List<DiscoInfo>.empty(growable: true);
    final result = await discoInfoQuery(serverJid);
    if (result.isType<DiscoInfo>()) {
      final info = result.get<DiscoInfo>();
      logger.finest('Discovered supported server features: ${info.features}');
      infoResults.add(info);

      attrs.sendEvent(ServerItemDiscoEvent(info));
      attrs.sendEvent(ServerDiscoDoneEvent());
    } else {
      logger.warning('Failed to discover server features');
      return Result(UnknownDiscoError());
    }

    final response = await discoItemsQuery(serverJid);
    if (response.isType<List<DiscoItem>>()) {
      logger.finest('Discovered disco items form $serverJid');

      // Query all items
      final items = response.get<List<DiscoItem>>();
      for (final item in items) {
        logger.finest('Querying info for ${item.jid}...');
        final itemInfoResult = await discoInfoQuery(item.jid);
        if (itemInfoResult.isType<DiscoInfo>()) {
          final itemInfo = itemInfoResult.get<DiscoInfo>();
          logger.finest('Received info for ${item.jid}');
          infoResults.add(itemInfo);
          attrs.sendEvent(ServerItemDiscoEvent(itemInfo));
        } else {
          logger.warning('Failed to discover info for ${item.jid}');
        }
      }
    } else {
      logger.warning('Failed to discover items of $serverJid');
    }

    return Result(infoResults);
  }

  /// A wrapper function around discoInfoQuery: Returns true if the entity with JID
  /// [entity] supports the disco feature [feature]. If not, returns false.
  Future<bool> supportsFeature(JID entity, String feature) async {
    final info = await discoInfoQuery(entity);
    if (info.isType<DiscoError>()) return false;

    return info.get<DiscoInfo>().features.contains(feature);
  }
}
