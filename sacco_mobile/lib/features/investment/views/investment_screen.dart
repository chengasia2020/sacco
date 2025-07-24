// lib/features/investment/views/investment_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/investment_models.dart';
import '../providers/investment_providers.dart';

class InvestmentScreen extends ConsumerStatefulWidget {
  const InvestmentScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<InvestmentScreen> createState() => _InvestmentScreenState();
}

class _InvestmentScreenState extends ConsumerState<InvestmentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Load investments when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(investmentListProvider.notifier).loadInvestments();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final investmentState = ref.watch(investmentListProvider);
    final portfolio = ref.watch(investmentPortfolioProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Investments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateInvestmentDialog(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Portfolio', icon: Icon(Icons.pie_chart)),
            Tab(text: 'Active', icon: Icon(Icons.trending_up)),
            Tab(text: 'History', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: investmentState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : investmentState.errorMessage != null
              ? _buildErrorState(investmentState.errorMessage!)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPortfolioTab(portfolio),
                    _buildActiveInvestmentsTab(),
                    _buildHistoryTab(),
                  ],
                ),
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
            'Error loading investments',
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
              ref.read(investmentListProvider.notifier).loadInvestments();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioTab(InvestmentPortfolio? portfolio) {
    if (portfolio == null) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(investmentListProvider.notifier).loadInvestments();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPortfolioSummary(portfolio),
          const SizedBox(height: 16),
          _buildAllocationChart(portfolio),
          const SizedBox(height: 16),
          _buildTopPerformer(portfolio),
          const SizedBox(height: 16),
          _buildMaturingSoon(),
        ],
      ),
    );
  }

  Widget _buildActiveInvestmentsTab() {
    final activeInvestments = ref.watch(activeInvestmentsProvider);

    if (activeInvestments.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(investmentListProvider.notifier).loadInvestments();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: activeInvestments.length,
        itemBuilder: (context, index) {
          return _buildInvestmentCard(activeInvestments[index]);
        },
      ),
    );
  }

  Widget _buildHistoryTab() {
    final maturedInvestments = ref.watch(maturedInvestmentsProvider);

    if (maturedInvestments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No Investment History',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text('Your completed investments will appear here'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(investmentListProvider.notifier).loadInvestments();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: maturedInvestments.length,
        itemBuilder: (context, index) {
          return _buildInvestmentCard(maturedInvestments[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.trending_up, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No Investments Yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Start investing to grow your wealth',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showCreateInvestmentDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Start Investing'),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioSummary(InvestmentPortfolio portfolio) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Portfolio Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Total Invested',
                    'UGX ${_formatCurrency(portfolio.totalInvestments)}',
                    Icons.account_balance_wallet,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Current Value',
                    'UGX ${_formatCurrency(portfolio.totalValue)}',
                    Icons.trending_up,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Total Returns',
                    'UGX ${_formatCurrency(portfolio.totalReturns)}',
                    Icons.attach_money,
                    portfolio.totalReturns >= 0 ? Colors.green : Colors.red,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Return %',
                    '${portfolio.returnPercentage.toStringAsFixed(1)}%',
                    Icons.percent,
                    portfolio.returnPercentage >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Active',
                    '${portfolio.activeInvestmentsCount}',
                    Icons.play_arrow,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Matured',
                    '${portfolio.maturedInvestmentsCount}',
                    Icons.check_circle,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
      ],
    );
  }

  Widget _buildAllocationChart(InvestmentPortfolio portfolio) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Allocation by Type',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...portfolio.allocationByType.entries.map((entry) {
              final percentage = (entry.value / portfolio.totalValue) * 100;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getColorForType(entry.key),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(entry.key.displayName),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopPerformer(InvestmentPortfolio portfolio) {
    final topPerformer = portfolio.topPerformer;
    if (topPerformer == null) return const SizedBox();

    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.amber,
          child: Icon(Icons.star, color: Colors.white),
        ),
        title: const Text(
          'Top Performer',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(topPerformer.name),
        trailing: Text(
          '${topPerformer.returnPercentage.toStringAsFixed(1)}%',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        onTap: () => _showInvestmentDetails(topPerformer),
      ),
    );
  }

  Widget _buildMaturingSoon() {
    final maturingSoon = ref.watch(maturingSoonProvider);
    if (maturingSoon.isEmpty) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Maturing Soon',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            ...maturingSoon.map((investment) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(_getIconForType(investment.type)),
                  title: Text(investment.name),
                  subtitle: Text('${investment.daysToMaturity} days to maturity'),
                  trailing: Text(
                    'UGX ${_formatCurrency(investment.currentValue)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () => _showInvestmentDetails(investment),
                )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildInvestmentCard(Investment investment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getColorForStatus(investment.status),
          child: Icon(
            _getIconForType(investment.type),
            color: Colors.white,
          ),
        ),
        title: Text(
          investment.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${investment.type.displayName} • ${investment.status.displayName}'),
            const SizedBox(height: 4),
            Text(
              'UGX ${_formatCurrency(investment.currentValue)} (${investment.returnPercentage >= 0 ? '+' : ''}${investment.returnPercentage.toStringAsFixed(1)}%)',
              style: TextStyle(
                color: investment.returnPercentage >= 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'withdraw') {
              _showWithdrawDialog(investment);
            } else if (value == 'details') {
              _showInvestmentDetails(investment);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'details',
              child: ListTile(
                leading: Icon(Icons.info),
                title: Text('View Details'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            if (investment.status == InvestmentStatus.active)
              const PopupMenuItem(
                value: 'withdraw',
                child: ListTile(
                  leading: Icon(Icons.money_off, color: Colors.orange),
                  title: Text('Withdraw', style: TextStyle(color: Colors.orange)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
          ],
        ),
        onTap: () => _showInvestmentDetails(investment),
      ),
    );
  }

  void _showCreateInvestmentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Investment'),
        content: const Text('Investment creation form will be implemented in the next phase.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to investment creation form
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showInvestmentDetails(Investment investment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
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
                investment.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '${investment.type.displayName} • ${investment.status.displayName}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildDetailItem('Principal Amount', 'UGX ${_formatCurrency(investment.principalAmount)}'),
                    _buildDetailItem('Current Value', 'UGX ${_formatCurrency(investment.currentValue)}'),
                    _buildDetailItem('Total Returns', 'UGX ${_formatCurrency(investment.totalReturns)}'),
                    _buildDetailItem('Return Percentage', '${investment.returnPercentage.toStringAsFixed(1)}%'),
                    _buildDetailItem('Interest Rate', '${investment.interestRate}% p.a.'),
                    _buildDetailItem('Risk Level', investment.riskLevel.displayName),
                    _buildDetailItem('Start Date', _formatDate(investment.startDate)),
                    if (investment.maturityDate != null)
                      _buildDetailItem('Maturity Date', _formatDate(investment.maturityDate!)),
                    if (investment.daysToMaturity > 0)
                      _buildDetailItem('Days to Maturity', '${investment.daysToMaturity} days'),
                    if (investment.description.isNotEmpty)
                      _buildDetailItem('Description', investment.description),
                    const SizedBox(height: 16),
                    Text(
                      'Transaction History',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    ...investment.transactions.map((transaction) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(_getIconForTransactionType(transaction.type)),
                          title: Text(transaction.type.displayName),
                          subtitle: Text(_formatDate(transaction.transactionDate)),
                          trailing: Text(
                            'UGX ${_formatCurrency(transaction.amount)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _getColorForTransactionType(transaction.type),
                            ),
                          ),
                        )).toList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showWithdrawDialog(Investment investment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw Investment'),
        content: Text('Withdraw from "${investment.name}"?\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(investmentListProvider.notifier)
                  .withdrawInvestment(investment.id, investment.currentValue);
            },
            child: const Text('Withdraw', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Color _getColorForType(InvestmentType type) {
    switch (type) {
      case InvestmentType.shareCapital:
        return Colors.blue;
      case InvestmentType.deposit:
        return Colors.green;
      case InvestmentType.bond:
        return Colors.purple;
      case InvestmentType.treasury:
        return Colors.orange;
      case InvestmentType.fixedDeposit:
        return Colors.teal;
      case InvestmentType.recurring:
        return Colors.indigo;
    }
  }

  Color _getColorForStatus(InvestmentStatus status) {
    switch (status) {
      case InvestmentStatus.active:
        return Colors.green;
      case InvestmentStatus.matured:
        return Colors.blue;
      case InvestmentStatus.pending:
        return Colors.orange;
      case InvestmentStatus.cancelled:
        return Colors.red;
      case InvestmentStatus.withdrawn:
        return Colors.grey;
    }
  }

  IconData _getIconForType(InvestmentType type) {
    switch (type) {
      case InvestmentType.shareCapital:
        return Icons.trending_up;
      case InvestmentType.deposit:
        return Icons.account_balance;
      case InvestmentType.bond:
        return Icons.receipt_long;
      case InvestmentType.treasury:
        return Icons.security;
      case InvestmentType.fixedDeposit:
        return Icons.savings;
      case InvestmentType.recurring:
        return Icons.autorenew;
    }
  }

  IconData _getIconForTransactionType(InvestmentTransactionType type) {
    switch (type) {
      case InvestmentTransactionType.deposit:
        return Icons.add;
      case InvestmentTransactionType.withdrawal:
        return Icons.remove;
      case InvestmentTransactionType.interest:
        return Icons.percent;
      case InvestmentTransactionType.dividend:
        return Icons.attach_money;
      case InvestmentTransactionType.maturity:
        return Icons.check_circle;
      case InvestmentTransactionType.penalty:
        return Icons.warning;
    }
  }

  Color _getColorForTransactionType(InvestmentTransactionType type) {
    switch (type) {
      case InvestmentTransactionType.deposit:
        return Colors.green;
      case InvestmentTransactionType.withdrawal:
        return Colors.red;
      case InvestmentTransactionType.interest:
        return Colors.blue;
      case InvestmentTransactionType.dividend:
        return Colors.purple;
      case InvestmentTransactionType.maturity:
        return Colors.teal;
      case InvestmentTransactionType.penalty:
        return Colors.orange;
    }
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!$))'),
          (Match m) => '${m[1]},',
        );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}