import 'package:moxxmpp/src/events.dart';
import 'package:moxxmpp/src/jid.dart';
import 'package:moxxmpp/src/managers/base.dart';
import 'package:moxxmpp/src/managers/data.dart';
import 'package:moxxmpp/src/managers/handlers.dart';
import 'package:moxxmpp/src/managers/namespaces.dart';
import 'package:moxxmpp/src/message.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/stanza.dart';
import 'package:moxxmpp/src/stringxml.dart';
import 'package:moxxmpp/src/util/typed_map.dart';

class MessageDeliveryReceiptData implements StanzaHandlerExtension {
  const MessageDeliveryReceiptData(this.receiptRequested);

  /// Indicates whether a delivery receipt is requested or not.
  final bool receiptRequested;

  XMLNode toXML() {
    assert(
      receiptRequested,
      'This method makes little sense with receiptRequested == false',
    );
    return XMLNode.xmlns(
      tag: 'request',
      xmlns: deliveryXmlns,
    );
  }
}

class MessageDeliveryReceivedData implements StanzaHandlerExtension {
  const MessageDeliveryReceivedData(this.id);

  /// The stanza id of the message we received.
  final String id;

  XMLNode toXML() {
    return XMLNode.xmlns(
      tag: 'received',
      xmlns: deliveryXmlns,
      attributes: {'id': id},
    );
  }
}

class MessageDeliveryReceiptManager extends XmppManagerBase {
  MessageDeliveryReceiptManager() : super(messageDeliveryReceiptManager);

  @override
  List<String> getDiscoFeatures() => [deliveryXmlns];

  @override
  List<StanzaHandler> getIncomingStanzaHandlers() => [
        StanzaHandler(
          stanzaTag: 'message',
          tagName: 'received',
          tagXmlns: deliveryXmlns,
          callback: _onDeliveryReceiptReceived,
          // Before the message handler
          priority: -99,
        ),
        StanzaHandler(
          stanzaTag: 'message',
          tagName: 'request',
          tagXmlns: deliveryXmlns,
          callback: _onDeliveryRequestReceived,
          // Before the message handler
          priority: -99,
        )
      ];

  @override
  Future<bool> isSupported() async => true;

  Future<StanzaHandlerData> _onDeliveryRequestReceived(
    Stanza message,
    StanzaHandlerData state,
  ) async {
    return state..extensions.set(const MessageDeliveryReceiptData(true));
  }

  Future<StanzaHandlerData> _onDeliveryReceiptReceived(
    Stanza message,
    StanzaHandlerData state,
  ) async {
    final received = message.firstTag('received', xmlns: deliveryXmlns)!;
    // for (final item in message.children) {
    //   if (!['origin-id', 'stanza-id', 'delay', 'store', 'received']
    //       .contains(item.tag)) {
    //     logger.info(
    //       "Won't handle stanza as delivery receipt because we found an '${item.tag}' element",
    //     );

    //     return state.copyWith(done: true);
    //   }
    // }

    getAttributes().sendEvent(
      DeliveryReceiptReceivedEvent(
        from: JID.fromString(message.attributes['from']! as String),
        id: received.attributes['id']! as String,
      ),
    );
    return state..done = true;
  }

  List<XMLNode> _messageSendingCallback(
    TypedMap<StanzaHandlerExtension> extensions,
  ) {
    final data = extensions.get<MessageDeliveryReceivedData>();
    return data != null
        ? [
            data.toXML(),
          ]
        : [];
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
