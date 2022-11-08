import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:moxxmpp_socket/src/ssl.dart';

void main(List<String> argv) async {
  if (argv.length < 2) {
    print('Usage: test_wrong_host.dart server-addr host-name');
    exit(1);
  }

  final server = argv[0];
  final hostname = argv[1];
  final port = argv.length == 3 ? argv[2] : '5223';

  final ctx = MbedSockCtx('/etc/ssl/certs/');
  final sock = MbedSock(ctx);

  print('Connecting to $server:$port while indicating $hostname...');
  final done = sock.connectSecure(
    server,
    port,
    alpn: 'xmpp-client',
    hostname: hostname,
  );

  print('Success? $done');
  print('Secure? ${sock.isSecure()}');

  final write = sock.write(
    "<?xml version='1.0'?><stream:stream to='$hostname' version='1.0' xml:lang='en' xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'>"
  );
  print('Write: $write');

  Uint8List? read = Uint8List(0);
  do {
    read = sock.read();
    if (read != null) {
      final str = utf8.decode(read);
      print('Read: $str');
    } else {
      print('Read: Null');
    }
  } while (read != null);
  
  sock.free();
  ctx.free();
  print('OKAY');
}
