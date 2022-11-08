# moxxmpp

moxxmpp is a XMPP library written purely in Dart for usage in Moxxy.

## Packages
### moxxmpp

This package contains the actual XMPP code that is platform-independent.

### moxxmpp_socket

`moxxmpp_socket` contains the implementation of the `BaseSocketWrapper` class that
implements the RFC6120 connection algorithm and XEP-0368 direct TLS connections,
if a DNS implementation is given, and supports StartTLS.

## License

See `./LICENSE`.
