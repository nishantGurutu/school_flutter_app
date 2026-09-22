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

  NetworkApiService() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
        responseType: ResponseType.json,
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    _refreshDio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        responseType: ResponseType.json,
      ),
    );

    _dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await StorageHelper.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
            options.headers['token'] = token;
          }
          options.headers['Content-Type'] = 'application/json';

          if (kDebugMode) {
            print("\n==========================================");
            print("➡️ API REQUEST [${options.method}] => ${options.uri}");
            print("Headers: ${options.headers}");
            if (options.data != null) print("Body: ${options.data}");
            print("==========================================\n");
          }
          handler.next(options);
        },
        onResponse: (response, handler) async {
          if (kDebugMode) {
            log("✅ API RESPONSE [${response.statusCode}] ${response.requestOptions.uri} => ${response.data}");
          }

          // Handle 401 Unauthorized for token refresh
          if (response.statusCode == 401) {
            final path = response.requestOptions.path;
            if (!path.contains('/auth/login') && !path.contains('/auth/refresh')) {
              try {
                final newToken = await _handleTokenRefresh();
                if (newToken != null && newToken.isNotEmpty) {
                  final options = response.requestOptions;
                  options.headers['Authorization'] = 'Bearer $newToken';
                  options.headers['token'] = newToken;

                  final retryResponse = await _dio.fetch(options);
                  return handler.resolve(retryResponse);
                }
              } catch (e) {
                if (kDebugMode) {
                  print("❌ Refresh token error during 401 retry: $e");
                }
              }
            }
          }

          handler.next(response);
        },
        onError: (DioException e, handler) async {
          if (kDebugMode) {
            print("❌ API ERROR [${e.response?.statusCode ?? 'NETWORK_ERR'}] ${e.requestOptions.uri} => ${e.message}");
            if (e.response != null) print("Error Details: ${e.response?.data}");
          }

          if (e.response?.statusCode == 401) {
            final path = e.requestOptions.path;
            if (!path.contains('/auth/login') && !path.contains('/auth/refresh')) {
              try {
                final newToken = await _handleTokenRefresh();
                if (newToken != null && newToken.isNotEmpty) {
                  final options = e.requestOptions;
                  options.headers['Authorization'] = 'Bearer $newToken';
                  options.headers['token'] = newToken;

                  final retryResponse = await _dio.fetch(options);
                  return handler.resolve(retryResponse);
                }
              } catch (_) {}
            }
          }

          handler.next(e);
        },
      ),
    );
  }

  /// Synchronized refresh token execution using a Completer lock
  Future<String?> _handleTokenRefresh() async {
    if (_refreshTokenCompleter != null) {
      return await _refreshTokenCompleter!.future;
    }

    _refreshTokenCompleter = Completer<String?>();

    try {
      final refreshToken = await StorageHelper.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        await StorageHelper.clear();
        _refreshTokenCompleter!.complete(null);
        _refreshTokenCompleter = null;
        return null;
      }

      final response = await _refreshDio.post(
        AppUrl.refresh,
        data: {'refreshToken': refreshToken},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if ((response.statusCode == 200 || response.statusCode == 201) && response.data != null) {
        final data = response.data;
        final newAccessToken = data['accessToken'] ?? data['token'];
        final newRefreshToken = data['refreshToken'];
        final expiresAt = data['expiresAt'];

        if (newAccessToken != null) {
          await StorageHelper.setAccessToken(newAccessToken.toString());
          if (newRefreshToken != null) {
            await StorageHelper.setRefreshToken(newRefreshToken.toString());
          }
          if (expiresAt != null) {
            final expInt = expiresAt is int ? expiresAt : int.tryParse(expiresAt.toString()) ?? 0;
            await StorageHelper.setExpiresAt(expInt);
          }

          _refreshTokenCompleter!.complete(newAccessToken.toString());
          _refreshTokenCompleter = null;
          return newAccessToken.toString();
        }
      }

      await StorageHelper.clear();
      _refreshTokenCompleter!.complete(null);
      _refreshTokenCompleter = null;
      return null;
    } catch (e) {
      await StorageHelper.clear();
      _refreshTokenCompleter!.complete(null);
      _refreshTokenCompleter = null;
      return null;
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
        return response.data;
      case 400:
        throw BadRequestException(_extractErrorMessage(response, "Invalid request"));
      case 401:
      case 403:
        throw UnauthorisedException(_extractErrorMessage(response, "Invalid credentials or unauthorized access"));
      case 404:
        throw FetchDataException(_extractErrorMessage(response, "API Resource not found"));
      case 500:
        throw FetchDataException(_extractErrorMessage(response, "Internal Server Error"));
      default:
        throw FetchDataException(_extractErrorMessage(response, "HTTP Error status code: ${response.statusCode}"));
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
    } else if (response.data is String && (response.data as String).isNotEmpty) {
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
      default:
        return FetchDataException("Unexpected network error occurred");
    }
  }
}


