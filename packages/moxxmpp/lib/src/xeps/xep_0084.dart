import 'package:moxxmpp/src/events.dart';
import 'package:moxxmpp/src/managers/base.dart';
import 'package:moxxmpp/src/managers/namespaces.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/stringxml.dart';
import 'package:moxxmpp/src/types/result.dart';
import 'package:moxxmpp/src/xeps/xep_0030/errors.dart';
import 'package:moxxmpp/src/xeps/xep_0030/types.dart';
import 'package:moxxmpp/src/xeps/xep_0030/xep_0030.dart';
import 'package:moxxmpp/src/xeps/xep_0060/errors.dart';
import 'package:moxxmpp/src/xeps/xep_0060/xep_0060.dart';

abstract class AvatarError {}

class UnknownAvatarError extends AvatarError {}

class UserAvatar {
  const UserAvatar({ required this.base64, required this.hash });
  final String base64;
  final String hash;
}

class UserAvatarMetadata {
  const UserAvatarMetadata(
    this.id,
    this.length,
    this.width,
    this.height,
    this.mime,
  );
  /// The amount of bytes in the file
  final int length;
  /// The identifier of the avatar
  final String id;
  /// Image proportions
  final int width;
  final int height;
  /// The MIME type of the avatar
  final String mime;
}

/// NOTE: This class requires a PubSubManager
class UserAvatarManager extends XmppManagerBase {
  @override
  String getId() => userAvatarManager;

  @override
  String getName() => 'UserAvatarManager';

  PubSubManager _getPubSubManager() => getAttributes().getManagerById(pubsubManager)! as PubSubManager;
  
  @override
  Future<void> onXmppEvent(XmppEvent event) async {
    if (event is PubSubNotificationEvent) {
      if (event.item.node != userAvatarDataXmlns) return;

      if (event.item.payload.tag != 'data' ||
          event.item.payload.attributes['xmlns'] != userAvatarDataXmlns) {
        logger.warning('Received avatar update from ${event.from} but the payload is invalid. Ignoring...');
        return;
      }

      getAttributes().sendEvent(
        AvatarUpdatedEvent(
          jid: event.from,
          base64: event.item.payload.innerText(),
          hash: event.item.id,
        ),
      );
    }
  }

  // TODO(PapaTutuWawa): Check for PEP support
  @override
  Future<bool> isSupported() async => true;

  /// Requests the avatar from [jid]. Returns the avatar data if the request was
  /// successful. Null otherwise
  Future<Result<AvatarError, UserAvatar>> getUserAvatar(String jid) async {
    final pubsub = _getPubSubManager();
    final resultsRaw = await pubsub.getItems(jid, userAvatarDataXmlns);
    if (resultsRaw.isType<PubSubError>()) return Result(UnknownAvatarError());

    final results = resultsRaw.get<List<PubSubItem>>();
    if (results.isEmpty) return Result(UnknownAvatarError());

    final item = results[0];
    return Result(
      UserAvatar(
        base64: item.payload.innerText(),
        hash: item.id,
      ),
    );
  }

  /// Publish the avatar data, [base64], on the pubsub node using [hash] as
  /// the item id. [hash] must be the SHA-1 hash of the image data, while
  /// [base64] must be the base64-encoded version of the image data.
  Future<Result<AvatarError, bool>> publishUserAvatar(String base64, String hash, bool public) async {
    final pubsub = _getPubSubManager();
    final result = await pubsub.publish(
      getAttributes().getFullJID().toBare().toString(),
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
  Future<Result<AvatarError, bool>> publishUserAvatarMetadata(UserAvatarMetadata metadata, bool public) async {
    final pubsub = _getPubSubManager();
    final result = await pubsub.publish(
      getAttributes().getFullJID().toBare().toString(),
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
              'type': metadata.mime,
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
  Future<Result<AvatarError, bool>> subscribe(String jid) async {
    await _getPubSubManager().subscribe(jid, userAvatarDataXmlns);
    await _getPubSubManager().subscribe(jid, userAvatarMetadataXmlns);

    return const Result(true);
  }

  /// Unsubscribe the data and metadata node of [jid].
  Future<Result<AvatarError, bool>> unsubscribe(String jid) async {
    await _getPubSubManager().unsubscribe(jid, userAvatarDataXmlns);
    await _getPubSubManager().subscribe(jid, userAvatarMetadataXmlns);

    return const Result(true);
  }

  /// Returns the PubSub Id of an avatar after doing a disco#items query.
  /// Note that this assumes that there is only one (1) item published on
  /// the node.
  Future<Result<AvatarError, String>> getAvatarId(String jid) async {
    final disco = getAttributes().getManagerById(discoManager)! as DiscoManager;
    final response = await disco.discoItemsQuery(jid, node: userAvatarDataXmlns, shouldEncrypt: false);
    if (response.isType<DiscoError>()) return Result(UnknownAvatarError());

    final items = response.get<List<DiscoItem>>();
    if (items.isEmpty) return Result(UnknownAvatarError());

    return Result(items.first.name);
  }
}
