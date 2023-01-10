# moxxmpp_socket

A socket for moxxmpp that implements the connection algorithm as specified by
[RFC6210](https://xmpp.org/rfcs/rfc6120.html) and [XEP-0368](https://xmpp.org/extensions/xep-0368.html),
while also supporting StartTLS and direct TLS.

In order to make this package independent of Flutter, I removed DNS SRV resolution from
the package. The `TCPSocketWrapper` contains a method called `srvQuery` that can be
overridden by the user. It takes the domain to query and a DNSSEC flag and is expected
to return the list of SRV records, encoded by `MoxSrvRecord` objects. To perform the
resolution, one can use any DNS library. A Flutter plugin implementing SRV resolution
is, for example, [moxdns](https://codeberg.org/moxxy/moxdns).

## Usage

Include the following as a dependency in your pubspec file:

```
 moxxmpp_socket_tcp:
    hosted: https://git.polynom.me/api/packages/Moxxy/pub
    version: 0.1.2+9
```

## License

See `./LICENSE`.

## Support

If you like what I do and you want to support me, feel free to donate to me on Ko-Fi.

[<img src="https://codeberg.org/moxxy/moxxyv2/raw/branch/master/assets/repo/kofi.png" height="36" style="height: 36px; border: 0px;"></img>](https://ko-fi.com/papatutuwawa)
