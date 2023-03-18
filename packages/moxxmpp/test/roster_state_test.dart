import 'package:moxxmpp/moxxmpp.dart';
import 'package:test/test.dart';

void main() {
  test('Test receiving a roster push', () async {
    final rs = TestingRosterStateManager(null, [])..register((_) {});

    await rs.handleRosterPush(
      RosterPushResult(
        const XmppRosterItem(
          jid: 'testuser@server.example',
          subscription: 'both',
        ),
        null,
      ),
    );

    expect(
      rs
              .getRosterItems()
              .indexWhere((item) => item.jid == 'testuser@server.example') !=
          -1,
      true,
    );
    expect(rs.loadCount, 1);
    expect(rs.getRosterItems().length, 1);

    // Receive another roster push
    await rs.handleRosterPush(
      RosterPushResult(
        const XmppRosterItem(
          jid: 'testuser2@server2.example',
          subscription: 'to',
        ),
        null,
      ),
    );

    expect(
      rs
              .getRosterItems()
              .indexWhere((item) => item.jid == 'testuser2@server2.example') !=
          -1,
      true,
    );
    expect(rs.loadCount, 1);
    expect(rs.getRosterItems().length, 2);

    // Remove one of the items
    await rs.handleRosterPush(
      RosterPushResult(
        const XmppRosterItem(
          jid: 'testuser2@server2.example',
          subscription: 'remove',
        ),
        null,
      ),
    );

    expect(
      rs
              .getRosterItems()
              .indexWhere((item) => item.jid == 'testuser2@server2.example') ==
          -1,
      true,
    );
    expect(
      rs
              .getRosterItems()
              .indexWhere((item) => item.jid == 'testuser@server.example') !=
          1,
      true,
    );
    expect(rs.loadCount, 1);
    expect(rs.getRosterItems().length, 1);
  });

  test('Test a roster fetch', () async {
    final rs = TestingRosterStateManager(null, [])..register((_) {});

    // Fetch the roster
    await rs.handleRosterFetch(
      RosterRequestResult(
        [
          const XmppRosterItem(
            jid: 'testuser@server.example',
            subscription: 'both',
          ),
          const XmppRosterItem(
            jid: 'testuser2@server2.example',
            subscription: 'to',
          ),
          const XmppRosterItem(
            jid: 'testuser3@server3.example',
            subscription: 'from',
          ),
        ],
        'aaaaaaaa',
      ),
    );

    expect(rs.loadCount, 1);
    expect(rs.getRosterItems().length, 3);
    expect(
      rs
              .getRosterItems()
              .indexWhere((item) => item.jid == 'testuser@server.example') !=
          -1,
      true,
    );
    expect(
      rs
              .getRosterItems()
              .indexWhere((item) => item.jid == 'testuser2@server2.example') !=
          -1,
      true,
    );
    expect(
      rs
              .getRosterItems()
              .indexWhere((item) => item.jid == 'testuser3@server3.example') !=
          -1,
      true,
    );
  });

  test('Test a roster fetch if we already have a roster', () async {
    XmppEvent? event;
    final rs = TestingRosterStateManager('aaaaa', [
      const XmppRosterItem(
        jid: 'testuser@server.example',
        subscription: 'both',
      ),
      const XmppRosterItem(
        jid: 'testuser2@server2.example',
        subscription: 'to',
      ),
      const XmppRosterItem(
        jid: 'testuser3@server3.example',
        subscription: 'from',
      ),
    ])
      ..register((e) {
        event = e;
      });

    // Fetch the roster
    await rs.handleRosterFetch(
      RosterRequestResult(
        [
          const XmppRosterItem(
            jid: 'testuser@server.example',
            subscription: 'both',
          ),
          const XmppRosterItem(
            jid: 'testuser2@server2.example',
            subscription: 'to',
          ),
          const XmppRosterItem(
            jid: 'testuser3@server3.example',
            subscription: 'both',
          ),
          const XmppRosterItem(
            jid: 'testuser4@server4.example',
            subscription: 'both',
          ),
        ],
        'bbbbb',
      ),
    );

    expect(event is RosterUpdatedEvent, true);
    final updateEvent = event! as RosterUpdatedEvent;

    expect(updateEvent.added.length, 1);
    expect(updateEvent.added.first.jid, 'testuser4@server4.example');
    expect(updateEvent.modified.length, 1);
    expect(updateEvent.modified.first.jid, 'testuser3@server3.example');
    expect(updateEvent.removed.isEmpty, true);
  });
}
