import 'dart:convert';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:test/test.dart';

void main() {
  test('Test accepting newlines', () {
    const data = UserAvatarData(
      'cGFwYXR1d\nHV3\n\nYXdh',
      'some-id',
    );

    expect(utf8.decode(data.data), 'papatutuwawa');
  });
}
