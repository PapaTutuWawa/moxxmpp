import 'dart:convert';
import 'package:moxlib/moxlib.dart';
import 'package:moxxmpp/src/events.dart';
import 'package:moxxmpp/src/jid.dart';
import 'package:moxxmpp/src/managers/base.dart';
import 'package:moxxmpp/src/managers/namespaces.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/stringxml.dart';
import 'package:moxxmpp/src/xeps/xep_0060/errors.dart';
import 'package:moxxmpp/src/xeps/xep_0060/xep_0060.dart';

abstract class AvatarError {}

class UnknownAvatarError extends AvatarError {}

/// The result of a successful query of a users avatar.
class UserAvatarData {
  const UserAvatarData(this.base64, this.hash);

  /// The base64-encoded avatar data.
  final String base64;

  /// The SHA-1 hash of the raw avatar data.
  final String hash;

  /// The raw avatar data.
  /// NOTE: Remove newlines because "Line feeds SHOULD NOT be added but MUST be accepted"
  /// (https://xmpp.org/extensions/xep-0084.html#proto-data).
  List<int> get data => base64Decode(base64.replaceAll('\n', ''));
}

class UserAvatarMetadata {
  const UserAvatarMetadata(
    this.id,
    this.length,
    this.width,
    this.height,
    this.type,
    this.url,
  );

  factory UserAvatarMetadata.fromXML(XMLNode node) {
    assert(node.tag == 'info', 'node must be an <info /> element');

    final width = node.attributes['width'] as String?;
    final height = node.attributes['height'] as String?;
    return UserAvatarMetadata(
      node.attributes['id']! as String,
      int.parse(node.attributes['bytes']! as String),
      width != null ? int.parse(width) : null,
      height != null ? int.parse(height) : null,
      node.attributes['type']! as String,
      node.attributes['url'] as String?,
    );
  }

  /// The amount of bytes in the file.
  final int length;

  /// The identifier of the avatar.
  final String id;

  /// Image proportions.
  final int? width;
  final int? height;

  /// The URL where the avatar can be found.
  final String? url;

  /// The MIME type of the avatar.
  final String type;
}

/// NOTE: This class requires a PubSubManager
class UserAvatarManager extends XmppManagerBase {
  UserAvatarManager() : super(userAvatarManager);

  PubSubManager _getPubSubManager() =>
      getAttributes().getManagerById(pubsubManager)! as PubSubManager;

  @override
  List<String> getDiscoFeatures() => [
        '$userAvatarMetadataXmlns+notify',
      ];

  @override
  Future<void> onXmppEvent(XmppEvent event) async {
    if (event is PubSubNotificationEvent) {
      if (event.item.node != userAvatarMetadataXmlns) return;

      if (event.item.payload.tag != 'metadata' ||
          event.item.payload.attributes['xmlns'] != userAvatarMetadataXmlns) {
        logger.warning(
          'Received avatar update from ${event.from} but the payload is invalid. Ignoring...',
        );
        return;
      }

      getAttributes().sendEvent(
        UserAvatarUpdatedEvent(
          JID.fromString(event.from),
          event.item.payload
              .findTags('metadata', xmlns: userAvatarMetadataXmlns)
              .map(UserAvatarMetadata.fromXML)
              .toList(),
        ),
      );
    }
  }

  // TODO(PapaTutuWawa): Check for PEP support
  @override
  Future<bool> isSupported() async => true;

  /// Requests the avatar from [jid]. Returns the avatar data if the request was
  /// successful. Null otherwise
  Future<Result<AvatarError, UserAvatarData>> getUserAvatarData(
    JID jid,
    String id,
  ) async {
    final pubsub = _getPubSubManager();
    final resultRaw = await pubsub.getItem(jid, userAvatarDataXmlns, id);
    if (resultRaw.isType<PubSubError>()) return Result(UnknownAvatarError());

    final result = resultRaw.get<PubSubItem>();
    return Result(
      UserAvatarData(
        result.payload.innerText(),
        id,
      ),
    );
  }

  /// Attempts to fetch the latest item from the User Avatar metadata node. Returns the list of
  /// metadata contained within it. The list may be empty.
  ///
  /// If an error occured, returns an [AvatarError].
  Future<Result<AvatarError, List<UserAvatarMetadata>>> getLatestMetadata(
    JID jid,
  ) async {
    final resultsRaw = await _getPubSubManager()
        .getItems(jid, userAvatarMetadataXmlns, maxItems: 1);
    if (resultsRaw.isType<PubSubError>()) return Result(UnknownAvatarError());

    final results = resultsRaw.get<List<PubSubItem>>();
    if (results.isEmpty) {
      return Result(UnknownAvatarError());
    }

    final metadata = results.first.payload
        .firstTag('metadata', xmlns: userAvatarMetadataXmlns)!;
    return Result(
      metadata.findTags('info').map(UserAvatarMetadata.fromXML).toList(),
    );
  }

  /// Publish the avatar data, [base64], on the pubsub node using [hash] as
  /// the item id. [hash] must be the SHA-1 hash of the image data, while
  /// [base64] must be the base64-encoded version of the image data.
  Future<Result<AvatarError, bool>> publishUserAvatar(
    String base64,
    String hash,
    bool public,
  ) async {
    final pubsub = _getPubSubManager();
    final result = await pubsub.publish(
      getAttributes().getFullJID().toBare(),
      userAvatarDataXmlns,
      XMLNode.xmlns(
        tag: 'data',
        xmlns: userAvatarDataXmlns,
        text: base64,
      ),
      id: hash,
      options: PubSubPublishOptions(
        accessModel: public ? 'open' : 'roster',
      ),
    );

    if (result.isType<PubSubError>()) return Result(UnknownAvatarError());

    return const Result(true);
  }

  /// Publish avatar metadata [metadata] to the User Avatar's metadata node. If [public]
  /// is true, then the node will be set to an 'open' access model. If [public] is false,
  /// then the node will be set to an 'roster' access model.
  Future<Result<AvatarError, bool>> publishUserAvatarMetadata(
    UserAvatarMetadata metadata,
    bool public,
  ) async {
    final pubsub = _getPubSubManager();
    final result = await pubsub.publish(
      getAttributes().getFullJID().toBare(),
      userAvatarMetadataXmlns,
      XMLNode.xmlns(
        tag: 'metadata',
        xmlns: userAvatarMetadataXmlns,
        children: [
          XMLNode(
            tag: 'info',
            attributes: <String, String>{
              'bytes': metadata.length.toString(),
              'height': metadata.height.toString(),
              'width': metadata.width.toString(),
              'type': metadata.type,
              'id': metadata.id,
            },
          ),
        ],
      ),
      id: metadata.id,
      options: PubSubPublishOptions(
        accessModel: public ? 'open' : 'roster',
      ),
    );

    if (result.isType<PubSubError>()) return Result(UnknownAvatarError());
    return const Result(true);
  }

  /// Subscribe the data and metadata node of [jid].
  Future<Result<AvatarError, bool>> subscribe(JID jid) async {
    await _getPubSubManager().subscribe(jid, userAvatarMetadataXmlns);

    return const Result(true);
  }

  /// Unsubscribe the data and metadata node of [jid].
  Future<Result<AvatarError, bool>> unsubscribe(JID jid) async {
    await _getPubSubManager().subscribe(jid, userAvatarMetadataXmlns);

    return const Result(true);
  }
}
