import 'dart:async';
import 'dart:convert';
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
import 'package:moxxmpp/src/xeps/xep_0030/errors.dart';
import 'package:moxxmpp/src/xeps/xep_0030/types.dart';
import 'package:moxxmpp/src/xeps/xep_0030/xep_0030.dart';
import 'package:moxxmpp/src/xeps/xep_0060/errors.dart';
import 'package:moxxmpp/src/xeps/xep_0060/xep_0060.dart';
import 'package:moxxmpp/src/xeps/xep_0280.dart';
import 'package:moxxmpp/src/xeps/xep_0334.dart';
import 'package:moxxmpp/src/xeps/xep_0380.dart';
import 'package:moxxmpp/src/xeps/xep_0384/crypto.dart';
import 'package:moxxmpp/src/xeps/xep_0384/errors.dart';
import 'package:moxxmpp/src/xeps/xep_0384/helpers.dart';
import 'package:moxxmpp/src/xeps/xep_0384/types.dart';
import 'package:omemo_dart/omemo_dart.dart' as omemo;
import 'package:xml/xml.dart';

/// A callback that is executed whenever we need to acquire the OmemoManager backing
/// the manager.
typedef GetOmemoManagerCallback = Future<omemo.OmemoManager> Function();

/// A callback for figuring out whether a stanza should be encrypted or not. Note that
/// returning true here does not necessarily mean that a stanza gets encrypted because
/// handlers can indicate that a stanza should not be encrypted, e.g. PubSub.
typedef ShouldEncryptStanzaCallback = Future<bool> Function(
  JID toJid,
  Stanza stanza,
);

const _doNotEncryptList = [
  // XEP-0033
  DoNotEncrypt('addresses', extendedAddressingXmlns),
  // XEP-0060
  DoNotEncrypt('pubsub', pubsubXmlns),
  DoNotEncrypt('pubsub', pubsubOwnerXmlns),
  // XEP-0334
  DoNotEncrypt('no-permanent-store', messageProcessingHintsXmlns),
  DoNotEncrypt('no-store', messageProcessingHintsXmlns),
  DoNotEncrypt('no-copy', messageProcessingHintsXmlns),
  DoNotEncrypt('store', messageProcessingHintsXmlns),
  // XEP-0359
  DoNotEncrypt('origin-id', stableIdXmlns),
  DoNotEncrypt('stanza-id', stableIdXmlns),
];

class OmemoManager extends XmppManagerBase {
  OmemoManager(this._getOmemoManager, this._shouldEncryptStanza)
      : super(omemoManager);

  /// Callback for getting the [omemo.OmemoManager].
  final GetOmemoManagerCallback _getOmemoManager;

  /// Callback for checking whether a stanza should be encrypted or not.
  final ShouldEncryptStanzaCallback _shouldEncryptStanza;

  // TODO(Unknown): Technically, this is not always true
  @override
  Future<bool> isSupported() async => true;

  @override
  List<StanzaHandler> getIncomingPreStanzaHandlers() => [
        StanzaHandler(
          stanzaTag: 'iq',
          tagXmlns: omemoXmlns,
          tagName: 'encrypted',
          callback: _onIncomingStanza,
        ),
        StanzaHandler(
          stanzaTag: 'presence',
          tagXmlns: omemoXmlns,
          tagName: 'encrypted',
          callback: _onIncomingStanza,
        ),
        StanzaHandler(
          stanzaTag: 'message',
          tagXmlns: omemoXmlns,
          tagName: 'encrypted',
          callback: _onIncomingStanza,
        ),
      ];

  @override
  List<StanzaHandler> getOutgoingPreStanzaHandlers() => [
        StanzaHandler(
          stanzaTag: 'iq',
          callback: _onOutgoingStanza,
        ),
        StanzaHandler(
          stanzaTag: 'presence',
          callback: _onOutgoingStanza,
        ),
        StanzaHandler(
          stanzaTag: 'message',
          callback: _onOutgoingStanza,
          priority: 100,
        ),
      ];

