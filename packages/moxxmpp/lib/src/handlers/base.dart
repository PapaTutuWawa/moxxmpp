import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:moxxmpp/src/errors.dart';
import 'package:moxxmpp/src/events.dart';
import 'package:moxxmpp/src/negotiators/negotiator.dart';
import 'package:moxxmpp/src/parser.dart';
import 'package:moxxmpp/src/settings.dart';
import 'package:moxxmpp/src/stringxml.dart';

/// A callback for when the [NegotiationsHandler] is done.
typedef NegotiationsDoneCallback = Future<void> Function();

/// A callback for the case that an error occurs while negotiating.
typedef ErrorCallback = Future<void> Function(XmppError);

/// Return true if the current connection is authenticated. If not, return false.
typedef IsAuthenticatedFunction = bool Function();

/// Send a nonza on the stream
typedef SendNonzaFunction = void Function(XMLNode);

/// Returns the connection settings.
typedef GetConnectionSettingsFunction = ConnectionSettings Function();

/// This class implements the stream feature negotiation for XmppConnection.
abstract class NegotiationsHandler {
  @protected
  late final Logger log;

  /// Map of all negotiators registered against the handler.
  @protected
  final Map<String, XmppFeatureNegotiatorBase> negotiators = {};

  /// Function that is called once the negotiator is done with its stream negotiations.
  @protected
  late final NegotiationsDoneCallback onNegotiationsDone;

  /// XmppConnection's handleError method.
  @protected
  late final ErrorCallback handleError;

  /// Returns true if the connection is authenticated. If not, returns false.
  @protected
  late final IsAuthenticatedFunction isAuthenticated;

  /// Send a nonza over the stream.
  @protected
  late final SendNonzaFunction sendNonza;

  /// Get the connection's settings.
  @protected
  late final GetConnectionSettingsFunction getConnectionSettings;

  /// The id included in the last stream header.
  @protected
  String? streamId;

  /// Set the id of the last stream header.
  void setStreamHeaderId(String? id) {
    streamId = id;
  }

  /// Returns, if registered, a negotiator with id [id].
  T? getNegotiatorById<T extends XmppFeatureNegotiatorBase>(String id) =>
      negotiators[id] as T?;

  /// Register the parameters as the corresponding methods in this class. Also
  /// initializes the logger.
  void register(
    NegotiationsDoneCallback onNegotiationsDone,
    ErrorCallback handleError,
    IsAuthenticatedFunction isAuthenticated,
    SendNonzaFunction sendNonza,
    GetConnectionSettingsFunction getConnectionSettings,
  ) {
    this.onNegotiationsDone = onNegotiationsDone;
    this.handleError = handleError;
    this.isAuthenticated = isAuthenticated;
    this.sendNonza = sendNonza;
    this.getConnectionSettings = getConnectionSettings;
    log = Logger(toString());
  }

  /// Returns the xmlns attribute that stanzas should have.
  String getStanzaNamespace();

  /// Registers the negotiator [negotiator] against this negotiations handler.
  void registerNegotiator(XmppFeatureNegotiatorBase negotiator);

  /// Sends the stream header.
  void sendStreamHeader();

  /// Runs the post-register callback of all negotiators.
  Future<void> runPostRegisterCallback() async {
    for (final negotiator in negotiators.values) {
      await negotiator.postRegisterCallback();
    }
  }

  Future<void> sendEventToNegotiators(XmppEvent event) async {
    for (final negotiator in negotiators.values) {
      await negotiator.onXmppEvent(event);
    }
  }

  /// Remove [feature] from the stream features we are currently negotiating.
  void removeNegotiatingFeature(String feature) {}

  /// Resets all registered negotiators and the negotiation handler.
  @mustCallSuper
  void reset() {
    streamId = null;
    for (final negotiator in negotiators.values) {
      negotiator.reset();
    }
  }

  /// Called whenever the stream buffer outputs a new event [event].
  Future<void> negotiate(XMPPStreamObject event) async {
    if (event is XMPPStreamHeader) {
      streamId = event.attributes['id'];
    }
  }
}
