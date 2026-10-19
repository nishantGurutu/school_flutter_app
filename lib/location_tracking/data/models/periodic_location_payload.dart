import 'dart:math';

class PeriodicLocationPayload {
  const PeriodicLocationPayload({
    required this.address,
    required this.batteryLevel,
    required this.date,
    required this.deviceId,
    required this.empId,
    required this.foreground,
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.time,
  });

  factory PeriodicLocationPayload.fromDetails({
    required double latitude,
    required double longitude,
    required String address,
    required double batteryLevel,
    required String deviceId,
    required int empId,
    required bool foreground,
    required DateTime timestamp,
  }) {
    final dateStr = _formatDate(timestamp);
    final timeStr = _formatTime(timestamp);
    return PeriodicLocationPayload(
      address: address,
      batteryLevel: batteryLevel,
      date: dateStr,
      deviceId: deviceId,
      empId: empId,
      foreground: foreground,
      id: generateUuidV4(),
      latitude: latitude,
      longitude: longitude,
      time: timeStr,
    );
  }

  final String address;
  final double batteryLevel;
  final String date;
  final String deviceId;
  final int empId;
  final bool foreground;
  final String id;
  final double latitude;
  final double longitude;
  final String time;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'address': address,
      'batteryLevel': batteryLevel,
      'date': date,
      'deviceId': deviceId,
      'empId': empId,
      'foreground': foreground,
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'time': time,
    };
  }

  factory PeriodicLocationPayload.fromJson(Map<String, dynamic> json) {
    return PeriodicLocationPayload(
      address: json['address'] as String? ?? 'NO Address',
      batteryLevel: (json['batteryLevel'] as num?)?.toDouble() ?? 100.0,
      date: json['date'] as String? ?? '',
      deviceId: json['deviceId'] as String? ?? '',
      empId: json['empId'] as int? ?? 0,
      foreground: json['foreground'] as bool? ?? false,
      id: json['id'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      time: json['time'] as String? ?? '',
    );
  }

  static String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$min:$s';
  }

  static String generateUuidV4() {
    final random = Random.secure();
    final hex = List<String>.generate(32, (i) {
      if (i == 12) return '4';
      if (i == 16) return ((random.nextInt(4) + 8).toRadixString(16));
      return random.nextInt(16).toRadixString(16);
    });
    return '${hex.sublist(0, 8).join()}-${hex.sublist(8, 12).join()}-${hex.sublist(12, 16).join()}-${hex.sublist(16, 20).join()}-${hex.sublist(20, 32).join()}';
  }
}
