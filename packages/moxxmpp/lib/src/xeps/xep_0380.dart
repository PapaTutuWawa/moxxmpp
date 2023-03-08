import 'package:moxxmpp/src/managers/base.dart';
import 'package:moxxmpp/src/managers/data.dart';
import 'package:moxxmpp/src/managers/handlers.dart';
import 'package:moxxmpp/src/managers/namespaces.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/stanza.dart';
import 'package:moxxmpp/src/stringxml.dart';

enum ExplicitEncryptionType {
  otr,
  legacyOpenPGP,
  openPGP,
  omemo,
  omemo1,
  omemo2,
  unknown,
}

String _explicitEncryptionTypeToString(ExplicitEncryptionType type) {
  switch (type) {
    case ExplicitEncryptionType.otr:
      return emeOtr;
    case ExplicitEncryptionType.legacyOpenPGP:
      return emeLegacyOpenPGP;
    case ExplicitEncryptionType.openPGP:
      return emeOpenPGP;
    case ExplicitEncryptionType.omemo:
      return emeOmemo;
    case ExplicitEncryptionType.omemo1:
      return emeOmemo1;
    case ExplicitEncryptionType.omemo2:
      return emeOmemo2;
    case ExplicitEncryptionType.unknown:
      return '';
  }
}

ExplicitEncryptionType _explicitEncryptionTypeFromString(String str) {
  switch (str) {
    case emeOtr:
      return ExplicitEncryptionType.otr;
    case emeLegacyOpenPGP:
      return ExplicitEncryptionType.legacyOpenPGP;
    case emeOpenPGP:
      return ExplicitEncryptionType.openPGP;
    case emeOmemo:
      return ExplicitEncryptionType.omemo;
    case emeOmemo1:
      return ExplicitEncryptionType.omemo1;
    case emeOmemo2:
      return ExplicitEncryptionType.omemo2;
    default:
      return ExplicitEncryptionType.unknown;
  }
}

/// Create an <encryption /> element with [type] indicating which type of encryption was
/// used.
XMLNode buildEmeElement(ExplicitEncryptionType type) {
  return XMLNode.xmlns(
    tag: 'encryption',
    xmlns: emeXmlns,
    attributes: <String, String>{
      'namespace': _explicitEncryptionTypeToString(type),
    },
  );
}

class EmeManager extends XmppManagerBase {
  EmeManager() : super(emeManager);
  @override
  Future<bool> isSupported() async => true;

  @override
  List<String> getDiscoFeatures() => [emeXmlns];

  @override
  List<StanzaHandler> getIncomingStanzaHandlers() => [
        StanzaHandler(
          tagName: 'encryption',
          tagXmlns: emeXmlns,
          callback: _onStanzaReceived,
          // Before the message handler
          priority: -99,
        ),
      ];

  Future<StanzaHandlerData> _onStanzaReceived(
    Stanza message,
    StanzaHandlerData state,
  ) async {
    final encryption = message.firstTag('encryption', xmlns: emeXmlns)!;

    return state.copyWith(
      encryptionType: _explicitEncryptionTypeFromString(
        encryption.attributes['namespace']! as String,
      ),
    );
  }
}
