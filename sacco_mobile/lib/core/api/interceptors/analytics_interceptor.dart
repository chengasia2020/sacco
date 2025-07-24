// lib/core/api/interceptors/analytics_interceptor.dart
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/services/cache_service.dart';

enum ApiEventType {
  request,
  response,
  error,
  timeout,
  retry,
}

class ApiAnalyticsEvent {
  final String id;
  final ApiEventType type;
  final String method;
  final String endpoint;
  final int? statusCode;
  final Duration duration;
  final int? responseSize;
  final String? errorMessage;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;

  ApiAnalyticsEvent({
    required this.id,
    required this.type,
    required this.method,
    required this.endpoint,
    this.statusCode,
    required this.duration,
    this.responseSize,
    this.errorMessage,
    this.metadata = const {},
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.toString(),
        'method': method,
        'endpoint': endpoint,
        'statusCode': statusCode,
        'durationMs': duration.inMilliseconds,
        'responseSize': responseSize,
        'errorMessage': errorMessage,
        'metadata': metadata,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ApiAnalyticsEvent.fromJson(Map<String, dynamic> json) => ApiAnalyticsEvent(
        id: json['id'],
        type: ApiEventType.values.firstWhere(
          (e) => e.toString() == json['type'],
          orElse: () => ApiEventType.request,
        ),
        method: json['method'],
        endpoint: json['endpoint'],
        statusCode: json['statusCode'],
        duration: Duration(milliseconds: json['durationMs'] ?? 0),
        responseSize: json['responseSize'],
        errorMessage: json['errorMessage'],
        metadata: json['metadata'] ?? {},
        timestamp: DateTime.parse(json['timestamp']),
      );
}

class AnalyticsInterceptor extends Interceptor {
  final CacheService _cacheService;
  final Map<String, DateTime> _requestStartTimes = {};
  final List<ApiAnalyticsEvent> _events = [];
  
  static const int _maxStoredEvents = 1000;
  static const String _analyticsKey = 'api_analytics_events';

  AnalyticsInterceptor(this._cacheService);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final requestId = _generateRequestId(options);
    _requestStartTimes[requestId] = DateTime.now();

    // Record request event
    final event = ApiAnalyticsEvent(
      id: requestId,
      type: ApiEventType.request,
      method: options.method,
      endpoint: _sanitizeEndpoint(options.path),
      duration: Duration.zero,
      timestamp: DateTime.now(),
      metadata: {
        'hasBody': options.data != null,
        'queryParams': options.queryParameters.keys.toList(),
        'retryCount': options.extra['retryCount'] ?? 0,
      },
    );

    _addEvent(event);
    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final requestId = _generateRequestId(response.requestOptions);
    final startTime = _requestStartTimes.remove(requestId);
    final duration = startTime != null 
        ? DateTime.now().difference(startTime)
        : Duration.zero;

    // Calculate response size
    int? responseSize;
    try {
      if (response.data != null) {
        final jsonString = jsonEncode(response.data);
        responseSize = jsonString.length;
      }
    } catch (e) {
      // If we can't serialize, estimate size
      responseSize = response.data.toString().length;
    }

    // Record response event
    final event = ApiAnalyticsEvent(
      id: requestId,
      type: ApiEventType.response,
      method: response.requestOptions.method,
      endpoint: _sanitizeEndpoint(response.requestOptions.path),
      statusCode: response.statusCode,
      duration: duration,
      responseSize: responseSize,
      timestamp: DateTime.now(),
      metadata: {
        'retryCount': response.requestOptions.extra['retryCount'] ?? 0,
        'fromCache': response.headers.value('X-From-Cache') == 'true',
        'isStale': response.headers.value('X-Cache-Stale') == 'true',
      },
    );

    _addEvent(event);
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final requestId = _generateRequestId(err.requestOptions);
    final startTime = _requestStartTimes.remove(requestId);
    final duration = startTime != null 
        ? DateTime.now().difference(startTime)
        : Duration.zero;

    // Determine error type
    ApiEventType eventType = ApiEventType.error;
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout) {
      eventType = ApiEventType.timeout;
    }

    // Record error event
    final event = ApiAnalyticsEvent(
      id: requestId,
      type: eventType,
      method: err.requestOptions.method,
      endpoint: _sanitizeEndpoint(err.requestOptions.path),
      statusCode: err.response?.statusCode,
      duration: duration,
      errorMessage: _sanitizeErrorMessage(err.message),
      timestamp: DateTime.now(),
      metadata: {
        'errorType': err.type.toString(),
        'retryCount': err.requestOptions.extra['retryCount'] ?? 0,
        'willRetry': _willRetry(err),
      },
    );

    _addEvent(event);
    return handler.next(err);
  }

