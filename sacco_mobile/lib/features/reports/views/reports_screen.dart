// lib/features/reports/views/reports_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/report_models.dart';
import '../providers/report_providers.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Load reports when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reportListProvider.notifier).loadReports();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(reportListProvider);
    final reportStats = ref.watch(reportStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateReportDialog(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(
              child: _buildTabWithBadge('All', reportStats['total'] ?? 0),
            ),
            Tab(
              child: _buildTabWithBadge('Completed', reportStats['completed'] ?? 0),
            ),
            Tab(
              child: _buildTabWithBadge('Generating', reportStats['generating'] ?? 0),
            ),
            Tab(
              child: _buildTabWithBadge('Templates', 0),
            ),
          ],
        ),
      ),
      body: reportState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : reportState.errorMessage != null
              ? _buildErrorState(reportState.errorMessage!)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAllReportsTab(),
                    _buildCompletedReportsTab(),
                    _buildGeneratingReportsTab(),
                    _buildTemplatesTab(),
                  ],
                ),
    );
  }

  Widget _buildTabWithBadge(String title, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title),
        if (count > 0) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(10),
            ),
            constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error loading reports',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.read(reportListProvider.notifier).loadReports();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildAllReportsTab() {
    final reportState = ref.watch(reportListProvider);

    if (reportState.reports.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(reportListProvider.notifier).loadReports();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reportState.reports.length,
        itemBuilder: (context, index) {
          return _buildReportCard(reportState.reports[index]);
        },
      ),
    );
  }

  Widget _buildCompletedReportsTab() {
    final completedReports = ref.watch(completedReportsProvider);

    if (completedReports.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No Completed Reports'),
            Text('Your completed reports will appear here'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(reportListProvider.notifier).loadReports();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: completedReports.length,
        itemBuilder: (context, index) {
          return _buildReportCard(completedReports[index]);
        },
      ),
    );
  }

  Widget _buildGeneratingReportsTab() {
    final generatingReports = ref.watch(generatingReportsProvider);

    if (generatingReports.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_empty, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No Reports Generating'),
            Text('Reports currently being generated will appear here'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(reportListProvider.notifier).loadReports();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: generatingReports.length,
        itemBuilder: (context, index) {
          return _buildReportCard(generatingReports[index]);
        },
      ),
    );
  }

  Widget _buildTemplatesTab() {
    final templates = ref.watch(reportTemplatesProvider);

    return RefreshIndicator(
      onRefresh: () async {
        // Templates are static, but keep consistency
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: templates.length,
        itemBuilder: (context, index) {
          return _buildTemplateCard(templates[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.description, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No Reports Yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Generate your first report to get insights into your finances',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showCreateReportDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Create Report'),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(Report report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getColorForStatus(report.status),
          child: Icon(
            _getIconForType(report.type),
            color: Colors.white,
          ),
        ),
        title: Text(
          report.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${report.type.displayName} • ${report.status.displayName}'),
            const SizedBox(height: 4),
            Text(_formatDateRange(report.startDate, report.endDate)),
            if (report.status == ReportStatus.completed && report.fileSizeBytes != null)
              Text(
                'Size: ${report.fileSizeFormatted}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            if (report.status == ReportStatus.failed && report.errorMessage != null)
              Text(
                report.errorMessage!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: _buildReportActions(report),
        onTap: () => _showReportDetails(report),
      ),
    );
  }

  Widget _buildTemplateCard(ReportTemplate template) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getColorForReportType(template.type),
          child: Icon(
            _getIconForType(template.type),
            color: Colors.white,
          ),
        ),
        title: Text(
          template.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(template.description),
            const SizedBox(height: 4),
            Text(
              'Formats: ${template.supportedFormats.map((f) => f.displayName).join(', ')}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.play_arrow),
          onPressed: () => _generateFromTemplate(template),
        ),
        onTap: () => _showTemplateDetails(template),
      ),
    );
  }

  Widget _buildReportActions(Report report) {
    switch (report.status) {
      case ReportStatus.completed:
        return PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'download':
                _downloadReport(report);
                break;
              case 'delete':
                _deleteReport(report);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'download',
              child: ListTile(
                leading: Icon(Icons.download),
                title: Text('Download'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Delete', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        );
      case ReportStatus.generating:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case ReportStatus.failed:
        return IconButton(
          icon: const Icon(Icons.refresh, color: Colors.orange),
          onPressed: () => _retryReport(report),
        );
      case ReportStatus.expired:
        return IconButton(
          icon: const Icon(Icons.refresh, color: Colors.grey),
          onPressed: () => _retryReport(report),
        );
    }
  }

  void _showCreateReportDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const ReportGenerationForm(),
    );
  }

  void _showReportDetails(Report report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ReportDetailsSheet(report: report),
    );
  }

  void _showTemplateDetails(ReportTemplate template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(template.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(template.description),
            const SizedBox(height: 16),
            Text(
              'Required Fields:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            ...template.requiredFields.map((field) => Text('• $field')),
            if (template.optionalFields.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Optional Fields:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              ...template.optionalFields.map((field) => Text('• $field')),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _generateFromTemplate(template);
            },
            child: const Text('Use Template'),
          ),
        ],
      ),
    );
  }

  void _generateFromTemplate(ReportTemplate template) {
    // Set up the report generation form with template defaults
    final notifier = ref.read(reportGenerationProvider.notifier);
    notifier.updateType(template.type);
    notifier.updateName('${template.name} - ${_formatDate(DateTime.now())}');
    
    _showCreateReportDialog();
  }

  void _downloadReport(Report report) {
    ref.read(reportListProvider.notifier).downloadReport(report.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading ${report.name}...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _deleteReport(Report report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Report'),
        content: Text('Are you sure you want to delete "${report.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(reportListProvider.notifier).deleteReport(report.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _retryReport(Report report) {
    // In a real app, this would re-trigger report generation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Retrying ${report.name}...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Color _getColorForStatus(ReportStatus status) {
    switch (status) {
      case ReportStatus.completed:
        return Colors.green;
      case ReportStatus.generating:
        return Colors.orange;
      case ReportStatus.failed:
        return Colors.red;
      case ReportStatus.expired:
        return Colors.grey;
    }
  }

  Color _getColorForReportType(ReportType type) {
    switch (type) {
      case ReportType.financial:
        return Colors.blue;
      case ReportType.transaction:
        return Colors.green;
      case ReportType.loan:
        return Colors.red;
      case ReportType.savings:
        return Colors.teal;
      case ReportType.budget:
        return Colors.purple;
      case ReportType.investment:
        return Colors.orange;
      case ReportType.tax:
        return Colors.indigo;
    }
  }

  IconData _getIconForType(ReportType type) {
    switch (type) {
      case ReportType.financial:
        return Icons.account_balance;
      case ReportType.transaction:
        return Icons.receipt_long;
      case ReportType.loan:
        return Icons.money_off;
      case ReportType.savings:
        return Icons.savings;
      case ReportType.budget:
        return Icons.pie_chart;
      case ReportType.investment:
        return Icons.trending_up;
      case ReportType.tax:
        return Icons.description;
    }
  }

  String _formatDateRange(DateTime start, DateTime end) {
    return '${_formatDate(start)} - ${_formatDate(end)}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// Report Generation Form Widget
class ReportGenerationForm extends ConsumerStatefulWidget {
  const ReportGenerationForm({Key? key}) : super(key: key);

  @override
  ConsumerState<ReportGenerationForm> createState() => _ReportGenerationFormState();
}

class _ReportGenerationFormState extends ConsumerState<ReportGenerationForm> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final generationState = ref.watch(reportGenerationProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Generate Report',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Report Name',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      ref.read(reportGenerationProvider.notifier).updateName(value);
                    },
                  ),
                  const SizedBox(height: 16),
                  // Add more form fields here for report configuration
                  if (generationState.errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        generationState.errorMessage!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: generationState.isGenerating ? null : _generateReport,
                    child: generationState.isGenerating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Generate'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateReport() async {
    final success = await ref.read(reportGenerationProvider.notifier).generateReport();
    
    if (success && mounted) {
      Navigator.of(context).pop();
      ref.read(reportListProvider.notifier).loadReports(); // Refresh the list
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report generation started successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

// Report Details Sheet Widget
class ReportDetailsSheet extends StatelessWidget {
  final Report report;

  const ReportDetailsSheet({Key? key, required this.report}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.8,
      minChildSize: 0.4,
      builder: (context, scrollController) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              report.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  _buildDetailItem('Type', report.type.displayName),
                  _buildDetailItem('Status', report.status.displayName),
                  _buildDetailItem('Period', '${_formatDate(report.startDate)} - ${_formatDate(report.endDate)}'),
                  _buildDetailItem('Created', _formatDateTime(report.createdAt)),
                  if (report.completedAt != null)
                    _buildDetailItem('Completed', _formatDateTime(report.completedAt!)),
                  if (report.fileSizeBytes != null)
                    _buildDetailItem('File Size', report.fileSizeFormatted),
                  if (report.generationTime != null)
                    _buildDetailItem('Generation Time', '${report.generationTime!.inSeconds} seconds'),
                  if (report.errorMessage != null)
                    _buildDetailItem('Error', report.errorMessage!, isError: true),
                  if (report.parameters.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Parameters',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    ...report.parameters.entries.map((entry) =>
                        _buildDetailItem(entry.key, entry.value.toString())),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isError ? Colors.red : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}