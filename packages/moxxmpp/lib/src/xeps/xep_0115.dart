import 'dart:async';
import 'dart:convert';
import 'package:meta/meta.dart';
import 'package:moxxmpp/src/events.dart';
import 'package:moxxmpp/src/jid.dart';
import 'package:moxxmpp/src/managers/base.dart';
import 'package:moxxmpp/src/managers/data.dart';
import 'package:moxxmpp/src/managers/handlers.dart';
import 'package:moxxmpp/src/managers/namespaces.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/presence.dart';
import 'package:moxxmpp/src/rfcs/rfc_4790.dart';
import 'package:moxxmpp/src/stanza.dart';
import 'package:moxxmpp/src/stringxml.dart';
import 'package:moxxmpp/src/util/list.dart';
import 'package:moxxmpp/src/xeps/xep_0004.dart';
import 'package:moxxmpp/src/xeps/xep_0030/cache.dart';
import 'package:moxxmpp/src/xeps/xep_0030/errors.dart';
import 'package:moxxmpp/src/xeps/xep_0030/types.dart';
import 'package:moxxmpp/src/xeps/xep_0030/xep_0030.dart';
import 'package:moxxmpp/src/xeps/xep_0300.dart';
import 'package:synchronized/synchronized.dart';

/// Given an identity [i], compute the string according to XEP-0115 § 5.1 step 2.
String _identityString(Identity i) =>
    '${i.category}/${i.type}/${i.lang ?? ""}/${i.name ?? ""}';

/// Calculates the Entitiy Capability hash according to XEP-0115 based on the
/// disco information.
Future<String> calculateCapabilityHash(
  HashFunction algorithm,
  DiscoInfo info,
) async {
  final buffer = StringBuffer();
  final identitiesSorted = info.identities.map(_identityString).toList();
  // ignore: cascade_invocations
  identitiesSorted.sort(ioctetSortComparator);
  buffer.write('${identitiesSorted.join("<")}<');

  final featuresSorted = List<String>.from(info.features)
    ..sort(ioctetSortComparator);
  buffer.write('${featuresSorted.join("<")}<');

  if (info.extendedInfo.isNotEmpty) {
    final sortedExt = info.extendedInfo
      ..sort(
        (a, b) => ioctetSortComparator(
          a.getFieldByVar('FORM_TYPE')!.values.first,
          b.getFieldByVar('FORM_TYPE')!.values.first,
        ),
      );

    for (final ext in sortedExt) {
      buffer.write('${ext.getFieldByVar("FORM_TYPE")!.values.first}<');

      final sortedFields = ext.fields
        ..sort(
          (a, b) => ioctetSortComparator(
            a.varAttr!,
            b.varAttr!,
          ),
        );

      for (final field in sortedFields) {
        if (field.varAttr == 'FORM_TYPE') continue;

        buffer.write('${field.varAttr!}<');
        final sortedValues = field.values..sort(ioctetSortComparator);
        for (final value in sortedValues) {
          buffer.write('$value<');
        }
      }
    }
  }

  final rawHash = await CryptographicHashManager.hashFromData(
    algorithm,
    utf8.encode(buffer.toString()),
  );
  return base64.encode(rawHash);
}

/// A manager implementing the advertising of XEP-0115. It responds to the
/// disco#info requests on the specified node with the information provided by
/// the DiscoManager.
/// NOTE: This manager requires that the DiscoManager is also registered.
class EntityCapabilitiesManager extends XmppManagerBase {
  EntityCapabilitiesManager(this._capabilityHashBase)
      : super(entityCapabilitiesManager);

  /// The string that is both the node under which we advertise the disco info
  /// and the base for the actual node on which we respond to disco#info requests.
  final String _capabilityHashBase;

  /// The cached capability hash.
  String? _capabilityHash;

  /// Cache the mapping between the full JID and the capability hash string.
  final Map<String, String> _jidToCapHashCache = {};

