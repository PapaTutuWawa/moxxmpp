import 'package:moxxmpp/moxxmpp.dart';
import 'package:test/test.dart';

void main() {
  test('Parse a full JID', () {
    final jid = JID.fromString('test@server/abc');

    expect(jid.local, 'test');
    expect(jid.domain, 'server');
    expect(jid.resource, 'abc');
    expect(jid.toString(), 'test@server/abc');
  });

  test('Parse a bare JID', () {
    final jid = JID.fromString('test@server');

    expect(jid.local, 'test');
    expect(jid.domain, 'server');
    expect(jid.resource, '');
    expect(jid.toString(), 'test@server');
  });

  test('Parse a JID with no local part', () {
    final jid = JID.fromString('server/abc');

    expect(jid.local, '');
    expect(jid.domain, 'server');
    expect(jid.resource, 'abc');
    expect(jid.toString(), 'server/abc');
  });

  test('Equality', () {
    expect(
      JID.fromString('hallo@welt/abc') == const JID('hallo', 'welt', 'abc'),
      true,
    );
    expect(
      JID.fromString('hallo@welt') == const JID('hallo', 'welt', 'a'),
      false,
    );
  });

  test('Dot suffix at domain part', () {
    expect(
      JID.fromString('hallo@welt.example.') ==
          const JID('hallo', 'welt.example', ''),
      true,
    );
    expect(
      JID.fromString('hallo@welt.example./test') ==
          const JID('hallo', 'welt.example', 'test'),
      true,
    );
  });

  test('Parse resource with a slash', () {
    expect(
      JID.fromString('hallo@welt.example./test/welt') ==
          const JID('hallo', 'welt.example', 'test/welt'),
      true,
    );
  });

  test('bareCompare', () {
    const jid1 = JID('hallo', 'welt', 'lol');
    const jid2 = JID('hallo', 'welt', '');
    const jid3 = JID('hallo', 'earth', 'true');

    expect(jid1.bareCompare(jid2), true);
    expect(jid2.bareCompare(jid1), true);
    expect(jid2.bareCompare(jid1, ensureBare: true), false);
    expect(jid2.bareCompare(jid3), false);
  });
}
