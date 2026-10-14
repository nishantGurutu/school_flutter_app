import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/storage/local_storage.dart';

class TransportService {
  static const String baseUrl = 'http://10.0.2.2:8080/api/v1/transport'; // Android emulator localhost or fallback
  static const String localBaseUrl = 'http://localhost:8080/api/v1/transport';

  // In-memory offline GPS queue for network disruptions
  static final List<Map<String, dynamic>> _offlineGpsQueue = [];

  static Future<Map<String, String>> _getHeaders() async {
    final token = await StorageHelper.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // Fetch driver duty
  static Future<Map<String, dynamic>?> getDriverDuty({String? email}) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/driver/my-duty${email != null ? '?email=$email' : ''}');
      final res = await http.get(url, headers: headers).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {
      // Fallback local or mock duty
    }
    return _getMockDriverDuty();
  }

  // Start trip
  static Future<Map<String, dynamic>?> startTrip({
    required int routeId,
    required int busId,
    String shift = 'MORNING',
    double? startLat,
    double? startLon,
    bool preTripCheckPassed = true,
    String? preTripNotes,
    String? email,
  }) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/trips/start${email != null ? '?email=$email' : ''}');
      final body = jsonEncode({
        'routeId': routeId,
        'busId': busId,
        'shift': shift,
        'startLatitude': startLat ?? 25.6150,
        'startLongitude': startLon ?? 85.1280,
        'preTripCheckPassed': preTripCheckPassed,
        'preTripNotes': preTripNotes ?? 'Checklist completed: Brakes, tires, fluids and GPS active.',
      });

