import 'package:moxxmpp/moxxmpp.dart';
import 'package:test/test.dart';

void main() {
  test('Test receiving a roster push', () async {
    final rs = TestingRosterStateManager(null, []);

    await rs.handleRosterPush(
      RosterPushEvent(
        item: XmppRosterItem(
          jid: 'testuser@server.example',
          subscription: 'both',
        ),
      ),
    );

    expect(
      rs.currentRoster!.indexWhere((item) => item.jid == 'testuser@server.example') != -1,
      true,
    );
    expect(rs.loadCount, 1);
    expect(rs.currentRoster!.length, 1);

    // Receive another roster push
    await rs.handleRosterPush(
      RosterPushEvent(
        item: XmppRosterItem(
          jid: 'testuser2@server2.example',
          subscription: 'to',
        ),
      ),
    );

    expect(
      rs.currentRoster!.indexWhere((item) => item.jid == 'testuser2@server2.example') != -1,
      true,
    );
    expect(rs.loadCount, 1);
    expect(rs.currentRoster!.length, 2);

    // Remove one of the items
     await rs.handleRosterPush(
      RosterPushEvent(
        item: XmppRosterItem(
          jid: 'testuser2@server2.example',
          subscription: 'remove',
        ),
      ),
    );

    expect(
      rs.currentRoster!.indexWhere((item) => item.jid == 'testuser2@server2.example') == -1,
      true,
    );
    expect(
      rs.currentRoster!.indexWhere((item) => item.jid == 'testuser@server.example') != 1,
      true,
    );
    expect(rs.loadCount, 1);
    expect(rs.currentRoster!.length, 1);   
  });

  test('Test a roster fetch', () async {
    final rs = TestingRosterStateManager(null, []);

    // Fetch the roster
    await rs.handleRosterFetch(
      RosterRequestResult(
        items: [
          XmppRosterItem(
            jid: 'testuser@server.example',
            subscription: 'both',
          ),
          XmppRosterItem(
            jid: 'testuser2@server2.example',
            subscription: 'to',
          ),
          XmppRosterItem(
            jid: 'testuser3@server3.example',
            subscription: 'from',
          ),
        ],
        ver: 'aaaaaaaa',
      ),
    );

    expect(rs.loadCount, 1);
    expect(rs.currentRoster!.length, 3);
    expect(rs.currentRoster!.indexWhere((item) => item.jid == 'testuser@server.example') != -1, true);
    expect(rs.currentRoster!.indexWhere((item) => item.jid == 'testuser2@server2.example') != -1, true);
    expect(rs.currentRoster!.indexWhere((item) => item.jid == 'testuser3@server3.example') != -1, true);
  });
}
