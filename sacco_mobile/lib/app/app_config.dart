import 'package:flutter/foundation.dart';

enum Environment { development, staging, production }

class AppConfig {
  static Environment _environment = Environment.development;
  
  static Environment get environment => _environment;
  
  static void setEnvironment(Environment env) {
    _environment = env;
  }
  
  static String get baseUrl {
    switch (_environment) {
      case Environment.development:
        return 'http://localhost:8000/api/v1';
      case Environment.staging:
        return 'https://staging-api.sacco.com/api/v1';
      case Environment.production:
        return 'https://api.sacco.com/api/v1';
    }
  }
  
  static String get websocketUrl {
    switch (_environment) {
      case Environment.development:
        return 'ws://localhost:8000/ws';
      case Environment.staging:
        return 'wss://staging-api.sacco.com/ws';
      case Environment.production:
        return 'wss://api.sacco.com/ws';
    }
  }
  
  static bool get enableLogging => _environment != Environment.production;
  
  static bool get enableDebugMode => kDebugMode && _environment == Environment.development;
  
  static String get appName {
    switch (_environment) {
      case Environment.development:
        return 'SACCO Dev';
      case Environment.staging:
        return 'SACCO Staging';
      case Environment.production:
        return 'SACCO';
    }
  }
  
  static String get packageName {
    switch (_environment) {
      case Environment.development:
        return 'com.sacco.mobile.dev';
      case Environment.staging:
        return 'com.sacco.mobile.staging';
      case Environment.production:
        return 'com.sacco.mobile';
    }
  }
  
  // Feature Flags
  static bool get enableBiometrics => true;
  static bool get enableOfflineMode => true;
  static bool get enablePushNotifications => true;
  static bool get enableAnalytics => _environment == Environment.production;
  static bool get enableCrashReporting => _environment != Environment.development;
  
  // Security Configuration
  static Duration get sessionTimeout => const Duration(minutes: 30);
  static int get maxLoginAttempts => 5;
  static Duration get lockoutDuration => const Duration(minutes: 15);
  
  // API Configuration
  static Duration get apiTimeout => const Duration(seconds: 30);
  static int get maxRetryAttempts => 3;
  static Duration get retryDelay => const Duration(seconds: 2);
  
  // Cache Configuration
  static Duration get cacheExpiry => const Duration(hours: 24);
  static int get maxCacheSize => 100 * 1024 * 1024; // 100MB
  
  // UI Configuration
  static Duration get animationDuration => const Duration(milliseconds: 300);
  static Duration get splashScreenDuration => const Duration(seconds: 3);
}