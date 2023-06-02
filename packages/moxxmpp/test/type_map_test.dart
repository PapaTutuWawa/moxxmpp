import 'package:moxxmpp/src/util/typed_map.dart';
import 'package:test/test.dart';

class TestType1 {
  const TestType1(this.i);
  final int i;
}

class TestType2 {
  const TestType2(this.j);
  final bool j;
}

void main() {
  test('Test storing data in the type map', () {
    // Set
    final map = TypedMap()
      ..set(const TestType1(1))
      ..set(const TestType2(false));

    // And access
    expect(map.get<TestType1>()?.i, 1);
    expect(map.get<TestType2>()?.j, false);
  });
}
