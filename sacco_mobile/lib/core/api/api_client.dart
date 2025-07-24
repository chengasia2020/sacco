// lib/core/api/api_client.dart
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:sacco_mobile/app/app_constants.dart';
import 'package:sacco_mobile/core/api/interceptors/auth_interceptor.dart';
import 'package:sacco_mobile/core/api/interceptors/logging_interceptor.dart';
import 'package:sacco_mobile/core/api/interceptors/cache_interceptor.dart';
import 'package:sacco_mobile/core/api/interceptors/retry_interceptor.dart';
import 'package:sacco_mobile/core/api/interceptors/analytics_interceptor.dart';
import 'package:sacco_mobile/core/errors/app_error.dart';
import 'package:sacco_mobile/core/services/connectivity_service.dart';
import 'package:sacco_mobile/core/services/cache_service.dart';

class ApiClient {
  late final Dio _dio;
  final ConnectivityService _connectivityService;
  final CacheService? _cacheService;
  late final AnalyticsInterceptor _analyticsInterceptor;

  ApiClient(this._connectivityService, [this._cacheService]) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: Duration(seconds: AppConstants.requestTimeoutSeconds),
        receiveTimeout: Duration(seconds: AppConstants.requestTimeoutSeconds),
        sendTimeout: Duration(seconds: AppConstants.requestTimeoutSeconds),
        contentType: 'application/json',
        responseType: ResponseType.json,
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    _setupInterceptors();
  }

  void _setupInterceptors() {
    // Order matters! Interceptors are executed in the order they are added
    
    // 1. Analytics interceptor (first to capture all requests)
    if (_cacheService != null) {
      _analyticsInterceptor = AnalyticsInterceptor(_cacheService!);
      _dio.interceptors.add(_analyticsInterceptor);
    }

    // 2. Auth interceptor (add auth headers)
    _dio.interceptors.add(AuthInterceptor());

    // 3. Cache interceptor (serve cached responses if available)
    if (_cacheService != null) {
      _dio.interceptors.add(CacheInterceptor(_cacheService!));
    }

    // 4. Retry interceptor with circuit breaker (handle failures)
    _dio.interceptors.add(CircuitBreakerRetryInterceptor(
      maxRetries: 3,
      baseDelay: const Duration(milliseconds: 1000),
      maxDelay: const Duration(seconds: 30),
      circuitBreakerWindow: const Duration(minutes: 5),
      failureThreshold: 5,
      circuitBreakerCooldown: const Duration(minutes: 1),
    ));

    // 5. Logging interceptor (log requests/responses for debugging)
    _dio.interceptors.add(LoggingInterceptor());
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    await _checkConnectivity();

    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw AppError(
        message: AppConstants.genericErrorMessage,
        originalError: e.toString(),
      );
    }
  }

  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    await _checkConnectivity();

    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw AppError(
        message: AppConstants.genericErrorMessage,
        originalError: e.toString(),
      );
    }
  }

  Future<dynamic> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    await _checkConnectivity();

    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw AppError(
        message: AppConstants.genericErrorMessage,
        originalError: e.toString(),
      );
    }
  }

  Future<dynamic> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    await _checkConnectivity();

    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw AppError(
        message: AppConstants.genericErrorMessage,
        originalError: e.toString(),
      );
    }
  }

  // Check for connectivity before making a request
  Future<void> _checkConnectivity() async {
    final isConnected = await _connectivityService.isConnected();
    if (!isConnected) {
      throw AppError(
        message: AppConstants.networkErrorMessage,
        originalError: 'No internet connection',
        statusCode: 0,
      );
    }
  }

  AppError _handleError(DioException error) {
    if (error.error is SocketException) {
      return AppError(
        message: AppConstants.networkErrorMessage,
        originalError: error.toString(),
        statusCode: 0,
      );
    }

    int statusCode = error.response?.statusCode ?? 0;
    String message = '';

    try {
      // Try to parse error message from response
      if (error.response?.data != null) {
        final responseData = error.response?.data;
        if (responseData is Map<String, dynamic> &&
            responseData.containsKey('error')) {
          message = responseData['error'];
        } else if (responseData is String) {
          // Try to parse JSON string
          final Map<String, dynamic> jsonData = json.decode(responseData);
          if (jsonData.containsKey('error')) {
            message = jsonData['error'];
          }
        }
      }
    } catch (_) {
      // If can't parse error message, use default
      message = error.message ?? AppConstants.genericErrorMessage;
    }

    // Handle specific status codes
    switch (statusCode) {
      case 401:
        return AppError(
          message: 'Unauthorized. Please login again.',
          originalError: error.toString(),
          statusCode: statusCode,
        );
      case 403:
        return AppError(
          message: 'You do not have permission to access this resource.',
          originalError: error.toString(),
          statusCode: statusCode,
        );
      case 404:
        return AppError(
          message: 'Resource not found.',
          originalError: error.toString(),
          statusCode: statusCode,
        );
      case 500:
        return AppError(
          message: 'Server error. Please try again later.',
          originalError: error.toString(),
          statusCode: statusCode,
        );
      default:
        return AppError(
          message:
              message.isNotEmpty ? message : AppConstants.genericErrorMessage,
          originalError: error.toString(),
          statusCode: statusCode,
        );
    }
  }

  // Utility methods for cache control
  Future<dynamic> getWithCacheControl(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool forceRefresh = false,
    Duration? cacheTimeout,
  }) async {
    final options = Options();
    
    if (forceRefresh) {
      options.headers = {'Cache-Control': 'no-cache'};
    }
    
    if (cacheTimeout != null) {
      options.headers = {
        ...?options.headers,
        'Cache-Timeout': cacheTimeout.inSeconds.toString(),
      };
    }

    return get(path, queryParameters: queryParameters, options: options);
  }

  // Analytics methods
  Map<String, dynamic>? getAnalyticsSummary({Duration? period}) {
    return _cacheService != null 
        ? _analyticsInterceptor.getAnalyticsSummary(period: period)
        : null;
  }

  Future<void> clearAnalytics() async {
    if (_cacheService != null) {
      await _analyticsInterceptor.clearAnalytics();
    }
  }

  // Initialize analytics (load persisted events)
  Future<void> initializeAnalytics() async {
    if (_cacheService != null) {
      await _analyticsInterceptor.loadPersistedEvents();
    }
  }

  // Upload file with progress tracking
  Future<dynamic> uploadFile(
    String path,
    File file, {
    String fieldName = 'file',
    Map<String, dynamic>? data,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    await _checkConnectivity();

    try {
      final formData = FormData();
      
      // Add file
      formData.files.add(
        MapEntry(
          fieldName,
          await MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
        ),
      );

      // Add other data
      if (data != null) {
        data.forEach((key, value) {
          formData.fields.add(MapEntry(key, value.toString()));
        });
      }

      final response = await _dio.post(
        path,
        data: formData,
        onSendProgress: onSendProgress,
      );

      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw AppError(
        message: AppConstants.genericErrorMessage,
        originalError: e.toString(),
      );
    }
  }

  // Download file with progress tracking
  Future<void> downloadFile(
    String url,
    String savePath, {
    void Function(int received, int total)? onReceiveProgress,
    Map<String, dynamic>? queryParameters,
  }) async {
    await _checkConnectivity();

    try {
      await _dio.download(
        url,
        savePath,
        queryParameters: queryParameters,
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw AppError(
        message: 'Failed to download file',
        originalError: e.toString(),
      );
    }
  }

  // Cancel requests
  void cancelRequests() {
    _dio.close(force: true);
  }
}
