import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:meta/meta.dart';
import 'package:moxxmpp/src/managers/base.dart';
import 'package:moxxmpp/src/managers/namespaces.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/presence.dart';
import 'package:moxxmpp/src/rfcs/rfc_4790.dart';
import 'package:moxxmpp/src/stringxml.dart';
import 'package:moxxmpp/src/xeps/xep_0030/types.dart';
import 'package:moxxmpp/src/xeps/xep_0030/xep_0030.dart';
import 'package:moxxmpp/src/xeps/xep_0414.dart';

@immutable
class CapabilityHashInfo {
  const CapabilityHashInfo(this.ver, this.node, this.hash);
  final String ver;
  final String node;
  final String hash;
}

/// Calculates the Entitiy Capability hash according to XEP-0115 based on the
/// disco information.
Future<String> calculateCapabilityHash(DiscoInfo info, HashAlgorithm algorithm) async {
  final buffer = StringBuffer();
  final identitiesSorted = info.identities
    .map((Identity i) => '${i.category}/${i.type}/${i.lang ?? ""}/${i.name ?? ""}')
    .toList();
  // ignore: cascade_invocations
  identitiesSorted.sort(ioctetSortComparator);
  buffer.write('${identitiesSorted.join("<")}<');

  final featuresSorted = List<String>.from(info.features)
    ..sort(ioctetSortComparator);
  buffer.write('${featuresSorted.join("<")}<');

  if (info.extendedInfo.isNotEmpty) {
    final sortedExt = info.extendedInfo
      ..sort((a, b) => ioctetSortComparator(
        a.getFieldByVar('FORM_TYPE')!.values.first,
        b.getFieldByVar('FORM_TYPE')!.values.first,
      ),
    );

    for (final ext in sortedExt) {
      buffer.write('${ext.getFieldByVar("FORM_TYPE")!.values.first}<');

      final sortedFields = ext.fields..sort((a, b) => ioctetSortComparator(
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
  
  return base64.encode((await algorithm.hash(utf8.encode(buffer.toString()))).bytes);
}

/// A manager implementing the advertising of XEP-0115. It responds to the
/// disco#info requests on the specified node with the information provided by
/// the DiscoManager.
/// NOTE: This manager requires that the DiscoManager is also registered.
class EntityCapabilitiesManager extends XmppManagerBase {
  EntityCapabilitiesManager(this._capabilityHashBase) : super();

  /// The string that is both the node under which we advertise the disco info
  /// and the base for the actual node on which we respond to disco#info requests.
  final String _capabilityHashBase;

  /// The cached capability hash.
  String? _capabilityHash;

  @override
  String getName() => 'EntityCapabilitiesManager';
  
  @override
  String getId() => entityCapabilitiesManager;

  @override
  Future<bool> isSupported() async => true;

  @override
  List<String> getDiscoFeatures() => [
    capsXmlns,
  ];

  /// Computes, if required, the capability hash of the data provided by
  /// the DiscoManager.
  Future<String> getCapabilityHash() async {
    _capabilityHash ??= await calculateCapabilityHash(
      getAttributes()
        .getManagerById<DiscoManager>(discoManager)!
        .getDiscoInfo(null),
      getHashByName('sha-1')!,
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
  
  @override
  Future<void> postRegisterCallback() async {
    await super.postRegisterCallback();
    
    getAttributes().getManagerById<DiscoManager>(discoManager)!.registerInfoCallback(
        await _getNode(),
        _onInfoQuery,
      );

    getAttributes()
      .getManagerById<PresenceManager>(presenceManager)!
      .registerPreSendCallback(
        _prePresenceSent,
      );
  }
}
