import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/periodic_location_payload.dart';

/// Handles local persistence of location upload queue.
///
/// Single Responsibility: only manages offline queue read/write.
class LocationLocalDataSource {
  final String _offlineQueueKey;

  final SharedPreferences _prefs;

  LocationLocalDataSource(
    this._prefs, {
    String queueKey = 'location_tracking_offline_queue',
  }) : _offlineQueueKey = queueKey;

  /// Returns the current offline queue.
  List<Map<String, dynamic>> getQueue() {
    final queueJson = _prefs.getString(_offlineQueueKey);
    if (queueJson == null || queueJson.isEmpty) return [];

    final List<dynamic> decoded = jsonDecode(queueJson);
    return decoded
        .map((item) {
          if (item is Map<String, dynamic>) return item;
          if (item is Map) return Map<String, dynamic>.from(item);
          return <String, dynamic>{};
        })
        .where((item) => item.isNotEmpty)
        .toList();
  }

  /// Appends a single payload to the queue.
  Future<void> enqueue(PeriodicLocationPayload payload) async {
    final queue = getQueue();
    queue.add(payload.toJson());
    await _saveQueue(queue);
  }

  /// Replaces the entire queue.
  Future<void> saveQueue(List<Map<String, dynamic>> queue) async {
    await _saveQueue(queue);
  }

  /// Clears the queue.
  Future<void> clearQueue() async {
    await _prefs.remove(_offlineQueueKey);
  }

  Future<void> _saveQueue(List<Map<String, dynamic>> queue) async {
    await _prefs.setString(_offlineQueueKey, jsonEncode(queue));
  }
}
