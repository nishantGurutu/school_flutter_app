import 'driver_location_gate.dart';
import 'dart:async';
import 'dart:developer';
import '../data/network/network_api_services.dart';
import '../utils/app_url.dart';
import '../location_tracking/data/datasources/location_service.dart';
import '../location_tracking/data/trip_completion_coordinator.dart';
import '../data/models/user_model.dart';
import 'storage/local_storage.dart';

class TransportService {
  static final NetworkApiService _apiService = NetworkApiService();

  static final _completion = TripCompletionCoordinator(
    store: LocationService.store,
    stopTracking: LocationService.stop,
    upload: (tripId, body) async {
      final user = await StorageHelper.getUserSession();
      final email = user?.email;
      return _toMap(
        await _apiService.postApi(
          AppUrl.transportEndTrip(tripId, email: email),
          {
            ...body,
            if (email != null && email.isNotEmpty) 'driverEmail': email,
          },
        ),
      );
    },
  );

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
    return null;
  }

  // Start trip dynamically via NetworkApiService and AppUrl
  static Future<Map<String, dynamic>?> startTrip({
    required int routeId,
    required int busId,
    String? driverEmail,
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
  }) async {
    final body = {
      'routeId': routeId,
      'busId': busId,
      if (driverEmail != null && driverEmail.isNotEmpty)
        'driverEmail': driverEmail,
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
      await DriverLocationGate.requireReady();
      final url = AppUrl.transportStartTrip(email: driverEmail);
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

    return null;
  }

  /// Latest position only, held in server memory; no history database write.
  static Future<void> publishLiveLocation(
    int tripId,
    Map<String, dynamic> point, {
    String? email,
  }) async {
    await _apiService.postApi(
      AppUrl.transportLiveLocation(tripId, email: email),
      point,
    );
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
    final body = {
      'incidentType': incidentType,
      'severity': severity,
      'description': description,
      'latitude': lat,
      'longitude': lon,
    };

    try {
      final url = AppUrl.transportIncidents(tripId, email: email);
      final res = await _apiService.postApi(url, body);
      return res != null;
    } catch (e) {
      log("TransportService: reportIncident error: $e");
      return false;
    }
  }

  /// Freeze GPS locally first, then save points and complete the trip atomically.
  /// A retry uses the same SQLite batch; server completion is idempotent.
  static Future<Map<String, dynamic>> endTrip({
    required int tripId,
    double? totalDistanceKm,
    String? notes,
    String? email,
  }) async {
    final user = await StorageHelper.getUserSession();
    if (user?.role != UserRole.driver) {
      throw StateError('Only the signed-in driver can complete this trip.');
    }
    await DriverLocationGate.requireReady();
    return _completion.complete(
      tripId: tripId,
      driverEmail: user!.email,
      distanceKm: totalDistanceKm,
      notes: notes,
    );
  }

  // Parent child transport info
  static Future<Map<String, dynamic>> getStudentTransport() async {
    final res = await _apiService.getApi(AppUrl.transportStudentMyTransport());
    final data = _toMap(res);
    if (data == null) throw StateError('Invalid transport response');
    return data;
  }

  static Future<Map<String, dynamic>> getParentChildTransport(
    int studentId, {
    String? email,
  }) async {
    final res = await _apiService.getApi(
      AppUrl.transportParentChild(studentId),
    );
    final data = _toMap(res);
    if (data == null) throw StateError('Invalid transport response');
    return data;
  }
}