  /// Cache the mapping between capability hash string and the resulting disco#info.
  final Map<String, DiscoInfo> _capHashCache = {};

  /// A lock guarding access to the capability hash cache.
  final Lock _cacheLock = Lock();

  @override
  Future<bool> isSupported() async => true;

  @override
  List<String> getDiscoFeatures() => [
        capsXmlns,
      ];

  @override
  List<StanzaHandler> getIncomingStanzaHandlers() => [
        StanzaHandler(
          stanzaTag: 'presence',
          tagName: 'c',
          tagXmlns: capsXmlns,
          callback: onPresence,
          priority: PresenceManager.presenceHandlerPriority + 1,
        ),
      ];

  /// Computes, if required, the capability hash of the data provided by
  /// the DiscoManager.
  Future<String> getCapabilityHash() async {
    _capabilityHash ??= await calculateCapabilityHash(
      HashFunction.sha1,
      getAttributes()
          .getManagerById<DiscoManager>(discoManager)!
          .getDiscoInfo(null),
    );

    return _capabilityHash!;
  }

  Future<String> _getNode() async {
    final hash = await getCapabilityHash();
    return '$_capabilityHashBase#$hash';
  }

  Future<DiscoInfo> _onInfoQuery() async {
    return getAttributes()
        .getManagerById<DiscoManager>(discoManager)!
        .getDiscoInfo(await _getNode());
  }

  Future<List<XMLNode>> _prePresenceSent() async {
    return [
      XMLNode.xmlns(
        tag: 'c',
        xmlns: capsXmlns,
        attributes: {
          'hash': 'sha-1',
          'node': _capabilityHashBase,
          'ver': await getCapabilityHash(),
        },
      ),
    ];
  }

  /// If we know of [jid]'s capability hash, look up the [DiscoInfo] associated with
  /// that capability hash. If we don't know of [jid]'s capability hash, return null.
  Future<DiscoInfo?> getCachedDiscoInfoFromJid(JID jid) async {
    return _cacheLock.synchronized(() {
      final capHash = _jidToCapHashCache[jid.toString()];
      if (capHash == null) {
        return null;
      }

      return _capHashCache[capHash];
    });
  }

