// lib/features/investment/models/investment_models.dart

enum InvestmentType {
  shareCapital,
  deposit,
  bond,
  treasury,
  fixedDeposit,
  recurring,
}

enum InvestmentStatus {
  active,
  matured,
  pending,
  cancelled,
  withdrawn,
}

enum InvestmentRisk {
  low,
  medium,
  high,
}

class Investment {
  final String id;
  final String name;
  final InvestmentType type;
  final double principalAmount;
  final double currentValue;
  final double interestRate;
  final InvestmentStatus status;
  final InvestmentRisk riskLevel;
  final DateTime startDate;
  final DateTime? maturityDate;
  final String description;
  final List<InvestmentTransaction> transactions;
  final DateTime createdAt;
  final DateTime updatedAt;

  Investment({
    required this.id,
    required this.name,
    required this.type,
    required this.principalAmount,
    required this.currentValue,
    required this.interestRate,
    required this.status,
    required this.riskLevel,
    required this.startDate,
    this.maturityDate,
    this.description = '',
    this.transactions = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  double get totalReturns => currentValue - principalAmount;
  double get returnPercentage => principalAmount > 0 ? (totalReturns / principalAmount) * 100 : 0;
  
  bool get isMatured {
    if (maturityDate == null) return false;
    return DateTime.now().isAfter(maturityDate!);
  }

  int get daysToMaturity {
    if (maturityDate == null) return 0;
    final difference = maturityDate!.difference(DateTime.now());
    return difference.inDays > 0 ? difference.inDays : 0;
  }

  Duration get investmentDuration => DateTime.now().difference(startDate);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.toString(),
        'principalAmount': principalAmount,
        'currentValue': currentValue,
        'interestRate': interestRate,
        'status': status.toString(),
        'riskLevel': riskLevel.toString(),
        'startDate': startDate.toIso8601String(),
        'maturityDate': maturityDate?.toIso8601String(),
        'description': description,
        'transactions': transactions.map((t) => t.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Investment.fromJson(Map<String, dynamic> json) => Investment(
        id: json['id'],
        name: json['name'],
        type: InvestmentType.values.firstWhere(
          (e) => e.toString() == json['type'],
          orElse: () => InvestmentType.deposit,
        ),
        principalAmount: (json['principalAmount'] as num).toDouble(),
        currentValue: (json['currentValue'] as num).toDouble(),
        interestRate: (json['interestRate'] as num).toDouble(),
        status: InvestmentStatus.values.firstWhere(
          (e) => e.toString() == json['status'],
          orElse: () => InvestmentStatus.active,
        ),
        riskLevel: InvestmentRisk.values.firstWhere(
          (e) => e.toString() == json['riskLevel'],
          orElse: () => InvestmentRisk.medium,
        ),
        startDate: DateTime.parse(json['startDate']),
        maturityDate: json['maturityDate'] != null ? DateTime.parse(json['maturityDate']) : null,
        description: json['description'] ?? '',
        transactions: (json['transactions'] as List<dynamic>?)
                ?.map((t) => InvestmentTransaction.fromJson(t))
                .toList() ??
            [],
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
      );

  Investment copyWith({
    String? id,
    String? name,
    InvestmentType? type,
    double? principalAmount,
    double? currentValue,
    double? interestRate,
    InvestmentStatus? status,
    InvestmentRisk? riskLevel,
    DateTime? startDate,
    DateTime? maturityDate,
    String? description,
    List<InvestmentTransaction>? transactions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Investment(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      principalAmount: principalAmount ?? this.principalAmount,
      currentValue: currentValue ?? this.currentValue,
      interestRate: interestRate ?? this.interestRate,
      status: status ?? this.status,
      riskLevel: riskLevel ?? this.riskLevel,
      startDate: startDate ?? this.startDate,
      maturityDate: maturityDate ?? this.maturityDate,
      description: description ?? this.description,
      transactions: transactions ?? this.transactions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum InvestmentTransactionType {
  deposit,
  withdrawal,
  interest,
  dividend,
  maturity,
  penalty,
}

class InvestmentTransaction {
  final String id;
  final String investmentId;
  final InvestmentTransactionType type;
  final double amount;
  final String description;
  final DateTime transactionDate;
  final String? referenceNumber;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  InvestmentTransaction({
    required this.id,
    required this.investmentId,
    required this.type,
    required this.amount,
    required this.description,
    required this.transactionDate,
    this.referenceNumber,
    this.metadata,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'investmentId': investmentId,
        'type': type.toString(),
        'amount': amount,
        'description': description,
        'transactionDate': transactionDate.toIso8601String(),
        'referenceNumber': referenceNumber,
        'metadata': metadata,
        'createdAt': createdAt.toIso8601String(),
      };

  factory InvestmentTransaction.fromJson(Map<String, dynamic> json) => InvestmentTransaction(
        id: json['id'],
        investmentId: json['investmentId'],
        type: InvestmentTransactionType.values.firstWhere(
          (e) => e.toString() == json['type'],
          orElse: () => InvestmentTransactionType.deposit,
        ),
        amount: (json['amount'] as num).toDouble(),
        description: json['description'],
        transactionDate: DateTime.parse(json['transactionDate']),
        referenceNumber: json['referenceNumber'],
        metadata: json['metadata'],
        createdAt: DateTime.parse(json['createdAt']),
      );
}

class InvestmentPortfolio {
  final double totalInvestments;
  final double totalValue;
  final double totalReturns;
  final double averageReturn;
  final List<Investment> investments;
  final Map<InvestmentType, double> allocationByType;
  final Map<InvestmentRisk, double> allocationByRisk;

  InvestmentPortfolio({
    required this.totalInvestments,
    required this.totalValue,
    required this.totalReturns,
    required this.averageReturn,
    required this.investments,
    required this.allocationByType,
    required this.allocationByRisk,
  });

  double get returnPercentage => totalInvestments > 0 ? (totalReturns / totalInvestments) * 100 : 0;
  
  int get activeInvestmentsCount => investments.where((i) => i.status == InvestmentStatus.active).length;
  int get maturedInvestmentsCount => investments.where((i) => i.status == InvestmentStatus.matured).length;
  
  Investment? get topPerformer {
    if (investments.isEmpty) return null;
    return investments.reduce((a, b) => a.returnPercentage > b.returnPercentage ? a : b);
  }
}

// Extension methods for better display
extension InvestmentTypeExtension on InvestmentType {
  String get displayName {
    switch (this) {
      case InvestmentType.shareCapital:
        return 'Share Capital';
      case InvestmentType.deposit:
        return 'Fixed Deposit';
      case InvestmentType.bond:
        return 'Corporate Bond';
      case InvestmentType.treasury:
        return 'Treasury Bill';
      case InvestmentType.fixedDeposit:
        return 'Term Deposit';
      case InvestmentType.recurring:
        return 'Recurring Deposit';
    }
  }

  String get iconName {
    switch (this) {
      case InvestmentType.shareCapital:
        return 'trending_up';
      case InvestmentType.deposit:
        return 'account_balance';
      case InvestmentType.bond:
        return 'receipt_long';
      case InvestmentType.treasury:
        return 'security';
      case InvestmentType.fixedDeposit:
        return 'savings';
      case InvestmentType.recurring:
        return 'autorenew';
    }
  }
}

extension InvestmentStatusExtension on InvestmentStatus {
  String get displayName {
    switch (this) {
      case InvestmentStatus.active:
        return 'Active';
      case InvestmentStatus.matured:
        return 'Matured';
      case InvestmentStatus.pending:
        return 'Pending';
      case InvestmentStatus.cancelled:
        return 'Cancelled';
      case InvestmentStatus.withdrawn:
        return 'Withdrawn';
    }
  }
}

extension InvestmentRiskExtension on InvestmentRisk {
  String get displayName {
    switch (this) {
      case InvestmentRisk.low:
        return 'Low Risk';
      case InvestmentRisk.medium:
        return 'Medium Risk';
      case InvestmentRisk.high:
        return 'High Risk';
    }
  }
}

extension InvestmentTransactionTypeExtension on InvestmentTransactionType {
  String get displayName {
    switch (this) {
      case InvestmentTransactionType.deposit:
        return 'Deposit';
      case InvestmentTransactionType.withdrawal:
        return 'Withdrawal';
      case InvestmentTransactionType.interest:
        return 'Interest';
      case InvestmentTransactionType.dividend:
        return 'Dividend';
      case InvestmentTransactionType.maturity:
        return 'Maturity';
      case InvestmentTransactionType.penalty:
        return 'Penalty';
    }
  }
}