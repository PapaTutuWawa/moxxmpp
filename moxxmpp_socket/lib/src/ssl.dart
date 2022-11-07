import 'dart:io';
import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as path;
import 'package:moxxmpp_socket/src/generated/ffi.dart' as libmbedsock;

//final libPath = path.join(Directory.current.path, 'libmbedsock.so');
final lib = libmbedsock.NativeLibrary(DynamicLibrary.open('libmbedsock.so'));

class MbedSockCtx {
  late Pointer<libmbedsock.mbedsock_ctx> _ctxPtr;

  MbedSockCtx(String caPath) {
    final caPathNative = caPath.toNativeUtf8();
    _ctxPtr = lib.mbedsock_ctx_new_ex(caPathNative.cast());
    malloc.free(caPathNative);
  }

  void free() {
    lib.mbedsock_ctx_free_ex(_ctxPtr);
  }

  Pointer<libmbedsock.mbedsock_ctx> get ctx => _ctxPtr;
}

class MbedSock {
  late Pointer<libmbedsock.mbedsock> sock;

  MbedSock(MbedSockCtx ctx) {
    sock = lib.mbedsock_new_ex(ctx.ctx);
  }

  bool connect(String host, int port) {
    final nativeHost = host.toNativeUtf8();
    final nativePort = port.toString().toNativeUtf8();
    final ret = lib.mbedsock_connect(sock, nativeHost.cast(), nativePort.cast());

    malloc
      ..free(nativeHost)
      ..free(nativePort);

    return ret == 0;
  }

  bool connectSecure(String host, String port, {String? alpn, String? hostname}) {
    final nativeHost = host.toNativeUtf8();
    final nativePort = port.toNativeUtf8();
    final nativeAlpn = alpn != null ? alpn.toNativeUtf8() : nullptr;
    final nativeHostname = hostname != null ? hostname.toNativeUtf8() : nullptr;

    final ret = lib.mbedsock_connect_secure(
      sock,
      nativeHost.cast(),
      nativePort.cast(),
      nativeAlpn.cast(),
      nativeHostname.cast(),
    );

    malloc
      ..free(nativeHost)
      ..free(nativePort);

    if (alpn != null) {
      malloc.free(nativeAlpn);
    }
    if (hostname != null) {
      malloc.free(nativeHostname);
    }

    print(ret);
    return ret == 0;
  }

  bool isSecure() {
    return lib.mbedsock_is_secure(sock) == 1;
  }

  void write(String data) {
    //lib.mbedsock_write(sock, data, data.length);
  }
  
  void free() {
    lib.mbedsock_free_ex(sock);
  }
}
