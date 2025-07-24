// lib/features/investment/providers/investment_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/investment_models.dart';

// Investment state classes
class InvestmentListState {
  final List<Investment> investments;
  final bool isLoading;
  final String? errorMessage;

  const InvestmentListState({
    this.investments = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  InvestmentListState copyWith({
    List<Investment>? investments,
    bool? isLoading,
    String? errorMessage,
  }) {
    return InvestmentListState(
      investments: investments ?? this.investments,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class InvestmentFormState {
  final String name;
  final InvestmentType type;
  final double amount;
  final double interestRate;
  final InvestmentRisk riskLevel;
  final DateTime startDate;
  final DateTime? maturityDate;
  final String description;
  final bool isLoading;
  final String? errorMessage;

  InvestmentFormState({
    this.name = '',
    this.type = InvestmentType.deposit,
    this.amount = 0.0,
    this.interestRate = 0.0,
    this.riskLevel = InvestmentRisk.medium,
    DateTime? startDate,
    this.maturityDate,
    this.description = '',
    this.isLoading = false,
    this.errorMessage,
  }) : startDate = startDate ?? DateTime.now();

  InvestmentFormState copyWith({
    String? name,
    InvestmentType? type,
    double? amount,
    double? interestRate,
    InvestmentRisk? riskLevel,
    DateTime? startDate,
    DateTime? maturityDate,
    String? description,
    bool? isLoading,
    String? errorMessage,
  }) {
    return InvestmentFormState(
      name: name ?? this.name,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      interestRate: interestRate ?? this.interestRate,
      riskLevel: riskLevel ?? this.riskLevel,
      startDate: startDate ?? this.startDate,
      maturityDate: maturityDate ?? this.maturityDate,
      description: description ?? this.description,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// Investment state notifiers
class InvestmentListNotifier extends StateNotifier<InvestmentListState> {
  InvestmentListNotifier() : super(const InvestmentListState());

  Future<void> loadInvestments() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Simulate API call - replace with actual repository call
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock data
      final mockInvestments = [
        Investment(
          id: '1',
          name: 'Fixed Deposit - 12 Months',
          type: InvestmentType.fixedDeposit,
          principalAmount: 100000.0,
          currentValue: 108000.0,
          interestRate: 8.0,
          status: InvestmentStatus.active,
          riskLevel: InvestmentRisk.low,
          startDate: DateTime(2024, 1, 1),
          maturityDate: DateTime(2024, 12, 31),
          description: 'Annual fixed deposit with guaranteed 8% return',
          transactions: [
            InvestmentTransaction(
              id: '1',
              investmentId: '1',
              type: InvestmentTransactionType.deposit,
              amount: 100000.0,
              description: 'Initial deposit',
              transactionDate: DateTime(2024, 1, 1),
              referenceNumber: 'FD001',
              createdAt: DateTime(2024, 1, 1),
            ),
          ],
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime.now(),
        ),
        Investment(
          id: '2',
          name: 'Share Capital Investment',
          type: InvestmentType.shareCapital,
          principalAmount: 50000.0,
          currentValue: 62500.0,
          interestRate: 12.5,
          status: InvestmentStatus.active,
          riskLevel: InvestmentRisk.medium,
          startDate: DateTime(2023, 6, 1),
          description: 'Investment in SACCO share capital',
          transactions: [
            InvestmentTransaction(
              id: '2',
              investmentId: '2',
              type: InvestmentTransactionType.deposit,
              amount: 50000.0,
              description: 'Share capital purchase',
              transactionDate: DateTime(2023, 6, 1),
              referenceNumber: 'SC001',
              createdAt: DateTime(2023, 6, 1),
            ),
            InvestmentTransaction(
              id: '3',
              investmentId: '2',
              type: InvestmentTransactionType.dividend,
              amount: 12500.0,
              description: 'Annual dividend payment',
              transactionDate: DateTime(2024, 6, 1),
              referenceNumber: 'DIV001',
              createdAt: DateTime(2024, 6, 1),
            ),
          ],
          createdAt: DateTime(2023, 6, 1),
          updatedAt: DateTime.now(),
        ),
        Investment(
          id: '3',
          name: 'Treasury Bill - 91 Days',
          type: InvestmentType.treasury,
          principalAmount: 25000.0,
          currentValue: 25000.0,  // Matured
          interestRate: 6.5,
          status: InvestmentStatus.matured,
          riskLevel: InvestmentRisk.low,
          startDate: DateTime(2024, 4, 1),
          maturityDate: DateTime(2024, 7, 1),
          description: '91-day treasury bill investment',
          transactions: [
            InvestmentTransaction(
              id: '4',
              investmentId: '3',
              type: InvestmentTransactionType.deposit,
              amount: 25000.0,
              description: 'Treasury bill purchase',
              transactionDate: DateTime(2024, 4, 1),
              referenceNumber: 'TB001',
              createdAt: DateTime(2024, 4, 1),
            ),
            InvestmentTransaction(
              id: '5',
              investmentId: '3',
              type: InvestmentTransactionType.maturity,
              amount: 25406.25,
              description: 'Treasury bill maturity payment',
              transactionDate: DateTime(2024, 7, 1),
              referenceNumber: 'TBM001',
              createdAt: DateTime(2024, 7, 1),
            ),
          ],
          createdAt: DateTime(2024, 4, 1),
          updatedAt: DateTime(2024, 7, 1),
        ),
      ];

      state = state.copyWith(
        investments: mockInvestments,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> withdrawInvestment(String investmentId, double amount) async {
    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));
      
      final updatedInvestments = state.investments.map((investment) {
        if (investment.id == investmentId) {
          return investment.copyWith(
            currentValue: investment.currentValue - amount,
            status: amount >= investment.currentValue 
                ? InvestmentStatus.withdrawn 
                : investment.status,
          );
        }
        return investment;
      }).toList();
      
      state = state.copyWith(investments: updatedInvestments);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

class InvestmentFormNotifier extends StateNotifier<InvestmentFormState> {
  InvestmentFormNotifier() : super(InvestmentFormState(startDate: DateTime.now()));

  void updateName(String name) {
    state = state.copyWith(name: name);
  }

  void updateType(InvestmentType type) {
    state = state.copyWith(type: type);
  }

  void updateAmount(double amount) {
    state = state.copyWith(amount: amount);
  }

  void updateInterestRate(double rate) {
    state = state.copyWith(interestRate: rate);
  }

  void updateRiskLevel(InvestmentRisk risk) {
    state = state.copyWith(riskLevel: risk);
  }

  void updateStartDate(DateTime date) {
    state = state.copyWith(startDate: date);
  }

  void updateMaturityDate(DateTime? date) {
    state = state.copyWith(maturityDate: date);
  }

  void updateDescription(String description) {
    state = state.copyWith(description: description);
  }

  Future<bool> createInvestment() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Validate form
      if (state.name.isEmpty) {
        throw Exception('Investment name is required');
      }
      if (state.amount <= 0) {
        throw Exception('Amount must be greater than 0');
      }
      if (state.interestRate < 0) {
        throw Exception('Interest rate cannot be negative');
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
    state = InvestmentFormState(startDate: DateTime.now());
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

// Providers
final investmentListProvider = StateNotifierProvider<InvestmentListNotifier, InvestmentListState>((ref) {
  return InvestmentListNotifier();
});

final investmentFormProvider = StateNotifierProvider<InvestmentFormNotifier, InvestmentFormState>((ref) {
  return InvestmentFormNotifier();
});

// Computed providers
final investmentPortfolioProvider = Provider<InvestmentPortfolio?>((ref) {
  final investmentState = ref.watch(investmentListProvider);
  
  if (investmentState.investments.isEmpty) return null;

  final investments = investmentState.investments;
  final totalInvestments = investments.fold(0.0, (sum, inv) => sum + inv.principalAmount);
  final totalValue = investments.fold(0.0, (sum, inv) => sum + inv.currentValue);
  final totalReturns = totalValue - totalInvestments;
  final averageReturn = investments.isNotEmpty 
      ? investments.fold(0.0, (sum, inv) => sum + inv.returnPercentage) / investments.length
      : 0.0;

  // Calculate allocation by type
  final allocationByType = <InvestmentType, double>{};
  for (final investment in investments) {
    allocationByType[investment.type] = 
        (allocationByType[investment.type] ?? 0) + investment.currentValue;
  }

  // Calculate allocation by risk
  final allocationByRisk = <InvestmentRisk, double>{};
  for (final investment in investments) {
    allocationByRisk[investment.riskLevel] = 
        (allocationByRisk[investment.riskLevel] ?? 0) + investment.currentValue;
  }

  return InvestmentPortfolio(
    totalInvestments: totalInvestments,
    totalValue: totalValue,
    totalReturns: totalReturns,
    averageReturn: averageReturn,
    investments: investments,
    allocationByType: allocationByType,
    allocationByRisk: allocationByRisk,
  );
});

final activeInvestmentsProvider = Provider<List<Investment>>((ref) {
  final investmentState = ref.watch(investmentListProvider);
  return investmentState.investments
      .where((inv) => inv.status == InvestmentStatus.active)
      .toList();
});

final maturedInvestmentsProvider = Provider<List<Investment>>((ref) {
  final investmentState = ref.watch(investmentListProvider);
  return investmentState.investments
      .where((inv) => inv.status == InvestmentStatus.matured)
      .toList();
});

final maturingSoonProvider = Provider<List<Investment>>((ref) {
  final investmentState = ref.watch(investmentListProvider);
  final thirtyDaysFromNow = DateTime.now().add(const Duration(days: 30));
  
  return investmentState.investments
      .where((inv) => 
          inv.status == InvestmentStatus.active &&
          inv.maturityDate != null &&
          inv.maturityDate!.isBefore(thirtyDaysFromNow))
      .toList();
});