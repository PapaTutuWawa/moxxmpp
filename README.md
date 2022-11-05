# moxxmpp

moxxmpp is a XMPP library written purely in Dart for usage in Moxxy.

## Packages
### moxxmpp

This package contains the actual XMPP code that is platform-independent.

### moxxmpp_socket

`moxxmpp_socket` contains the implementation of the `BaseSocketWrapper` class that
allows the user to resolve SRV records and thus support XEP-0368. Due to how DNS
resolution is implemented, Flutter is required.

## License

See `./LICENSE`.
