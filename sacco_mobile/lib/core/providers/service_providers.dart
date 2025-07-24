// lib/core/providers/service_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../api/api_client.dart';
import '../services/auth_service.dart';
import '../services/connectivity_service.dart';
import '../services/biometric_service.dart';
import '../services/cache_service.dart';
import '../services/notification_service.dart';
import '../storage/secure_storage_service.dart';
import '../../features/auth/repositories/auth_repository.dart';
import '../../features/loans/repositories/loan_repository.dart';
import '../../features/savings/repositories/savings_repository.dart';
import '../../features/profile/repositories/profile_repository.dart';

// Core service providers
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService(Connectivity());
});

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService(const FlutterSecureStorage());
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    ref.watch(connectivityServiceProvider),
    ref.watch(secureStorageServiceProvider),
  );
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref.watch(apiClientProvider),
    ref.watch(secureStorageServiceProvider),
  );
});

// Repository providers
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider));
});

final loanRepositoryProvider = Provider<LoanRepository>((ref) {
  return LoanRepository(ref.watch(apiClientProvider));
});

final savingsRepositoryProvider = Provider<SavingsRepository>((ref) {
  return SavingsRepository(ref.watch(apiClientProvider));
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(apiClientProvider));
});

// New service providers
final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService(
    LocalAuthentication(),
    ref.watch(secureStorageServiceProvider),
  );
});

final cacheServiceProvider = Provider<CacheService>((ref) {
  return CacheService();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(
    FlutterLocalNotificationsPlugin(),
    FirebaseMessaging.instance,
    ref.watch(secureStorageServiceProvider),
  );
});