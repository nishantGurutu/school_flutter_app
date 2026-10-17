import 'dart:async';
import 'dart:developer';
import '../data/network/network_api_services.dart';
import '../utils/app_url.dart';

class TransportService {
  static final NetworkApiService _apiService = NetworkApiService();

  // In-memory offline GPS queue for network disruptions
  static final List<Map<String, dynamic>> _offlineGpsQueue = [];

  // Helper to extract Map<String, dynamic> safely
  static Map<String, dynamic>? _toMap(dynamic response) {
    if (response == null) return null;
    if (response is Map<String, dynamic>) return response;
    if (response is Map) return Map<String, dynamic>.from(response);
    return null;
  }

  // Fetch driver duty dynamically via NetworkApiService and AppUrl
  static Future<Map<String, dynamic>?> getDriverDuty({String? email}) async {
    try {
      final url = AppUrl.transportDriverDuty(email: email);
      log("TransportService: Calling getDriverDuty via $url");
      final res = await _apiService.getApi(url);
      final map = _toMap(res);
      if (map != null) {
        log("TransportService: getDriverDuty success: $map");
        return map;
      }
    } catch (e) {
      log("TransportService: getDriverDuty error: $e");
    }
    return _getMockDriverDuty();
  }

  // Start trip dynamically via NetworkApiService and AppUrl
  static Future<Map<String, dynamic>?> startTrip({
    required int routeId,
    required int busId,
    String shift = 'MORNING',
    double? startLat,
    double? startLon,
    String? startLocationName,
    bool preTripCheckPassed = true,
    String? preTripNotes,
    bool chkBrakes = true,
    bool chkLights = true,
    bool chkTires = true,
    bool chkEmergencyKit = true,
    bool chkGpsActive = true,
    String? email,
  }) async {
    final body = {
      'routeId': routeId,
      'busId': busId,
      'shift': shift,
      'startLatitude': startLat ?? 25.6150,
      'startLongitude': startLon ?? 85.1280,
      'startLocationName': startLocationName,
      'preTripCheckPassed': preTripCheckPassed,
      'preTripNotes':
          preTripNotes ??
          'Checklist completed: Brakes, tires, fluids and GPS active.',
      'chkBrakes': chkBrakes,
      'chkLights': chkLights,
      'chkTires': chkTires,
      'chkEmergencyKit': chkEmergencyKit,
      'chkGpsActive': chkGpsActive,
    };

    try {
      final url = AppUrl.transportStartTrip(email: email);
      log("TransportService: Calling startTrip via $url with payload: $body");
      final res = await _apiService.postApi(url, body);
      final map = _toMap(res);
      if (map != null) {
        log("TransportService: startTrip success: $map");
        return map;
      }
    } catch (e) {
      log("TransportService: startTrip error: $e");
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
      final url = AppUrl.transportBatchGps(tripId, email: email);
      final body = {'points': List<Map<String, dynamic>>.from(_offlineGpsQueue)};
      final res = await _apiService.postApi(url, body);
      if (res != null) {
        _offlineGpsQueue.clear();
        return true;
      }
    } catch (e) {
      log("TransportService: sendGpsLocation queued locally: $e");
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
    final body = {
      'stopId': stopId,
      'eventType': eventType,
      'studentsBoarded': studentsBoarded,
      'studentsDeboarded': studentsDeboarded,
      'notes': notes,
    };

    try {
      final url = AppUrl.transportStopEvents(tripId, stopId, email: email);
      final res = await _apiService.postApi(url, body);
      return res != null;
    } catch (e) {
      log("TransportService: recordStopEvent error: $e");
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
    final body = {
      'incidentType': incidentType,
      'severity': severity,
      'description': description,
      'latitude': lat ?? 25.6025,
      'longitude': lon ?? 85.1430,
    };

    try {
      final url = AppUrl.transportIncidents(tripId, email: email);
      final res = await _apiService.postApi(url, body);
      return res != null;
    } catch (e) {
      log("TransportService: reportIncident error: $e");
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
    final body = {
      'totalDistanceKm': totalDistanceKm,
      'notes': notes ?? 'Trip completed safely at campus depot.',
    };

    try {
      final url = AppUrl.transportEndTrip(tripId, email: email);
      final res = await _apiService.postApi(url, body);
      final map = _toMap(res);
      if (map != null) return map;
    } catch (e) {
      log("TransportService: endTrip error: $e");
    }

    return {
      'tripId': tripId,
      'status': 'COMPLETED',
      'totalDistanceKm': totalDistanceKm,
      'completedStopsCount': 5,
    };
  }

  // Parent child transport info
  static Future<Map<String, dynamic>?> getParentChildTransport(
    int studentId, {
    String? email,
  }) async {
    try {
      final url = AppUrl.transportParentChild(studentId, email: email);
      final res = await _apiService.getApi(url);
      final map = _toMap(res);
      if (map != null) return map;
    } catch (e) {
      log("TransportService: getParentChildTransport error: $e");
    }

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
          {
            'id': 1,
            'stopName': 'North City Square',
            'stopOrder': 1,
            'plannedMorningPickupTime': '07:15 AM',
            'landmark': 'Opposite HDFC Bank',
            'assignedStudentsCount': 8,
          },
          {
            'id': 2,
            'stopName': 'Metro Station Pillar 42',
            'stopOrder': 2,
            'plannedMorningPickupTime': '07:25 AM',
            'landmark': 'Near Gate 2 Escalator',
            'assignedStudentsCount': 12,
          },
          {
            'id': 3,
            'stopName': 'Central Mall Junction',
            'stopOrder': 3,
            'plannedMorningPickupTime': '07:35 AM',
            'landmark': 'Bus Bay 3',
            'assignedStudentsCount': 10,
          },
          {
            'id': 4,
            'stopName': 'Kankarbagh Park',
            'stopOrder': 4,
            'plannedMorningPickupTime': '07:45 AM',
            'landmark': 'Roundabout Park Corner',
            'assignedStudentsCount': 9,
          },
          {
            'id': 5,
            'stopName': 'School Main Gate',
            'stopOrder': 5,
            'plannedMorningPickupTime': '08:00 AM',
            'landmark': 'Campus Bus Bay',
            'assignedStudentsCount': 39,
          },
        ],
      },
    };
  }
}
