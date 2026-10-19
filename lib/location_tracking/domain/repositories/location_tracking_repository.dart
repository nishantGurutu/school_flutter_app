import '../../data/models/periodic_location_payload.dart';

abstract class LocationTrackingRepository {
  Future<void> uploadLocation({
    required int empId,
    required String companyCode,
    required String token,
    required PeriodicLocationPayload payload,
  });
}
