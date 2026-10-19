import 'dart:async';
import 'dart:io';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:school_desk_app/data/network/base_api_services.dart';
import 'package:school_desk_app/services/storage/local_storage.dart';
import 'package:school_desk_app/utils/app_url.dart';

import '../exception/app_exceptions.dart';

class NetworkApiService implements BaseApiServices {
  late final Dio _dio;
  late final Dio _refreshDio;
  Completer<String?>? _refreshTokenCompleter;

  NetworkApiService({Dio? dio, Dio? refreshDio}) {
    _dio =
        dio ??
        Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 20),
            sendTimeout: const Duration(seconds: 20),
            responseType: ResponseType.json,
            validateStatus: (status) => status != null && status < 500,
          ),
        );

    _refreshDio =
        refreshDio ??
        Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            responseType: ResponseType.json,
          ),
        );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await StorageHelper.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
            options.headers['token'] = token;
          }
          options.headers['Content-Type'] = options.data is FormData
              ? 'multipart/form-data'
              : 'application/json';

          if (kDebugMode) {
            print("\n==========================================");
            print("➡️ API REQUEST [${options.method}] => ${options.uri}");
            print("Headers: ${_redact(options.headers)}");
            if (options.data != null) print("Body: ${_redact(options.data)}");
            print("==========================================\n");
          }
          handler.next(options);
        },
        onResponse: (response, handler) async {
          if (kDebugMode) {
            log(
              "✅ API RESPONSE [${response.statusCode}] ${response.requestOptions.uri} => ${_redact(response.data)}",
            );
          }

          if (response.statusCode == 401) {
            try {
              final retry = await _retryUnauthorized(response.requestOptions);
              if (retry != null) return handler.resolve(retry);
            } on DioException catch (error) {
              return handler.reject(error);
            }
          }

          handler.next(response);
        },
        onError: (DioException e, handler) async {
          if (kDebugMode) {
            print(
              "❌ API ERROR [${e.response?.statusCode ?? 'NETWORK_ERR'}] ${e.requestOptions.uri} => ${e.message}",
            );
            if (e.response != null) {
              print("Error Details: ${_redact(e.response?.data)}");
            }
          }

          if (e.response?.statusCode == 401) {
            try {
              final retry = await _retryUnauthorized(e.requestOptions);
              if (retry != null) return handler.resolve(retry);
            } on DioException catch (error) {
              return handler.next(error);
            }
          }

          handler.next(e);
        },
      ),
    );
  }

  static const _authRetryKey = 'auth_retry_attempted';

  Future<Response<dynamic>?> _retryUnauthorized(RequestOptions request) async {
    if (request.extra[_authRetryKey] == true ||
        request.path.contains('/auth/login') ||
        request.path.contains('/auth/refresh')) {
      return null;
    }
    // Another request may already have refreshed this expired access token.
    final storedToken = await StorageHelper.getAccessToken();
    final token =
        storedToken != null &&
            storedToken.isNotEmpty &&
            request.headers['Authorization'] != 'Bearer $storedToken'
        ? storedToken
        : await _handleTokenRefresh();
    if (token == null || token.isEmpty) return null;
    return _dio.fetch<dynamic>(
      request.copyWith(
        headers: {
          ...request.headers,
          'Authorization': 'Bearer $token',
          'token': token,
        },
        extra: {...request.extra, _authRetryKey: true},
      ),
    );
  }

  static dynamic _redact(dynamic value) {
    if (value is Map) {
      return value.map(
        (key, item) => MapEntry(
          key,
          const {
                'authorization',
                'token',
                'accesstoken',
                'refreshtoken',
                'password',
              }.contains(key.toString().toLowerCase())
              ? '[redacted]'
              : _redact(item),
        ),
      );
    }
    if (value is List) return value.map(_redact).toList();
    return value;
  }

  /// Share one refresh among concurrent requests, and always release waiters.
  Future<String?> _handleTokenRefresh() async {
    final pending = _refreshTokenCompleter;
    if (pending != null) return pending.future;
    final completer = Completer<String?>();
    _refreshTokenCompleter = completer;
    String? token;
    try {
      final refreshToken = await StorageHelper.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) return null;
      final response = await _refreshDio.post(
        AppUrl.refresh,
        data: {'refreshToken': refreshToken},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data is Map) {
        final data = response.data as Map;
        final access = data['accessToken'] ?? data['token'];
        if (access != null && access.toString().isNotEmpty) {
          token = access.toString();
          await StorageHelper.setAccessToken(token);
          if (data['refreshToken'] != null) {
            await StorageHelper.setRefreshToken(
              data['refreshToken'].toString(),
            );
          }
          final expiresAt = int.tryParse(data['expiresAt']?.toString() ?? '');
          if (expiresAt != null) await StorageHelper.setExpiresAt(expiresAt);
        }
      } else if ([400, 401, 403].contains(response.statusCode)) {
        await StorageHelper.clear();
      }
      return token;
    } on DioException catch (error) {
      // A temporary network failure must not erase an offline driver's session.
      if ([400, 401, 403].contains(error.response?.statusCode)) {
        await StorageHelper.clear();
      }
      return null;
    } catch (_) {
      return null;
    } finally {
      completer.complete(token);
      _refreshTokenCompleter = null;
    }
  }

  @override
  Future<dynamic> getApi(String url) async {
    try {
      final response = await _dio.get(url);
      return _returnResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } on SocketException {
      throw NoInternetException('No Internet Connection');
    }
  }

  @override
  Future<dynamic> postApi(String url, dynamic data) async {
    try {
      final response = await _dio.post(url, data: data);
      return _returnResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } on SocketException {
      throw NoInternetException('No Internet Connection');
    }
  }

  @override
  Future<dynamic> putApi(String url, dynamic data) async {
    try {
      final response = await _dio.put(url, data: data);
      return _returnResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } on SocketException {
      throw NoInternetException('No Internet Connection');
    }
  }

  @override
  Future<dynamic> patchApi(String url, dynamic data) async {
    try {
      final response = await _dio.patch(url, data: data);
      return _returnResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } on SocketException {
      throw NoInternetException('No Internet Connection');
    }
  }

  @override
  Future<dynamic> deleteApi(String url) async {
    try {
      final response = await _dio.delete(url);
      return _returnResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } on SocketException {
      throw NoInternetException('No Internet Connection');
    }
  }

  dynamic _returnResponse(Response response) {
    switch (response.statusCode) {
      case 200:
      case 201:
      case 204:
        return response.data;
      case 400:
        throw BadRequestException(
          _extractErrorMessage(response, "Invalid request"),
        );
      case 401:
      case 403:
        throw UnauthorisedException(
          _extractErrorMessage(
            response,
            "Invalid credentials or unauthorized access",
          ),
        );
      case 404:
        throw FetchDataException(
          _extractErrorMessage(response, "API Resource not found"),
        );
      case 500:
        throw FetchDataException(
          _extractErrorMessage(response, "Internal Server Error"),
        );
      default:
        throw FetchDataException(
          _extractErrorMessage(
            response,
            "HTTP Error status code: ${response.statusCode}",
          ),
        );
    }
  }

  String _extractErrorMessage(Response response, String fallback) {
    if (response.data is Map) {
      final data = response.data as Map;
      if (data['error'] != null && data['error'].toString().isNotEmpty) {
        return data['error'].toString();
      }
      if (data['message'] != null && data['message'].toString().isNotEmpty) {
        return data['message'].toString();
      }
      if (data['detail'] != null && data['detail'].toString().isNotEmpty) {
        return data['detail'].toString();
      }
    } else if (response.data is String &&
        (response.data as String).isNotEmpty) {
      return response.data as String;
    }
    return fallback;
  }

  Exception _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return FetchDataException("Request timeout");
      case DioExceptionType.connectionError:
        return NoInternetException("No Internet connection");
      case DioExceptionType.badResponse:
        return FetchDataException(
          error.response == null
              ? 'Request failed'
              : _extractErrorMessage(error.response!, 'Request failed'),
        );
      default:
        return FetchDataException("Unexpected network error occurred");
    }
  }
}
