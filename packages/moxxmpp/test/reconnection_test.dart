import 'dart:async';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:test/test.dart';
import 'helpers/logging.dart';

void main() {
  initLogger();

  test('Test triggering a reconnect multiple times', () async {
    final policy = RandomBackoffReconnectionPolicy(
      9998,
      9999,
    );
    await policy.setShouldReconnect(true);

    // We have a failure
    expect(
      await policy.canTriggerFailure(),
      true,
    );
    await policy.onFailure();

    // Try to trigger another one
    expect(
      await policy.canTriggerFailure(),
      false,
    );
  });

  test('Test resetting while reconnecting', () async {
    final policy = RandomBackoffReconnectionPolicy(
      9998,
      9999,
    )..register(() async => expect(true, false));
    await policy.setShouldReconnect(true);

    // We have a failure
    expect(
      await policy.canTriggerFailure(),
      true,
    );
    await policy.onFailure();
    expect(policy.isTimerRunning(), true);

    // We reset
    await policy.reset();
    expect(policy.isTimerRunning(), false);

    // We have another failure
    expect(
      await policy.canTriggerFailure(),
      true,
    );
  });

  test('Test triggering the timer callback twice', () async {
    final policy = RandomBackoffReconnectionPolicy(
      9998,
      9999,
    );
    var counter = 0;
    policy.register(() async {
      await policy.reset();
      counter++;
    });
    await policy.setShouldReconnect(true);
    // ignore: avoid_print
    print('policy.setShouldReconnect(true) done');

    // We have a failure
    expect(
      await policy.canTriggerFailure(),
      true,
    );
    await policy.onFailure();
    // ignore: avoid_print
    print('policy.onFailure() done');

    unawaited(policy.onTimerElapsed());
    unawaited(policy.onTimerElapsed());

    await Future<void>.delayed(const Duration(seconds: 3));
    expect(counter, 1);
  });
}