  @override
  Future<void> onXmppEvent(XmppEvent event) async {
    if (event is PubSubNotificationEvent) {
      if (event.item.node != omemoDevicesXmlns) return;

      logger.finest('Received PubSub device notification for ${event.from}');
      final ownJid = getAttributes().getFullJID().toBare().toString();
      final jid = JID.fromString(event.from).toBare();
      final ids = event.item.payload.children
          .map((child) => int.parse(child.attributes['id']! as String))
          .toList();

      if (event.from == ownJid) {
        // Another client published to our device list node
        if (!ids.contains(await _getDeviceId())) {
          // Attempt to publish again
          unawaited(publishBundle(await _getDeviceBundle()));
        }
      } else {
        // Someone published to their device list node
        logger.finest('Got devices $ids');
      }

      // Tell the OmemoManager
      await (await _getOmemoManager()).onDeviceListUpdate(jid.toString(), ids);

      // Generate an event
      getAttributes().sendEvent(OmemoDeviceListUpdatedEvent(jid, ids));
    }
  }

  /// Wrapper around using getSessionManager and then calling getDeviceId on it.
  Future<int> _getDeviceId() async => (await _getOmemoManager()).getDeviceId();

  /// Wrapper around using getSessionManager and then calling getDeviceId on it.
  Future<omemo.OmemoBundle> _getDeviceBundle() async {
    final om = await _getOmemoManager();
    final device = await om.getDevice();
    return device.toBundle();
  }

  /// Determines what child elements of a stanza should be encrypted. If shouldEncrypt
  /// returns true for [element], then [element] will be encrypted. If shouldEncrypt
  /// returns false, then [element] won't be encrypted.
  ///
  /// The default implementation ignores all elements that are mentioned in XEP-0420, i.e.:
  /// - XEP-0033 elements (<addresses />)
  /// - XEP-0334 elements (<store/>, <no-copy/>, <no-store/>, <no-permanent-store/>)
  /// - XEP-0359 elements (<origin-id />, <stanza-id />)
  @visibleForOverriding
  bool shouldEncryptElement(XMLNode element) {
    for (final ignore in _doNotEncryptList) {
      final xmlns = element.attributes['xmlns'] ?? '';
      if (element.tag == ignore.tag && xmlns == ignore.xmlns) {
        return false;
      }
    }

    return true;
  }

  /// Encrypt [children] using OMEMO. This either produces an <encrypted /> element with
  /// an attached payload, if [children] is not null, or an empty OMEMO message if
  /// [children] is null. This function takes care of creating the affix elements as
  /// specified by both XEP-0420 and XEP-0384.
  /// [toJid] is the list of JIDs the payload should be encrypted for.
  String _buildEnvelope(List<XMLNode> children, String toJid) {
    final payload = XMLNode.xmlns(
      tag: 'envelope',
      xmlns: sceXmlns,
      children: [
        XMLNode(
          tag: 'content',
          children: children,
        ),
        XMLNode(
          tag: 'rpad',
          text: generateRpad(),
        ),
        XMLNode(
          tag: 'to',
          attributes: <String, String>{
            'jid': toJid,
          },
        ),
        XMLNode(
          tag: 'from',
          attributes: <String, String>{
            'jid': getAttributes().getFullJID().toString(),
          },
        ),
        /*
        XMLNode(
          tag: 'time',
          // TODO(Unknown): Implement
          attributes: <String, String>{
            'stamp': '',
          },
        ),
        */
      ],
    );

    return payload.toXml();
  }

