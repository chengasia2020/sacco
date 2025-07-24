import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sacco_mobile/core/errors/app_error.dart';
import 'package:sacco_mobile/features/profile/models/member_profile.dart';
import 'package:sacco_mobile/features/profile/repositories/profile_repository.dart';

enum ProfileState {
  initial,
  loading,
  success,
  error,
}

class ProfileViewModel extends ChangeNotifier {
  final ProfileRepository _profileRepository;

  ProfileState _state = ProfileState.initial;
  ProfileState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  MemberProfile? _memberProfile;
  MemberProfile? get memberProfile => _memberProfile;

  List<Map<String, dynamic>> _nextOfKin = [];
  List<Map<String, dynamic>> get nextOfKin => _nextOfKin;

  ProfileViewModel(this._profileRepository);

  // Load member profile
  Future<void> loadMemberProfile() async {
    _state = ProfileState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final memberProfile = await _profileRepository.getMemberProfile();
      final nextOfKin = await _profileRepository.getMemberNextOfKin();

      _memberProfile = memberProfile;
      _nextOfKin = nextOfKin;
      _state = ProfileState.success;
      notifyListeners();
    } on AppError catch (e) {
      _state = ProfileState.error;
      _errorMessage = e.userFriendlyMessage;
      notifyListeners();
    } catch (e) {
      _state = ProfileState.error;
      _errorMessage = 'An unexpected error occurred. Please try again.';
      notifyListeners();
    }
  }

  // Update member profile
  Future<bool> updateMemberProfile(Map<String, dynamic> profileData) async {
    _state = ProfileState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedProfile =
          await _profileRepository.updateMemberProfile(profileData);

      _memberProfile = updatedProfile;
      _state = ProfileState.success;
      notifyListeners();
      return true;
    } on AppError catch (e) {
      _state = ProfileState.error;
      _errorMessage = e.userFriendlyMessage;
      notifyListeners();
      return false;
    } catch (e) {
      _state = ProfileState.error;
      _errorMessage = 'An unexpected error occurred. Please try again.';
      notifyListeners();
      return false;
    }
  }

  // Upload profile photo
  Future<bool> uploadProfilePhoto(File photoFile) async {
    _state = ProfileState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _profileRepository.uploadProfilePhoto(photoFile);

      // Update member profile with new photo URL
      if (_memberProfile != null) {
        final updatedProfile = await _profileRepository.getMemberProfile();
        _memberProfile = updatedProfile;
      }

      _state = ProfileState.success;
      notifyListeners();
      return true;
    } on AppError catch (e) {
      _state = ProfileState.error;
      _errorMessage = e.userFriendlyMessage;
      notifyListeners();
      return false;
    } catch (e) {
      _state = ProfileState.error;
      _errorMessage = 'An unexpected error occurred. Please try again.';
      notifyListeners();
      return false;
    }
  }

  // Upload ID document
  Future<bool> uploadIdDocument(File documentFile) async {
    _state = ProfileState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _profileRepository.uploadIdDocument(documentFile);

      // Update member profile with new document URL
      if (_memberProfile != null) {
        final updatedProfile = await _profileRepository.getMemberProfile();
        _memberProfile = updatedProfile;
      }

      _state = ProfileState.success;
      notifyListeners();
      return true;
    } on AppError catch (e) {
      _state = ProfileState.error;
      _errorMessage = e.userFriendlyMessage;
      notifyListeners();
      return false;
    } catch (e) {
      _state = ProfileState.error;
      _errorMessage = 'An unexpected error occurred. Please try again.';
      notifyListeners();
      return false;
    }
  }

  // Add next of kin
  Future<bool> addNextOfKin(Map<String, dynamic> nextOfKinData) async {
    _state = ProfileState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _profileRepository.addNextOfKin(nextOfKinData);

      // Reload next of kin list
      final nextOfKin = await _profileRepository.getMemberNextOfKin();
      _nextOfKin = nextOfKin;

      _state = ProfileState.success;
      notifyListeners();
      return true;
    } on AppError catch (e) {
      _state = ProfileState.error;
      _errorMessage = e.userFriendlyMessage;
      notifyListeners();
      return false;
    } catch (e) {
      _state = ProfileState.error;
      _errorMessage = 'An unexpected error occurred. Please try again.';
      notifyListeners();
      return false;
    }
  }

  // Update next of kin
  Future<bool> updateNextOfKin(
      int nextOfKinId, Map<String, dynamic> nextOfKinData) async {
    _state = ProfileState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _profileRepository.updateNextOfKin(
        nextOfKinId,
        nextOfKinData,
      );

      // Reload next of kin list
      final nextOfKin = await _profileRepository.getMemberNextOfKin();
      _nextOfKin = nextOfKin;

      _state = ProfileState.success;
      notifyListeners();
      return true;
    } on AppError catch (e) {
      _state = ProfileState.error;
      _errorMessage = e.userFriendlyMessage;
      notifyListeners();
      return false;
    } catch (e) {
      _state = ProfileState.error;
      _errorMessage = 'An unexpected error occurred. Please try again.';
      notifyListeners();
      return false;
    }
  }

  // Delete next of kin
  Future<bool> deleteNextOfKin(int nextOfKinId) async {
    _state = ProfileState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _profileRepository.deleteNextOfKin(nextOfKinId);

      // Reload next of kin list
      final nextOfKin = await _profileRepository.getMemberNextOfKin();
      _nextOfKin = nextOfKin;

      _state = ProfileState.success;
      notifyListeners();
      return true;
    } on AppError catch (e) {
      _state = ProfileState.error;
      _errorMessage = e.userFriendlyMessage;
      notifyListeners();
      return false;
    } catch (e) {
      _state = ProfileState.error;
      _errorMessage = 'An unexpected error occurred. Please try again.';
      notifyListeners();
      return false;
    }
  }

  // Refresh profile data
  Future<void> refreshProfile() async {
    await loadMemberProfile();
  }
}
