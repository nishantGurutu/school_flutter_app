import 'dart:async';
import '../utils/app_url.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/storage/local_storage.dart';

class TransportService {
  static const String baseUrl = '${AppUrl.baseUrl}/v1/transport';
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
      // The caller displays a connection error.
    }
    return null;
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
        'startLatitude': startLat,
        'startLongitude': startLon,
        'preTripCheckPassed': preTripCheckPassed,
        'preTripNotes': preTripNotes,
      });

      final res = await http.post(url, headers: headers, body: body).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200 || res.statusCode == 201) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {
      // A failed request must never create a local trip.
    }
    return null;
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
      return false;
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
        'latitude': lat,
        'longitude': lon,
      });

      final res = await http.post(url, headers: headers, body: body).timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // End Trip
  static Future<Map<String, dynamic>?> endTrip({
    required int tripId,
    double totalDistanceKm = 0,
    String? notes,
    String? email,
  }) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/trips/$tripId/end${email != null ? '?email=$email' : ''}');
      final body = jsonEncode({
        'totalDistanceKm': totalDistanceKm,
        'notes': notes,
      });

      final res = await http.post(url, headers: headers, body: body).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {
      // Fallback
    }
    return null;
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

    return null;
  }

  static int get queuedPointsCount => _offlineGpsQueue.length;

}
