// lib/features/reports/models/report_models.dart

enum ReportType {
  financial,
  transaction,
  loan,
  savings,
  budget,
  investment,
  tax,
}

enum ReportPeriod {
  daily,
  weekly,
  monthly,
  quarterly,
  yearly,
  custom,
}

enum ReportFormat {
  pdf,
  excel,
  csv,
}

enum ReportStatus {
  generating,
  completed,
  failed,
  expired,
}

class Report {
  final String id;
  final String name;
  final ReportType type;
  final ReportPeriod period;
  final DateTime startDate;
  final DateTime endDate;
  final ReportStatus status;
  final String? filePath;
  final String? downloadUrl;
  final double? fileSizeBytes;
  final Map<String, dynamic> parameters;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? errorMessage;

  Report({
    required this.id,
    required this.name,
    required this.type,
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.filePath,
    this.downloadUrl,
    this.fileSizeBytes,
    this.parameters = const {},
    required this.createdAt,
    this.completedAt,
    this.errorMessage,
  });

  bool get isExpired {
    if (completedAt == null) return false;
    final expiryDate = completedAt!.add(const Duration(days: 30));
    return DateTime.now().isAfter(expiryDate);
  }

  String get fileSizeFormatted {
    if (fileSizeBytes == null) return 'Unknown';
    final kb = fileSizeBytes! / 1024;
    final mb = kb / 1024;
    
    if (mb >= 1) {
      return '${mb.toStringAsFixed(1)} MB';
    } else {
      return '${kb.toStringAsFixed(1)} KB';
    }
  }

  Duration? get generationTime {
    if (completedAt == null) return null;
    return completedAt!.difference(createdAt);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.toString(),
        'period': period.toString(),
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'status': status.toString(),
        'filePath': filePath,
        'downloadUrl': downloadUrl,
        'fileSizeBytes': fileSizeBytes,
        'parameters': parameters,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'errorMessage': errorMessage,
      };

  factory Report.fromJson(Map<String, dynamic> json) => Report(
        id: json['id'],
        name: json['name'],
        type: ReportType.values.firstWhere(
          (e) => e.toString() == json['type'],
          orElse: () => ReportType.financial,
        ),
        period: ReportPeriod.values.firstWhere(
          (e) => e.toString() == json['period'],
          orElse: () => ReportPeriod.monthly,
        ),
        startDate: DateTime.parse(json['startDate']),
        endDate: DateTime.parse(json['endDate']),
        status: ReportStatus.values.firstWhere(
          (e) => e.toString() == json['status'],
          orElse: () => ReportStatus.generating,
        ),
        filePath: json['filePath'],
        downloadUrl: json['downloadUrl'],
        fileSizeBytes: json['fileSizeBytes']?.toDouble(),
        parameters: Map<String, dynamic>.from(json['parameters'] ?? {}),
        createdAt: DateTime.parse(json['createdAt']),
        completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
        errorMessage: json['errorMessage'],
      );

