import 'dart:async';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:moxlib/moxlib.dart';
import 'package:moxxmpp/src/jid.dart';
import 'package:moxxmpp/src/managers/attributes.dart';
import 'package:moxxmpp/src/managers/base.dart';
import 'package:moxxmpp/src/managers/data.dart';
import 'package:moxxmpp/src/managers/handlers.dart';
import 'package:moxxmpp/src/managers/namespaces.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/negotiators/namespaces.dart';
import 'package:moxxmpp/src/negotiators/negotiator.dart';
import 'package:moxxmpp/src/roster/errors.dart';
import 'package:moxxmpp/src/roster/state.dart';
import 'package:moxxmpp/src/stanza.dart';
import 'package:moxxmpp/src/stringxml.dart';

@immutable
class XmppRosterItem {
  const XmppRosterItem({
    required this.jid,
    required this.subscription,
    this.ask,
    this.name,
    this.groups = const [],
  });
  final String jid;
  final String? name;
  final String subscription;
  final String? ask;
  final List<String> groups;

  @override
  bool operator ==(Object other) {
    return other is XmppRosterItem &&
        other.jid == jid &&
        other.name == name &&
        other.subscription == subscription &&
        other.ask == ask &&
        const ListEquality<String>().equals(other.groups, groups);
  }

  @override
  int get hashCode =>
      jid.hashCode ^
      name.hashCode ^
      subscription.hashCode ^
      ask.hashCode ^
      groups.hashCode;

  @override
  String toString() {
    return 'XmppRosterItem('
        'jid: $jid, '
        'name: $name, '
        'subscription: $subscription, '
        'ask: $ask, '
        'groups: $groups)';
  }
}

enum RosterRemovalResult { okay, error, itemNotFound }

class RosterRequestResult {
  RosterRequestResult(this.items, this.ver);
  List<XmppRosterItem> items;
  String? ver;
}

class RosterPushResult {
  RosterPushResult(this.item, this.ver);
  final XmppRosterItem item;
  final String? ver;
}

/// A Stub feature negotiator for finding out whether roster versioning is supported.
class RosterFeatureNegotiator extends XmppFeatureNegotiatorBase {
  RosterFeatureNegotiator()
      : _supported = false,
        super(11, false, rosterVersioningXmlns, rosterNegotiator);

  /// True if rosterVersioning is supported. False otherwise.
  bool _supported;
  bool get isSupported => _supported;

  @override
  Future<Result<NegotiatorState, NegotiatorError>> negotiate(
    XMLNode nonza,
  ) async {
    // negotiate is only called when the negotiator matched, meaning the server
    // advertises roster versioning.
    _supported = true;
    return const Result(NegotiatorState.done);
  }

  @override
  void reset() {
    _supported = false;

    super.reset();
  }
}

/// This manager requires a RosterFeatureNegotiator to be registered.
class RosterManager extends XmppManagerBase {
  RosterManager(this._stateManager) : super(rosterManager);

  /// The class managing the entire roster state.
  final BaseRosterStateManager _stateManager;

  @override
  void register(XmppManagerAttributes attributes) {
    super.register(attributes);
    _stateManager.register(attributes.sendEvent);
  }

  @override
  List<StanzaHandler> getIncomingStanzaHandlers() => [
        StanzaHandler(
          stanzaTag: 'iq',
          tagName: 'query',
          tagXmlns: rosterXmlns,
          callback: _onRosterPush,
        ),
      ];

  @override
  Future<bool> isSupported() async => true;

  Future<StanzaHandlerData> _onRosterPush(
    Stanza stanza,
    StanzaHandlerData state,
  ) async {
    final attrs = getAttributes();
    final from = stanza.attributes['from'] as String?;
    final selfJid = attrs.getConnectionSettings().jid;

    logger.fine('Received roster push');

    // Only allow the push if the from attribute is either
    // - empty, i.e. not set
    // - a full JID of our own
    if (from != null && JID.fromString(from).toBare() != selfJid) {
      logger.warning(
        'Roster push invalid! Unexpected from attribute: ${stanza.toXml()}',
      );
      return state..done = true;
    }

    final query = stanza.firstTag('query', xmlns: rosterXmlns)!;
    logger.fine('Roster push: ${query.toXml()}');
    final item = query.firstTag('item');

    if (item == null) {
      logger.warning('Received empty roster push');
      return state..done = true;
    }

    unawaited(
      _stateManager.handleRosterPush(
        RosterPushResult(
          XmppRosterItem(
            jid: item.attributes['jid']! as String,
            subscription: item.attributes['subscription']! as String,
            ask: item.attributes['ask'] as String?,
            name: item.attributes['name'] as String?,
          ),
          query.attributes['ver'] as String?,
        ),
      ),
    );

    await reply(
      state,
      'result',
      [],
    );

    return state..done = true;
  }

