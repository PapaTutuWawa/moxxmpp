# moxxmpp

moxxmpp is a XMPP library written purely in Dart for usage in Moxxy.

## Packages
### moxxmpp

This package contains the actual XMPP code that is platform-independent.

### moxxmpp_socket

`moxxmpp_socket` contains the implementation of the `BaseSocketWrapper` class that
allows the user to resolve SRV records and thus support XEP-0368. Due to how DNS
resolution is implemented, Flutter is required.

### mbedsock

This package contains a C library that wraps [mbedTLS](https://github.com/Mbed-TLS/mbedtls)
into a form that makes it easily digestable in Dart for use in `moxxmpp_socket`.

This is so that we can work around various issues with Dart's `SecureSocket`, though
mostly just the issue with setting a SNI value different from the connecting host name.

## License

See `./LICENSE`.
