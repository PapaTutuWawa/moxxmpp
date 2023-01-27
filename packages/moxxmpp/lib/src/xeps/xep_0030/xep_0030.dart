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
import 'package:moxxmpp/src/xeps/xep_0030/errors.dart';
import 'package:moxxmpp/src/xeps/xep_0030/helpers.dart';
import 'package:moxxmpp/src/xeps/xep_0030/types.dart';
import 'package:moxxmpp/src/xeps/xep_0115.dart';
import 'package:synchronized/synchronized.dart';

/// Callback that is called when a disco#info requests is received on a given node.
typedef DiscoInfoRequestCallback = Future<DiscoInfo> Function();

/// Callback that is called when a disco#items requests is received on a given node.
typedef DiscoItemsRequestCallback = Future<List<DiscoItem>> Function();

@immutable
class DiscoCacheKey {
  const DiscoCacheKey(this.jid, this.node);
  final String jid;
  final String? node;

  @override
  bool operator ==(Object other) {
    return other is DiscoCacheKey && jid == other.jid && node == other.node;
  }
  
  @override
  int get hashCode => jid.hashCode ^ node.hashCode;
}

/// This manager implements XEP-0030 by providing a way of performing disco#info and
/// disco#items requests and answering those requests.
/// A caching mechanism is also provided.
class DiscoManager extends XmppManagerBase {
  /// [identities] is a list of disco identities that should be added by default
  /// to a disco#info response.
  DiscoManager(List<Identity> identities)
    : _identities = List<Identity>.from(identities),
      super();

  /// Our features
  final List<String> _features = List.empty(growable: true);

  /// Disco identities that we advertise
  final List<Identity> _identities;
  
  /// Map full JID to Capability hashes
  final Map<String, CapabilityHashInfo> _capHashCache = {};

  /// Map capability hash to the disco info
  final Map<String, DiscoInfo> _capHashInfoCache = {};

  /// Map full JID to Disco Info
  final Map<DiscoCacheKey, DiscoInfo> _discoInfoCache = {};

  /// Mapping the full JID to a list of running requests
  final Map<DiscoCacheKey, List<Completer<Result<DiscoError, DiscoInfo>>>> _runningInfoQueries = {};

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
  bool hasInfoQueriesRunning() => _runningInfoQueries.isNotEmpty;

  @visibleForTesting
  List<Completer<Result<DiscoError, DiscoInfo>>> getRunningInfoQueries(DiscoCacheKey key) => _runningInfoQueries[key]!;
  
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
  String getId() => discoManager;

  @override
  String getName() => 'DiscoManager';

  @override
  List<String> getDiscoFeatures() => [ discoInfoXmlns, discoItemsXmlns ];

  @override
  Future<bool> isSupported() async => true;

