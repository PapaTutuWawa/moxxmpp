import 'package:moxxmpp/src/stringxml.dart';

/// A data class describing the user agent. See https://xmpp.org/extensions/xep-0388.html#initiation.
class UserAgent {
  const UserAgent({
    this.id,
    this.software,
    this.device,
  });

  /// The identifier of the software/device combo connecting. SHOULD be a UUIDv4.
  final String? id;

  /// The software's name that's connecting at the moment.
  final String? software;

  /// The name of the device.
  final String? device;

  XMLNode toXml() {
    assert(
      id != null || software != null || device != null,
      'A completely empty user agent makes no sense',
    );
    return XMLNode(
      tag: 'user-agent',
      attributes: {
        if (id != null) 'id': id,
      },
      children: [
        if (software != null)
          XMLNode(
            tag: 'software',
            text: software,
          ),
        if (device != null)
          XMLNode(
            tag: 'device',
            text: device,
          ),
      ],
    );
  }
}
