// lib/core/api/interceptors/retry_interceptor.dart
import 'dart:math';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class RetryInterceptor extends Interceptor {
  static const int _defaultMaxRetries = 3;
  static const Duration _baseDelay = Duration(milliseconds: 1000);
  static const Duration _maxDelay = Duration(seconds: 30);
  
  // HTTP status codes that should be retried
  static const List<int> _retryableStatusCodes = [
    408, // Request Timeout
    429, // Too Many Requests
    500, // Internal Server Error
    502, // Bad Gateway
    503, // Service Unavailable
    504, // Gateway Timeout
  ];

  // Methods that are safe to retry (idempotent)
  static const List<String> _retryableMethods = [
    'GET',
    'HEAD',
    'OPTIONS',
    'PUT',
    'DELETE',
  ];

  final int maxRetries;
  final Duration baseDelay;
  final Duration maxDelay;
  final List<int> retryableStatusCodes;
  final List<String> retryableMethods;

  RetryInterceptor({
    this.maxRetries = _defaultMaxRetries,
    this.baseDelay = _baseDelay,
    this.maxDelay = _maxDelay,
    this.retryableStatusCodes = _retryableStatusCodes,
    this.retryableMethods = _retryableMethods,
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Check if request is retryable
    if (!_shouldRetry(err)) {
      return handler.next(err);
    }

    // Get current retry count
    final retryCount = err.requestOptions.extra['retryCount'] as int? ?? 0;
    
    // Check if we've exceeded max retries
    if (retryCount >= maxRetries) {
      debugPrint('Retry: Max retries ($maxRetries) exceeded for ${err.requestOptions.path}');
      return handler.next(err);
    }

    // Calculate delay with exponential backoff and jitter
    final delay = _calculateDelay(retryCount);
    
    debugPrint('Retry: Attempting retry ${retryCount + 1}/$maxRetries for ${err.requestOptions.path} after ${delay.inMilliseconds}ms delay');
    
    // Wait before retry
    await Future.delayed(delay);

    try {
      // Update retry count
      err.requestOptions.extra['retryCount'] = retryCount + 1;
      
      // Clone the request options
      final retryOptions = Options(
        method: err.requestOptions.method,
        headers: err.requestOptions.headers,
        extra: err.requestOptions.extra,
        responseType: err.requestOptions.responseType,
        contentType: err.requestOptions.contentType,
        validateStatus: err.requestOptions.validateStatus,
        receiveDataWhenStatusError: err.requestOptions.receiveDataWhenStatusError,
        followRedirects: err.requestOptions.followRedirects,
        maxRedirects: err.requestOptions.maxRedirects,
        persistentConnection: err.requestOptions.persistentConnection,
        requestEncoder: err.requestOptions.requestEncoder,
        responseDecoder: err.requestOptions.responseDecoder,
        listFormat: err.requestOptions.listFormat,
      );

      // Retry the request
      final response = await Dio().request(
        err.requestOptions.path,
        data: err.requestOptions.data,
        queryParameters: err.requestOptions.queryParameters,
        options: retryOptions,
      );

      debugPrint('Retry: Successfully retried ${err.requestOptions.path} on attempt ${retryCount + 1}');
      return handler.resolve(response);
      
    } catch (e) {
      debugPrint('Retry: Retry ${retryCount + 1} failed for ${err.requestOptions.path}: $e');
      
      // If this was our last retry, return the original error
      if (retryCount + 1 >= maxRetries) {
        return handler.next(err);
      }
      
      // Otherwise, continue with the retry process
      if (e is DioException) {
        return onError(e, handler);
      } else {
        // Convert non-DioException to DioException
        final dioError = DioException(
          requestOptions: err.requestOptions,
          error: e,
          type: DioExceptionType.unknown,
        );
        return handler.next(dioError);
      }
    }
  }

  /// Determine if a request should be retried
  bool _shouldRetry(DioException error) {
    // Don't retry if method is not safe to retry
    if (!retryableMethods.contains(error.requestOptions.method.toUpperCase())) {
      debugPrint('Retry: Method ${error.requestOptions.method} is not retryable');
      return false;
    }

    // Retry on network errors
    if (_isNetworkError(error)) {
      debugPrint('Retry: Network error detected, will retry');
      return true;
    }

    // Retry on specific HTTP status codes
    if (error.response?.statusCode != null &&
        retryableStatusCodes.contains(error.response!.statusCode)) {
      debugPrint('Retry: HTTP ${error.response!.statusCode} is retryable');
      return true;
    }

    // Don't retry client errors (4xx) except for specific cases
    if (error.response?.statusCode != null &&
        error.response!.statusCode! >= 400 &&
        error.response!.statusCode! < 500 &&
        !retryableStatusCodes.contains(error.response!.statusCode)) {
      debugPrint('Retry: HTTP ${error.response!.statusCode} is not retryable (client error)');
      return false;
    }

    return false;
  }

  /// Check if error is a network error
  bool _isNetworkError(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
           error.type == DioExceptionType.receiveTimeout ||
           error.type == DioExceptionType.sendTimeout ||
           error.type == DioExceptionType.connectionError;
  }

  /// Calculate delay for retry with exponential backoff and jitter
  Duration _calculateDelay(int retryCount) {
    // Exponential backoff: delay = baseDelay * (2 ^ retryCount)
    final exponentialDelay = baseDelay.inMilliseconds * pow(2, retryCount);
    
    // Add jitter (random factor between 0.5 and 1.5)
    final jitter = 0.5 + Random().nextDouble();
    final delayWithJitter = (exponentialDelay * jitter).round();
    
    // Cap at maximum delay
    final cappedDelay = math.min(delayWithJitter, maxDelay.inMilliseconds);
    
    return Duration(milliseconds: cappedDelay);
  }
}

/// Extended retry interceptor with circuit breaker pattern
class CircuitBreakerRetryInterceptor extends RetryInterceptor {
  final Duration circuitBreakerWindow;
  final int failureThreshold;
  final Duration circuitBreakerCooldown;
  
  // Circuit breaker state per endpoint
  final Map<String, _CircuitBreakerState> _circuitStates = {};

  CircuitBreakerRetryInterceptor({
    super.maxRetries,
    super.baseDelay,
    super.maxDelay,
    super.retryableStatusCodes,
    super.retryableMethods,
    this.circuitBreakerWindow = const Duration(minutes: 5),
    this.failureThreshold = 5,
    this.circuitBreakerCooldown = const Duration(minutes: 1),
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final endpoint = _getEndpointKey(err.requestOptions);
    final circuitState = _getCircuitState(endpoint);

    // Check if circuit is open
    if (circuitState.isOpen()) {
      debugPrint('CircuitBreaker: Circuit is OPEN for $endpoint');
      return handler.next(DioException(
        requestOptions: err.requestOptions,
        error: 'Circuit breaker is open for this endpoint',
        type: DioExceptionType.unknown,
      ));
    }

    // Record failure
    circuitState.recordFailure();

    // If circuit should open, open it
    if (circuitState.shouldOpen(failureThreshold, circuitBreakerWindow)) {
      debugPrint('CircuitBreaker: Opening circuit for $endpoint due to failures');
      circuitState.open();
    }

    // Proceed with normal retry logic
    return super.onError(err, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Record success to reset circuit breaker
    final endpoint = _getEndpointKey(response.requestOptions);
    final circuitState = _getCircuitState(endpoint);
    circuitState.recordSuccess();

    return handler.next(response);
  }

  String _getEndpointKey(RequestOptions options) {
    // Use base path without query parameters for circuit breaker key
    final uri = Uri.parse(options.path);
    return '${options.method.toUpperCase()}_${uri.path}';
  }

  _CircuitBreakerState _getCircuitState(String endpoint) {
    _circuitStates[endpoint] ??= _CircuitBreakerState();
    return _circuitStates[endpoint]!;
  }
}

class _CircuitBreakerState {
  bool _isOpen = false;
  DateTime? _openedAt;
  final List<DateTime> _failures = [];
  
  void recordFailure() {
    _failures.add(DateTime.now());
    _cleanOldFailures();
  }

  void recordSuccess() {
    _failures.clear();
    _isOpen = false;
    _openedAt = null;
  }

  bool isOpen() {
    if (!_isOpen) return false;
    
    // Check if cooldown period has passed
    if (_openedAt != null) {
      final cooldownExpired = DateTime.now().difference(_openedAt!).inMinutes >= 1;
      if (cooldownExpired) {
        _isOpen = false;
        _openedAt = null;
        _failures.clear();
        return false;
      }
    }
    
    return true;
  }

  bool shouldOpen(int threshold, Duration window) {
    _cleanOldFailures();
    return _failures.length >= threshold;
  }

  void open() {
    _isOpen = true;
    _openedAt = DateTime.now();
  }

  void _cleanOldFailures() {
    final cutoff = DateTime.now().subtract(const Duration(minutes: 5));
    _failures.removeWhere((failure) => failure.isBefore(cutoff));
  }
}