import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxmpp_socket_tcp/src/events.dart';
import 'package:moxxmpp_socket_tcp/src/record.dart';
import 'package:moxxmpp_socket_tcp/src/rfc_2782.dart';

/// TCP socket implementation for XmppConnection
class TCPSocketWrapper extends BaseSocketWrapper {
  TCPSocketWrapper(this._logData);

  /// The underlying Socket/SecureSocket instance.
  Socket? _socket;

  /// Indicates that we expect a socket closure.
  bool _expectSocketClosure = false;

  /// The stream of incoming data from the socket.
  final StreamController<String> _dataStream = StreamController.broadcast();

  /// The stream of outgoing (TCPSocketWrapper -> XmppConnection) events.
  final StreamController<XmppSocketEvent> _eventStream =
      StreamController.broadcast();

  /// A subscription on the socket's data stream.
  StreamSubscription<dynamic>? _socketSubscription;

  /// Logger
  final Logger _log = Logger('TCPSocketWrapper');

  /// Flag to indicate if incoming and outgoing data should get logged.
  final bool _logData;

  /// Indiacted whether the connection is secure.
  bool _secure = false;

  @override
  bool isSecure() => _secure;

  @override
  bool whitespacePingAllowed() => true;

  @override
  bool managesKeepalives() => false;

  /// Allow the socket to be destroyed by cancelling internal subscriptions.
  void destroy() {
    _socketSubscription?.cancel();
  }

  /// Called on connect to perform a SRV query against [domain]. If [dnssec] is true,
  /// then DNSSEC validation should be performed.
  ///
  /// Returns a list of SRV records. If none are available or an error occured, an empty
  /// list is returned.
  @visibleForOverriding
  Future<List<MoxSrvRecord>> srvQuery(String domain, bool dnssec) async {
    return <MoxSrvRecord>[];
  }

  /// Called when we encounter a certificate we cannot verify. [certificate] refers to the certificate
  /// in question, while [domain] refers to the domain we try to validate the certificate against.
  ///
  /// Return true if the certificate should be accepted. Return false if it should be rejected.
  @visibleForOverriding
  bool onBadCertificate(dynamic certificate, String domain) {
    return false;
  }

  Future<bool> _xep368Connect(String domain) async {
    // TODO(Unknown): Maybe do DNSSEC one day
    final results = await srvQuery('_xmpps-client._tcp.$domain', false);
    if (results.isEmpty) {
      return false;
    }

    var failedDueToTLS = false;
    results.sort(srvRecordSortComparator);
    for (final srv in results) {
      try {
        _log.finest(
          'Attempting secure connection to ${srv.target}:${srv.port}...',
        );

        // Workaround: We cannot set the SNI directly when using SecureSocket.connect.
        // instead, we connect using a regular socket and then secure it. This allows
        // us to set the SNI to whatever we want.
        final sock = await Socket.connect(
          srv.target,
          srv.port,
          timeout: const Duration(seconds: 5),
        );
        _socket = await SecureSocket.secure(
          sock,
          host: domain,
          supportedProtocols: const [xmppClientALPNId],
          onBadCertificate: (cert) => onBadCertificate(cert, domain),
        );

        _secure = true;
        _log.finest('Success!');
        return true;
      } on Exception catch (e) {
        _log.finest('Failure! $e');

        if (e is HandshakeException) {
          failedDueToTLS = true;
        }
      }
    }

    if (failedDueToTLS) {
      _eventStream.add(XmppSocketTLSFailedEvent());
    }

    return false;
  }

  Future<bool> _rfc6120Connect(String domain) async {
    // TODO(Unknown): Maybe do DNSSEC one day
    final results = await srvQuery('_xmpp-client._tcp.$domain', false);
    results.sort(srvRecordSortComparator);

    for (final srv in results) {
      try {
        _log.finest('Attempting connection to ${srv.target}:${srv.port}...');
        _socket = await Socket.connect(
          srv.target,
          srv.port,
          timeout: const Duration(seconds: 5),
        );

        _log.finest('Success!');
        return true;
      } on Exception catch (e) {
        _log.finest('Failure! $e');
        continue;
      }
    }

    return _rfc6120FallbackConnect(domain);
  }

