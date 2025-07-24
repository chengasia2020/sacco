// lib/features/budget/models/budget_models.dart

enum BudgetPeriod {
  weekly,
  monthly,
  yearly,
}

enum BudgetCategory {
  food,
  transportation,
  utilities,
  entertainment,
  healthcare,
  education,
  clothing,
  savings,
  other,
}

class Budget {
  final String id;
  final String name;
  final double totalAmount;
  final BudgetPeriod period;
  final DateTime startDate;
  final DateTime endDate;
  final List<BudgetItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  Budget({
    required this.id,
    required this.name,
    required this.totalAmount,
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  double get totalAllocated => items.fold(0.0, (sum, item) => sum + item.allocatedAmount);
  double get totalSpent => items.fold(0.0, (sum, item) => sum + item.spentAmount);
  double get remainingAmount => totalAmount - totalSpent;
  double get progressPercentage => totalAmount > 0 ? (totalSpent / totalAmount) * 100 : 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'totalAmount': totalAmount,
        'period': period.toString(),
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'items': items.map((item) => item.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Budget.fromJson(Map<String, dynamic> json) => Budget(
        id: json['id'],
        name: json['name'],
        totalAmount: (json['totalAmount'] as num).toDouble(),
        period: BudgetPeriod.values.firstWhere(
          (e) => e.toString() == json['period'],
          orElse: () => BudgetPeriod.monthly,
        ),
        startDate: DateTime.parse(json['startDate']),
        endDate: DateTime.parse(json['endDate']),
        items: (json['items'] as List<dynamic>)
            .map((item) => BudgetItem.fromJson(item))
            .toList(),
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
      );

  Budget copyWith({
    String? id,
    String? name,
    double? totalAmount,
    BudgetPeriod? period,
    DateTime? startDate,
    DateTime? endDate,
    List<BudgetItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Budget(
      id: id ?? this.id,
      name: name ?? this.name,
      totalAmount: totalAmount ?? this.totalAmount,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class BudgetItem {
  final String id;
  final String budgetId;
  final BudgetCategory category;
  final String name;
  final double allocatedAmount;
  final double spentAmount;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  BudgetItem({
    required this.id,
    required this.budgetId,
    required this.category,
    required this.name,
    required this.allocatedAmount,
    required this.spentAmount,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  double get remainingAmount => allocatedAmount - spentAmount;
  double get progressPercentage => allocatedAmount > 0 ? (spentAmount / allocatedAmount) * 100 : 0;
  bool get isOverBudget => spentAmount > allocatedAmount;

  Map<String, dynamic> toJson() => {
        'id': id,
        'budgetId': budgetId,
        'category': category.toString(),
        'name': name,
        'allocatedAmount': allocatedAmount,
        'spentAmount': spentAmount,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory BudgetItem.fromJson(Map<String, dynamic> json) => BudgetItem(
        id: json['id'],
        budgetId: json['budgetId'],
        category: BudgetCategory.values.firstWhere(
          (e) => e.toString() == json['category'],
          orElse: () => BudgetCategory.other,
        ),
        name: json['name'],
        allocatedAmount: (json['allocatedAmount'] as num).toDouble(),
        spentAmount: (json['spentAmount'] as num).toDouble(),
        description: json['description'],
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
      );

  BudgetItem copyWith({
    String? id,
    String? budgetId,
    BudgetCategory? category,
    String? name,
    double? allocatedAmount,
    double? spentAmount,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BudgetItem(
      id: id ?? this.id,
      budgetId: budgetId ?? this.budgetId,
      category: category ?? this.category,
      name: name ?? this.name,
      allocatedAmount: allocatedAmount ?? this.allocatedAmount,
      spentAmount: spentAmount ?? this.spentAmount,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class BudgetSummary {
  final double totalBudget;
  final double totalSpent;
  final double totalRemaining;
  final double progressPercentage;
  final int totalBudgets;
  final int overBudgetItems;
  final BudgetCategory topSpendingCategory;

  BudgetSummary({
    required this.totalBudget,
    required this.totalSpent,
    required this.totalRemaining,
    required this.progressPercentage,
    required this.totalBudgets,
    required this.overBudgetItems,
    required this.topSpendingCategory,
  });

  bool get isOverBudget => totalSpent > totalBudget;
  bool get isOnTrack => progressPercentage <= 80;
}

// Extension methods for categories
extension BudgetCategoryExtension on BudgetCategory {
  String get displayName {
    switch (this) {
      case BudgetCategory.food:
        return 'Food & Dining';
      case BudgetCategory.transportation:
        return 'Transportation';
      case BudgetCategory.utilities:
        return 'Utilities';
      case BudgetCategory.entertainment:
        return 'Entertainment';
      case BudgetCategory.healthcare:
        return 'Healthcare';
      case BudgetCategory.education:
        return 'Education';
      case BudgetCategory.clothing:
        return 'Clothing';
      case BudgetCategory.savings:
        return 'Savings';
      case BudgetCategory.other:
        return 'Other';
    }
  }

  String get iconName {
    switch (this) {
      case BudgetCategory.food:
        return 'restaurant';
      case BudgetCategory.transportation:
        return 'directions_car';
      case BudgetCategory.utilities:
        return 'home';
      case BudgetCategory.entertainment:
        return 'movie';
      case BudgetCategory.healthcare:
        return 'local_hospital';
      case BudgetCategory.education:
        return 'school';
      case BudgetCategory.clothing:
        return 'shopping_bag';
      case BudgetCategory.savings:
        return 'savings';
      case BudgetCategory.other:
        return 'category';
    }
  }
}

extension BudgetPeriodExtension on BudgetPeriod {
  String get displayName {
    switch (this) {
      case BudgetPeriod.weekly:
        return 'Weekly';
      case BudgetPeriod.monthly:
        return 'Monthly';
      case BudgetPeriod.yearly:
        return 'Yearly';
    }
  }

  Duration get duration {
    switch (this) {
      case BudgetPeriod.weekly:
        return const Duration(days: 7);
      case BudgetPeriod.monthly:
        return const Duration(days: 30);
      case BudgetPeriod.yearly:
        return const Duration(days: 365);
    }
  }
}