  Report copyWith({
    String? id,
    String? name,
    ReportType? type,
    ReportPeriod? period,
    DateTime? startDate,
    DateTime? endDate,
    ReportStatus? status,
    String? filePath,
    String? downloadUrl,
    double? fileSizeBytes,
    Map<String, dynamic>? parameters,
    DateTime? createdAt,
    DateTime? completedAt,
    String? errorMessage,
  }) {
    return Report(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      filePath: filePath ?? this.filePath,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      parameters: parameters ?? this.parameters,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ReportTemplate {
  final String id;
  final String name;
  final ReportType type;
  final String description;
  final List<String> requiredFields;
  final List<String> optionalFields;
  final List<ReportFormat> supportedFormats;
  final bool isCustomizable;
  final String? previewImageUrl;

  ReportTemplate({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.requiredFields,
    this.optionalFields = const [],
    this.supportedFormats = const [ReportFormat.pdf],
    this.isCustomizable = false,
    this.previewImageUrl,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.toString(),
        'description': description,
        'requiredFields': requiredFields,
        'optionalFields': optionalFields,
        'supportedFormats': supportedFormats.map((f) => f.toString()).toList(),
        'isCustomizable': isCustomizable,
        'previewImageUrl': previewImageUrl,
      };

  factory ReportTemplate.fromJson(Map<String, dynamic> json) => ReportTemplate(
        id: json['id'],
        name: json['name'],
        type: ReportType.values.firstWhere(
          (e) => e.toString() == json['type'],
          orElse: () => ReportType.financial,
        ),
        description: json['description'],
        requiredFields: List<String>.from(json['requiredFields']),
        optionalFields: List<String>.from(json['optionalFields'] ?? []),
        supportedFormats: (json['supportedFormats'] as List<dynamic>?)
                ?.map((f) => ReportFormat.values.firstWhere(
                      (e) => e.toString() == f,
                      orElse: () => ReportFormat.pdf,
                    ))
                .toList() ??
            [ReportFormat.pdf],
        isCustomizable: json['isCustomizable'] ?? false,
        previewImageUrl: json['previewImageUrl'],
      );
}

class ReportData {
  final String reportId;
  final Map<String, dynamic> summary;
  final List<Map<String, dynamic>> details;
  final Map<String, dynamic> metadata;
  final DateTime generatedAt;

  ReportData({
    required this.reportId,
    required this.summary,
    required this.details,
    this.metadata = const {},
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() => {
        'reportId': reportId,
        'summary': summary,
        'details': details,
        'metadata': metadata,
        'generatedAt': generatedAt.toIso8601String(),
      };

  factory ReportData.fromJson(Map<String, dynamic> json) => ReportData(
        reportId: json['reportId'],
        summary: Map<String, dynamic>.from(json['summary']),
        details: List<Map<String, dynamic>>.from(json['details']),
        metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
        generatedAt: DateTime.parse(json['generatedAt']),
      );
}

class FinancialSummary {
  final double totalIncome;
  final double totalExpenses;
  final double netIncome;
  final double totalSavings;
  final double totalLoans;
  final double totalInvestments;
  final Map<String, double> categoryBreakdown;
  final DateTime periodStart;
  final DateTime periodEnd;

  FinancialSummary({
    required this.totalIncome,
    required this.totalExpenses,
    required this.netIncome,
    required this.totalSavings,
    required this.totalLoans,
    required this.totalInvestments,
    required this.categoryBreakdown,
    required this.periodStart,
    required this.periodEnd,
  });

  double get savingsRate => totalIncome > 0 ? (totalSavings / totalIncome) * 100 : 0;
  double get expenseRatio => totalIncome > 0 ? (totalExpenses / totalIncome) * 100 : 0;

  Map<String, dynamic> toJson() => {
        'totalIncome': totalIncome,
        'totalExpenses': totalExpenses,
        'netIncome': netIncome,
        'totalSavings': totalSavings,
        'totalLoans': totalLoans,
        'totalInvestments': totalInvestments,
        'categoryBreakdown': categoryBreakdown,
        'periodStart': periodStart.toIso8601String(),
        'periodEnd': periodEnd.toIso8601String(),
      };

  factory FinancialSummary.fromJson(Map<String, dynamic> json) => FinancialSummary(
        totalIncome: (json['totalIncome'] as num).toDouble(),
        totalExpenses: (json['totalExpenses'] as num).toDouble(),
        netIncome: (json['netIncome'] as num).toDouble(),
        totalSavings: (json['totalSavings'] as num).toDouble(),
        totalLoans: (json['totalLoans'] as num).toDouble(),
        totalInvestments: (json['totalInvestments'] as num).toDouble(),
        categoryBreakdown: Map<String, double>.from(json['categoryBreakdown']),
        periodStart: DateTime.parse(json['periodStart']),
        periodEnd: DateTime.parse(json['periodEnd']),
      );
}

// Extension methods for better display
extension ReportTypeExtension on ReportType {
  String get displayName {
    switch (this) {
      case ReportType.financial:
        return 'Financial Report';
      case ReportType.transaction:
        return 'Transaction Report';
      case ReportType.loan:
        return 'Loan Report';
      case ReportType.savings:
        return 'Savings Report';
      case ReportType.budget:
        return 'Budget Report';
      case ReportType.investment:
        return 'Investment Report';
      case ReportType.tax:
        return 'Tax Report';
    }
  }

  String get description {
    switch (this) {
      case ReportType.financial:
        return 'Comprehensive overview of your financial position';
      case ReportType.transaction:
        return 'Detailed transaction history and analysis';
      case ReportType.loan:
        return 'Loan balances, payments, and schedules';
      case ReportType.savings:
        return 'Savings account balances and growth';
      case ReportType.budget:
        return 'Budget vs actual spending analysis';
      case ReportType.investment:
        return 'Investment portfolio performance';
      case ReportType.tax:
        return 'Tax-related transactions and summaries';
    }
  }

  String get iconName {
    switch (this) {
      case ReportType.financial:
        return 'account_balance';
      case ReportType.transaction:
        return 'receipt_long';
      case ReportType.loan:
        return 'money_off';
      case ReportType.savings:
        return 'savings';
      case ReportType.budget:
        return 'pie_chart';
      case ReportType.investment:
        return 'trending_up';
      case ReportType.tax:
        return 'description';
    }
  }
}

extension ReportPeriodExtension on ReportPeriod {
  String get displayName {
    switch (this) {
      case ReportPeriod.daily:
        return 'Daily';
      case ReportPeriod.weekly:
        return 'Weekly';
      case ReportPeriod.monthly:
        return 'Monthly';
      case ReportPeriod.quarterly:
        return 'Quarterly';
      case ReportPeriod.yearly:
        return 'Yearly';
      case ReportPeriod.custom:
        return 'Custom Period';
    }
  }
}

extension ReportFormatExtension on ReportFormat {
  String get displayName {
    switch (this) {
      case ReportFormat.pdf:
        return 'PDF';
      case ReportFormat.excel:
        return 'Excel';
      case ReportFormat.csv:
        return 'CSV';
    }
  }

  String get fileExtension {
    switch (this) {
      case ReportFormat.pdf:
        return '.pdf';
      case ReportFormat.excel:
        return '.xlsx';
      case ReportFormat.csv:
        return '.csv';
    }
  }

  String get mimeType {
    switch (this) {
      case ReportFormat.pdf:
        return 'application/pdf';
      case ReportFormat.excel:
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case ReportFormat.csv:
        return 'text/csv';
    }
  }
}

extension ReportStatusExtension on ReportStatus {
  String get displayName {
    switch (this) {
      case ReportStatus.generating:
        return 'Generating';
      case ReportStatus.completed:
        return 'Completed';
      case ReportStatus.failed:
        return 'Failed';
      case ReportStatus.expired:
        return 'Expired';
    }
  }
}