import 'package:meta/meta.dart';
import 'package:moxxmpp/src/events.dart';
import 'package:moxxmpp/src/roster/roster.dart';
import 'package:synchronized/synchronized.dart';

class _RosterProcessTriple {
  const _RosterProcessTriple(this.removed, this.modified, this.added);
  final String? removed;
  final XmppRosterItem? modified;
  final XmppRosterItem? added;
}

class RosterCacheLoadResult {
  const RosterCacheLoadResult(this.version, this.roster);
  final String? version;
  final List<XmppRosterItem> roster;
}

/// This class manages the roster state in order to correctly process and persist
/// roster pushes and facilitate roster versioning requests.
abstract class BaseRosterStateManager {
  /// The cached version of the roster. If null, then it has not been loaded yet.
  List<XmppRosterItem>? _currentRoster;

  /// The cached version of the roster version.
  String? _currentVersion;

  /// A critical section locking both _currentRoster and _currentVersion.
  final Lock _lock = Lock();
  
  /// Overrideable function
  /// Loads the old cached version of the roster and optionally that roster version
  /// from persistent storage into a RosterCacheLoadResult object.
  Future<RosterCacheLoadResult> loadRosterCache();

  /// Overrideable function
  /// Commits the roster data to persistent storage.
  ///
  /// [version] is the roster version string. If none was provided, then this value
  /// is null.
  ///
  /// [removed] is a (possibly empty) list of bare JIDs that are removed from the
  /// roster.
  ///
  /// [modified] is a (possibly empty) list of XmppRosterItems that are modified. Correlation with
  /// the cache is done using its jid attribute.
  ///
  /// [added] is a (possibly empty) list of XmppRosterItems that are added by the
  /// roster push or roster fetch request.
  Future<void> commitRoster(String? version, List<String> removed, List<XmppRosterItem> modified, List<XmppRosterItem> added);

  /// Load and cache or return the cached roster version.
  Future<String?> getRosterVersion() async {
    return _lock.synchronized(() async {
      await _loadRosterCache();

      return _currentVersion;
    });
  }

  /// Loads the cached roster data into memory, if that has not already happened.
  /// NOTE: Must be called from within the _lock critical section.
  Future<void> _loadRosterCache() async {
    if (_currentRoster == null) {
      final result = await loadRosterCache();

      _currentRoster = result.roster;
      _currentVersion = result.version;
    }
  }

  /// Processes only single XmppRosterItem [item].
  /// NOTE: Requires to be called from within the _lock critical section.
  _RosterProcessTriple _handleRosterItem(XmppRosterItem item) {
    if (item.subscription == 'remove') {
      // The item has been removed
      _currentRoster!.removeWhere((i) => i.jid == item.jid);
      return _RosterProcessTriple(
        item.jid,
        null,
        null,
      );
    }
    
    final index = _currentRoster!.indexWhere((i) => i.jid == item.jid);
    if (index == -1) {
      // The item does not exist
      _currentRoster!.add(item);
      return _RosterProcessTriple(
        null,
        null,
        item,
      );
    } else {
      // The item is updated
      _currentRoster![index] = item;
      return _RosterProcessTriple(
        null,
        item,
        null,
      );
    }
  }

  /// Handles a roster push from the RosterManager.
  Future<void> handleRosterPush(RosterPushEvent event) async {
    await _lock.synchronized(() async {
      await _loadRosterCache();

      _currentVersion = event.ver;
      final result = _handleRosterItem(event.item);

      if (result.removed != null) {
        return commitRoster(
          _currentVersion,
          [result.removed!],
          [],
          [],
        );
      } else if (result.modified != null) {
        return commitRoster(
          _currentVersion,
          [],
          [result.modified!],
          [],
        );
      } else if (result.added != null) {
        return commitRoster(
          _currentVersion,
          [],
          [],
          [result.added!],
        );
      }
    });
  }

  /// Handles the result from a roster fetch.
  Future<void> handleRosterFetch(RosterRequestResult result) async {
    await _lock.synchronized(() async {
      final removed = List<String>.empty(growable: true);
      final modified = List<XmppRosterItem>.empty(growable: true);
      final added = List<XmppRosterItem>.empty(growable: true);

      await _loadRosterCache();

      _currentVersion = result.ver;
      for (final item in result.items) {
        final result = _handleRosterItem(item);

        if (result.removed != null) removed.add(result.removed!);
        if (result.modified != null) modified.add(result.modified!);
        if (result.added != null) added.add(result.added!);
      }

      await commitRoster(
        _currentVersion,
        removed,
        modified,
        added,
      );
    });
  }

  @visibleForTesting
  List<XmppRosterItem> getRosterItems() => _currentRoster!;
}

@visibleForTesting
class TestingRosterStateManager extends BaseRosterStateManager {
  TestingRosterStateManager(
    this.initialRosterVersion,
    this.initialRoster,
  );
  final String? initialRosterVersion;
  final List<XmppRosterItem> initialRoster;
  int loadCount = 0;

  @override
  Future<RosterCacheLoadResult> loadRosterCache() async {
    loadCount++;
    return RosterCacheLoadResult(
      initialRosterVersion,
      initialRoster,
    );
  }

  @override
  Future<void> commitRoster(String? version, List<String> removed, List<XmppRosterItem> modified, List<XmppRosterItem> added) async {}

}
