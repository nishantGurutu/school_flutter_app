import 'dart:async';

/// Publishes fresh telemetry without overlapping requests or restarting after stop.
/// GPS history is recorded separately in SQLite, regardless of connectivity.
class LiveLocationScheduler {
  LiveLocationScheduler({
    required this.latestPoint,
    required this.authorized,
    required this.publish,
    DateTime Function()? now,
    this.interval = const Duration(seconds: 30),
    this.maxFixAge = const Duration(seconds: 120),
  }) : _now = now ?? DateTime.now;

  final Map<String, dynamic>? Function() latestPoint;
  final Future<bool> Function() authorized;
  final Future<void> Function(Map<String, dynamic>) publish;
  final DateTime Function() _now;
  final Duration interval;
  final Duration maxFixAge;
  Timer? _timer;
  bool _stopped = false;
  bool _sending = false;

  void start() {
    if (_stopped || _timer != null) return;
    _timer = Timer.periodic(interval, (_) => unawaited(tick()));
  }

  Future<void> tick() async {
    if (_stopped || _sending) return;
    _sending = true;
    try {
      if (!await authorized() || _stopped) return;
      final point = latestPoint();
      final timestamp = DateTime.tryParse(
        point?['recordedAt']?.toString() ?? '',
      );
      if (point == null || timestamp == null) return;
      // The API's offset-free timestamps explicitly represent UTC.
      final utc = timestamp.isUtc
          ? timestamp
          : DateTime.utc(
              timestamp.year,
              timestamp.month,
              timestamp.day,
              timestamp.hour,
              timestamp.minute,
              timestamp.second,
              timestamp.millisecond,
              timestamp.microsecond,
            );
      final age = _now().toUtc().difference(utc);
      if (age > maxFixAge || age.isNegative) return;
      await publish(Map<String, dynamic>.from(point));
    } catch (_) {
      // Connectivity failure must not interrupt local GPS recording.
    } finally {
      _sending = false;
    }
  }

  void stop() {
    _stopped = true;
    _timer?.cancel();
    _timer = null;
  }
}