  @visibleForTesting
  Future<StanzaHandlerData> onPresence(
    Stanza stanza,
    StanzaHandlerData state,
  ) async {
    if (stanza.from == null) {
      return state;
    }

    final from = JID.fromString(stanza.from!);
    final c = stanza.firstTag('c', xmlns: capsXmlns)!;

    final hashFunctionName = c.attributes['hash'] as String?;
    final capabilityNode = c.attributes['node'] as String?;
    final ver = c.attributes['ver'] as String?;
    if (hashFunctionName == null || capabilityNode == null || ver == null) {
      return state;
    }

    // Check if we know of the hash
    final isCached =
        await _cacheLock.synchronized(() => _capHashCache.containsKey(ver));
    if (isCached) {
      return state;
    }

    final dm = getAttributes().getManagerById<DiscoManager>(discoManager)!;
    final discoRequest = await dm.discoInfoQuery(
      from,
      node: capabilityNode,
    );
    if (discoRequest.isType<DiscoError>()) {
      return state;
    }
    final discoInfo = discoRequest.get<DiscoInfo>();

    final hashFunction = HashFunction.maybeFromName(hashFunctionName);
    if (hashFunction == null) {
      await dm.addCachedDiscoInfo(
        MapEntry<DiscoCacheKey, DiscoInfo>(
          DiscoCacheKey(
            from,
            null,
          ),
          discoInfo,
        ),
      );
      return state;
    }

    // Validate the disco#info result according to XEP-0115 § 5.4
    // > If the response includes more than one service discovery identity with the
    // > same category/type/lang/name, consider the entire response to be ill-formed.
    for (final identity in discoInfo.identities) {
      final identityString = _identityString(identity);
      if (discoInfo.identities
              .count((i) => _identityString(i) == identityString) >
          1) {
        logger.warning(
          'Malformed disco#info response: More than one equal identity',
        );
        return state;
      }
    }

    // > If the response includes more than one service discovery feature with the same
    // > XML character data, consider the entire response to be ill-formed.
    for (final feature in discoInfo.features) {
      if (discoInfo.features.count((f) => f == feature) > 1) {
        logger.warning(
          'Malformed disco#info response: More than one equal feature',
        );
        return state;
      }
    }

    // > If the response includes more than one extended service discovery information
    // > form with the same FORM_TYPE or the FORM_TYPE field contains more than one
    // > <value/> element with different XML character data, consider the entire response
    // > to be ill-formed.
    // >
    // > If the response includes an extended service discovery information form where
    // > the FORM_TYPE field is not of type "hidden" or the form does not include a
    // > FORM_TYPE field, ignore the form but continue processing.
    final validExtendedInfoItems = List<DataForm>.empty(growable: true);
    for (final extendedInfo in discoInfo.extendedInfo) {
      final formType = extendedInfo.getFieldByVar('FORM_TYPE');

      // Form should have a FORM_TYPE field
      if (formType == null) {
        logger.fine('Skipping extended info as it contains no FORM_TYPE field');
        continue;
      }

      // Check if we only have one unique FORM_TYPE value
      if (formType.values.length > 1) {
        if (Set<String>.from(formType.values).length > 1) {
          logger.warning(
            'Malformed disco#info response: Extended Info FORM_TYPE contains more than one value(s) of different value.',
          );
          return state;
        }
      }

      // Check if we have more than one extended info forms of the same type
      final sameFormTypeFormsNumber = discoInfo.extendedInfo.count((form) {
        final type = form.getFieldByVar('FORM_TYPE')?.values.first;
        if (type == null) return false;

        return type == formType.values.first;
      });
      if (sameFormTypeFormsNumber > 1) {
        logger.warning(
          'Malformed disco#info response: More than one Extended Disco Info forms with the same FORM_TYPE value',
        );
        return state;
      }

      // Check if the field type is hidden
      if (formType.type != 'hidden') {
        logger.fine(
          'Skipping extended info as the FORM_TYPE field is not of type "hidden"',
        );
        continue;
      }

      validExtendedInfoItems.add(extendedInfo);
    }

    // Validate the capability hash
    final newDiscoInfo = DiscoInfo(
      discoInfo.features,
      discoInfo.identities,
      validExtendedInfoItems,
      discoInfo.node,
      discoInfo.jid,
    );
    final computedCapabilityHash = await calculateCapabilityHash(
      hashFunction,
      newDiscoInfo,
    );

    if (computedCapabilityHash == ver) {
      await _cacheLock.synchronized(() {
        _jidToCapHashCache[from.toString()] = ver;
        _capHashCache[ver] = newDiscoInfo;
      });
    } else {
      logger.warning(
        'Capability hash mismatch from $from: Received "$ver", expected "$computedCapabilityHash".',
      );
    }

    return state;
  }

  @visibleForTesting
  void injectIntoCache(JID jid, String ver, DiscoInfo info) {
    _jidToCapHashCache[jid.toString()] = ver;
    _capHashCache[ver] = info;
  }

  @override
  Future<void> onXmppEvent(XmppEvent event) async {
    if (event is StreamNegotiationsDoneEvent) {
      // Clear the JID to cap. hash mapping.
      await _cacheLock.synchronized(_jidToCapHashCache.clear);
    }
  }

  @override
  Future<void> postRegisterCallback() async {
    await super.postRegisterCallback();

    getAttributes()
        .getManagerById<DiscoManager>(discoManager)
        ?.registerInfoCallback(
          await _getNode(),
          _onInfoQuery,
        );

    getAttributes()
        .getManagerById<PresenceManager>(presenceManager)
        ?.registerPreSendCallback(
          _prePresenceSent,
        );
  }
}