  XMLNode _buildEncryptedElement(
    omemo.EncryptionResult result,
    String recipientJid,
    int deviceId,
  ) {
    final keyElements = <String, List<XMLNode>>{};
    for (final keys in result.encryptedKeys.entries) {
      keyElements[keys.key] = keys.value
          .map(
            (ek) => XMLNode(
              tag: 'key',
              attributes: {
                'rid': ek.rid.toString(),
                if (ek.kex) 'kex': 'true',
              },
              text: ek.value,
            ),
          )
          .toList();
    }

    final keysElements = keyElements.entries.map((entry) {
      return XMLNode(
        tag: 'keys',
        attributes: {
          'jid': entry.key,
        },
        children: entry.value,
      );
    }).toList();

    return XMLNode.xmlns(
      tag: 'encrypted',
      xmlns: omemoXmlns,
      children: [
        if (result.ciphertext != null)
          XMLNode(
            tag: 'payload',
            text: base64Encode(result.ciphertext!),
          ),
        XMLNode(
          tag: 'header',
          attributes: <String, String>{
            'sid': deviceId.toString(),
          },
          children: keysElements,
        ),
      ],
    );
  }

  /// For usage with omemo_dart's OmemoManager.
  Future<void> sendEmptyMessageImpl(
    omemo.EncryptionResult result,
    String toJid,
  ) async {
    await getAttributes().sendStanza(
      StanzaDetails(
        Stanza.message(
          to: toJid,
          type: 'chat',
          children: [
            _buildEncryptedElement(
              result,
              toJid,
              await _getDeviceId(),
            ),

            // Add a storage hint in case this is a message
            // Taken from the example at
            // https://xmpp.org/extensions/xep-0384.html#message-structure-description.
            MessageProcessingHint.store.toXML(),
          ],
        ),
        awaitable: false,
        encrypted: true,
      ),
    );
  }

  /// Send a heartbeat message to [jid].
  Future<void> sendOmemoHeartbeat(String jid) async {
    final om = await _getOmemoManager();
    await om.sendOmemoHeartbeat(jid);
  }

  /// For usage with omemo_dart's OmemoManager
  Future<List<int>?> fetchDeviceList(String jid) async {
    final result = await getDeviceList(JID.fromString(jid));
    if (result.isType<OmemoError>()) return null;

    return result.get<List<int>>();
  }

  /// For usage with omemo_dart's OmemoManager
  Future<omemo.OmemoBundle?> fetchDeviceBundle(String jid, int id) async {
    final result = await retrieveDeviceBundle(JID.fromString(jid), id);
    if (result.isType<OmemoError>()) return null;

    return result.get<omemo.OmemoBundle>();
  }

  Future<StanzaHandlerData> _onOutgoingStanza(
    Stanza stanza,
    StanzaHandlerData state,
  ) async {
    if (!state.shouldEncrypt) {
      logger.finest('Not encrypting since state.shouldEncrypt is false');
      return state;
    }

    if (state.encrypted) {
      logger.finest('Not encrypting since state.encrypted is true');
      return state;
    }

    if (stanza.to == null) {
      // We cannot encrypt in this case.
      logger.finest('Not encrypting since stanza.to is null');
      return state;
    }

    final toJid = JID.fromString(stanza.to!).toBare();
    final shouldEncryptResult = await _shouldEncryptStanza(toJid, stanza);
    if (!shouldEncryptResult && !state.forceEncryption) {
      logger.finest(
        'Not encrypting stanza for $toJid: Both shouldEncryptStanza and forceEncryption are false.',
      );
      return state;
    } else {
      logger.finest(
        'Encrypting stanza for $toJid: shouldEncryptResult=$shouldEncryptResult, forceEncryption=${state.forceEncryption}',
      );
    }

    final toEncrypt = List<XMLNode>.empty(growable: true);
    final children = List<XMLNode>.empty(growable: true);
    for (final child in stanza.children) {
      if (!shouldEncryptElement(child)) {
        children.add(child);
      } else {
        toEncrypt.add(child);
      }
    }

    logger.finest('Beginning encryption');
    final carbonsEnabled = getAttributes()
            .getManagerById<CarbonsManager>(carbonsManager)
            ?.isEnabled ??
        false;
    final om = await _getOmemoManager();
    final encryptToJids = [
      toJid.toString(),
      if (carbonsEnabled) getAttributes().getFullJID().toBare().toString(),
    ];
    final result = await om.onOutgoingStanza(
      omemo.OmemoOutgoingStanza(
        encryptToJids,
        _buildEnvelope(toEncrypt, toJid.toString()),
      ),
    );
    logger.finest('Encryption done');

    if (!result.canSend) {
      return state
        ..cancel = true
        // If we have no device list for toJid, then the contact most likely does not
        // support OMEMO:2
        ..cancelReason = result.deviceEncryptionErrors[toJid.toString()]!.first
                .error is omemo.NoKeyMaterialAvailableError
            ? OmemoNotSupportedForContactException()
            : UnknownOmemoError()
        ..encryptionError = OmemoEncryptionError(
          result.deviceEncryptionErrors,
        );
    }

    final encrypted = _buildEncryptedElement(
      result,
      toJid.toString(),
      await _getDeviceId(),
    );
    children.add(encrypted);

    // Only add message specific metadata when actually sending a message
    if (stanza.tag == 'message') {
      children
        // Add EME data
        ..add(ExplicitEncryptionType.omemo2.toXML())
        // Add a storage hint in case this is a message
        // Taken from the example at
        // https://xmpp.org/extensions/xep-0384.html#message-structure-description.
        ..add(MessageProcessingHint.store.toXML());
    }

    return state
      ..stanza = state.stanza.copyWith(children: children)
      ..encrypted = true;
  }