  /// Shared code between requesting rosters without and with roster versioning, if
  /// the server deems a regular roster response more efficient than n roster pushes.
  ///
  /// [query] is the <query /> child of the iq, if available.
  ///
  /// If roster versioning was used, then [requestedRosterVersion] is the version
  /// we requested the roster with.
  ///
  /// Note that if roster versioning is used and the server returns us an empty iq,
  /// it means that the roster did not change since the last version. In that case,
  /// we do nothing and just return. The roster state manager will not be notified.
  Future<Result<RosterRequestResult, RosterError>> _handleRosterResponse(
    XMLNode? query,
    String? requestedRosterVersion,
  ) async {
    final List<XmppRosterItem> items;
    String? rosterVersion;
    if (query != null) {
      items = query.children
          .map(
            (item) => XmppRosterItem(
              name: item.attributes['name'] as String?,
              jid: item.attributes['jid']! as String,
              subscription: item.attributes['subscription']! as String,
              ask: item.attributes['ask'] as String?,
              groups: item
                  .findTags('group')
                  .map((groupNode) => groupNode.innerText())
                  .toList(),
            ),
          )
          .toList();

      rosterVersion = query.attributes['ver'] as String?;
    } else if (requestedRosterVersion != null) {
      // Skip the handleRosterFetch call since nothing changed.
      return Result(
        RosterRequestResult(
          [],
          requestedRosterVersion,
        ),
      );
    } else {
      logger.warning(
        'Server response to roster request without roster versioning does not contain a <query /> element, while the type is not error. This violates RFC6121',
      );
      return Result(NoQueryError());
    }

    final result = RosterRequestResult(
      items,
      rosterVersion,
    );

    unawaited(
      _stateManager.handleRosterFetch(result),
    );

    return Result(result);
  }

  /// Requests the roster following RFC 6121. If [useRosterVersion] is set to false, then
  /// roster versioning will not be used, even if the server supports it and we have a last
  /// known roster version.
  Future<Result<RosterRequestResult, RosterError>> requestRoster({
    bool useRosterVersion = true,
  }) async {
    final attrs = getAttributes();
    final query = XMLNode.xmlns(
      tag: 'query',
      xmlns: rosterXmlns,
    );
    final rosterVersion = await _stateManager.getRosterVersion();
    if (rosterVersion != null &&
        rosterVersioningAvailable() &&
        useRosterVersion) {
      query.attributes['ver'] = rosterVersion;
    }

    final response = (await attrs.sendStanza(
      StanzaDetails(
        Stanza.iq(
          type: 'get',
          children: [
            query,
          ],
        ),
      ),
    ))!;

    if (response.attributes['type'] != 'result') {
      logger.warning('Error requesting roster: ${response.toXml()}');
      return Result(UnknownError());
    }

    final responseQuery = response.firstTag('query', xmlns: rosterXmlns);
    return _handleRosterResponse(responseQuery, rosterVersion);
  }

  /// Requests a series of roster pushes according to RFC6121. Requires that the server
  /// advertises urn:xmpp:features:rosterver in the stream features.
  Future<Result<RosterRequestResult?, RosterError>>
      requestRosterPushes() async {
    final attrs = getAttributes();
    final rosterVersion = await _stateManager.getRosterVersion();
    final result = (await attrs.sendStanza(
      StanzaDetails(
        Stanza.iq(
          type: 'get',
          children: [
            XMLNode.xmlns(
              tag: 'query',
              xmlns: rosterXmlns,
              attributes: {
                'ver': rosterVersion ?? '',
              },
            ),
          ],
        ),
      ),
    ))!;

    if (result.attributes['type'] != 'result') {
      logger.warning('Requesting roster pushes failed: ${result.toXml()}');
      return Result(UnknownError());
    }

    final query = result.firstTag('query', xmlns: rosterXmlns);
    return _handleRosterResponse(query, rosterVersion);
  }

  bool rosterVersioningAvailable() {
    return getAttributes()
        .getNegotiatorById<RosterFeatureNegotiator>(rosterNegotiator)!
        .isSupported;
  }

  /// Attempts to add [jid] with a title of [title] and groups [groups] to the roster.
  /// Returns true if the process was successful, false otherwise.
  Future<bool> addToRoster(
    String jid,
    String title, {
    List<String>? groups,
  }) async {
    final attrs = getAttributes();
    final response = (await attrs.sendStanza(
      StanzaDetails(
        Stanza.iq(
          type: 'set',
          children: [
            XMLNode.xmlns(
              tag: 'query',
              xmlns: rosterXmlns,
              children: [
                XMLNode(
                  tag: 'item',
                  attributes: <String, String>{
                    'jid': jid,
                    if (title == jid.split('@')[0]) 'name': title,
                  },
                  children: (groups ?? [])
                      .map((group) => XMLNode(tag: 'group', text: group))
                      .toList(),
                ),
              ],
            ),
          ],
        ),
      ),
    ))!;

    if (response.attributes['type'] != 'result') {
      logger.severe('Error adding $jid to roster: $response');
      return false;
    }

    return true;
  }

  /// Attempts to remove [jid] from the roster. Returns true if the process was successful,
  /// false otherwise.
  Future<RosterRemovalResult> removeFromRoster(String jid) async {
    final attrs = getAttributes();
    final response = (await attrs.sendStanza(
      StanzaDetails(
        Stanza.iq(
          type: 'set',
          children: [
            XMLNode.xmlns(
              tag: 'query',
              xmlns: rosterXmlns,
              children: [
                XMLNode(
                  tag: 'item',
                  attributes: {
                    'jid': jid,
                    'subscription': 'remove',
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    ))!;

    if (response.attributes['type'] != 'result') {
      logger.severe('Failed to remove roster item: ${response.toXml()}');

      final error = response.firstTag('error')!;
      final notFound = error.firstTag('item-not-found') != null;

      if (notFound) {
        logger.warning('Item was not found');
        return RosterRemovalResult.itemNotFound;
      }

      return RosterRemovalResult.error;
    }

    return RosterRemovalResult.okay;
  }
}
