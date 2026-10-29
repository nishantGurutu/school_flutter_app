import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// This address stays fixed when the selected API server changes.
class RuntimeEnvironment {
  static const configBaseUrl = String.fromEnvironment(
    'CONFIG_BASE_URL',
    defaultValue: 'http://10.103.180.61:8080/api',
  );
  static const _defaultApiUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: configBaseUrl,
  );
  static String baseUrl = _defaultApiUrl;
  static final _client = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
    ),
  );
  static const _storage = FlutterSecureStorage();
  static const _cacheKey = 'runtime_api_base_url:$configBaseUrl';
  static bool _hasSelection = false;
  static DateTime? _lastCheck;
  static Future<void>? _pending;
  static Timer? _timer;
  static final Set<String> _knownUrls = {
    _defaultApiUrl,
    'https://school-springboot-backend.onrender.com/api',
  };

  static String _validate(dynamic value) {
    final uri = Uri.parse(value as String);
    if (!['http', 'https'].contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw const FormatException('Invalid API URL');
    }
    return value.replaceFirst(RegExp(r'/+$'), '');
  }

  static Future<void> initialize() async {
    try {
      final cached = await _storage.read(key: _cacheKey);
      if (cached != null) {
        baseUrl = _validate(cached);
        _hasSelection = true;
        _knownUrls.add(baseUrl);
      }
    } catch (_) {
      /* Use build default if secure storage is unavailable. */
    }
    await refresh();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      unawaited(refresh());
    });
  }

  static Future<void> refresh({bool force = false, Dio? client}) {
    if (_pending != null) return _pending!;
    if (!force &&
        _lastCheck != null &&
        DateTime.now().difference(_lastCheck!) < const Duration(seconds: 15)) {
      return Future.value();
    }
    return _pending = _load(client ?? _client).whenComplete(() {
      _pending = null;
      _lastCheck = DateTime.now();
    });
  }

  static Future<void> _load(Dio client) async {
    try {
      final response = await client.get(
        '${configBaseUrl.replaceFirst(RegExp(r'/+$'), '')}/runtime-config',
        options: Options(headers: {'Cache-Control': 'no-cache'}),
      );
      final next = _validate(response.data['activeUrl']);
      _knownUrls.add(baseUrl);
      _knownUrls.add(next);
      baseUrl = next;
      _hasSelection = true;
      await _storage.write(key: _cacheKey, value: next);
    } catch (_) {
      /* Keep the last known URL during a configuration-server outage. */
    }
  }

  static Future<void> prepareLogin() async {
    await refresh(force: true);
    if (!_hasSelection) {
      throw StateError(
        'Unable to load saved API settings from $configBaseUrl. Check the configuration server connection.',
      );
    }
  }

  static String resolve(String url) {
    for (final old in _knownUrls) {
      if (url == old || url.startsWith('$old/')) {
        return '$baseUrl${url.substring(old.length)}';
      }
    }
    return url;
  }
}
