import 'package:moxlib/moxlib.dart';
import 'package:moxxmpp/src/managers/base.dart';
import 'package:moxxmpp/src/managers/data.dart';
import 'package:moxxmpp/src/managers/handlers.dart';
import 'package:moxxmpp/src/managers/namespaces.dart';
import 'package:moxxmpp/src/message.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/stanza.dart';
import 'package:moxxmpp/src/stringxml.dart';
import 'package:moxxmpp/src/util/typed_map.dart';
import 'package:moxxmpp/src/xeps/xep_0066.dart';
import 'package:moxxmpp/src/xeps/xep_0446.dart';
import 'package:moxxmpp/src/xeps/xep_0448.dart';

/// The base class for sources for StatelessFileSharing
// ignore: one_member_abstracts
abstract class StatelessFileSharingSource {
  /// Turn the source into an XML element.
  XMLNode toXml();
}

/// Implementation for url-data source elements.
class StatelessFileSharingUrlSource extends StatelessFileSharingSource {
  StatelessFileSharingUrlSource(this.url);

  factory StatelessFileSharingUrlSource.fromXml(XMLNode element) {
    assert(
      element.attributes['xmlns'] == urlDataXmlns,
      'Element has the wrong xmlns',
    );

    return StatelessFileSharingUrlSource(
      element.attributes['target']! as String,
    );
  }

  final String url;

  @override
  XMLNode toXml() {
    return XMLNode.xmlns(
      tag: 'url-data',
      xmlns: urlDataXmlns,
      attributes: <String, String>{
        'target': url,
      },
    );
  }
}

/// Finds the <sources/> element in [node] and returns the list of
/// StatelessFileSharingSources contained with it.
/// If [checkXmlns] is true, then the sources element must also have an xmlns attribute
/// of "urn:xmpp:sfs:0".
List<StatelessFileSharingSource> processStatelessFileSharingSources(
  XMLNode node, {
  bool checkXmlns = true,
}) {
  final sources = List<StatelessFileSharingSource>.empty(growable: true);

  final sourcesElement = node.firstTag(
    'sources',
    xmlns: checkXmlns ? sfsXmlns : null,
  )!;
  for (final source in sourcesElement.children) {
    if (source.attributes['xmlns'] == urlDataXmlns) {
      sources.add(StatelessFileSharingUrlSource.fromXml(source));
    } else if (source.attributes['xmlns'] == sfsEncryptionXmlns) {
      sources.add(StatelessFileSharingEncryptedSource.fromXml(source));
    }
  }

  return sources;
}

class StatelessFileSharingData {
  const StatelessFileSharingData(
    this.metadata,
    this.sources, {
    this.includeOOBFallback = false,
  });

  /// Parse [node] as a StatelessFileSharingData element.
  factory StatelessFileSharingData.fromXML(XMLNode node) {
    assert(node.attributes['xmlns'] == sfsXmlns, 'Invalid element xmlns');
    assert(node.tag == 'file-sharing', 'Invalid element name');

    return StatelessFileSharingData(
      FileMetadataData.fromXML(node.firstTag('file')!),
      // TODO(PapaTutuWawa): This is a work around for Stickers where the source element has a XMLNS but SFS does not have one.
      processStatelessFileSharingSources(node, checkXmlns: false),
    );
  }

  final FileMetadataData metadata;
  final List<StatelessFileSharingSource> sources;

  /// Flag indicating whether an OOB fallback should be set. The value is only
  /// relevant in the context of the messageSendingCallback.
  final bool includeOOBFallback;

  XMLNode toXML() {
    return XMLNode.xmlns(
      tag: 'file-sharing',
      xmlns: sfsXmlns,
      children: [
        metadata.toXML(),
        XMLNode(
          tag: 'sources',
          children: sources.map((source) => source.toXml()).toList(),
        ),
      ],
    );
  }

  StatelessFileSharingUrlSource? getFirstUrlSource() {
    return firstWhereOrNull(
      sources,
      (StatelessFileSharingSource source) =>
          source is StatelessFileSharingUrlSource,
    ) as StatelessFileSharingUrlSource?;
  }
}

class SFSManager extends XmppManagerBase {
  SFSManager() : super(sfsManager);

  @override
  List<StanzaHandler> getIncomingStanzaHandlers() => [
        StanzaHandler(
          stanzaTag: 'message',
          tagName: 'file-sharing',
          tagXmlns: sfsXmlns,
          callback: _onMessage,
          // Before the message handler
          priority: -98,
        )
      ];

  @override
  Future<bool> isSupported() async => true;

  List<XMLNode> _messageSendingCallback(TypedMap extensions) {
    final data = extensions.get<StatelessFileSharingData>();
    if (data == null) {
      return [];
    }

    // TODO(Unknown): Consider all sources?
    final source = data.sources.first;
    OOBData? oob;
    if (source is StatelessFileSharingUrlSource && data.includeOOBFallback) {
      // SFS recommends OOB as a fallback
      oob = OOBData(source.url, null);
    }

    return [
      data.toXML(),
      if (oob != null) oob.toXML(),
    ];
  }

  Future<StanzaHandlerData> _onMessage(
    Stanza message,
    StanzaHandlerData state,
  ) async {
    final sfs = message.firstTag('file-sharing', xmlns: sfsXmlns)!;

    return state
      ..extensions.set(
        StatelessFileSharingData.fromXML(sfs),
      );
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
