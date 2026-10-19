import 'package:dio/dio.dart';

import '../../domain/repositories/location_tracking_repository.dart';
import '../datasources/location_local_data_source.dart';
import '../models/periodic_location_payload.dart';

/// Implements [LocationTrackingRepository] using [Dio].
///
/// Responsibilities:
/// - Coordinate API uploads via [Dio].
/// - Delegate offline queue management to [LocationLocalDataSource].
class LocationTrackingRepositoryImpl implements LocationTrackingRepository {
  LocationTrackingRepositoryImpl({
    required Dio dioClient,
    required LocationLocalDataSource localDataSource,
    required String uploadUrl,
  }) : _dioClient = dioClient,
       _localDataSource = localDataSource,
       _uploadUrl = uploadUrl.trim();

  final Dio _dioClient;
  final LocationLocalDataSource _localDataSource;
  final String _uploadUrl;

  /// Offline-first upload:
  /// - Offline tick: the POST throws -> current payload is appended to the
  ///   local queue ([LocationLocalDataSource]).
  /// - Online tick: queued payloads + current payload are sent as one array;
  ///   on success the local queue is deleted.
  @override
  Future<void> uploadLocation({
    required int empId,
    required String companyCode,
    required String token,
    required PeriodicLocationPayload payload,
  }) async {
    if (_uploadUrl.isEmpty) {
      throw StateError('Background location upload URL is missing.');
    }
    await _localDataSource.enqueue(payload);
    final uploadList = _localDataSource.getQueue();
    await _dioClient.post<void>(
      _uploadUrl,
      data: uploadList,
      options: Options(headers: {'token': token}),
    );
    await _localDataSource.clearQueue();
  }
}
