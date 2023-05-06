import 'package:moxlib/moxlib.dart';
import 'package:moxxmpp/src/managers/data.dart';
import 'package:moxxmpp/src/stanza.dart';
import 'package:moxxmpp/src/stringxml.dart';

/// A Handler is responsible for matching any kind of toplevel item in the XML stream
/// (stanzas and Nonzas). For that, its [matches] method is called. What happens
/// next depends on the subclass.
// ignore: one_member_abstracts
abstract class Handler {
  /// Returns true if the node matches the description provided by this [Handler].
  bool matches(XMLNode node);
}

/// A Handler that specialises in matching Nonzas (and stanzas).
class NonzaHandler extends Handler {
  NonzaHandler({
    required this.callback,
    this.nonzaTag,
    this.nonzaXmlns,
  });

  /// The function to call when a nonza matches the description.
  final Future<bool> Function(XMLNode) callback;

  /// The expected tag of a matching nonza.
  final String? nonzaTag;

  // The expected xmlns attribute of a matching nonza.
  final String? nonzaXmlns;

  @override
  bool matches(XMLNode node) {
    var matches = true;
    if (nonzaTag == null && nonzaXmlns == null) {
      return true;
    } else {
      if (nonzaXmlns != null) {
        matches &= node.attributes['xmlns'] == nonzaXmlns;
      }
      if (nonzaTag != null) {
        matches &= node.tag == nonzaTag;
      }
    }

    return matches;
  }
}

/// A Handler that only matches stanzas.
class StanzaHandler extends Handler {
  StanzaHandler({
    required this.callback,
    this.tagXmlns,
    this.tagName,
    this.priority = 0,
    this.stanzaTag,
  });
  
  /// If specified, then the stanza must contain a direct child with a tag equal to
  /// [tagName].
  final String? tagName;

  /// If specified, then the stanza must contain a direct child with a xmlns attribute
  /// equal to [tagXmlns]. If [tagName] is also non-null, then the element must also
  /// have a tag equal to [tagName].
  final String? tagXmlns;

  /// If specified, the matching stanza must have a tag equal to [stanzaTag].
  final String? stanzaTag;

  /// The priority after which [StanzaHandler]s are sorted.
  final int priority;

  /// The function to call when a stanza matches the description.
  final Future<StanzaHandlerData> Function(Stanza, StanzaHandlerData) callback;

  @override
  bool matches(XMLNode node) {
    var matches = ['iq', 'message', 'presence'].contains(node.tag);
    if (stanzaTag != null) {
      matches &= node.tag == stanzaTag;
    }
    // if (xmlns != null) {
    //   matches &= node.xmlns == xmlns;
    //   if (flag != null)
    //     print('${node.xmlns} == $xmlns');
    // }

    if (tagName != null) {
      final firstTag = node.firstTag(tagName!, xmlns: tagXmlns);
      matches &= firstTag != null;

      if (tagXmlns != null) {
        matches &= firstTag?.xmlns == tagXmlns;
      }
    } else if (tagXmlns != null) {
      matches &= listContains(
        node.children,
        (XMLNode node_) => node_.attributes['xmlns'] == tagXmlns,
      );
    }

    return matches;
  }
}

int stanzaHandlerSortComparator(StanzaHandler a, StanzaHandler b) =>
    b.priority.compareTo(a.priority);