  Future<StanzaHandlerData> _onIncomingStanza(
    Stanza stanza,
    StanzaHandlerData state,
  ) async {
    if (stanza.from == null) return state;

    final encrypted = stanza.firstTag('encrypted', xmlns: omemoXmlns)!;
    final fromJid = JID.fromString(stanza.from!).toBare();
    final header = encrypted.firstTag('header')!;
    final ourJid = getAttributes().getFullJID();
    final ourJidString = ourJid.toBare().toString();
    final keys = List<omemo.EncryptedKey>.empty(growable: true);
    for (final keysElement in header.findTags('keys')) {
      // We only care about our own JID
      final jid = keysElement.attributes['jid']! as String;
      if (jid != ourJidString) {
        continue;
      }

      keys.addAll(
        keysElement.findTags('key').map(
              (key) => omemo.EncryptedKey(
                int.parse(key.attributes['rid']! as String),
                key.innerText(),
                key.attributes['kex'] == 'true',
              ),
            ),
      );
    }

    final sid = int.parse(header.attributes['sid']! as String);
    final om = await _getOmemoManager();
    final result = await om.onIncomingStanza(
      omemo.OmemoIncomingStanza(
        fromJid.toString(),
        sid,
        keys,
        encrypted.firstTag('payload')?.innerText(),
        false,
      ),
    );

    var children = stanza.children;
    if (result.error != null) {
      state.encryptionError = result.error;
    } else {
      children = stanza.children
          .where(
            (child) =>
                child.tag != 'encrypted' ||
                child.attributes['xmlns'] != omemoXmlns,
          )
          .toList();
    }

    logger.finest('Got payload: ${result.payload != null}');
    if (result.payload != null) {
      XMLNode envelope;
      try {
        envelope = XMLNode.fromString(result.payload!);
      } on XmlParserException catch (_) {
        logger.warning('Failed to parse envelope payload: ${result.payload!}');
        return state
          ..encrypted = true
          ..encryptionError = InvalidEnvelopePayloadException();
      }

      final envelopeChildren = envelope.firstTag('content')?.children;
      if (envelopeChildren != null) {
        children.addAll(
          // Do not add forbidden elements from the envelope
          envelopeChildren.where(shouldEncryptElement),
        );

        logger.finest('Adding children: ${envelopeChildren.map((c) => c.tag)}');
      } else {
        logger.warning('Invalid envelope element: No <content /> element');
      }

      if (!checkAffixElements(envelope, stanza.from!, ourJid)) {
        state.encryptionError = InvalidAffixElementsException();
      }
    }

    // Ignore heartbeat messages
    if (stanza.tag == 'message' && encrypted.firstTag('payload') == null) {
      logger.finest('Received empty OMEMO message. Ending processing early.');
      return state
        ..encrypted = true
        ..skip = true
        ..done = true;
    }

    return state
      ..encrypted = true
      ..stanza = Stanza(
        to: stanza.to,
        from: stanza.from,
        id: stanza.id,
        type: stanza.type,
        children: children,
        tag: stanza.tag,
        attributes: Map<String, String>.from(stanza.attributes),
      )
      ..extensions.set<OmemoData>(
        OmemoData(
          result.newRatchets,
          result.replacedRatchets,
        ),
      );
  }

