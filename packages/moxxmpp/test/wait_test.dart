import 'package:test/test.dart';
import 'package:moxxmpp/src/util/wait.dart';

void main() {
  test('Test adding and resolving', () async {
    // ID -> Milliseconds since epoch
    final tracker = WaitForTracker<int, int>();

    int r2 = 0;
    int r3 = 0;
    
    // Queue some jobs
    final r1 = await tracker.waitFor(0);
    expect(r1, null);
    
    tracker
      .waitFor(0)
      .then((result) async {
        expect(result != null, true);
        r2 = await result!;
      });
    tracker
      .waitFor(0)
      .then((result) async {
        expect(result != null, true);
        r3 = await result!;
      });

    final c = await tracker.waitFor(1);
    expect(c, null);

    // Resolve jobs
    await tracker.resolve(0, 42);
    await tracker.resolve(1, 25);
    await tracker.resolve(2, -1);

    expect(r2, 42);
    expect(r3, 42);
  });
}