  /// Connect to [host] with port [port] and returns true if the connection
  /// was successfully established. Does not setup the streams as this has
  /// to be done by the caller.
  Future<bool> _hostPortConnect(String host, int port) async {
    try {
      _log.finest('Attempting fallback connection to $host:$port...');
      _socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 5),
      );
      _log.finest('Success!');
      return true;
    } on Exception catch (e) {
      _log.finest('Failure! $e');
      return false;
    }
  }

  /// Connect to [domain] using the default C2S port of XMPP. Returns
  /// true if the connection was successful. Does not setup the streams
  /// as [_rfc6120FallbackConnect] should only be called from
  /// [_rfc6120Connect], which already sets the streams up on a successful
  /// connection.
  Future<bool> _rfc6120FallbackConnect(String domain) async {
    return _hostPortConnect(domain, 5222);
  }

  @override
  Future<bool> secure(String domain) async {
    if (_secure) {
      _log.warning('Connection is already marked as secure. Doing nothing');
      return true;
    }

    if (_socket == null) {
      _log.severe('Failed to secure socket since _socket is null');
      return false;
    }

    try {
      // The socket is closed during the entire process
      _expectSocketClosure = true;

      _socket = await SecureSocket.secure(
        _socket!,
        supportedProtocols: const [xmppClientALPNId],
        onBadCertificate: (cert) => onBadCertificate(cert, domain),
      );

      _secure = true;
      _setupStreams();
      return true;
    } on Exception catch (e) {
      _log.severe('Failed to secure socket: $e');

      if (e is HandshakeException) {
        _eventStream.add(XmppSocketTLSFailedEvent());
      }

      return false;
    }
  }

  void _setupStreams() {
    if (_socket == null) {
      _log.severe('Failed to setup streams as _socket is null');
      return;
    }

    _socketSubscription = _socket!.listen(
      (List<int> event) {
        final data = utf8.decode(event);
        if (_logData) {
          _log.finest('<== $data');
        }
        _dataStream.add(data);
      },
      onError: (Object error) {
        _log.severe(error.toString());
        _eventStream.add(XmppSocketErrorEvent(error));
      },
    );
    // ignore: implicit_dynamic_parameter
    _socket!.done.then((_) {
      _eventStream.add(XmppSocketClosureEvent(_expectSocketClosure));
      _expectSocketClosure = false;
    });
  }

  @override
  Future<bool> connect(String domain, {String? host, int? port}) async {
    _expectSocketClosure = false;
    _secure = false;

    // Connection order:
    // 1. host:port, if given
    // 2. XEP-0368
    // 3. RFC 6120
    // 4. RFC 6120 fallback

    if (host != null && port != null) {
      _log.finest('Specific host and port given');
      if (await _hostPortConnect(host, port)) {
        _setupStreams();
        return true;
      }
    }

    if (await _xep368Connect(domain)) {
      _setupStreams();
      return true;
    }

    // NOTE: _rfc6120Connect already attempts the fallback
    if (await _rfc6120Connect(domain)) {
      _setupStreams();
      return true;
    }

    return false;
  }

  @override
  void close() {
    _expectSocketClosure = true;

    if (_socketSubscription != null) {
      _log.finest('Closing socket subscription');
      _socketSubscription!.cancel();
    }

    if (_socket == null) {
      _log.warning('Failed to close socket since _socket is null');
      return;
    }

    try {
      _socket!.close();
    } catch (e) {
      _log.warning('Closing socket threw exception: $e');
    }
  }

  @override
  Stream<String> getDataStream() => _dataStream.stream.asBroadcastStream();

  @override
  Stream<XmppSocketEvent> getEventStream() =>
      _eventStream.stream.asBroadcastStream();

  @override
  void write(Object? data, {String? redact}) {
    if (_socket == null) {
      _log.severe('Failed to write to socket as _socket is null');
      return;
    }

    if (data != null && data is String && _logData) {
      if (redact != null) {
        _log.finest('**> $redact');
      } else {
        _log.finest('==> $data');
      }
    }

    try {
      _socket!.write(data);
    } on Exception catch (e) {
      _log.severe(e);
      _eventStream.add(XmppSocketErrorEvent(e));
    }
  }

  @override
  void prepareDisconnect() {}
}
