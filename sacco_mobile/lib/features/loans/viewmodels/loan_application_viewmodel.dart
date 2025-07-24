import 'package:flutter/material.dart';
import 'package:sacco_mobile/core/errors/app_error.dart';
import 'package:sacco_mobile/features/loans/models/loan_application.dart';
import 'package:sacco_mobile/features/loans/repositories/loan_repository.dart';

enum LoanApplicationState {
  initial,
  loading,
  success,
  error,
  submitting,
  submitted,
}

class LoanApplicationViewModel extends ChangeNotifier {
  final LoanRepository _loanRepository;

  LoanApplicationState _state = LoanApplicationState.initial;
  LoanApplicationState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<LoanApplication> _loanApplications = [];
  List<LoanApplication> get loanApplications => _loanApplications;

  // Current application being created or viewed
  LoanApplication? _currentApplication;
  LoanApplication? get currentApplication => _currentApplication;

  // Available loan types
  final List<Map<String, dynamic>> _loanTypes = [
    {
      'value': 'PERSONAL',
      'label': 'Personal Loan',
      'maxTerm': 24,
      'interestRate': 15.0,
      'description': 'General purpose loans for personal use.',
    },
    {
      'value': 'BUSINESS',
      'label': 'Business Loan',
      'maxTerm': 36,
      'interestRate': 16.5,
      'description': 'Financing for business expansion and operations.',
    },
    {
      'value': 'EDUCATION',
      'label': 'Education Loan',
      'maxTerm': 48,
      'interestRate': 12.0,
      'description': 'Low interest loans for education expenses.',
    },
    {
      'value': 'EMERGENCY',
      'label': 'Emergency Loan',
      'maxTerm': 6,
      'interestRate': 18.0,
      'description': 'Quick access loans for urgent needs with minimal documentation.',
    },
  ];
  
  List<Map<String, dynamic>> get loanTypes => _loanTypes;

  LoanApplicationViewModel(this._loanRepository);

  // Load loan applications
  Future<void> loadLoanApplications() async {
    _state = LoanApplicationState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final applications = await _loanRepository.getLoanApplications();
      _loanApplications = applications;
      _state = LoanApplicationState.success;
      notifyListeners();
    } on AppError catch (e) {
      _state = LoanApplicationState.error;
      _errorMessage = e.userFriendlyMessage;
      notifyListeners();
    } catch (e) {
      _state = LoanApplicationState.error;
      _errorMessage = 'An unexpected error occurred. Please try again.';
      notifyListeners();
    }
  }

  // Submit new loan application
  Future<bool> submitLoanApplication(Map<String, dynamic> applicationData) async {
    _state = LoanApplicationState.submitting;
    _errorMessage = null;
    notifyListeners();

    try {
      final application = await _loanRepository.applyForLoan(applicationData);
      
      // Update current application
      _currentApplication = application;
      
      // Update list of applications
      _loanApplications = [application, ..._loanApplications];
      
      _state = LoanApplicationState.submitted;
      notifyListeners();
      return true;
    } on AppError catch (e) {
      _state = LoanApplicationState.error;
      _errorMessage = e.userFriendlyMessage;
      notifyListeners();
      return false;
    } catch (e) {
      _state = LoanApplicationState.error;
      _errorMessage = 'An unexpected error occurred. Please try again.';
      notifyListeners();
      return false;
    }
  }

  // Get loan application by ID
  Future<LoanApplication?> getLoanApplicationById(int applicationId) async {
    try {
      // First check if application is already in the list
      final existingApplicationIndex = _loanApplications.indexWhere(
        (app) => app.id == applicationId,
      );

      if (existingApplicationIndex != -1) {
        return _loanApplications[existingApplicationIndex];
      }

      // If not found, fetch from API
      return await _loanRepository.getLoanApplicationById(applicationId);
    } catch (e) {
      return null;
    }
  }

  // Set current application
  void setCurrentApplication(LoanApplication application) {
    _currentApplication = application;
    notifyListeners();
  }

  // Calculate monthly payment
  double calculateMonthlyPayment(double amount, double rate, int term) {
    final monthlyRate = rate / 100 / 12;
    final payment = (amount * monthlyRate * pow((1 + monthlyRate), term)) /
                  (pow((1 + monthlyRate), term) - 1);
    return payment;
  }

  // Calculate total interest
  double calculateTotalInterest(double amount, double rate, int term) {
    final monthlyPayment = calculateMonthlyPayment(amount, rate, term);
    final totalPayment = monthlyPayment * term;
    return totalPayment - amount;
  }

  // Helper function for exponential calculation (since dart:math is not imported)
  double pow(double x, int y) {
    double result = 1.0;
    for (int i = 0; i < y; i++) {
      result *= x;
    }
    return result;
  }

  // Get loan type details
  Map<String, dynamic>? getLoanTypeDetails(String loanType) {
    try {
      return _loanTypes.firstWhere((type) => type['value'] == loanType);
    } catch (e) {
      return null;
    }
  }

  // Reset state
  void resetState() {
    _state = LoanApplicationState.initial;
    _errorMessage = null;
    _currentApplication = null;
    notifyListeners();
  }
}