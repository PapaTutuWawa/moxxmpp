import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
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
  late Pointer<libmbedsock.mbedsock> _sock;
  late Pointer<Uint8> _readBuf;
  late Pointer<Uint8> _writeBuf;

  MbedSock(MbedSockCtx ctx) {
    _sock = lib.mbedsock_new_ex(ctx.ctx);
    _readBuf = malloc.call<Uint8>(2048);
    _writeBuf = malloc.call<Uint8>(2048);
  }

  bool connect(String host, int port) {
    final nativeHost = host.toNativeUtf8();
    final nativePort = port.toString().toNativeUtf8();
    final ret = lib.mbedsock_connect(_sock, nativeHost.cast(), nativePort.cast());

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
      _sock,
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
    return lib.mbedsock_is_secure(_sock) == 1;
  }
  
  int write(String data) {
    final rawData = utf8.encode(data);

    // TODO: Buffer the write
    assert(rawData.length <= 2048);

    _writeBuf.asTypedList(2048).setAll(0, rawData);
    return lib.mbedsock_write(
      _sock,
      _writeBuf,
      rawData.length,
    );
  }

  Uint8List? read() {
    final result = lib.mbedsock_read(
      _sock,
      _readBuf,
      2048,
    );

    // TODO: Buffer the read
    assert(result <= 2048);
    
    if (result < 0) {
      print('Socket error');
      return null;
    } else if (result == 0) {
      print('Socket closed');
      return null;
    } else {
      return _readBuf.asTypedList(result) as Uint8List;
    }
  }
  
  void free() {
    lib.mbedsock_free_ex(_sock);
    malloc.free(_readBuf);
    malloc.free(_writeBuf);
  }
}
