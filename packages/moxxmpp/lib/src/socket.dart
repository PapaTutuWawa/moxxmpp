// NOTE: https://www.iana.org/assignments/tls-extensiontype-values/tls-extensiontype-values.xhtml#alpn-protocol-ids
const xmppClientALPNId = 'xmpp-client';

abstract class XmppSocketEvent {}

/// Triggered by the socket when an error occurs.
class XmppSocketErrorEvent extends XmppSocketEvent {

  XmppSocketErrorEvent(this.error);
  final Object error;
}

/// Triggered when the socket is closed
class XmppSocketClosureEvent extends XmppSocketEvent {}

/// This class is the base for a socket that XmppConnection can use.
abstract class BaseSocketWrapper {
  /// This must return the unbuffered string stream that the socket receives.
  Stream<String> getDataStream();

  /// This must return events generated by the socket.
  /// See sub-classes of [XmppSocketEvent] for possible events.
  Stream<XmppSocketEvent> getEventStream();
  
  /// This must close the socket but not the streams so that the same class can be
  /// reused by calling [this.connect] again.
  void close();

  /// Write [data] into the socket. If [redact] is not null, then [redact] will be
  /// logged instead of [data].
  void write(String data, { String? redact });
  
  /// This must connect to [host]:[port] and initialize the streams accordingly.
  /// [domain] is the domain that TLS should be validated against, in case the Socket
  /// provides TLS encryption. Returns true if the connection has been successfully
  /// established. Returns false if the connection has failed.
  Future<bool> connect(String domain, { String? host, int? port });

  /// Returns true if the socket is secured, e.g. using TLS.
  bool isSecure();

  /// Upgrades the connection into a secure version, e.g. by performing a TLS upgrade.
  /// May do nothing if the connection is always secure.
  /// Returns true if the socket has been successfully upgraded. False otherwise.
  Future<bool> secure(String domain);

  /// Returns true if whitespace pings are allowed. False if not.
  bool whitespacePingAllowed();

  /// Returns true if it manages its own keepalive pings, like websockets. False if not.
  bool managesKeepalives();

  /// Brings the socket into a state that allows it to close without triggering any errors
  /// to the XmppConnection.
  void prepareDisconnect() {}
}