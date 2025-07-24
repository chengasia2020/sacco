// lib/features/budget/providers/budget_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/budget_models.dart';

// Budget state classes
class BudgetListState {
  final List<Budget> budgets;
  final bool isLoading;
  final String? errorMessage;

  const BudgetListState({
    this.budgets = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  BudgetListState copyWith({
    List<Budget>? budgets,
    bool? isLoading,
    String? errorMessage,
  }) {
    return BudgetListState(
      budgets: budgets ?? this.budgets,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class BudgetFormState {
  final String name;
  final double totalAmount;
  final BudgetPeriod period;
  final DateTime startDate;
  final List<BudgetItem> items;
  final bool isLoading;
  final String? errorMessage;

  BudgetFormState({
    this.name = '',
    this.totalAmount = 0.0,
    this.period = BudgetPeriod.monthly,
    DateTime? startDate,
    this.items = const [],
    this.isLoading = false,
    this.errorMessage,
  }) : startDate = startDate ?? DateTime.now();

  BudgetFormState copyWith({
    String? name,
    double? totalAmount,
    BudgetPeriod? period,
    DateTime? startDate,
    List<BudgetItem>? items,
    bool? isLoading,
    String? errorMessage,
  }) {
    return BudgetFormState(
      name: name ?? this.name,
      totalAmount: totalAmount ?? this.totalAmount,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// Budget state notifiers
class BudgetListNotifier extends StateNotifier<BudgetListState> {
  BudgetListNotifier() : super(const BudgetListState());

  Future<void> loadBudgets() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Simulate API call - replace with actual repository call
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock data
      final mockBudgets = [
        Budget(
          id: '1',
          name: 'Monthly Budget - January 2024',
          totalAmount: 50000.0,
          period: BudgetPeriod.monthly,
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 31),
          items: [
            BudgetItem(
              id: '1',
              budgetId: '1',
              category: BudgetCategory.food,
              name: 'Food & Groceries',
              allocatedAmount: 15000.0,
              spentAmount: 12500.0,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
            BudgetItem(
              id: '2',
              budgetId: '1',
              category: BudgetCategory.transportation,
              name: 'Transport',
              allocatedAmount: 10000.0,
              spentAmount: 8500.0,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      state = state.copyWith(
        budgets: mockBudgets,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> deleteBudget(String budgetId) async {
    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));
      
      final updatedBudgets = state.budgets.where((b) => b.id != budgetId).toList();
      state = state.copyWith(budgets: updatedBudgets);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

class BudgetFormNotifier extends StateNotifier<BudgetFormState> {
  BudgetFormNotifier() : super(BudgetFormState(startDate: DateTime.now()));

  void updateName(String name) {
    state = state.copyWith(name: name);
  }

  void updateTotalAmount(double amount) {
    state = state.copyWith(totalAmount: amount);
  }

  void updatePeriod(BudgetPeriod period) {
    state = state.copyWith(period: period);
  }

  void updateStartDate(DateTime startDate) {
    state = state.copyWith(startDate: startDate);
  }

  void addBudgetItem(BudgetItem item) {
    final updatedItems = [...state.items, item];
    state = state.copyWith(items: updatedItems);
  }

  void removeBudgetItem(String itemId) {
    final updatedItems = state.items.where((item) => item.id != itemId).toList();
    state = state.copyWith(items: updatedItems);
  }

  void updateBudgetItem(BudgetItem updatedItem) {
    final updatedItems = state.items.map((item) {
      return item.id == updatedItem.id ? updatedItem : item;
    }).toList();
    state = state.copyWith(items: updatedItems);
  }

  Future<bool> saveBudget() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Validate form
      if (state.name.isEmpty) {
        throw Exception('Budget name is required');
      }
      if (state.totalAmount <= 0) {
        throw Exception('Total amount must be greater than 0');
      }
      if (state.items.isEmpty) {
        throw Exception('At least one budget item is required');
      }

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  void resetForm() {
    state = BudgetFormState(startDate: DateTime.now());
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

// Providers
final budgetListProvider = StateNotifierProvider<BudgetListNotifier, BudgetListState>((ref) {
  return BudgetListNotifier();
});

final budgetFormProvider = StateNotifierProvider<BudgetFormNotifier, BudgetFormState>((ref) {
  return BudgetFormNotifier();
});

// Computed providers
final budgetSummaryProvider = Provider<BudgetSummary?>((ref) {
  final budgetState = ref.watch(budgetListProvider);
  
  if (budgetState.budgets.isEmpty) return null;

  final totalBudget = budgetState.budgets.fold(0.0, (sum, budget) => sum + budget.totalAmount);
  final totalSpent = budgetState.budgets.fold(0.0, (sum, budget) => sum + budget.totalSpent);
  final totalRemaining = totalBudget - totalSpent;
  final progressPercentage = totalBudget > 0 ? (totalSpent / totalBudget) * 100 : 0.0;

  // Count over-budget items
  int overBudgetItems = 0;
  final categorySpending = <BudgetCategory, double>{};

  for (final budget in budgetState.budgets) {
    for (final item in budget.items) {
      if (item.isOverBudget) overBudgetItems++;
      
      categorySpending[item.category] = 
          (categorySpending[item.category] ?? 0) + item.spentAmount;
    }
  }

  // Find top spending category
  BudgetCategory topSpendingCategory = BudgetCategory.other;
  double maxSpending = 0;
  categorySpending.forEach((category, spending) {
    if (spending > maxSpending) {
      maxSpending = spending;
      topSpendingCategory = category;
    }
  });

  return BudgetSummary(
    totalBudget: totalBudget,
    totalSpent: totalSpent,
    totalRemaining: totalRemaining,
    progressPercentage: progressPercentage,
    totalBudgets: budgetState.budgets.length,
    overBudgetItems: overBudgetItems,
    topSpendingCategory: topSpendingCategory,
  );
});

final currentBudgetProvider = Provider<Budget?>((ref) {
  final budgetState = ref.watch(budgetListProvider);
  final now = DateTime.now();
  
  // Find the current active budget
  return budgetState.budgets.cast<Budget?>().firstWhere(
    (budget) => budget!.startDate.isBefore(now) && budget.endDate.isAfter(now),
    orElse: () => null,
  );
});