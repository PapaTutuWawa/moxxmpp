import 'package:moxxmpp/src/managers/base.dart';
import 'package:moxxmpp/src/managers/data.dart';
import 'package:moxxmpp/src/managers/handlers.dart';
import 'package:moxxmpp/src/managers/namespaces.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/stanza.dart';
import 'package:moxxmpp/src/stringxml.dart';

enum ExplicitEncryptionType implements StanzaHandlerExtension {
  otr,
  legacyOpenPGP,
  openPGP,
  omemo,
  omemo1,
  omemo2,
  unknown;

  factory ExplicitEncryptionType.fromNamespace(String namespace) {
    switch (namespace) {
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

  String toNamespace() {
    switch (this) {
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

  /// Create an <encryption /> element with an xmlns indicating what type of encryption was
  /// used.
  XMLNode toXML() {
    return XMLNode.xmlns(
      tag: 'encryption',
      xmlns: emeXmlns,
      attributes: <String, String>{
        'namespace': toNamespace(),
      },
    );
  }
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

    return state
      ..extensions.set(
        ExplicitEncryptionType.fromNamespace(
          encryption.attributes['namespace']! as String,
        ),
      );
  }
}
