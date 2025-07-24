// lib/features/budget/views/budget_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/budget_models.dart';
import '../providers/budget_providers.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  @override
  void initState() {
    super.initState();
    // Load budgets when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(budgetListProvider.notifier).loadBudgets();
    });
  }

  @override
  Widget build(BuildContext context) {
    final budgetState = ref.watch(budgetListProvider);
    final budgetSummary = ref.watch(budgetSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateBudgetDialog(),
          ),
        ],
      ),
      body: budgetState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : budgetState.errorMessage != null
              ? _buildErrorState(budgetState.errorMessage!)
              : budgetState.budgets.isEmpty
                  ? _buildEmptyState()
                  : _buildBudgetList(budgetState.budgets, budgetSummary),
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
            'Error loading budgets',
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
              ref.read(budgetListProvider.notifier).loadBudgets();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No Budgets Yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first budget to start tracking your expenses',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showCreateBudgetDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Create Budget'),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetList(List<Budget> budgets, BudgetSummary? summary) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(budgetListProvider.notifier).loadBudgets();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (summary != null) _buildSummaryCard(summary),
          const SizedBox(height: 16),
          Text(
            'Your Budgets',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          ...budgets.map((budget) => _buildBudgetCard(budget)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BudgetSummary summary) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Budget Overview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem(
                  'Total Budget',
                  'UGX ${_formatCurrency(summary.totalBudget)}',
                  Icons.account_balance_wallet,
                  Colors.blue,
                ),
                _buildSummaryItem(
                  'Total Spent',
                  'UGX ${_formatCurrency(summary.totalSpent)}',
                  Icons.money_off,
                  summary.isOverBudget ? Colors.red : Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem(
                  'Remaining',
                  'UGX ${_formatCurrency(summary.totalRemaining)}',
                  Icons.savings,
                  summary.totalRemaining >= 0 ? Colors.green : Colors.red,
                ),
                _buildSummaryItem(
                  'Progress',
                  '${summary.progressPercentage.toStringAsFixed(1)}%',
                  Icons.trending_up,
                  summary.isOnTrack ? Colors.green : Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: summary.progressPercentage / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                summary.isOverBudget ? Colors.red : 
                summary.isOnTrack ? Colors.green : Colors.orange,
              ),
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

  Widget _buildBudgetCard(Budget budget) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: budget.progressPercentage > 100 
              ? Colors.red : budget.progressPercentage > 80 
              ? Colors.orange : Colors.green,
          child: Text(
            '${budget.progressPercentage.toInt()}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          budget.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${budget.period.displayName} • ${budget.items.length} categories'),
            const SizedBox(height: 4),
            Text(
              'UGX ${_formatCurrency(budget.totalSpent)} of ${_formatCurrency(budget.totalAmount)}',
              style: TextStyle(
                color: budget.progressPercentage > 100 ? Colors.red : null,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete') {
              _confirmDelete(budget);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit'),
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
        ),
        onTap: () => _showBudgetDetails(budget),
      ),
    );
  }

  void _showCreateBudgetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Budget'),
        content: const Text('Budget creation form will be implemented in the next phase.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to budget creation form
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showBudgetDetails(Budget budget) {
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
                budget.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '${budget.period.displayName} Budget',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: budget.items.length,
                  itemBuilder: (context, index) {
                    final item = budget.items[index];
                    return ListTile(
                      leading: Icon(
                        _getCategoryIcon(item.category),
                        color: item.isOverBudget ? Colors.red : Colors.blue,
                      ),
                      title: Text(item.name),
                      subtitle: Text(item.category.displayName),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'UGX ${_formatCurrency(item.spentAmount)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: item.isOverBudget ? Colors.red : null,
                            ),
                          ),
                          Text(
                            'of ${_formatCurrency(item.allocatedAmount)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(Budget budget) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Budget'),
        content: Text('Are you sure you want to delete "${budget.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(budgetListProvider.notifier).deleteBudget(budget.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(BudgetCategory category) {
    switch (category) {
      case BudgetCategory.food:
        return Icons.restaurant;
      case BudgetCategory.transportation:
        return Icons.directions_car;
      case BudgetCategory.utilities:
        return Icons.home;
      case BudgetCategory.entertainment:
        return Icons.movie;
      case BudgetCategory.healthcare:
        return Icons.local_hospital;
      case BudgetCategory.education:
        return Icons.school;
      case BudgetCategory.clothing:
        return Icons.shopping_bag;
      case BudgetCategory.savings:
        return Icons.savings;
      case BudgetCategory.other:
        return Icons.category;
    }
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}