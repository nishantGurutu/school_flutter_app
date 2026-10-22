import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_desk_app/location_tracking/data/live_location_scheduler.dart';

void main() {
  final now = DateTime.utc(2026, 10, 22, 10);
  Map<String, dynamic> point(Duration age) => {
    'latitude': 28.6,
    'longitude': 77.0,
    'recordedAt': now.subtract(age).toIso8601String().replaceFirst('Z', ''),
  };

  testWidgets('30-second timer starts once and cancels permanently on stop', (
    tester,
  ) async {
    var uploads = 0;
    final scheduler = LiveLocationScheduler(
      latestPoint: () => point(Duration.zero),
      authorized: () async => true,
      publish: (_) async {
        uploads++;
      },
      now: () => now,
    );
    scheduler.start();
    scheduler.start();
    await tester.pump(const Duration(seconds: 29));
    expect(uploads, 0);
    await tester.pump(const Duration(seconds: 1));
    expect(uploads, 1);
    await tester.pump(const Duration(seconds: 30));
    expect(uploads, 2);
    scheduler.stop();
    scheduler.start();
    await tester.pump(const Duration(minutes: 2));
    expect(uploads, 2);
  });

  test(
    'publishes fresh UTC fixes and skips stale, future or missing fixes',
    () async {
      Map<String, dynamic>? latest;
      final sent = <Map<String, dynamic>>[];
      final scheduler = LiveLocationScheduler(
        latestPoint: () => latest,
        authorized: () async => true,
        publish: (value) async => sent.add(value),
        now: () => now,
      );
      expect(scheduler.interval, const Duration(seconds: 30));
      await scheduler.tick();
      latest = point(const Duration(minutes: 3));
      await scheduler.tick();
      latest = point(const Duration(seconds: -1));
      await scheduler.tick();
      latest = {'recordedAt': 'invalid'};
      await scheduler.tick();
      expect(sent, isEmpty);
      latest = point(const Duration(seconds: 15));
      await scheduler.tick();
      expect(sent, hasLength(1));
      expect(sent.single['latitude'], 28.6);
      scheduler.stop();
    },
  );

  test('stop during awaited session check prevents a late upload', () async {
    final gate = Completer<bool>();
    final scheduler = LiveLocationScheduler(
      latestPoint: () => point(Duration.zero),
      authorized: () => gate.future,
      publish: (_) async => fail('must not publish after stop'),
      now: () => now,
    );
    final pending = scheduler.tick();
    scheduler.stop();
    gate.complete(true);
    await pending;
    scheduler.start();
    await scheduler.tick();
  });

  test('slow network requests never overlap and failures can retry', () async {
    final gate = Completer<void>();
    var uploads = 0;
    final scheduler = LiveLocationScheduler(
      latestPoint: () => point(Duration.zero),
      authorized: () async => true,
      publish: (_) async {
        uploads++;
        if (uploads == 1) {
          await gate.future;
          throw StateError('offline');
        }
      },
      now: () => now,
    );
    final first = scheduler.tick();
    await scheduler.tick();
    gate.complete();
    await first;
    expect(uploads, 1);
    await scheduler.tick();
    expect(uploads, 2);
    scheduler.stop();
  });

  test('account change prevents publication', () async {
    final scheduler = LiveLocationScheduler(
      latestPoint: () => point(Duration.zero),
      authorized: () async => false,
      publish: (_) async => fail('must not publish for a different user'),
      now: () => now,
    );
    await scheduler.tick();
    scheduler.stop();
  });
}
