import 'dart:io';
import 'package:moxxmpp_socket/src/ssl.dart';

void main(List<String> argv) async {
  if (argv.length != 2) {
    print('Usage: test_wrong_host.dart server-addr host-name');
    exit(1);
  }

  final server = argv[0];
  final hostname = argv[1];
  final ctx = MbedSockCtx('/etc/ssl/certs/');
  final sock = MbedSock(ctx);

  print('Connecting...');
  final done = sock.connectSecure(
    server,
    '5223',
    alpn: 'xmpp-client',
    hostname: hostname,
  );

  print('Success? $done');
  print('Secure? ${sock.isSecure()}');

  sock.free();
  ctx.free();
  print('OKAY');
}
