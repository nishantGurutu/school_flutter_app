import 'package:dio/dio.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'location_local_data_source.dart';
import 'location_tracker.dart';
import 'location_upload_scheduler.dart';
import '../repositories/location_tracking_repository_impl.dart';

/// Dependencies are created separately inside the service isolate.
class BackgroundServiceLocator {
  late SharedPreferences _prefs;
  late LocationTrackingRepositoryImpl _repository;
  late LocationTracker _tracker;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _prefs.reload();
    final baseUrl = _prefs.getString('location_tracking_base_url') ?? '';
    final uploadUrl = _prefs.getString('location_tracking_upload_url') ?? '';
    if (baseUrl.isEmpty || uploadUrl.isEmpty || empId <= 0) {
      throw StateError('Location tracking configuration is missing.');
    }
    _repository = LocationTrackingRepositoryImpl(
      dioClient: Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      ),
      localDataSource: LocationLocalDataSource(
        _prefs,
        queueKey:
            'location_tracking_queue_${empId}_${Uri.encodeComponent(companyCode)}',
      ),
      uploadUrl: uploadUrl,
    );
    _tracker = LocationTracker();
  }

  LocationUploadScheduler createScheduler(ServiceInstance service) =>
      LocationUploadScheduler(
        tracker: _tracker,
        repository: _repository,
        serviceInstance: service,
      );

  int get empId => _prefs.getInt('location_tracking_emp_id') ?? 0;
  String get companyCode =>
      _prefs.getString('location_tracking_company_code') ?? '';
  String get token => _prefs.getString('location_tracking_token') ?? '';
  String get deviceId => _prefs.getString('location_tracking_device_id') ?? '';
}
