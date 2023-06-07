import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/stringxml.dart';

/// A description of a stanza to send.
class StanzaDetails {
  const StanzaDetails(
    this.stanza, {
    this.addId = true,
    this.awaitable = true,
    this.encrypted = false,
    this.forceEncryption = false,
    this.bypassQueue = false,
    this.excludeFromStreamManagement = false,
  });

  /// The stanza to send.
  final Stanza stanza;

  /// Flag indicating whether a stanza id should be added before sending.
  final bool addId;

  /// Track the stanza to allow awaiting its response.
  final bool awaitable;

  final bool encrypted;

  final bool forceEncryption;

  /// Bypasses being put into the queue. Useful for sending stanzas that must go out
  /// now, where it's okay if it does not get sent.
  /// This should never have to be set to true.
  final bool bypassQueue;

  /// This makes the Stream Management implementation, when available, ignore the stanza,
  /// meaning that it gets counted but excluded from resending.
  /// This should never have to be set to true.
  final bool excludeFromStreamManagement;
}

/// A simple description of the <error /> element that may be inside a stanza
class StanzaError {
  StanzaError(this.type, this.error);
  String type;
  String error;

  /// Returns a StanzaError if [stanza] contains a <error /> element. If not, returns
  /// null.
  static StanzaError? fromStanza(Stanza stanza) {
    final error = stanza.firstTag('error');
    if (error == null) return null;

    final stanzaError = error.firstTagByXmlns(fullStanzaXmlns);
    if (stanzaError == null) return null;

    return StanzaError(
      error.attributes['type']! as String,
      stanzaError.tag,
    );
  }
}

class Stanza extends XMLNode {
  // ignore: use_super_parameters
  Stanza({
    this.to,
    this.from,
    this.type,
    this.id,
    List<XMLNode> children = const [],
    required String tag,
    Map<String, String> attributes = const {},
    String? xmlns,
  }) : super(
          tag: tag,
          attributes: <String, dynamic>{
            ...attributes,
            ...type != null
                ? <String, dynamic>{'type': type}
                : <String, dynamic>{},
            ...id != null ? <String, dynamic>{'id': id} : <String, dynamic>{},
            ...to != null ? <String, dynamic>{'to': to} : <String, dynamic>{},
            ...from != null
                ? <String, dynamic>{'from': from}
                : <String, dynamic>{},
            if (xmlns != null) 'xmlns': xmlns,
          },
          children: children,
        );

  factory Stanza.iq({
    String? to,
    String? from,
    String? type,
    String? id,
    List<XMLNode> children = const [],
    Map<String, String>? attributes = const {},
    String? xmlns,
  }) {
    return Stanza(
      tag: 'iq',
      from: from,
      to: to,
      id: id,
      type: type,
      attributes: <String, String>{...attributes!},
      children: children,
      xmlns: xmlns,
    );
  }

  factory Stanza.presence({
    String? to,
    String? from,
    String? type,
    String? id,
    List<XMLNode> children = const [],
    Map<String, String>? attributes = const {},
    String? xmlns,
  }) {
    return Stanza(
      tag: 'presence',
      from: from,
      to: to,
      id: id,
      type: type,
      attributes: <String, String>{...attributes!},
      children: children,
      xmlns: xmlns,
    );
  }
  factory Stanza.message({
    String? to,
    String? from,
    String? type,
    String? id,
    List<XMLNode> children = const [],
    Map<String, String>? attributes = const {},
    String? xmlns,
  }) {
    return Stanza(
      tag: 'message',
      from: from,
      to: to,
      id: id,
      type: type,
      attributes: <String, String>{...attributes!},
      children: children,
      xmlns: xmlns,
    );
  }

  factory Stanza.fromXMLNode(XMLNode node) {
    return Stanza(
      to: node.attributes['to'] as String?,
      from: node.attributes['from'] as String?,
      id: node.attributes['id'] as String?,
      tag: node.tag,
      type: node.attributes['type'] as String?,
      children: node.children,
      // TODO(Unknown): Remove to, from, id, and type
      // TODO(Unknown): Not sure if this is the correct way to approach this
      attributes:
          node.attributes.map<String, String>((String key, dynamic value) {
        return MapEntry(key, value.toString());
      }),
    );
  }

  String? to;
  String? from;
  String? type;
  String? id;

  Stanza copyWith({
    String? id,
    String? from,
    String? to,
    String? type,
    List<XMLNode>? children,
    String? xmlns,
  }) {
    return Stanza(
      tag: tag,
      to: to ?? this.to,
      from: from ?? this.from,
      id: id ?? this.id,
      type: type ?? this.type,
      children: children ?? this.children,
      attributes: {
        ...attributes.cast<String, String>(),
      },
      xmlns: xmlns ?? this.xmlns,
    );
  }
}

/// Build an <error /> element with a child <[condition] type="[type]" />. If [text]
/// is not null, then the condition element will contain a <text /> element with [text]
/// as the body.
XMLNode buildErrorElement(String type, String condition, {String? text}) {
  return XMLNode(
    tag: 'error',
    attributes: <String, dynamic>{'type': type},
    children: [
      XMLNode.xmlns(
        tag: condition,
        xmlns: fullStanzaXmlns,
        children: text != null
            ? [
                XMLNode.xmlns(
                  tag: 'text',
                  xmlns: fullStanzaXmlns,
                  text: text,
                )
              ]
            : [],
      ),
    ],
  );
}
