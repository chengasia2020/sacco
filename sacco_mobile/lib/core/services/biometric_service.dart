// lib/core/services/biometric_service.dart
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';

import '../storage/secure_storage_service.dart';
import '../errors/app_error.dart';

enum BiometricType {
  fingerprint,
  face,
  voice,
  none,
}

enum BiometricStatus {
  unknown,
  available,
  notAvailable,
  notEnrolled,
  disabled,
}

class BiometricAuthResult {
  final bool isSuccess;
  final String? errorMessage;
  final BiometricType? usedBiometric;

  const BiometricAuthResult({
    required this.isSuccess,
    this.errorMessage,
    this.usedBiometric,
  });
}

class BiometricService {
  final LocalAuthentication _localAuth;
  final SecureStorageService _secureStorage;

  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _biometricTypeKey = 'biometric_type';
  static const String _fallbackPinKey = 'fallback_pin';

  BiometricService(this._localAuth, this._secureStorage);

  /// Check if biometric authentication is available on the device
  Future<BiometricStatus> getBiometricStatus() async {
    try {
      // Check if device supports biometric authentication
      final bool isAvailable = await _localAuth.isDeviceSupported();
      if (!isAvailable) {
        return BiometricStatus.notAvailable;
      }

      // Check if biometric authentication can be used
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      if (!canCheckBiometrics) {
        return BiometricStatus.disabled;
      }

      // Check if biometrics are enrolled
      final List<BiometricType> availableBiometrics = await getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        return BiometricStatus.notEnrolled;
      }

      return BiometricStatus.available;
    } catch (e) {
      return BiometricStatus.unknown;
    }
  }

  /// Get list of available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      final List<BiometricType> biometricTypes = [];
      final List<BiometricType> availableBiometrics = await _localAuth.getAvailableBiometrics();

      for (final biometric in availableBiometrics) {
        switch (biometric) {
          case BiometricType.fingerprint:
            biometricTypes.add(BiometricType.fingerprint);
            break;
          case BiometricType.face:
            biometricTypes.add(BiometricType.face);
            break;
          case BiometricType.voice:
            biometricTypes.add(BiometricType.voice);
            break;
          default:
            continue;
        }
      }

      return biometricTypes;
    } catch (e) {
      return [];
    }
  }

  /// Authenticate using biometrics
  Future<BiometricAuthResult> authenticate({
    String reason = 'Please authenticate to access your account',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    try {
      // Check if biometric is enabled for the user
      final bool isBiometricEnabled = await isBiometricEnabled();
      if (!isBiometricEnabled) {
        return const BiometricAuthResult(
          isSuccess: false,
          errorMessage: 'Biometric authentication is not enabled',
        );
      }

      // Perform biometric authentication
      final bool isAuthenticated = await _localAuth.authenticate(
        localizedFallbackTitle: 'Use PIN',
        authMessages: [
          AndroidAuthMessages(
            signInTitle: 'SACCO Mobile Authentication',
            biometricHint: 'Verify your identity',
            cancelButton: 'Cancel',
            deviceCredentialsRequiredTitle: 'Device credentials required',
            deviceCredentialsSetupDescription: 'Please set up device credentials',
            goToSettingsButton: 'Go to Settings',
            goToSettingsDescription: 'Set up biometric authentication in Settings',
          ),
          IOSAuthMessages(
            cancelButton: 'Cancel',
            goToSettingsButton: 'Go to Settings',
            goToSettingsDescription: 'Set up biometric authentication in Settings',
            lockOut: 'Biometric authentication is locked out',
          ),
        ],
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: false,
        ),
      );

      if (isAuthenticated) {
        final BiometricType? usedBiometric = await _getUsedBiometric();
        return BiometricAuthResult(
          isSuccess: true,
          usedBiometric: usedBiometric,
        );
      } else {
        return const BiometricAuthResult(
          isSuccess: false,
          errorMessage: 'Authentication failed or was cancelled',
        );
      }
    } on PlatformException catch (e) {
      String errorMessage = 'Biometric authentication failed';
      
      switch (e.code) {
        case 'NotAvailable':
          errorMessage = 'Biometric authentication is not available';
          break;
        case 'NotEnrolled':
          errorMessage = 'No biometric credentials are enrolled';
          break;
        case 'LockedOut':
          errorMessage = 'Too many failed attempts. Try again later';
          break;
        case 'PermanentlyLockedOut':
          errorMessage = 'Biometric authentication is permanently locked';
          break;
        case 'BiometricOnlyNotSupported':
          errorMessage = 'Device PIN is required as fallback';
          break;
        default:
          errorMessage = e.message ?? 'Unknown biometric error';
      }

      return BiometricAuthResult(
        isSuccess: false,
        errorMessage: errorMessage,
      );
    } catch (e) {
      return BiometricAuthResult(
        isSuccess: false,
        errorMessage: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  /// Enable biometric authentication for the user
  Future<bool> enableBiometric(BiometricType biometricType) async {
    try {
      // First verify that the user can authenticate
      final result = await authenticate(
        reason: 'Authenticate to enable biometric login',
      );

      if (!result.isSuccess) {
        throw AppError(
          message: 'Failed to verify biometric authentication',
          userFriendlyMessage: result.errorMessage ?? 'Authentication failed',
        );
      }

      // Store biometric preferences
      await _secureStorage.write(_biometricEnabledKey, 'true');
      await _secureStorage.write(_biometricTypeKey, biometricType.toString());

      return true;
    } catch (e) {
      throw AppError(
        message: 'Failed to enable biometric authentication: ${e.toString()}',
        userFriendlyMessage: 'Failed to enable biometric authentication',
      );
    }
  }

  /// Disable biometric authentication
  Future<void> disableBiometric() async {
    try {
      await _secureStorage.delete(_biometricEnabledKey);
      await _secureStorage.delete(_biometricTypeKey);
    } catch (e) {
      throw AppError(
        message: 'Failed to disable biometric authentication: ${e.toString()}',
        userFriendlyMessage: 'Failed to disable biometric authentication',
      );
    }
  }

  /// Check if biometric is enabled for the user
  Future<bool> isBiometricEnabled() async {
    try {
      final String? enabled = await _secureStorage.read(_biometricEnabledKey);
      return enabled == 'true';
    } catch (e) {
      return false;
    }
  }

  /// Get the enabled biometric type
  Future<BiometricType?> getEnabledBiometricType() async {
    try {
      final String? typeString = await _secureStorage.read(_biometricTypeKey);
      if (typeString == null) return null;

      switch (typeString) {
        case 'BiometricType.fingerprint':
          return BiometricType.fingerprint;
        case 'BiometricType.face':
          return BiometricType.face;
        case 'BiometricType.voice':
          return BiometricType.voice;
        default:
          return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Set up fallback PIN for biometric authentication
  Future<void> setFallbackPin(String pin) async {
    try {
      // In a real app, you'd want to hash this PIN
      await _secureStorage.write(_fallbackPinKey, pin);
    } catch (e) {
      throw AppError(
        message: 'Failed to set fallback PIN: ${e.toString()}',
        userFriendlyMessage: 'Failed to set fallback PIN',
      );
    }
  }

  /// Verify fallback PIN
  Future<bool> verifyFallbackPin(String pin) async {
    try {
      final String? storedPin = await _secureStorage.read(_fallbackPinKey);
      return storedPin == pin;
    } catch (e) {
      return false;
    }
  }

  /// Check if fallback PIN is set
  Future<bool> hasFallbackPin() async {
    try {
      final String? pin = await _secureStorage.read(_fallbackPinKey);
      return pin != null && pin.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get the biometric type that was used for authentication
  Future<BiometricType?> _getUsedBiometric() async {
    // This is a simplified implementation
    // In practice, you might need to track which biometric was actually used
    final List<BiometricType> available = await getAvailableBiometrics();
    final BiometricType? enabled = await getEnabledBiometricType();
    
    if (enabled != null && available.contains(enabled)) {
      return enabled;
    }
    
    return available.isNotEmpty ? available.first : null;
  }

  /// Reset all biometric settings
  Future<void> resetBiometricSettings() async {
    try {
      await _secureStorage.delete(_biometricEnabledKey);
      await _secureStorage.delete(_biometricTypeKey);
      await _secureStorage.delete(_fallbackPinKey);
    } catch (e) {
      throw AppError(
        message: 'Failed to reset biometric settings: ${e.toString()}',
        userFriendlyMessage: 'Failed to reset biometric settings',
      );
    }
  }

  /// Get human-readable name for biometric type
  String getBiometricTypeName(BiometricType type) {
    switch (type) {
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.face:
        return Platform.isIOS ? 'Face ID' : 'Face Recognition';
      case BiometricType.voice:
        return 'Voice Recognition';
      case BiometricType.none:
        return 'None';
    }
  }
}