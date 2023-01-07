import 'package:meta/meta.dart';
import 'package:moxxmpp/src/events.dart';
import 'package:moxxmpp/src/roster/roster.dart';

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

abstract class BaseRosterStateManager {
  List<XmppRosterItem>? currentRoster;
  String? currentVersion;

  Future<RosterCacheLoadResult> loadRosterCache();

  Future<void> commitRoster(String? version, List<String> removed, List<XmppRosterItem> modified, List<XmppRosterItem> added);

  Future<String?> getRosterVersion() async {
    await _loadRosterCache();

    return currentVersion;
  }
  
  Future<void> _loadRosterCache() async {
    if (currentRoster == null) {
      final result = await loadRosterCache();

      currentRoster = result.roster;
      currentVersion = result.version;
    }
  }
  
  _RosterProcessTriple _handleRosterItem(XmppRosterItem item) {
    if (item.subscription == 'remove') {
      // The item has been removed
      currentRoster!.removeWhere((i) => i.jid == item.jid);
      return _RosterProcessTriple(
        item.jid,
        null,
        null,
      );
    }
    
    final index = currentRoster!.indexWhere((i) => i.jid == item.jid);
    if (index == -1) {
      // The item does not exist
      currentRoster!.add(item);
      return _RosterProcessTriple(
        null,
        null,
        item,
      );
    } else {
      // The item is updated
      currentRoster![index] = item;
      return _RosterProcessTriple(
        null,
        item,
        null,
      );
    }
  }

  Future<void> handleRosterPush(RosterPushEvent event) async {
    await _loadRosterCache();

    currentVersion = event.ver;
    final result = _handleRosterItem(event.item);

    if (result.removed != null) {
      return commitRoster(
        currentVersion,
        [result.removed!],
        [],
        [],
      );
    } else if (result.modified != null) {
      return commitRoster(
        currentVersion,
        [],
        [result.modified!],
        [],
      );
    } else if (result.added != null) {
      return commitRoster(
        currentVersion,
        [],
        [],
        [result.added!],
      );
    }
  }

  Future<void> handleRosterFetch(RosterRequestResult result) async {
    final removed = List<String>.empty(growable: true);
    final modified = List<XmppRosterItem>.empty(growable: true);
    final added = List<XmppRosterItem>.empty(growable: true);

    await _loadRosterCache();

    currentVersion = result.ver;
    for (final item in result.items) {
      final result = _handleRosterItem(item);

      if (result.removed != null) removed.add(result.removed!);
      if (result.modified != null) modified.add(result.modified!);
      if (result.added != null) added.add(result.added!);
    }

    await commitRoster(
      currentVersion,
      removed,
      modified,
      added,
    );
  }
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
