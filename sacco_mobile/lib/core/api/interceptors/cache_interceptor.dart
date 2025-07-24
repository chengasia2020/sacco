// lib/core/api/interceptors/cache_interceptor.dart
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/services/cache_service.dart';

class CacheInterceptor extends Interceptor {
  final CacheService _cacheService;
  
  // Methods that should be cached
  static const List<String> _cacheableMethods = ['GET'];
  
  // Endpoints that should never be cached
  static const List<String> _nonCacheableEndpoints = [
    '/auth/login',
    '/auth/logout',
    '/auth/refresh',
    '/transactions/create',
    '/loans/apply',
    '/deposits/create',
    '/withdrawals/create',
  ];

  // Default cache durations for different endpoints
  static const Map<String, Duration> _cacheDurations = {
    '/profile': Duration(hours: 4),
    '/accounts': Duration(hours: 2),
    '/loans': Duration(hours: 1),
    '/settings': Duration(days: 1),
    '/transactions': Duration(minutes: 30),
    '/dashboard': Duration(minutes: 15),
  };

  CacheInterceptor(this._cacheService);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Only cache GET requests
    if (!_cacheableMethods.contains(options.method.toUpperCase())) {
      return handler.next(options);
    }

    // Don't cache non-cacheable endpoints
    if (_isNonCacheableEndpoint(options.path)) {
      return handler.next(options);
    }

    // Check for force refresh header
    final forceRefresh = options.headers['Cache-Control'] == 'no-cache';
    if (forceRefresh) {
      debugPrint('Cache: Force refresh requested for ${options.path}');
      return handler.next(options);
    }

    try {
      // Generate cache key
      final cacheKey = _generateCacheKey(options);
      
      // Try to get cached response
      final cachedResponse = await _cacheService.getCachedApiResponse(cacheKey);
      
      if (cachedResponse != null) {
        debugPrint('Cache: Serving cached response for ${options.path}');
        
        // Create response from cached data
        final response = Response(
          requestOptions: options,
          data: cachedResponse['data'],
          statusCode: cachedResponse['statusCode'] ?? 200,
          statusMessage: cachedResponse['statusMessage'] ?? 'OK',
          headers: Headers.fromMap(
            Map<String, List<String>>.from(cachedResponse['headers'] ?? {}),
          ),
        );
        
        return handler.resolve(response);
      }
    } catch (e) {
      debugPrint('Cache: Error retrieving cached response: $e');
    }

    // No cached response found, proceed with network request
    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    // Only cache successful GET responses
    if (!_cacheableMethods.contains(response.requestOptions.method.toUpperCase()) ||
        response.statusCode != 200) {
      return handler.next(response);
    }

    // Don't cache non-cacheable endpoints
    if (_isNonCacheableEndpoint(response.requestOptions.path)) {
      return handler.next(response);
    }

    try {
      // Generate cache key
      final cacheKey = _generateCacheKey(response.requestOptions);
      
      // Determine cache duration
      final cacheDuration = _getCacheDuration(response.requestOptions.path);
      
      // Prepare cache data
      final cacheData = {
        'data': response.data,
        'statusCode': response.statusCode,
        'statusMessage': response.statusMessage,
        'headers': response.headers.map,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Cache the response
      await _cacheService.cacheApiResponse(
        endpoint: cacheKey,
        response: cacheData,
        expiration: cacheDuration,
      );

      debugPrint('Cache: Cached response for ${response.requestOptions.path} (expires in ${cacheDuration.inMinutes} minutes)');
    } catch (e) {
      debugPrint('Cache: Error caching response: $e');
    }

    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // If there's a network error, try to serve stale cache
    if (_isNetworkError(err) && 
        _cacheableMethods.contains(err.requestOptions.method.toUpperCase())) {
      
      try {
        final cacheKey = _generateCacheKey(err.requestOptions);
        final staleResponse = await _cacheService.getCachedApiResponse(cacheKey);
        
        if (staleResponse != null) {
          debugPrint('Cache: Serving stale cache due to network error for ${err.requestOptions.path}');
          
          final response = Response(
            requestOptions: err.requestOptions,
            data: staleResponse['data'],
            statusCode: staleResponse['statusCode'] ?? 200,
            statusMessage: '${staleResponse['statusMessage'] ?? 'OK'} (Cached)',
            headers: Headers.fromMap({
              ...Map<String, List<String>>.from(staleResponse['headers'] ?? {}),
              'X-From-Cache': ['true'],
              'X-Cache-Stale': ['true'],
            }),
          );
          
          return handler.resolve(response);
        }
      } catch (e) {
        debugPrint('Cache: Error serving stale cache: $e');
      }
    }

    return handler.next(err);
  }

  /// Generate a unique cache key for the request
  String _generateCacheKey(RequestOptions options) {
    final buffer = StringBuffer();
    buffer.write(options.method.toUpperCase());
    buffer.write('_');
    buffer.write(options.path);
    
    // Include query parameters in cache key
    if (options.queryParameters.isNotEmpty) {
      final sortedParams = options.queryParameters.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      
      buffer.write('?');
      for (int i = 0; i < sortedParams.length; i++) {
        if (i > 0) buffer.write('&');
        buffer.write('${sortedParams[i].key}=${sortedParams[i].value}');
      }
    }

    // Include authorization header in cache key (to separate user-specific data)
    final authHeader = options.headers['Authorization'];
    if (authHeader != null) {
      // Use a hash of the auth header to avoid storing sensitive data
      buffer.write('_auth_${authHeader.hashCode}');
    }

    return buffer.toString();
  }

  /// Check if endpoint should not be cached
  bool _isNonCacheableEndpoint(String path) {
    return _nonCacheableEndpoints.any((endpoint) => path.contains(endpoint));
  }

  /// Get cache duration for specific endpoint
  Duration _getCacheDuration(String path) {
    for (final entry in _cacheDurations.entries) {
      if (path.contains(entry.key)) {
        return entry.value;
      }
    }
    
    // Default cache duration
    return const Duration(minutes: 30);
  }

  /// Check if error is a network error
  bool _isNetworkError(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
           error.type == DioExceptionType.receiveTimeout ||
           error.type == DioExceptionType.sendTimeout ||
           error.type == DioExceptionType.connectionError;
  }
}