import 'package:moxxmpp/src/managers/base.dart';
import 'package:moxxmpp/src/managers/data.dart';
import 'package:moxxmpp/src/managers/handlers.dart';
import 'package:moxxmpp/src/managers/namespaces.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/stanza.dart';
import 'package:moxxmpp/src/xeps/xep_0446.dart';

/// NOTE: Specified by https://github.com/PapaTutuWawa/custom-xeps/blob/master/xep-xxxx-file-upload-notifications.md
const fileUploadNotificationXmlns = 'proto:urn:xmpp:fun:0';

/// Indicates a file upload notification.
class FileUploadNotificationData {
  const FileUploadNotificationData(this.metadata);

  /// The file metadata indicated in the upload notification.
  final FileMetadataData metadata;
}

/// Indicates that a file upload has been cancelled.
class FileUploadNotificationCancellationData {
  const FileUploadNotificationCancellationData(this.id);

  /// The id of the upload notifiaction that is cancelled.
  final String id;
}

/// Indicates that a file upload has been completed.
class FileUploadNotificationReplacementData {
  const FileUploadNotificationReplacementData(this.id);

  /// The id of the upload notifiaction that is replaced.
  final String id;
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
}
