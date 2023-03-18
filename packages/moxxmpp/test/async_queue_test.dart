import 'package:moxxmpp/src/util/queue.dart';
import 'package:test/test.dart';

void main() {
  test('Test the async queue', () async {
    final queue = AsyncQueue();
    var future1Finish = 0;
    var future2Finish = 0;
    var future3Finish = 0;

    await queue.addJob(
      () => Future<void>.delayed(
        const Duration(seconds: 3),
        () => future1Finish = DateTime.now().millisecondsSinceEpoch,
      ),
    );
    await queue.addJob(
      () => Future<void>.delayed(
        const Duration(seconds: 3),
        () => future2Finish = DateTime.now().millisecondsSinceEpoch,
      ),
    );
    await queue.addJob(
      () => Future<void>.delayed(
        const Duration(seconds: 3),
        () => future3Finish = DateTime.now().millisecondsSinceEpoch,
      ),
    );

    await Future<void>.delayed(const Duration(seconds: 12));

    // The three futures must be done
    expect(future1Finish != 0, true);
    expect(future2Finish != 0, true);
    expect(future3Finish != 0, true);

    // The end times of the futures must be ordered (on a timeline)
    // |-- future1Finish -- future2Finish -- future3Finish --|
    expect(
      future1Finish < future2Finish && future1Finish < future3Finish,
      true,
    );
    expect(
      future2Finish < future3Finish && future2Finish > future1Finish,
      true,
    );
    expect(
      future3Finish > future1Finish && future3Finish > future2Finish,
      true,
    );

    // The queue must be empty at the end
    expect(queue.queue.isEmpty, true);

    // The queue must not be executing anything at the end
    expect(queue.isRunning, false);
  });
}
