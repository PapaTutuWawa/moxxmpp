# moxxmpp

moxxmpp is a XMPP library written purely in Dart for usage in Moxxy.

## Packages
### [moxxmpp](./packages/moxxmpp)

This package contains the actual XMPP code that is platform-independent.

Documentation is available [here](https://docs.moxxy.org/moxxmpp/index.html).

### [moxxmpp_socket_tcp](./packages/moxxmpp_socket_tcp)

`moxxmpp_socket_tcp` contains the implementation of the `BaseSocketWrapper` class that
implements the RFC6120 connection algorithm and XEP-0368 direct TLS connections,
if a DNS implementation is given, and supports StartTLS.

### moxxmpp_color

Implementation of [XEP-0392](https://xmpp.org/extensions/xep-0392.html).

## Development

To begin, use [melos](https://github.com/invertase/melos) to bootstrap the project: `melos bootstrap`. Then, the example
can be run with `flutter run` on Linux or Android.

To run the example, make sure that Flutter is correctly set up and working. If you use
the development shell provided by the NixOS Flake, ensure that `ANDROID_HOME` and
`ANDROID_AVD_HOME` are pointing to the correct directories.

## Examples

This repository contains 2 types of examples:

- `example_flutter`: An example of using moxxmpp using Flutter
- `examples_dart`: A collection of pure Dart examples for showing different aspects of moxxmpp

For more information, see the respective README files.

## License

See `./LICENSE`.

## Support

If you like what I do and you want to support me, feel free to donate to me on Ko-Fi.

[<img src="https://codeberg.org/moxxy/moxxyv2/raw/branch/master/assets/repo/kofi.png" height="36" style="height: 36px; border: 0px;"></img>](https://ko-fi.com/papatutuwawa)
