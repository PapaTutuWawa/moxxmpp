import 'package:meta/meta.dart';

/// Represents a Jabber ID in parsed form.
@immutable
class JID {
  const JID(this.local, this.domain, this.resource);

  /// Parses the string [jid] into a JID instance.
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

  /// Returns true if the JID is bare.
  bool isBare() => resource.isEmpty;

  /// Returns true if the JID is full.
  bool isFull() => resource.isNotEmpty;

  /// Converts the JID into a bare JID.
  JID toBare() => JID(local, domain, '');

  /// Converts the JID into one with a resource part of [resource].
  JID withResource(String resource) => JID(local, domain, resource);

  /// Compares the JID with [other]. This function assumes that JID and [other]
  /// are bare, i.e. only the domain- and localparts are compared. If [ensureBare]
  /// is optionally set to true, then [other] MUST be bare. Otherwise, false is returned.
  bool bareCompare(JID other, { bool ensureBare = false }) {
    if (ensureBare && !other.isBare()) return false;

    return local == other.local && domain == other.domain;
  }
  
  /// Converts to JID instance into its string representation of
  /// localpart@domainpart/resource.
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
