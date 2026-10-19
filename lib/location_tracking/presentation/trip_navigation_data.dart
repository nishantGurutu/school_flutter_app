import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Normalize route/API arguments before creating the native map.
class TripNavigationData {
  TripNavigationData(Map<String, dynamic>? arguments) {
    final duty = map(arguments?['duty']);
    final trip = {...map(duty['activeTrip']), ...map(arguments?['trip'])};
    tripId = integer(trip['tripId'] ?? duty['activeTripId']) ?? 0;
    busNumber = (trip['busNumber'] ?? duty['busNumber'] ?? 'School bus')
        .toString();
    routeName = (trip['routeName'] ?? duty['routeName'] ?? 'Assigned route')
        .toString();
    final raw = map(duty['route'])['stops'];
    stops = raw is List
        ? raw
              .whereType<Map>()
              .map((stop) => Map<String, dynamic>.from(stop))
              .toList()
        : [];
    stops.sort(
      (a, b) => (integer(a['stopOrder']) ?? 0).compareTo(
        integer(b['stopOrder']) ?? 0,
      ),
    );
    position = coordinate(
      trip['lastLatitude'] ??
          trip['startLatitude'] ??
          duty['todayStartLatitude'],
      trip['lastLongitude'] ??
          trip['startLongitude'] ??
          duty['todayStartLongitude'],
    );
    startedAt = DateTime.tryParse(
      (trip['actualStartTime'] ?? duty['todayActualStartTime'] ?? '')
          .toString(),
    );
  }
  late final int tripId;
  late final String busNumber;
  late final String routeName;
  late final List<Map<String, dynamic>> stops;
  late final LatLng? position;
  late final DateTime? startedAt;
  static Map<String, dynamic> map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : {};
  static int? integer(dynamic value) => int.tryParse(value?.toString() ?? '');
  static double? number(dynamic value) {
    final parsed = double.tryParse(value?.toString() ?? '');
    return parsed != null && parsed.isFinite ? parsed : null;
  }

  static LatLng? coordinate(dynamic latitude, dynamic longitude) {
    final lat = number(latitude), lon = number(longitude);
    if (lat == null || lon == null || lat.abs() > 90 || lon.abs() > 180) {
      return null;
    }
    return LatLng(lat, lon);
  }
}
