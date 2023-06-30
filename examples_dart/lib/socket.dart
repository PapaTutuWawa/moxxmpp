import 'package:moxxmpp_socket_tcp/moxxmpp_socket_tcp.dart';

/// A simple socket for examples that allows injection of SRV records (since
/// we cannot use moxdns here).
class ExampleTCPSocketWrapper extends TCPSocketWrapper {
  ExampleTCPSocketWrapper(this.srvRecord);

  /// A potential SRV record to inject for testing.
  final MoxSrvRecord? srvRecord;

  @override
  bool onBadCertificate(dynamic certificate, String domain) {
    return true;
  }

  @override
  Future<List<MoxSrvRecord>> srvQuery(String domain, bool dnssec) async {
    return [
      if (srvRecord != null) srvRecord!,
    ];
  }
}
