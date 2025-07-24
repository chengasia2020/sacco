// lib/features/reports/providers/report_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/report_models.dart';

// Report state classes
class ReportListState {
  final List<Report> reports;
  final bool isLoading;
  final String? errorMessage;

  const ReportListState({
    this.reports = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  ReportListState copyWith({
    List<Report>? reports,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ReportListState(
      reports: reports ?? this.reports,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ReportGenerationState {
  final String name;
  final ReportType type;
  final ReportPeriod period;
  final DateTime startDate;
  final DateTime endDate;
  final ReportFormat format;
  final Map<String, dynamic> parameters;
  final bool isGenerating;
  final String? errorMessage;

  ReportGenerationState({
    this.name = '',
    this.type = ReportType.financial,
    this.period = ReportPeriod.monthly,
    DateTime? startDate,
    DateTime? endDate,
    this.format = ReportFormat.pdf,
    this.parameters = const {},
    this.isGenerating = false,
    this.errorMessage,
  }) : startDate = startDate ?? DateTime.now().subtract(const Duration(days: 30)),
       endDate = endDate ?? DateTime.now();

  ReportGenerationState copyWith({
    String? name,
    ReportType? type,
    ReportPeriod? period,
    DateTime? startDate,
    DateTime? endDate,
    ReportFormat? format,
    Map<String, dynamic>? parameters,
    bool? isGenerating,
    String? errorMessage,
  }) {
    return ReportGenerationState(
      name: name ?? this.name,
      type: type ?? this.type,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      format: format ?? this.format,
      parameters: parameters ?? this.parameters,
      isGenerating: isGenerating ?? this.isGenerating,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// Report state notifiers
class ReportListNotifier extends StateNotifier<ReportListState> {
  ReportListNotifier() : super(const ReportListState());

  Future<void> loadReports() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Simulate API call - replace with actual repository call
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock data
      final mockReports = [
        Report(
          id: '1',
          name: 'Monthly Financial Report - July 2024',
          type: ReportType.financial,
          period: ReportPeriod.monthly,
          startDate: DateTime(2024, 7, 1),
          endDate: DateTime(2024, 7, 31),
          status: ReportStatus.completed,
          filePath: '/reports/financial_july_2024.pdf',
          downloadUrl: 'https://api.sacco.com/reports/download/1',
          fileSizeBytes: 1024 * 500, // 500KB
          parameters: {
            'includeCharts': true,
            'includeSummary': true,
            'format': 'pdf',
          },
          createdAt: DateTime(2024, 8, 1, 9, 0),
          completedAt: DateTime(2024, 8, 1, 9, 2),
        ),
        Report(
          id: '2',
          name: 'Transaction History - Q2 2024',
          type: ReportType.transaction,
          period: ReportPeriod.quarterly,
          startDate: DateTime(2024, 4, 1),
          endDate: DateTime(2024, 6, 30),
          status: ReportStatus.completed,
          filePath: '/reports/transactions_q2_2024.xlsx',
          downloadUrl: 'https://api.sacco.com/reports/download/2',
          fileSizeBytes: 1024 * 1200, // 1.2MB
          parameters: {
            'includeDescriptions': true,
            'groupByCategory': true,
            'format': 'excel',
          },
          createdAt: DateTime(2024, 7, 5, 14, 30),
          completedAt: DateTime(2024, 7, 5, 14, 33),
        ),
        Report(
          id: '3',
          name: 'Investment Portfolio Report',
          type: ReportType.investment,
          period: ReportPeriod.monthly,
          startDate: DateTime(2024, 7, 1),
          endDate: DateTime(2024, 7, 31),
          status: ReportStatus.generating,
          parameters: {
            'includePerformanceCharts': true,
            'includeRiskAnalysis': true,
            'format': 'pdf',
          },
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
        Report(
          id: '4',
          name: 'Loan Summary Report - June 2024',
          type: ReportType.loan,
          period: ReportPeriod.monthly,
          startDate: DateTime(2024, 6, 1),
          endDate: DateTime(2024, 6, 30),
          status: ReportStatus.failed,
          errorMessage: 'Insufficient data for the selected period',
          parameters: {
            'includePendingLoans': true,
            'includePaymentSchedule': true,
            'format': 'pdf',
          },
          createdAt: DateTime(2024, 7, 2, 10, 15),
        ),
        Report(
          id: '5',
          name: 'Budget Analysis - H1 2024',
          type: ReportType.budget,
          period: ReportPeriod.custom,
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 6, 30),
          status: ReportStatus.expired,
          filePath: '/reports/budget_h1_2024.pdf',
          fileSizeBytes: 1024 * 300, // 300KB
          parameters: {
            'compareWithPrevious': true,
            'includeVarianceAnalysis': true,
            'format': 'pdf',
          },
          createdAt: DateTime(2024, 6, 15, 16, 45),
          completedAt: DateTime(2024, 6, 15, 16, 47),
        ),
      ];

      state = state.copyWith(
        reports: mockReports,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> deleteReport(String reportId) async {
    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));
      
      final updatedReports = state.reports.where((r) => r.id != reportId).toList();
      state = state.copyWith(reports: updatedReports);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> downloadReport(String reportId) async {
    try {
      // Simulate download - in real app, would handle file download
      await Future.delayed(const Duration(seconds: 1));
      
      // Update report status or track download
      print('Report $reportId download initiated');
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

class ReportGenerationNotifier extends StateNotifier<ReportGenerationState> {
  ReportGenerationNotifier() : super(ReportGenerationState(
    startDate: DateTime.now().subtract(const Duration(days: 30)),
    endDate: DateTime.now(),
  ));

  void updateName(String name) {
    state = state.copyWith(name: name);
  }

  void updateType(ReportType type) {
    state = state.copyWith(type: type);
  }

  void updatePeriod(ReportPeriod period) {
    // Auto-adjust dates based on period
    DateTime startDate;
    DateTime endDate = DateTime.now();

    switch (period) {
      case ReportPeriod.daily:
        startDate = endDate.subtract(const Duration(days: 1));
        break;
      case ReportPeriod.weekly:
        startDate = endDate.subtract(const Duration(days: 7));
        break;
      case ReportPeriod.monthly:
        startDate = DateTime(endDate.year, endDate.month - 1, endDate.day);
        break;
      case ReportPeriod.quarterly:
        startDate = DateTime(endDate.year, endDate.month - 3, endDate.day);
        break;
      case ReportPeriod.yearly:
        startDate = DateTime(endDate.year - 1, endDate.month, endDate.day);
        break;
      case ReportPeriod.custom:
        startDate = state.startDate;
        break;
    }

    state = state.copyWith(
      period: period,
      startDate: startDate,
      endDate: endDate,
    );
  }

  void updateStartDate(DateTime date) {
    state = state.copyWith(startDate: date);
  }

  void updateEndDate(DateTime date) {
    state = state.copyWith(endDate: date);
  }

  void updateFormat(ReportFormat format) {
    state = state.copyWith(format: format);
  }

  void updateParameter(String key, dynamic value) {
    final updatedParameters = Map<String, dynamic>.from(state.parameters);
    updatedParameters[key] = value;
    state = state.copyWith(parameters: updatedParameters);
  }

  Future<bool> generateReport() async {
    state = state.copyWith(isGenerating: true, errorMessage: null);

    try {
      // Validate inputs
      if (state.name.isEmpty) {
        throw Exception('Report name is required');
      }
      if (state.startDate.isAfter(state.endDate)) {
        throw Exception('Start date must be before end date');
      }

      // Simulate API call for report generation
      await Future.delayed(const Duration(seconds: 3));

      // Simulate potential failure (10% chance)
      if (DateTime.now().millisecond % 10 == 0) {
        throw Exception('Report generation failed due to server error');
      }

      state = state.copyWith(isGenerating: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isGenerating: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  void resetForm() {
    state = ReportGenerationState(
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now(),
    );
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

// Providers
final reportListProvider = StateNotifierProvider<ReportListNotifier, ReportListState>((ref) {
  return ReportListNotifier();
});

final reportGenerationProvider = StateNotifierProvider<ReportGenerationNotifier, ReportGenerationState>((ref) {
  return ReportGenerationNotifier();
});

// Template provider
final reportTemplatesProvider = Provider<List<ReportTemplate>>((ref) {
  return [
    ReportTemplate(
      id: 'financial_summary',
      name: 'Financial Summary',
      type: ReportType.financial,
      description: 'Comprehensive overview of income, expenses, and net worth',
      requiredFields: ['startDate', 'endDate'],
      optionalFields: ['includeCharts', 'includeSummary', 'compareWithPrevious'],
      supportedFormats: [ReportFormat.pdf, ReportFormat.excel],
      isCustomizable: true,
    ),
    ReportTemplate(
      id: 'transaction_detail',
      name: 'Transaction Details',
      type: ReportType.transaction,
      description: 'Detailed list of all transactions with categories and descriptions',
      requiredFields: ['startDate', 'endDate'],
      optionalFields: ['includeDescriptions', 'groupByCategory', 'filterByAmount'],
      supportedFormats: [ReportFormat.pdf, ReportFormat.excel, ReportFormat.csv],
      isCustomizable: true,
    ),
    ReportTemplate(
      id: 'loan_statement',
      name: 'Loan Statement',
      type: ReportType.loan,
      description: 'Current loan balances, payment history, and schedules',
      requiredFields: ['startDate', 'endDate'],
      optionalFields: ['includePendingLoans', 'includePaymentSchedule'],
      supportedFormats: [ReportFormat.pdf],
      isCustomizable: false,
    ),
    ReportTemplate(
      id: 'savings_growth',
      name: 'Savings Growth',
      type: ReportType.savings,
      description: 'Track savings account balances and growth over time',
      requiredFields: ['startDate', 'endDate'],
      optionalFields: ['includeInterestBreakdown', 'compareAccounts'],
      supportedFormats: [ReportFormat.pdf, ReportFormat.excel],
      isCustomizable: true,
    ),
    ReportTemplate(
      id: 'budget_analysis',
      name: 'Budget Analysis',
      type: ReportType.budget,
      description: 'Compare budgeted vs actual spending across categories',
      requiredFields: ['startDate', 'endDate'],
      optionalFields: ['compareWithPrevious', 'includeVarianceAnalysis'],
      supportedFormats: [ReportFormat.pdf, ReportFormat.excel],
      isCustomizable: true,
    ),
    ReportTemplate(
      id: 'investment_portfolio',
      name: 'Investment Portfolio',
      type: ReportType.investment,
      description: 'Portfolio performance, returns, and asset allocation',
      requiredFields: ['startDate', 'endDate'],
      optionalFields: ['includePerformanceCharts', 'includeRiskAnalysis'],
      supportedFormats: [ReportFormat.pdf],
      isCustomizable: true,
    ),
    ReportTemplate(
      id: 'tax_summary',
      name: 'Tax Summary',
      type: ReportType.tax,
      description: 'Tax-relevant transactions and summaries for filing',
      requiredFields: ['startDate', 'endDate', 'taxYear'],
      optionalFields: ['includeDeductions', 'groupByTaxCategory'],
      supportedFormats: [ReportFormat.pdf, ReportFormat.csv],
      isCustomizable: false,
    ),
  ];
});

// Computed providers
final recentReportsProvider = Provider<List<Report>>((ref) {
  final reportState = ref.watch(reportListProvider);
  return reportState.reports
      .where((report) => 
          report.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 30))))
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});

final completedReportsProvider = Provider<List<Report>>((ref) {
  final reportState = ref.watch(reportListProvider);
  return reportState.reports
      .where((report) => report.status == ReportStatus.completed)
      .toList()
    ..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));
});

final failedReportsProvider = Provider<List<Report>>((ref) {
  final reportState = ref.watch(reportListProvider);
  return reportState.reports
      .where((report) => report.status == ReportStatus.failed)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});

final generatingReportsProvider = Provider<List<Report>>((ref) {
  final reportState = ref.watch(reportListProvider);
  return reportState.reports
      .where((report) => report.status == ReportStatus.generating)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});

final reportStatsProvider = Provider<Map<String, int>>((ref) {
  final reportState = ref.watch(reportListProvider);
  final reports = reportState.reports;

  return {
    'total': reports.length,
    'completed': reports.where((r) => r.status == ReportStatus.completed).length,
    'generating': reports.where((r) => r.status == ReportStatus.generating).length,
    'failed': reports.where((r) => r.status == ReportStatus.failed).length,
    'expired': reports.where((r) => r.status == ReportStatus.expired).length,
  };
});