import 'package:meta/meta.dart';
import 'package:moxxmpp/src/managers/base.dart';
import 'package:moxxmpp/src/managers/data.dart';
import 'package:moxxmpp/src/managers/handlers.dart';
import 'package:moxxmpp/src/managers/namespaces.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/stanza.dart';

/// Data summarizing the XEP-0461 data.
class ReplyData {
  const ReplyData({
    required this.id,
    this.to,
    this.start,
    this.end,
  });

  /// The bare JID to whom the reply applies to
  final String? to;

  /// The stanza ID of the message that is replied to
  final String id;

  /// The start of the fallback body (inclusive)
  final int? start;

  /// The end of the fallback body (exclusive)
  final int? end;

  /// Applies the metadata to the received body [body] in order to remove the fallback.
  /// If either [ReplyData.start] or [ReplyData.end] are null, then body is returned as
  /// is.
  String removeFallback(String body) {
    if (start == null || end == null) return body;

    return body.replaceRange(start!, end, '');
  }
}

/// Internal class describing how to build a message with a quote fallback body.
@visibleForTesting
class QuoteData {
  const QuoteData(this.body, this.fallbackLength);

  /// Takes the body of the message we want to quote [quoteBody] and the content of
  /// the reply [body] and computes the fallback body and its length.
  factory QuoteData.fromBodies(String quoteBody, String body) {
    final fallback = quoteBody.split('\n').map((line) => '> $line\n').join();

    return QuoteData(
      '$fallback$body',
      fallback.length,
    );
  }

  /// The new body with fallback data at the beginning
  final String body;

  /// The length of the fallback data
  final int fallbackLength;
}

/// A manager implementing support for parsing XEP-0461 metadata. The
/// MessageRepliesManager itself does not modify the body of the message.
class MessageRepliesManager extends XmppManagerBase {
  MessageRepliesManager() : super(messageRepliesManager);

  @override
  List<String> getDiscoFeatures() => [
        replyXmlns,
      ];

  @override
  List<StanzaHandler> getIncomingStanzaHandlers() => [
        StanzaHandler(
          stanzaTag: 'message',
          tagName: 'reply',
          tagXmlns: replyXmlns,
          callback: _onMessage,
          // Before the message handler
          priority: -99,
        )
      ];

  @override
  Future<bool> isSupported() async => true;

  Future<StanzaHandlerData> _onMessage(
    Stanza stanza,
    StanzaHandlerData state,
  ) async {
    final reply = stanza.firstTag('reply', xmlns: replyXmlns)!;
    final id = reply.attributes['id']! as String;
    final to = reply.attributes['to'] as String?;
    int? start;
    int? end;

    // TODO(Unknown): Maybe extend firstTag to also look for attributes
    final fallback = stanza.firstTag('fallback', xmlns: fallbackXmlns);
    if (fallback != null) {
      final body = fallback.firstTag('body')!;
      start = int.parse(body.attributes['start']! as String);
      end = int.parse(body.attributes['end']! as String);
    }

    return state
      ..extensions.set(
        ReplyData(
          id: id,
          to: to,
          start: start,
          end: end,
        ),
      );
  }
}
