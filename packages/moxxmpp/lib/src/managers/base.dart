import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:moxxmpp/src/events.dart';
import 'package:moxxmpp/src/managers/attributes.dart';
import 'package:moxxmpp/src/managers/data.dart';
import 'package:moxxmpp/src/managers/handlers.dart';
import 'package:moxxmpp/src/managers/namespaces.dart';
import 'package:moxxmpp/src/stringxml.dart';
import 'package:moxxmpp/src/xeps/xep_0030/types.dart';
import 'package:moxxmpp/src/xeps/xep_0030/xep_0030.dart';
import 'package:moxxmpp/src/xeps/xep_0198/xep_0198.dart';

abstract class XmppManagerBase {
  XmppManagerBase(this.id);

  late final XmppManagerAttributes _managerAttributes;
  late final Logger _log;

  /// Flag indicating that the post registration callback has been called once.
  bool initialized = false;

  /// Registers the callbacks from XmppConnection with the manager
  void register(XmppManagerAttributes attributes) {
    _managerAttributes = attributes;
    _log = Logger(name);
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

  /// Return a list of identities that should be included in a disco response.
  List<Identity> getDiscoIdentities() => [];

  /// Return the Id (akin to xmlns) of this manager.
  final String id;

  /// The name of the manager.
  String get name => toString();

  /// Return the logger for this manager.
  Logger get logger => _log;

  /// Called when XmppConnection triggers an event
  Future<void> onXmppEvent(XmppEvent event) async {}

  /// Returns true if the XEP is supported on the server. If not, returns false
  Future<bool> isSupported();

  /// Called after the registration of all managers against the XmppConnection is done.
  /// This method is only called once during the entire lifetime of it.
  @mustCallSuper
  Future<void> postRegisterCallback() async {
    initialized = true;

    final disco = getAttributes().getManagerById<DiscoManager>(discoManager);
    if (disco != null) {
      if (getDiscoFeatures().isNotEmpty) {
        disco.addFeatures(getDiscoFeatures());
      }

      if (getDiscoIdentities().isNotEmpty) {
        disco.addIdentities(getDiscoIdentities());
      }
    }
  }

  /// Runs all NonzaHandlers of this Manager which match the nonza. Resolves to true if
  /// the nonza has been handled by one of the handlers. Resolves to false otherwise.
  Future<bool> runNonzaHandlers(XMLNode nonza) async {
    var handled = false;
    await Future.forEach(getNonzaHandlers(), (NonzaHandler handler) async {
      if (handler.matches(nonza)) {
        handled = true;
        await handler.callback(nonza);
      }
    });

    return handled;
  }

  /// Returns true, if the current stream negotiations resulted in a new stream. Useful
  /// for plugins to reset their cache in case of a new stream.
  /// The value only makes sense after receiving a StreamNegotiationsDoneEvent.
  Future<bool> isNewStream() async {
    final sm =
        getAttributes().getManagerById<StreamManagementManager>(smManager);

    return sm?.streamResumed == false;
  }

  /// Sends a reply of the stanza in [data] with [type]. Replaces the original stanza's
  /// children with [children].
  ///
  /// Note that this function currently only accepts IQ stanzas.
  Future<void> reply(
    StanzaHandlerData data,
    String type,
    List<XMLNode> children,
  ) async {
    assert(
      data.stanza.tag == 'iq',
      'Reply makes little sense for non-IQ stanzas',
    );

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
