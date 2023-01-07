import 'package:moxxmpp/moxxmpp.dart';
import 'package:test/test.dart';

void main() {
  test('Test receiving a roster push', () async {
    final rs = TestingRosterStateManager(null, []);
    rs.register((_) {});

    await rs.handleRosterPush(
      RosterPushResult(
        XmppRosterItem(
          jid: 'testuser@server.example',
          subscription: 'both',
        ),
        null,
      ),
    );

    expect(
      rs.getRosterItems().indexWhere((item) => item.jid == 'testuser@server.example') != -1,
      true,
    );
    expect(rs.loadCount, 1);
    expect(rs.getRosterItems().length, 1);

    // Receive another roster push
    await rs.handleRosterPush(
      RosterPushResult(
        XmppRosterItem(
          jid: 'testuser2@server2.example',
          subscription: 'to',
        ),
        null,
      ),
    );

    expect(
      rs.getRosterItems().indexWhere((item) => item.jid == 'testuser2@server2.example') != -1,
      true,
    );
    expect(rs.loadCount, 1);
    expect(rs.getRosterItems().length, 2);

    // Remove one of the items
     await rs.handleRosterPush(
      RosterPushResult(
        XmppRosterItem(
          jid: 'testuser2@server2.example',
          subscription: 'remove',
        ),
        null,
      ),
    );

    expect(
      rs.getRosterItems().indexWhere((item) => item.jid == 'testuser2@server2.example') == -1,
      true,
    );
    expect(
      rs.getRosterItems().indexWhere((item) => item.jid == 'testuser@server.example') != 1,
      true,
    );
    expect(rs.loadCount, 1);
    expect(rs.getRosterItems().length, 1);   
  });

  test('Test a roster fetch', () async {
    final rs = TestingRosterStateManager(null, []);
    rs.register((_) {});

    // Fetch the roster
    await rs.handleRosterFetch(
      RosterRequestResult(
        [
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
        'aaaaaaaa',
      ),
    );

    expect(rs.loadCount, 1);
    expect(rs.getRosterItems().length, 3);
    expect(rs.getRosterItems().indexWhere((item) => item.jid == 'testuser@server.example') != -1, true);
    expect(rs.getRosterItems().indexWhere((item) => item.jid == 'testuser2@server2.example') != -1, true);
    expect(rs.getRosterItems().indexWhere((item) => item.jid == 'testuser3@server3.example') != -1, true);
  });
}
