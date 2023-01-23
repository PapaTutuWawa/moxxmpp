import 'package:logging/logging.dart';
import 'package:moxxmpp/src/events.dart';
import 'package:moxxmpp/src/managers/attributes.dart';
import 'package:moxxmpp/src/managers/data.dart';
import 'package:moxxmpp/src/managers/handlers.dart';
import 'package:moxxmpp/src/stringxml.dart';

abstract class XmppManagerBase {
  late final XmppManagerAttributes _managerAttributes;
  late final Logger _log;

  /// Registers the callbacks from XmppConnection with the manager
  void register(XmppManagerAttributes attributes) {
    _managerAttributes = attributes;
    _log = Logger(getName());
  }
  
  /// Returns the attributes that are registered with the manager.
  /// Must only be called after register has been called on it.
  XmppManagerAttributes getAttributes() {
    return _managerAttributes;
  }

  /// Return the StanzaHandlers associated with this manager that deal with stanzas we
  /// send. These are run before the stanza is sent. The higher the value of the
  /// handler's priority, the earlier it is run.
  List<StanzaHandler> getOutgoingPreStanzaHandlers() => [];

  /// Return the StanzaHandlers associated with this manager that deal with stanzas we
  /// send. These are run after the stanza is sent. The higher the value of the
  /// handler's priority, the earlier it is run.
  List<StanzaHandler> getOutgoingPostStanzaHandlers() => [];
  
  /// Return the StanzaHandlers associated with this manager that deal with stanzas we
  /// receive. The higher the value of the
  /// handler's priority, the earlier it is run.
  List<StanzaHandler> getIncomingStanzaHandlers() => [];

  /// Return the StanzaHandlers associated with this manager that deal with stanza handlers
  /// that have to run before the main ones run. This is useful, for example, for OMEMO
  /// as we have to decrypt the stanza before we do anything else. The higher the value
  /// of the handler's priority, the earlier it is run.
  List<StanzaHandler> getIncomingPreStanzaHandlers() => [];
  
  /// Return the NonzaHandlers associated with this manager. The higher the value of the
  /// handler's priority, the earlier it is run.
  List<NonzaHandler> getNonzaHandlers() => [];

  /// Return a list of features that should be included in a disco response.
  List<String> getDiscoFeatures() => [];
  
  /// Return the Id (akin to xmlns) of this manager.
  String getId();

  /// Return a name that will be used for logging.
  String getName();

  /// Return the logger for this manager.
  Logger get logger => _log;
  
  /// Called when XmppConnection triggers an event
  Future<void> onXmppEvent(XmppEvent event) async {}

  /// Returns true if the XEP is supported on the server. If not, returns false
  Future<bool> isSupported();
  
  /// Runs all NonzaHandlers of this Manager which match the nonza. Resolves to true if
  /// the nonza has been handled by one of the handlers. Resolves to false otherwise.
  Future<bool> runNonzaHandlers(XMLNode nonza) async {
    var handled = false;
    await Future.forEach(
      getNonzaHandlers(),
      (NonzaHandler handler) async {
        if (handler.matches(nonza)) {
          handled = true;
          await handler.callback(nonza);
        }
      }
    );

    return handled;
  }

  /// Sends a reply of the stanza in [data] with [type]. Replaces the original stanza's
  /// children with [children].
  ///
  /// Note that this function currently only accepts IQ stanzas.
  Future<void> reply(StanzaHandlerData data, String type, List<XMLNode> children) async {
    assert(data.stanza.tag == 'iq', 'Reply makes little sense for non-IQ stanzas');

    final stanza = data.stanza.copyWith(
      to: data.stanza.from,
      from: data.stanza.to,
      type: type,
      children: children,
    );

    await getAttributes().sendStanza(
      stanza,
      awaitable: false,
      forceEncryption: data.encrypted,
    );
  }
}