  /// Generate unique request ID
  String _generateRequestId(RequestOptions options) {
    return '${options.method}_${options.path}_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Sanitize endpoint to remove sensitive data
  String _sanitizeEndpoint(String path) {
    // Remove user IDs, account numbers, etc.
    String sanitized = path;
    
    // Replace UUIDs with placeholder
    sanitized = sanitized.replaceAllMapped(
      RegExp(r'[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}'),
      (match) => '{uuid}',
    );
    
    // Replace numeric IDs with placeholder
    sanitized = sanitized.replaceAllMapped(
      RegExp(r'/\d+(?=/|$)'),
      (match) => '/{id}',
    );
    
    return sanitized;
  }

  /// Sanitize error message to remove sensitive information
  String? _sanitizeErrorMessage(String? message) {
    if (message == null) return null;
    
    // Remove potential sensitive data from error messages
    String sanitized = message;
    
    // Remove phone numbers
    sanitized = sanitized.replaceAllMapped(
      RegExp(r'\b\d{10,15}\b'),
      (match) => '[PHONE]',
    );
    
    // Remove email addresses
    sanitized = sanitized.replaceAllMapped(
      RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'),
      (match) => '[EMAIL]',
    );
    
    // Remove potential account numbers
    sanitized = sanitized.replaceAllMapped(
      RegExp(r'\b\d{8,20}\b'),
      (match) => '[ACCOUNT]',
    );
    
    return sanitized;
  }

  /// Check if request will be retried
  bool _willRetry(DioException err) {
    final retryCount = err.requestOptions.extra['retryCount'] as int? ?? 0;
    const maxRetries = 3; // Should match RetryInterceptor configuration
    return retryCount < maxRetries;
  }

  /// Add event to collection and persist
  void _addEvent(ApiAnalyticsEvent event) {
    _events.add(event);
    
    // Keep only recent events in memory
    if (_events.length > _maxStoredEvents) {
      _events.removeAt(0);
    }

    // Persist events asynchronously
    _persistEvents();
  }

  /// Persist events to cache
  Future<void> _persistEvents() async {
    try {
      final eventsJson = _events.map((e) => e.toJson()).toList();
      await _cacheService.store(
        key: _analyticsKey,
        data: eventsJson,
        type: CacheType.temporary,
        expiration: const Duration(days: 7),
      );
    } catch (e) {
      debugPrint('Analytics: Failed to persist events: $e');
    }
  }

  /// Load persisted events
  Future<void> loadPersistedEvents() async {
    try {
      final eventsJson = await _cacheService.retrieve<List<dynamic>>(
        _analyticsKey,
        CacheType.temporary,
      );
      
      if (eventsJson != null) {
        _events.clear();
        _events.addAll(
          eventsJson.map((json) => ApiAnalyticsEvent.fromJson(json)).toList(),
        );
        debugPrint('Analytics: Loaded ${_events.length} persisted events');
      }
    } catch (e) {
      debugPrint('Analytics: Failed to load persisted events: $e');
    }
  }

  /// Get analytics summary
  Map<String, dynamic> getAnalyticsSummary({Duration? period}) {
    final cutoff = period != null ? DateTime.now().subtract(period) : null;
    final filteredEvents = cutoff != null 
        ? _events.where((e) => e.timestamp.isAfter(cutoff)).toList()
        : _events;

    if (filteredEvents.isEmpty) {
      return {'totalRequests': 0, 'message': 'No data available'};
    }

    // Calculate metrics
    final totalRequests = filteredEvents.where((e) => e.type == ApiEventType.request).length;
    final successfulRequests = filteredEvents.where((e) => 
        e.type == ApiEventType.response && 
        e.statusCode != null && 
        e.statusCode! >= 200 && 
        e.statusCode! < 300).length;
    final failedRequests = filteredEvents.where((e) => e.type == ApiEventType.error).length;
    final timeouts = filteredEvents.where((e) => e.type == ApiEventType.timeout).length;

    // Calculate average response time
    final responseTimes = filteredEvents
        .where((e) => e.type == ApiEventType.response || e.type == ApiEventType.error)
        .map((e) => e.duration.inMilliseconds)
        .where((duration) => duration > 0)
        .toList();
    
    final avgResponseTime = responseTimes.isNotEmpty 
        ? responseTimes.reduce((a, b) => a + b) / responseTimes.length
        : 0.0;

    // Most common endpoints
    final endpointCounts = <String, int>{};
    for (final event in filteredEvents) {
      endpointCounts[event.endpoint] = (endpointCounts[event.endpoint] ?? 0) + 1;
    }
    
    final topEndpoints = endpointCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Error analysis
    final errorsByEndpoint = <String, int>{};
    final errorsByStatus = <int, int>{};
    
    for (final event in filteredEvents.where((e) => e.type == ApiEventType.error)) {
      errorsByEndpoint[event.endpoint] = (errorsByEndpoint[event.endpoint] ?? 0) + 1;
      if (event.statusCode != null) {
        errorsByStatus[event.statusCode!] = (errorsByStatus[event.statusCode!] ?? 0) + 1;
      }
    }

    return {
      'period': period?.toString() ?? 'all time',
      'totalRequests': totalRequests,
      'successfulRequests': successfulRequests,
      'failedRequests': failedRequests,
      'timeouts': timeouts,
      'successRate': totalRequests > 0 ? (successfulRequests / totalRequests * 100).toStringAsFixed(2) : '0.00',
      'averageResponseTimeMs': avgResponseTime.toStringAsFixed(2),
      'topEndpoints': topEndpoints.take(10).map((e) => {
        'endpoint': e.key,
        'count': e.value,
      }).toList(),
      'errorsByEndpoint': errorsByEndpoint.entries.map((e) => {
        'endpoint': e.key,
        'count': e.value,
      }).toList(),
      'errorsByStatus': errorsByStatus.entries.map((e) => {
        'statusCode': e.key,
        'count': e.value,
      }).toList(),
    };
  }

  /// Get all events (for debugging)
  List<ApiAnalyticsEvent> getAllEvents() => List.unmodifiable(_events);

  /// Clear all analytics data
  Future<void> clearAnalytics() async {
    _events.clear();
    try {
      await _cacheService.remove(_analyticsKey, CacheType.temporary);
      debugPrint('Analytics: Cleared all analytics data');
    } catch (e) {
      debugPrint('Analytics: Failed to clear analytics data: $e');
    }
  }
}