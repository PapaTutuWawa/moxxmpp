import 'package:moxxmpp/src/managers/base.dart';
import 'package:moxxmpp/src/managers/data.dart';
import 'package:moxxmpp/src/managers/handlers.dart';
import 'package:moxxmpp/src/managers/namespaces.dart';
import 'package:moxxmpp/src/message.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/stanza.dart';
import 'package:moxxmpp/src/stringxml.dart';
import 'package:moxxmpp/src/util/typed_map.dart';
import 'package:moxxmpp/src/xeps/xep_0446.dart';

/// NOTE: Specified by https://github.com/PapaTutuWawa/custom-xeps/blob/master/xep-xxxx-file-upload-notifications.md
const fileUploadNotificationXmlns = 'proto:urn:xmpp:fun:0';

/// Indicates a file upload notification.
class FileUploadNotificationData implements StanzaHandlerExtension {
  const FileUploadNotificationData(this.metadata);

  /// The file metadata indicated in the upload notification.
  final FileMetadataData metadata;

  XMLNode toXML() {
    return XMLNode.xmlns(
      tag: 'file-upload',
      xmlns: fileUploadNotificationXmlns,
      children: [
        metadata.toXML(),
      ],
    );
  }
}

/// Indicates that a file upload has been cancelled.
class FileUploadNotificationCancellationData implements StanzaHandlerExtension {
  const FileUploadNotificationCancellationData(this.id);

  /// The id of the upload notifiaction that is cancelled.
  final String id;

  XMLNode toXML() {
    return XMLNode.xmlns(
      tag: 'cancelled',
      xmlns: fileUploadNotificationXmlns,
      attributes: {
        'id': id,
      },
    );
  }
}

/// Indicates that a file upload has been completed.
class FileUploadNotificationReplacementData implements StanzaHandlerExtension {
  const FileUploadNotificationReplacementData(this.id);

  /// The id of the upload notifiaction that is replaced.
  final String id;

  XMLNode toXML() {
    return XMLNode.xmlns(
      tag: 'replaces',
      xmlns: fileUploadNotificationXmlns,
      attributes: {
        'id': id,
      },
    );
  }
}

class FileUploadNotificationManager extends XmppManagerBase {
  FileUploadNotificationManager() : super(fileUploadNotificationManager);

  @override
  List<StanzaHandler> getIncomingStanzaHandlers() => [
        StanzaHandler(
          stanzaTag: 'message',
          tagName: 'file-upload',
          tagXmlns: fileUploadNotificationXmlns,
          callback: _onFileUploadNotificationReceived,
          priority: -99,
        ),
        StanzaHandler(
          stanzaTag: 'message',
          tagName: 'replaces',
          tagXmlns: fileUploadNotificationXmlns,
          callback: _onFileUploadNotificationReplacementReceived,
          priority: -99,
        ),
        StanzaHandler(
          stanzaTag: 'message',
          tagName: 'cancelled',
          tagXmlns: fileUploadNotificationXmlns,
          callback: _onFileUploadNotificationCancellationReceived,
          priority: -99,
        ),
      ];

  @override
  Future<bool> isSupported() async => true;

  Future<StanzaHandlerData> _onFileUploadNotificationReceived(
    Stanza message,
    StanzaHandlerData state,
  ) async {
    final funElement =
        message.firstTag('file-upload', xmlns: fileUploadNotificationXmlns)!;
    return state
      ..extensions.set(
        FileUploadNotificationData(
          FileMetadataData.fromXML(
            funElement.firstTag('file', xmlns: fileMetadataXmlns)!,
          ),
        ),
      );
  }

  Future<StanzaHandlerData> _onFileUploadNotificationReplacementReceived(
    Stanza message,
    StanzaHandlerData state,
  ) async {
    final element =
        message.firstTag('replaces', xmlns: fileUploadNotificationXmlns)!;
    return state
      ..extensions.set(
        FileUploadNotificationReplacementData(
          element.attributes['id']! as String,
        ),
      );
  }

  Future<StanzaHandlerData> _onFileUploadNotificationCancellationReceived(
    Stanza message,
    StanzaHandlerData state,
  ) async {
    final element =
        message.firstTag('cancels', xmlns: fileUploadNotificationXmlns)!;
    return state
      ..extensions.set(
        FileUploadNotificationCancellationData(
          element.attributes['id']! as String,
        ),
      );
  }

  List<XMLNode> _messageSendingCallback(TypedMap<StanzaHandlerExtension> extensions) {
    final fun = extensions.get<FileUploadNotificationData>();
    if (fun != null) {
      return [fun.toXML()];
    }

    final cancel = extensions.get<FileUploadNotificationCancellationData>();
    if (cancel != null) {
      return [cancel.toXML()];
    }

    final replace = extensions.get<FileUploadNotificationReplacementData>();
    if (replace != null) {
      return [replace.toXML()];
    }

    return [];
  }

  @override
  Future<void> postRegisterCallback() async {
    await super.postRegisterCallback();

    // Register the sending callback
    getAttributes()
        .getManagerById<MessageManager>(messageManager)
        ?.registerMessageSendingCallback(_messageSendingCallback);
  }
}
