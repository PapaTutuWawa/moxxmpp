import 'package:meta/meta.dart';

@immutable
class JID {

  const JID(this.local, this.domain, this.resource);

  factory JID.fromString(String jid) {
    // Algorithm taken from here: https://blog.samwhited.com/2021/02/xmpp-addresses/
    var localPart = '';
    var domainPart = '';
    var resourcePart = '';

    final slashParts = jid.split('/');
    if (slashParts.length == 1) {
      resourcePart = '';
    } else {
      resourcePart = slashParts.sublist(1).join('/');

      assert(resourcePart.isNotEmpty, 'Resource part cannot be there and empty');
    }

    final atParts = slashParts.first.split('@');
    if (atParts.length == 1) {
      localPart = '';
      domainPart = atParts.first;
    } else {
      localPart = atParts.first;
      domainPart = atParts.sublist(1).join('@');

      assert(localPart.isNotEmpty, 'Local part cannot be there and empty');
    }

    return JID(
      localPart,
      domainPart.endsWith('.') ?
        domainPart.substring(0, domainPart.length - 1) :
        domainPart,
      resourcePart,
    );
  }
  final String local;
  final String domain;
  final String resource;

  bool isBare() => resource.isEmpty;
  bool isFull() => resource.isNotEmpty;

  JID toBare() => JID(local, domain, '');
  JID withResource(String resource) => JID(local, domain, resource);
  
  @override
  String toString() {
    var result = '';

    if (local.isNotEmpty) {
      result += '$local@$domain';
    } else {
      result += domain;
    }
    if (isFull()) {
      result += '/$resource';
    }

    return result;
  }

  @override
  bool operator ==(Object other) {
    if (other is JID) {
      return other.local == local && other.domain == domain && other.resource == resource;
    }

    return false;
  }

  @override
  int get hashCode => local.hashCode ^ domain.hashCode ^ resource.hashCode;
}
