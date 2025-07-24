import 'package:flutter/material.dart';
import 'package:sacco_mobile/core/errors/app_error.dart';
import 'package:sacco_mobile/features/loans/models/loan.dart';
import 'package:sacco_mobile/features/loans/repositories/loan_repository.dart';

enum LoanListState {
  initial,
  loading,
  success,
  error,
}

class LoanListViewModel extends ChangeNotifier {
  final LoanRepository _loanRepository;

  LoanListState _state = LoanListState.initial;
  LoanListState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<Loan> _loans = [];
  List<Loan> get loans => _loans;

  List<Loan> _activeLoans = [];
  List<Loan> get activeLoans => _activeLoans;

  LoanListViewModel(this._loanRepository);

  // Load all loans
  Future<void> loadLoans() async {
    _state = LoanListState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final loans = await _loanRepository.getLoans();
      _loans = loans;
      
      // Filter active loans (DISBURSED status)
      _activeLoans = loans.where((loan) => loan.isActive).toList();
      
      _state = LoanListState.success;
      notifyListeners();
    } on AppError catch (e) {
      _state = LoanListState.error;
      _errorMessage = e.userFriendlyMessage;
      notifyListeners();
    } catch (e) {
      _state = LoanListState.error;
      _errorMessage = 'An unexpected error occurred. Please try again.';
      notifyListeners();
    }
  }

  // Load active loans only
  Future<void> loadActiveLoans() async {
    _state = LoanListState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final loans = await _loanRepository.getActiveLoans();
      _activeLoans = loans;
      _state = LoanListState.success;
      notifyListeners();
    } on AppError catch (e) {
      _state = LoanListState.error;
      _errorMessage = e.userFriendlyMessage;
      notifyListeners();
    } catch (e) {
      _state = LoanListState.error;
      _errorMessage = 'An unexpected error occurred. Please try again.';
      notifyListeners();
    }
  }

  // Get loan by ID
  Future<Loan?> getLoanById(int loanId) async {
    try {
      // First check if loan is already in the list
      final existingLoanIndex = _loans.indexWhere(
        (loan) => loan.id == loanId,
      );

      if (existingLoanIndex != -1) {
        return _loans[existingLoanIndex];
      }

      // If not found, fetch from API
      return await _loanRepository.getLoanById(loanId);
    } catch (e) {
      return null;
    }
  }

  // Refresh loans
  Future<void> refreshLoans() async {
    return loadLoans();
  }
}