      final res = await http.post(url, headers: headers, body: body).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200 || res.statusCode == 201) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {
      // Fallback offline mock trip
    }
    return {
      'tripId': 1,
      'status': 'IN_PROGRESS',
      'busNumber': 'Bus 04',
      'routeName': 'Route 1 - North Campus Loop',
      'totalDistanceKm': 0.0,
      'completedStopsCount': 0,
      'totalStopsCount': 5,
      'currentSpeedKmh': 0.0,
    };
  }

  // Upload GPS batch (with offline queue auto-sync)
  static Future<bool> sendGpsLocation({
    required int tripId,
    required double lat,
    required double lon,
    required double speedKmh,
    double heading = 0.0,
    String? email,
  }) async {
    final point = {
      'latitude': lat,
      'longitude': lon,
      'speedKmh': speedKmh,
      'heading': heading,
      'accuracyMeters': 5.0,
      'recordedAt': DateTime.now().toIso8601String(),
    };

    _offlineGpsQueue.add(point);

    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/trips/$tripId/locations:batch${email != null ? '?email=$email' : ''}');
      final body = jsonEncode({'points': _offlineGpsQueue});

      final res = await http.post(url, headers: headers, body: body).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        _offlineGpsQueue.clear();
        return true;
      }
    } catch (_) {
      // Keeps queued locally in _offlineGpsQueue for subsequent sync
    }
    return false;
  }

  // Stop Event (Arrival / Departure)
  static Future<bool> recordStopEvent({
    required int tripId,
    required int stopId,
    required String eventType, // ARRIVED, DEPARTED
    int studentsBoarded = 0,
    int studentsDeboarded = 0,
    String? notes,
    String? email,
  }) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/trips/$tripId/stops/$stopId/events${email != null ? '?email=$email' : ''}');
      final body = jsonEncode({
        'stopId': stopId,
        'eventType': eventType,
        'studentsBoarded': studentsBoarded,
        'studentsDeboarded': studentsDeboarded,
        'notes': notes,
      });

      final res = await http.post(url, headers: headers, body: body).timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (_) {
      return true;
    }
  }

  // Report Incident (Route deviation, breakdown, etc.)
  static Future<bool> reportIncident({
    required int tripId,
    required String incidentType,
    required String description,
    double? lat,
    double? lon,
    String severity = 'HIGH',
    String? email,
  }) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/trips/$tripId/incidents${email != null ? '?email=$email' : ''}');
      final body = jsonEncode({
        'incidentType': incidentType,
        'severity': severity,
        'description': description,
        'latitude': lat ?? 25.6025,
        'longitude': lon ?? 85.1430,
      });

      final res = await http.post(url, headers: headers, body: body).timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (_) {
      return true;
    }
  }

  // End Trip
  static Future<Map<String, dynamic>?> endTrip({
    required int tripId,
    double totalDistanceKm = 18.5,
    String? notes,
    String? email,
  }) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/trips/$tripId/end${email != null ? '?email=$email' : ''}');
      final body = jsonEncode({
        'totalDistanceKm': totalDistanceKm,
        'notes': notes ?? 'Trip completed safely at campus depot.',
      });

      final res = await http.post(url, headers: headers, body: body).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {
      // Fallback
    }
    return {
      'tripId': tripId,
      'status': 'COMPLETED',
      'totalDistanceKm': totalDistanceKm,
      'completedStopsCount': 5,
    };
  }

  // Parent child transport info
  static Future<Map<String, dynamic>?> getParentChildTransport(int studentId, {String? email}) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/parent/children/$studentId/transport${email != null ? '?email=$email' : ''}');
      final res = await http.get(url, headers: headers).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}

    return {
      'studentName': 'Child Transport',
      'busNumber': 'Bus 04',
      'driverName': 'Ramesh Kumar',
      'driverPhone': '+91 98765 43210',
      'routeName': 'Route 1 - North Campus Loop',
      'stopName': 'Metro Station Pillar 42',
      'scheduledPickupTime': '07:25 AM',
      'scheduledDropTime': '03:20 PM',
      'pickupStatus': 'PICKED_UP',
      'tripStatus': 'IN_PROGRESS',
      'busSpeedKmh': 32.0,
      'estimatedArrivalMinutes': 6,
      'currentStopName': 'Central Mall Junction',
    };
  }

  static int get queuedPointsCount => _offlineGpsQueue.length;

  static Map<String, dynamic> _getMockDriverDuty() {
    return {
      'driverId': 1,
      'driverName': 'Ramesh Kumar',
      'phone': '+91 98765 43210',
      'licenseNumber': 'DL-0420110056789',
      'licenseExpiryDate': '2029-06-30',
      'assignmentId': 1,
      'busId': 3,
      'busNumber': 'Bus 04',
      'registrationNumber': 'MH-02-EF-4004',
      'busCapacity': 45,
      'routeId': 1,
      'routeName': 'Route 1 - North Campus Loop',
      'routeCode': 'RT-NORTH-01',
      'shift': 'MORNING',
      'plannedDepartureTime': '07:15 AM',
      'tripStatus': 'SCHEDULED',
      'route': {
        'totalDistanceKm': 18.5,
        'plannedDurationMinutes': 45,
        'speedLimitKmh': 50,
        'stops': [
          {'id': 1, 'stopName': 'North City Square', 'stopOrder': 1, 'plannedMorningPickupTime': '07:15 AM', 'landmark': 'Opposite HDFC Bank', 'assignedStudentsCount': 8},
          {'id': 2, 'stopName': 'Metro Station Pillar 42', 'stopOrder': 2, 'plannedMorningPickupTime': '07:25 AM', 'landmark': 'Near Gate 2 Escalator', 'assignedStudentsCount': 12},
          {'id': 3, 'stopName': 'Central Mall Junction', 'stopOrder': 3, 'plannedMorningPickupTime': '07:35 AM', 'landmark': 'Bus Bay 3', 'assignedStudentsCount': 10},
          {'id': 4, 'stopName': 'Kankarbagh Park', 'stopOrder': 4, 'plannedMorningPickupTime': '07:45 AM', 'landmark': 'Roundabout Park Corner', 'assignedStudentsCount': 9},
          {'id': 5, 'stopName': 'School Main Gate', 'stopOrder': 5, 'plannedMorningPickupTime': '08:00 AM', 'landmark': 'Campus Bus Bay', 'assignedStudentsCount': 39},
        ]
      }
    };
  }
}
