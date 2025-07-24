// lib/core/services/cache_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../errors/app_error.dart';

enum CacheType {
  userProfile,
  transactions,
  accounts,
  loans,
  settings,
  apiResponse,
  documents,
  temporary,
}

class CacheItem<T> {
  final String key;
  final T data;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final CacheType type;

  CacheItem({
    required this.key,
    required this.data,
    required this.createdAt,
    this.expiresAt,
    required this.type,
  });

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'data': data,
        'createdAt': createdAt.toIso8601String(),
        'expiresAt': expiresAt?.toIso8601String(),
        'type': type.toString(),
      };

  factory CacheItem.fromJson(Map<String, dynamic> json) => CacheItem<T>(
        key: json['key'],
        data: json['data'],
        createdAt: DateTime.parse(json['createdAt']),
        expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
        type: CacheType.values.firstWhere(
          (e) => e.toString() == json['type'],
          orElse: () => CacheType.temporary,
        ),
      );
}

class CacheService {
  static const String _boxPrefix = 'sacco_cache_';
  static const Duration _defaultExpiration = Duration(hours: 24);
  static const Duration _userDataExpiration = Duration(days: 7);
  static const Duration _transactionExpiration = Duration(days: 30);
  static const Duration _apiResponseExpiration = Duration(hours: 1);

  late Box<String> _mainBox;
  late Box<String> _userBox;
  late Box<String> _transactionBox;
  late Box<String> _settingsBox;
  
  bool _isInitialized = false;

