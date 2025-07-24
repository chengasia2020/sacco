// lib/core/di/service_locator.dart
// DEPRECATED: This service locator is being phased out in favor of Riverpod providers.
// Only kept for backward compatibility with screens that haven't been migrated yet.
// See lib/core/providers/service_providers.dart for the new Riverpod-based DI.

import 'package:get_it/get_it.dart';
import 'package:sacco_mobile/core/api/api_client.dart';
import 'package:sacco_mobile/core/services/auth_service.dart';
import 'package:sacco_mobile/core/storage/secure_storage_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sacco_mobile/core/services/connectivity_service.dart';
import 'package:sacco_mobile/features/auth/repositories/auth_repository.dart';
import 'package:sacco_mobile/features/dashboard/viewmodels/dashboard_viewmodel.dart';
import 'package:sacco_mobile/features/loans/repositories/loan_repository.dart';
import 'package:sacco_mobile/features/loans/viewmodels/loan_list_viewmodel.dart';
import 'package:sacco_mobile/features/loans/viewmodels/loan_application_viewmodel.dart';
import 'package:sacco_mobile/features/loans/viewmodels/loan_repayment_viewmodel.dart';
import 'package:sacco_mobile/features/savings/repositories/savings_repository.dart';
import 'package:sacco_mobile/features/savings/viewmodels/savings_account_viewmodel.dart';
import 'package:sacco_mobile/features/savings/viewmodels/transaction_viewmodel.dart';
import 'package:sacco_mobile/features/profile/repositories/profile_repository.dart';
import 'package:sacco_mobile/features/profile/viewmodels/profile_viewmodel.dart';

// Global instance of GetIt service locator
final GetIt getIt = GetIt.instance;

@Deprecated('Use Riverpod providers instead. This will be removed once all screens are migrated.')
Future<void> setupServiceLocator() async {
  // LEGACY SUPPORT: Register core services for backward compatibility
  // These should be managed by Riverpod providers in new code
  
  getIt.registerLazySingleton<ConnectivityService>(() => ConnectivityService(Connectivity()));
  getIt.registerLazySingleton<SecureStorageService>(
      () => SecureStorageService(const FlutterSecureStorage()));

  getIt.registerLazySingleton<ApiClient>(() => ApiClient(
        getIt<ConnectivityService>(),
        getIt<SecureStorageService>(), // Added the missing second argument
      ));

  getIt.registerLazySingleton<AuthService>(() => AuthService(
        getIt<ApiClient>(),
        getIt<SecureStorageService>(),
      ));

  // Register repositories - these will be migrated to Riverpod
  getIt.registerLazySingleton<AuthRepository>(() => AuthRepository(
        getIt<ApiClient>(),
      ));

  getIt.registerLazySingleton<LoanRepository>(() => LoanRepository(
        getIt<ApiClient>(),
      ));

  getIt.registerLazySingleton<SavingsRepository>(() => SavingsRepository(
        getIt<ApiClient>(),
      ));

  getIt.registerLazySingleton<ProfileRepository>(() => ProfileRepository(
        getIt<ApiClient>(),
      ));

  // LEGACY ViewModels - to be removed once screens are migrated to Riverpod
  // Auth ViewModels have already been migrated to Riverpod providers
  
  getIt.registerFactory<DashboardViewModel>(() => DashboardViewModel(
        getIt<AuthService>(),
        getIt<SavingsRepository>(),
        getIt<LoanRepository>(),
      ));

  getIt.registerFactory<LoanListViewModel>(() => LoanListViewModel(
        getIt<LoanRepository>(),
      ));

  getIt.registerFactory<LoanApplicationViewModel>(() => LoanApplicationViewModel(
        getIt<LoanRepository>(),
      ));

  getIt.registerFactory<LoanRepaymentViewModel>(() => LoanRepaymentViewModel(
        getIt<LoanRepository>(),
      ));

  getIt.registerFactory<SavingsAccountViewModel>(() => SavingsAccountViewModel(
        getIt<SavingsRepository>(),
      ));

  getIt.registerFactory<TransactionViewModel>(() => TransactionViewModel(
        getIt<SavingsRepository>(),
      ));

  getIt.registerFactory<ProfileViewModel>(() => ProfileViewModel(
        getIt<ProfileRepository>(),
      ));
}