  @override
  Future<void> onXmppEvent(XmppEvent event) async {
    if (event is PresenceReceivedEvent) {
      await _onPresence(event.jid, event.presence);
    } else if (event is StreamResumeFailedEvent) {
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
  
  Future<void> _onPresence(JID from, Stanza presence) async {
    final c = presence.firstTag('c', xmlns: capsXmlns);
    if (c == null) return;

    final info = CapabilityHashInfo(
      c.attributes['ver']! as String,
      c.attributes['node']! as String,
      c.attributes['hash']! as String,
    );
    
    // Check if we already know of that cache
    var cached = false;
    await _cacheLock.synchronized(() async {
      if (!_capHashCache.containsKey(info.ver)) {
        cached = true;
      }
    });
    if (cached) return;

    // Request the cap hash
    logger.finest("Received capability hash we don't know about. Requesting it...");
    final result = await discoInfoQuery(from.toString(), node: '${info.node}#${info.ver}');
    if (result.isType<DiscoError>()) return;

    await _cacheLock.synchronized(() async {
      _capHashCache[from.toString()] = info;
      _capHashInfoCache[info.ver] = result.get<DiscoInfo>();
    });
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
  
  Future<StanzaHandlerData> _onDiscoInfoRequest(Stanza stanza, StanzaHandlerData state) async {
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

      return state.copyWith(done: true);
    }

    await reply(
      state,
      'result',
      [
        getDiscoInfo(node).toXml(),
      ],
    );

    return state.copyWith(done: true);
  }

  Future<StanzaHandlerData> _onDiscoItemsRequest(Stanza stanza, StanzaHandlerData state) async {
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

      return state.copyWith(done: true);
    }

    return state;
  }

  Future<void> _exitDiscoInfoCriticalSection(DiscoCacheKey key, Result<DiscoError, DiscoInfo> result) async {
    return _cacheLock.synchronized(() async {
      // Complete all futures
      for (final completer in _runningInfoQueries[key]!) {
        completer.complete(result);
      }

      // Add to cache if it is a result
      if (result.isType<DiscoInfo>()) {
        _discoInfoCache[key] = result.get<DiscoInfo>();
      }
      
      // Remove from the request cache
      _runningInfoQueries.remove(key);
    });
  }
  
  /// Sends a disco info query to the (full) jid [entity], optionally with node=[node].
  Future<Result<DiscoError, DiscoInfo>> discoInfoQuery(String entity, { String? node, bool shouldEncrypt = true }) async {
    final cacheKey = DiscoCacheKey(entity, node);
    DiscoInfo? info;
    Completer<Result<DiscoError, DiscoInfo>>? completer;
    await _cacheLock.synchronized(() async {
      // Check if we already know what the JID supports
      if (_discoInfoCache.containsKey(cacheKey)) {
        info = _discoInfoCache[cacheKey];
      } else {
        // Is a request running?
        if (_runningInfoQueries.containsKey(cacheKey)) {
          completer = Completer();
          _runningInfoQueries[cacheKey]!.add(completer!);
        } else {
          _runningInfoQueries[cacheKey] = List.from(<Completer<DiscoInfo?>>[]);
        }
      }
    });

    if (info != null) {
      return Result<DiscoError, DiscoInfo>(info);
    } else if (completer != null) {
      return completer!.future;
    }

    final stanza = await getAttributes().sendStanza(
      buildDiscoInfoQueryStanza(entity, node),
      encrypted: !shouldEncrypt,
    );
    final query = stanza.firstTag('query');
    if (query == null) {
      final result = Result<DiscoError, DiscoInfo>(InvalidResponseDiscoError());
      await _exitDiscoInfoCriticalSection(cacheKey, result);
      return result;
    }

    if (stanza.attributes['type'] == 'error') {
      //final error = stanza.firstTag('error');
      final result = Result<DiscoError, DiscoInfo>(ErrorResponseDiscoError());
      await _exitDiscoInfoCriticalSection(cacheKey, result);
      return result;
    }
    
    final result = Result<DiscoError, DiscoInfo>(
      DiscoInfo.fromQuery(
        query,
        JID.fromString(entity),
      ),
    );
    await _exitDiscoInfoCriticalSection(cacheKey, result);
    return result;
  }

  /// Sends a disco items query to the (full) jid [entity], optionally with node=[node].
  Future<Result<DiscoError, List<DiscoItem>>> discoItemsQuery(String entity, { String? node, bool shouldEncrypt = true }) async {
    final stanza = await getAttributes()
      .sendStanza(
        buildDiscoItemsQueryStanza(entity, node: node),
        encrypted: !shouldEncrypt,
      ) as Stanza;

    final query = stanza.firstTag('query');
    if (query == null) return Result(InvalidResponseDiscoError());

    if (stanza.type == 'error') {
      //final error = stanza.firstTag('error');
      //print("Disco Items error: " + error.toXml());
      return Result(ErrorResponseDiscoError());
    }

    final items = query.findTags('item').map((node) => DiscoItem(
      jid: node.attributes['jid']! as String,
      node: node.attributes['node'] as String?,
      name: node.attributes['name'] as String?,
    ),).toList();

    return Result(items);
  }

  /// Queries information about a jid based on its node and capability hash.
  Future<Result<DiscoError, DiscoInfo>> discoInfoCapHashQuery(String jid, String node, String ver) async {
    return discoInfoQuery(jid, node: '$node#$ver');
  }

  Future<Result<DiscoError, List<DiscoInfo>>> performDiscoSweep() async {
    final attrs = getAttributes();
    final serverJid = attrs.getConnectionSettings().jid.domain;
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
    final info = await discoInfoQuery(entity.toString());
    if (info.isType<DiscoError>()) return false;

    return info.get<DiscoInfo>().features.contains(feature);
  }
}