  /// Convenience function that attempts to retrieve the raw XML payload from the
  /// device list PubSub node.
  ///
  /// On success, returns the XML data. On failure, returns an OmemoError.
  Future<Result<OmemoError, XMLNode>> _retrieveDeviceListPayload(
    JID jid,
  ) async {
    final pm = getAttributes().getManagerById<PubSubManager>(pubsubManager)!;
    final result = await pm.getItems(jid.toBare(), omemoDevicesXmlns);
    if (result.isType<PubSubError>()) return Result(UnknownOmemoError());
    return Result(result.get<List<PubSubItem>>().first.payload);
  }

  /// Retrieves the OMEMO device list from [jid].
  Future<Result<OmemoError, List<int>>> getDeviceList(JID jid) async {
    final itemsRaw = await _retrieveDeviceListPayload(jid);
    if (itemsRaw.isType<OmemoError>()) return Result(UnknownOmemoError());

    final ids = itemsRaw
        .get<XMLNode>()
        .children
        .map((child) => int.parse(child.attributes['id']! as String))
        .toList();
    return Result(ids);
  }

  /// Retrieve all device bundles for the JID [jid].
  ///
  /// On success, returns a list of devices. On failure, returns am OmemoError.
  Future<Result<OmemoError, List<omemo.OmemoBundle>>> retrieveDeviceBundles(
    JID jid,
  ) async {
    // TODO(Unknown): Should we query the device list first?
    final pm = getAttributes().getManagerById<PubSubManager>(pubsubManager)!;
    final bundlesRaw = await pm.getItems(jid, omemoBundlesXmlns);
    if (bundlesRaw.isType<PubSubError>()) return Result(UnknownOmemoError());

    final bundles = bundlesRaw
        .get<List<PubSubItem>>()
        .map(
          (bundle) => bundleFromXML(jid, int.parse(bundle.id), bundle.payload),
        )
        .toList();

    return Result(bundles);
  }

  /// Retrieves a bundle from entity [jid] with the device id [deviceId].
  ///
  /// On success, returns the device bundle. On failure, returns an OmemoError.
  Future<Result<OmemoError, omemo.OmemoBundle>> retrieveDeviceBundle(
    JID jid,
    int deviceId,
  ) async {
    final pm = getAttributes().getManagerById<PubSubManager>(pubsubManager)!;
    final bareJid = jid.toBare().toString();
    final item = await pm.getItem(bareJid, omemoBundlesXmlns, '$deviceId');
    if (item.isType<PubSubError>()) return Result(UnknownOmemoError());

    return Result(bundleFromXML(jid, deviceId, item.get<PubSubItem>().payload));
  }

