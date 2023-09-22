import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:moxlib/moxlib.dart';
import 'package:moxxmpp/src/events.dart';
import 'package:moxxmpp/src/jid.dart';
import 'package:moxxmpp/src/managers/base.dart';
import 'package:moxxmpp/src/managers/namespaces.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/stanza.dart';
import 'package:moxxmpp/src/stringxml.dart';
import 'package:moxxmpp/src/xeps/xep_0030/errors.dart';
import 'package:moxxmpp/src/xeps/xep_0030/types.dart';
import 'package:moxxmpp/src/xeps/xep_0030/xep_0030.dart';
import 'package:moxxmpp/src/xeps/xep_0363/errors.dart';

const allowedHTTPHeaders = ['authorization', 'cookie', 'expires'];

class HttpFileUploadSlot {
  const HttpFileUploadSlot(this.putUrl, this.getUrl, this.headers);
  final String putUrl;
  final String getUrl;
  final Map<String, String> headers;
}

/// Strips out all newlines from [value].
String _stripNewlinesFromString(String value) {
  return value.replaceAll('\n', '').replaceAll('\r', '');
}

/// Prepares a list of headers by removing newlines from header names and values
/// and also removes any headers that are not allowed by the XEP.
@visibleForTesting
Map<String, String> prepareHeaders(Map<String, String> headers) {
  return headers.map((key, value) {
    return MapEntry(
      _stripNewlinesFromString(key),
      _stripNewlinesFromString(value),
    );
  })
    ..removeWhere((key, _) => !allowedHTTPHeaders.contains(key.toLowerCase()));
}

class HttpFileUploadManager extends XmppManagerBase {
  HttpFileUploadManager() : super(httpFileUploadManager);

  /// The entity that we will request file uploads from, if discovered.
  JID? _entityJid;

  /// The maximum file upload file size, if advertised and discovered.
  int? _maxUploadSize;

  /// Flag, if we every tried to discover the upload entity.
  bool _gotSupported = false;

  /// Flag, if we can use HTTP File Upload
  bool _supported = false;

  /// Returns whether the entity provided an identity that tells us that we can ask it
  /// for an HTTP upload slot.
  bool _containsFileUploadIdentity(DiscoInfo info) {
    return info.identities.firstWhereOrNull(
          (Identity id) => id.category == 'store' && id.type == 'file',
        ) !=
        null;
  }

  /// Extract the maximum filesize in octets from the disco response. Returns null
  /// if none was specified.
  int? _getMaxFileSize(DiscoInfo info) {
    for (final form in info.extendedInfo) {
      for (final field in form.fields) {
        if (field.varAttr == 'max-file-size') {
          return int.parse(field.values.first);
        }
      }
    }

    return null;
  }

  @override
  Future<void> onXmppEvent(XmppEvent event) async {
    if (event is StreamNegotiationsDoneEvent) {
      final newStream = await isNewStream();
      if (newStream) {
        _gotSupported = false;
        _supported = false;
        _entityJid = null;
        _maxUploadSize = null;
      }
    }
  }

  @override
  Future<bool> isSupported() async {
    if (_gotSupported) return _supported;

    final result = await getAttributes()
        .getManagerById<DiscoManager>(discoManager)!
        .performDiscoSweep();
    if (result.isType<DiscoError>()) {
      _gotSupported = false;
      _supported = false;
      return false;
    }

    final infos = result.get<List<DiscoInfo>>();
    _gotSupported = true;
    for (final info in infos) {
      if (_containsFileUploadIdentity(info) &&
          info.features.contains(httpFileUploadXmlns)) {
        logger.info('Discovered HTTP File Upload for ${info.jid}');

        _entityJid = info.jid;
        _maxUploadSize = _getMaxFileSize(info);
        _supported = true;
        break;
      }
    }

    return _supported;
  }

  /// Request a slot to upload a file to. [filename] is the file's name and [filesize] is
  /// the file's size in octets. [contentType] is optional and refers to the file's
  /// Mime type.
  /// Returns an [HttpFileUploadSlot] if the request was successful; null otherwise.
  Future<Result<HttpFileUploadSlot, HttpFileUploadError>> requestUploadSlot(
    String filename,
    int filesize, {
    String? contentType,
  }) async {
    if (!(await isSupported())) {
      return Result(NoEntityKnownError());
    }

    if (_entityJid == null) {
      logger.warning(
        'Attempted to request HTTP File Upload slot but no entity is known to send this request to.',
      );
      return Result(NoEntityKnownError());
    }

    if (_maxUploadSize != null && filesize > _maxUploadSize!) {
      logger.warning(
        'Attempted to request HTTP File Upload slot for a file that exceeds the filesize limit',
      );
      return Result(FileTooBigError());
    }

    final attrs = getAttributes();
    final response = (await attrs.sendStanza(
      StanzaDetails(
        Stanza.iq(
          to: _entityJid.toString(),
          type: 'get',
          children: [
            XMLNode.xmlns(
              tag: 'request',
              xmlns: httpFileUploadXmlns,
              attributes: {
                'filename': filename,
                'size': filesize.toString(),
                if (contentType != null) 'content-type': contentType,
              },
            ),
          ],
        ),
      ),
    ))!;

    if (response.attributes['type']! != 'result') {
      logger.severe('Failed to request HTTP File Upload slot.');
      // TODO(Unknown): Be more precise
      return Result(UnknownHttpFileUploadError());
    }

    final slot = response.firstTag('slot', xmlns: httpFileUploadXmlns)!;
    final putUrl = slot.firstTag('put')!.attributes['url']! as String;
    final getUrl = slot.firstTag('get')!.attributes['url']! as String;
    final headers = Map<String, String>.fromEntries(
      slot.findTags('header').map((tag) {
        return MapEntry(
          tag.attributes['name']! as String,
          tag.innerText(),
        );
      }),
    );

    return Result(
      HttpFileUploadSlot(
        putUrl,
        getUrl,
        prepareHeaders(headers),
      ),
    );
  }
}
