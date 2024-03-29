import 'package:moxxmpp/src/stanza.dart';
import 'package:moxxmpp/src/util/typed_map.dart';

abstract class StanzaHandlerExtension {}

class StanzaHandlerData {
  StanzaHandlerData(
    this.done,
    this.cancel,
    this.stanza,
    this.extensions, {
    this.cancelReason,
    this.encryptionError,
    this.encrypted = false,
    this.forceEncryption = false,
    this.shouldEncrypt = true,
    this.skip = false,
  });

  /// Indicates to the runner that processing is now done. This means that all
  /// pre-processing is done and no other handlers should be consulted.
  bool done;

  /// Only useful in combination with [done] = true: When [skip] is set to true and
  /// this [StanzaHandlerData] object is returned from a IncomingPreStanzaHandler, then
  /// moxxmpp will skip checking whether the stanza was awaited and will not run any actual
  /// IncomingStanzaHandler callbacks.
  bool skip;

  /// Indicates to the runner that processing is to be cancelled and no further handlers
  /// should run. The stanza also will not be sent.
  bool cancel;

  /// The reason why we cancelled the processing and sending.
  Object? cancelReason;

  /// The reason why an encryption or decryption failed.
  Object? encryptionError;

  /// The stanza that is being dealt with. SHOULD NOT be overwritten, unless it is
  /// absolutely necessary, e.g. with Message Carbons or OMEMO.
  Stanza stanza;

  /// Whether the stanza is already encrypted
  bool encrypted;

  // If true, forces the encryption manager to encrypt to the JID, even if it
  // would not normally. In the case of OMEMO: If shouldEncrypt returns false
  // but forceEncryption is true, then the OMEMO manager will try to encrypt
  // to the JID anyway.
  bool forceEncryption;

  /// Flag indicating whether a E2EE implementation should encrypt the stanza (true)
  /// or not (false).
  bool shouldEncrypt;

  /// Additional data from other managers.
  final TypedMap<StanzaHandlerExtension> extensions;
}