  /// Attempts to publish a device bundle to the device list and device bundle PubSub
  /// nodes.
  ///
  /// On success, returns true. On failure, returns an OmemoError.
  Future<Result<OmemoError, bool>> publishBundle(
    omemo.OmemoBundle bundle,
  ) async {
    final attrs = getAttributes();
    final pm = attrs.getManagerById<PubSubManager>(pubsubManager)!;
    final bareJid = attrs.getFullJID().toBare();

    XMLNode? deviceList;
    final deviceListRaw = await _retrieveDeviceListPayload(bareJid);
    if (!deviceListRaw.isType<OmemoError>()) {
      deviceList = deviceListRaw.get<XMLNode>();
    }

    deviceList ??= XMLNode.xmlns(
      tag: 'devices',
      xmlns: omemoDevicesXmlns,
    );

    final ids = deviceList.children
        .map((child) => int.parse(child.attributes['id']! as String));

    if (!ids.contains(bundle.id)) {
      // Only update the device list if the device Id is not there
      final newDeviceList = XMLNode.xmlns(
        tag: 'devices',
        xmlns: omemoDevicesXmlns,
        children: [
          ...deviceList.children,
          XMLNode(
            tag: 'device',
            attributes: <String, String>{
              'id': '${bundle.id}',
            },
          ),
        ],
      );

      final deviceListPublish = await pm.publish(
        bareJid,
        omemoDevicesXmlns,
        newDeviceList,
        id: 'current',
        options: const PubSubPublishOptions(
          accessModel: 'open',
        ),
      );
      if (deviceListPublish.isType<PubSubError>()) return const Result(false);
    }

    final deviceBundlePublish = await pm.publish(
      bareJid,
      omemoBundlesXmlns,
      bundleToXML(bundle),
      id: '${bundle.id}',
      options: const PubSubPublishOptions(
        accessModel: 'open',
        maxItems: 'max',
      ),
    );

    return Result(deviceBundlePublish.isType<PubSubError>());
  }

  /// Subscribes to the device list PubSub node of [jid].
  Future<void> subscribeToDeviceListImpl(String jid) async {
    final pm = getAttributes().getManagerById<PubSubManager>(pubsubManager)!;
    await pm.subscribe(JID.fromString(jid), omemoDevicesXmlns);
  }

  /// Implementation for publishing our device [device].
  Future<void> publishDeviceImpl(omemo.OmemoDevice device) async {
    await publishBundle(await device.toBundle());
  }

  /// Attempts to find out if [jid] supports omemo:2.
  ///
  /// On success, returns whether [jid] has published a device list and device bundles.
  /// On failure, returns an OmemoError.
  Future<Result<OmemoError, bool>> supportsOmemo(JID jid) async {
    final dm = getAttributes().getManagerById<DiscoManager>(discoManager)!;
    final items = await dm.discoItemsQuery(jid.toBare());

    if (items.isType<DiscoError>()) return Result(UnknownOmemoError());

    final nodes = items.get<List<DiscoItem>>();
    final result = nodes.any((item) => item.node == omemoDevicesXmlns) &&
        nodes.any((item) => item.node == omemoBundlesXmlns);
    return Result(result);
  }

  /// Attempts to delete a device with device id [deviceId] from the device bundles node
  /// and then the device list node. This allows a device that was accidentally removed
  /// to republish without any race conditions.
  /// Note that this does not delete a possibly existent ratchet session.
  ///
  /// On success, returns true. On failure, returns an OmemoError.
  Future<Result<OmemoError, bool>> deleteDevice(int deviceId) async {
    final pm = getAttributes().getManagerById<PubSubManager>(pubsubManager)!;
    final jid = getAttributes().getFullJID().toBare();

    final bundleResult = await pm.retract(jid, omemoBundlesXmlns, '$deviceId');
    if (bundleResult.isType<PubSubError>()) {
      // TODO(Unknown): Be more specific
      return Result(UnknownOmemoError());
    }

    final deviceListResult = await _retrieveDeviceListPayload(jid);
    if (deviceListResult.isType<OmemoError>()) {
      return Result(bundleResult.get<OmemoError>());
    }

    final payload = deviceListResult.get<XMLNode>();
    final newPayload = XMLNode.xmlns(
      tag: 'devices',
      xmlns: omemoDevicesXmlns,
      children: payload.children
          .where((child) => child.attributes['id'] != '$deviceId')
          .toList(),
    );
    final publishResult = await pm.publish(
      jid,
      omemoDevicesXmlns,
      newPayload,
      id: 'current',
      options: const PubSubPublishOptions(
        accessModel: 'open',
      ),
    );

    if (publishResult.isType<PubSubError>()) return Result(UnknownOmemoError());

    return const Result(true);
  }
}
