import 'package:flutter/material.dart';
import 'package:sacco_mobile/core/errors/app_error.dart';
import 'package:sacco_mobile/features/savings/models/transaction.dart';
import 'package:sacco_mobile/features/savings/repositories/savings_repository.dart';

enum TransactionState {
  initial,
  loading,
  success,
  error,
}

class TransactionViewModel extends ChangeNotifier {
  final SavingsRepository _savingsRepository;

  TransactionState _state = TransactionState.initial;
  TransactionState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<Transaction> _transactions = [];
  List<Transaction> get transactions => _transactions;

  // Pagination and filtering
  int _page = 1;
  final int _pageSize = 20;
  bool _hasMoreTransactions = true;
  bool get hasMoreTransactions => _hasMoreTransactions;

  // Optional filters
  int? _accountId;
  DateTime? _startDate;
  DateTime? _endDate;

  // Getters for filters
  int? get accountId => _accountId;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  TransactionViewModel(this._savingsRepository);

  // Load initial transactions
  Future<void> loadTransactions({
    int? accountId,
    DateTime? startDate,
    DateTime? endDate,
    bool refresh = false,
  }) async {
    // Set filters
    if (refresh ||
        accountId != _accountId ||
        startDate != _startDate ||
        endDate != _endDate) {
      _page = 1;
      _hasMoreTransactions = true;
      _transactions = [];
      _accountId = accountId;
      _startDate = startDate;
      _endDate = endDate;
    }

    if (!_hasMoreTransactions && !refresh) {
      return;
    }

    _state = TransactionState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final newTransactions = await _savingsRepository.getTransactions(
        accountId: _accountId,
        startDate: _startDate?.toIso8601String(),
        endDate: _endDate?.toIso8601String(),
        limit: _pageSize,
        offset: (_page - 1) * _pageSize,
      );

      if (newTransactions.isEmpty) {
        _hasMoreTransactions = false;
      } else {
        _transactions =
            refresh ? newTransactions : [..._transactions, ...newTransactions];
        _page++;
      }

      _state = TransactionState.success;
      notifyListeners();
    } on AppError catch (e) {
      _state = TransactionState.error;
      _errorMessage = e.userFriendlyMessage;
      notifyListeners();
    } catch (e) {
      _state = TransactionState.error;
      _errorMessage = 'An unexpected error occurred. Please try again.';
      notifyListeners();
    }
  }

  // Load more transactions (pagination)
  Future<void> loadMoreTransactions() async {
    if (!_hasMoreTransactions || _state == TransactionState.loading) {
      return;
    }

    await loadTransactions(
      accountId: _accountId,
      startDate: _startDate,
      endDate: _endDate,
    );
  }

  // Refresh transactions
  Future<void> refreshTransactions() async {
    await loadTransactions(
      accountId: _accountId,
      startDate: _startDate,
      endDate: _endDate,
      refresh: true,
    );
  }

  // Filter transactions by date range
  Future<void> filterTransactionsByDateRange(
      DateTime start, DateTime end) async {
    await loadTransactions(
      accountId: _accountId,
      startDate: start,
      endDate: end,
      refresh: true,
    );
  }

  // Filter transactions by account
  Future<void> filterTransactionsByAccount(int accountId) async {
    await loadTransactions(
      accountId: accountId,
      startDate: _startDate,
      endDate: _endDate,
      refresh: true,
    );
  }

  // Reset filters
  Future<void> resetFilters() async {
    await loadTransactions(refresh: true);
  }

  // Get transaction by ID
  Future<Transaction?> getTransactionById(int transactionId) async {
    try {
      // First check if transaction is already in the list
      final existingTransactionIndex = _transactions.indexWhere(
        (tx) => tx.id == transactionId,
      );

      if (existingTransactionIndex != -1) {
        return _transactions[existingTransactionIndex];
      }

      // If not found, attempt to fetch from API (implementation depends on API)
      // This is a placeholder - actual implementation would depend on your API

      return null;
    } catch (e) {
      return null;
    }
  }
}
