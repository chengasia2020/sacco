// lib/features/auth/providers/auth_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sacco_mobile/core/providers/service_providers.dart';
import '../models/user.dart';
import '../models/login_request.dart';
import '../repositories/auth_repository.dart';

// Auth state classes
class LoginState {
  final bool isLoading;
  final User? user;
  final String? errorMessage;
  final bool isSuccess;

  const LoginState({
    this.isLoading = false,
    this.user,
    this.errorMessage,
    this.isSuccess = false,
  });

  LoginState copyWith({
    bool? isLoading,
    User? user,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class RegisterState {
  final bool isLoading;
  final bool isSuccess;
  final String? errorMessage;

  const RegisterState({
    this.isLoading = false,
    this.isSuccess = false,
    this.errorMessage,
  });

  RegisterState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? errorMessage,
  }) {
    return RegisterState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// Auth state notifiers
class LoginNotifier extends StateNotifier<LoginState> {
  LoginNotifier(this._authService) : super(const LoginState());

  final dynamic _authService; // AuthService

  Future<bool> login(LoginRequest loginRequest) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final user = await _authService.login(loginRequest);
      state = state.copyWith(
        isLoading: false,
        user: user,
        isSuccess: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
        isSuccess: false,
      );
      return false;
    }
  }

  void resetState() {
    state = const LoginState();
  }
}

class RegisterNotifier extends StateNotifier<RegisterState> {
  RegisterNotifier(this._authRepository) : super(const RegisterState());

  final AuthRepository _authRepository;

  Future<bool> register(Map<String, dynamic> registerData) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _authRepository.register(registerData);
      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
        isSuccess: false,
      );
      return false;
    }
  }

  void resetState() {
    state = const RegisterState();
  }
}

// Current user provider
final currentUserProvider = StateProvider<User?>((ref) => null);

// Auth providers
final loginProvider = StateNotifierProvider<LoginNotifier, LoginState>((ref) {
  return LoginNotifier(
    ref.watch(authServiceProvider),
  );
});

final registerProvider = StateNotifierProvider<RegisterNotifier, RegisterState>((ref) {
  return RegisterNotifier(
    ref.watch(authRepositoryProvider),
  );
});

// Authentication status provider
final authStatusProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});