  /// Initialize the cache service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (!kIsWeb) {
        final directory = await getApplicationDocumentsDirectory();
        Hive.init(directory.path);
      } else {
        await Hive.initFlutter();
      }

      // Open different boxes for different data types
      _mainBox = await Hive.openBox<String>('${_boxPrefix}main');
      _userBox = await Hive.openBox<String>('${_boxPrefix}user');
      _transactionBox = await Hive.openBox<String>('${_boxPrefix}transactions');
      _settingsBox = await Hive.openBox<String>('${_boxPrefix}settings');

      _isInitialized = true;

      // Clean up expired items on initialization
      await _cleanupExpiredItems();
    } catch (e) {
      throw AppError(
        message: 'Failed to initialize cache service: ${e.toString()}',
        originalError: e.toString(),
      );
    }
  }

  /// Store data in cache
  Future<void> store<T>({
    required String key,
    required T data,
    CacheType type = CacheType.temporary,
    Duration? expiration,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      final Duration actualExpiration = expiration ?? _getDefaultExpiration(type);
      final expiresAt = DateTime.now().add(actualExpiration);

      final cacheItem = CacheItem<T>(
        key: key,
        data: data,
        createdAt: DateTime.now(),
        expiresAt: expiresAt,
        type: type,
      );

      final box = _getBoxForType(type);
      await box.put(key, jsonEncode(cacheItem.toJson()));

      debugPrint('Cache: Stored $key (type: $type, expires: $expiresAt)');
    } catch (e) {
      throw AppError(
        message: 'Failed to store cache item: ${e.toString()}',
        originalError: e.toString(),
      );
    }
  }

  /// Retrieve data from cache
  Future<T?> retrieve<T>(String key, CacheType type) async {
    if (!_isInitialized) await initialize();

    try {
      final box = _getBoxForType(type);
      final jsonString = box.get(key);
      
      if (jsonString == null) return null;

      final cacheItem = CacheItem<T>.fromJson(jsonDecode(jsonString));

      // Check if item has expired
      if (cacheItem.isExpired) {
        await box.delete(key);
        debugPrint('Cache: Removed expired item $key');
        return null;
      }

      debugPrint('Cache: Retrieved $key (type: $type)');
      return cacheItem.data;
    } catch (e) {
      debugPrint('Cache: Failed to retrieve $key: ${e.toString()}');
      return null;
    }
  }

  /// Check if key exists in cache and is not expired
  Future<bool> exists(String key, CacheType type) async {
    if (!_isInitialized) await initialize();

    try {
      final box = _getBoxForType(type);
      final jsonString = box.get(key);
      
      if (jsonString == null) return false;

      final cacheItem = CacheItem.fromJson(jsonDecode(jsonString));
      
      if (cacheItem.isExpired) {
        await box.delete(key);
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Remove specific item from cache
  Future<void> remove(String key, CacheType type) async {
    if (!_isInitialized) await initialize();

    try {
      final box = _getBoxForType(type);
      await box.delete(key);
      debugPrint('Cache: Removed $key');
    } catch (e) {
      throw AppError(
        message: 'Failed to remove cache item: ${e.toString()}',
        originalError: e.toString(),
      );
    }
  }

  /// Clear all items of a specific type
  Future<void> clearType(CacheType type) async {
    if (!_isInitialized) await initialize();

    try {
      final box = _getBoxForType(type);
      await box.clear();
      debugPrint('Cache: Cleared all items of type $type');
    } catch (e) {
      throw AppError(
        message: 'Failed to clear cache type: ${e.toString()}',
        originalError: e.toString(),
      );
    }
  }

  /// Clear all cached data
  Future<void> clearAll() async {
    if (!_isInitialized) await initialize();

    try {
      await Future.wait([
        _mainBox.clear(),
        _userBox.clear(),
        _transactionBox.clear(),
        _settingsBox.clear(),
      ]);
      debugPrint('Cache: Cleared all cached data');
    } catch (e) {
      throw AppError(
        message: 'Failed to clear all cache: ${e.toString()}',
        originalError: e.toString(),
      );
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getStats() async {
    if (!_isInitialized) await initialize();

    try {
      final mainCount = _mainBox.length;
      final userCount = _userBox.length;
      final transactionCount = _transactionBox.length;
      final settingsCount = _settingsBox.length;

      // Calculate total size (approximate)
      int totalSize = 0;
      for (final box in [_mainBox, _userBox, _transactionBox, _settingsBox]) {
        for (final value in box.values) {
          totalSize += value.length;
        }
      }

      return {
        'totalItems': mainCount + userCount + transactionCount + settingsCount,
        'mainBoxItems': mainCount,
        'userBoxItems': userCount,
        'transactionBoxItems': transactionCount,
        'settingsBoxItems': settingsCount,
        'approximateSizeBytes': totalSize,
        'approximateSizeMB': (totalSize / (1024 * 1024)).toStringAsFixed(2),
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Clean up expired items
  Future<void> _cleanupExpiredItems() async {
    if (!_isInitialized) return;

    try {
      int removedCount = 0;
      
      for (final box in [_mainBox, _userBox, _transactionBox, _settingsBox]) {
        final keysToRemove = <dynamic>[];
        
        for (final key in box.keys) {
          final jsonString = box.get(key);
          if (jsonString == null) continue;

          try {
            final cacheItem = CacheItem.fromJson(jsonDecode(jsonString));
            if (cacheItem.isExpired) {
              keysToRemove.add(key);
            }
          } catch (e) {
            // If we can't parse the item, remove it
            keysToRemove.add(key);
          }
        }

        for (final key in keysToRemove) {
          await box.delete(key);
          removedCount++;
        }
      }

      if (removedCount > 0) {
        debugPrint('Cache: Cleaned up $removedCount expired items');
      }
    } catch (e) {
      debugPrint('Cache: Error during cleanup: ${e.toString()}');
    }
  }

  /// Get the appropriate box for the cache type
  Box<String> _getBoxForType(CacheType type) {
    switch (type) {
      case CacheType.userProfile:
      case CacheType.accounts:
        return _userBox;
      case CacheType.transactions:
        return _transactionBox;
      case CacheType.settings:
        return _settingsBox;
      case CacheType.loans:
      case CacheType.apiResponse:
      case CacheType.documents:
      case CacheType.temporary:
        return _mainBox;
    }
  }

  /// Get default expiration for cache type
  Duration _getDefaultExpiration(CacheType type) {
    switch (type) {
      case CacheType.userProfile:
      case CacheType.accounts:
        return _userDataExpiration;
      case CacheType.transactions:
        return _transactionExpiration;
      case CacheType.apiResponse:
        return _apiResponseExpiration;
      case CacheType.settings:
        return const Duration(days: 30);
      case CacheType.loans:
        return const Duration(days: 7);
      case CacheType.documents:
        return const Duration(days: 90);
      case CacheType.temporary:
        return _defaultExpiration;
    }
  }

  /// Dispose of resources
  Future<void> dispose() async {
    if (!_isInitialized) return;

    try {
      await Future.wait([
        _mainBox.close(),
        _userBox.close(),
        _transactionBox.close(),
        _settingsBox.close(),
      ]);
      _isInitialized = false;
      debugPrint('Cache: Service disposed');
    } catch (e) {
      debugPrint('Cache: Error disposing service: ${e.toString()}');
    }
  }

  /// Utility method to cache API responses
  Future<void> cacheApiResponse({
    required String endpoint,
    required Map<String, dynamic> response,
    Duration? expiration,
  }) async {
    await store<Map<String, dynamic>>(
      key: 'api_$endpoint',
      data: response,
      type: CacheType.apiResponse,
      expiration: expiration ?? _apiResponseExpiration,
    );
  }

  /// Utility method to retrieve cached API responses
  Future<Map<String, dynamic>?> getCachedApiResponse(String endpoint) async {
    return await retrieve<Map<String, dynamic>>('api_$endpoint', CacheType.apiResponse);
  }
}