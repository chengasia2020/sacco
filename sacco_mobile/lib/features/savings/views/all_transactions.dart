import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sacco_mobile/app/app_theme.dart';
import 'package:sacco_mobile/core/di/service_locator.dart';
import 'package:sacco_mobile/features/savings/models/transaction.dart';
import 'package:sacco_mobile/features/savings/viewmodels/transaction_viewmodel.dart';
import 'package:sacco_mobile/features/savings/views/transaction_detail_screen.dart';
import 'package:sacco_mobile/shared/widgets/app_button.dart';
import 'package:sacco_mobile/shared/widgets/error_widget.dart';
import 'package:sacco_mobile/shared/widgets/loading_indicator.dart';

class AllTransactionsScreen extends StatefulWidget {
  final int? accountId;

  const AllTransactionsScreen({
    super.key,
    this.accountId,
  });

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  final currencyFormat = NumberFormat.currency(
    symbol: 'UGX ',
    decimalDigits: 0,
  );

  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedType;

  final List<Map<String, String>> _transactionTypes = [
    {'value': 'ALL', 'label': 'All Types'},
    {'value': 'DEPOSIT', 'label': 'Deposits'},
    {'value': 'WITHDRAWAL', 'label': 'Withdrawals'},
    {'value': 'TRANSFER', 'label': 'Transfers'},
    {'value': 'INTEREST', 'label': 'Interest Credits'},
    {'value': 'FEE', 'label': 'Service Fees'},
  ];

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    
    // Set default filter values
    _selectedType = 'ALL';
    
    // Load transactions when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionViewModel>().loadTransactions(
        accountId: widget.accountId,
      );
    });
    
    // Add scroll listener for pagination
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 500) {
      // Load more transactions when near the bottom
      final viewModel = context.read<TransactionViewModel>();
      if (viewModel.state != TransactionState.loading && 
          viewModel.hasMoreTransactions) {
        viewModel.loadMoreTransactions();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => getIt<TransactionViewModel>(),
      child: Consumer<TransactionViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Transaction History'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () {
                    _showFilterBottomSheet(context, viewModel);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: viewModel.state == TransactionState.loading
                      ? null
                      : () => viewModel.refreshTransactions(),
                ),
              ],
            ),
            body: _buildBody(viewModel),
          );
        },
      ),
    );
  }

  Widget _buildBody(TransactionViewModel viewModel) {
    if (viewModel.state == TransactionState.initial) {
      return const Center(
        child: LoadingIndicator(
          message: 'Loading transactions...',
        ),
      );
    } else if (viewModel.state == TransactionState.error) {
      return AppErrorWidget(
        message: viewModel.errorMessage ?? 'Failed to load transactions',
        onRetry: () => viewModel.refreshTransactions(),
      );
    } else {
      return _buildTransactionsList(viewModel);
    }
  }

  Widget _buildTransactionsList(TransactionViewModel viewModel) {
    final transactions = viewModel.transactions;
    
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No transactions found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            if (_startDate != null || _endDate != null || _selectedType != 'ALL') ...[
              const Text(
                'Try changing your filters',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              AppButton(
                text: 'Clear Filters',
                onPressed: () {
                  setState(() {
                    _startDate = null;
                    _endDate = null;
                    _selectedType = 'ALL';
                  });
                  viewModel.resetFilters();
                },
                buttonType: ButtonType.outline,
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      children: [
        // Active filters display
        if (_startDate != null || _endDate != null || _selectedType != 'ALL')
          _buildActiveFilters(viewModel),
          
        // Transactions list
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => viewModel.refreshTransactions(),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(top: 8),
              itemCount: transactions.length + (viewModel.hasMoreTransactions ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == transactions.length) {
                  // Loading indicator for pagination
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                } else {
                  return _buildTransactionItem(context, transactions[index]);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveFilters(TransactionViewModel viewModel) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[100],
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_selectedType != 'ALL')
                  _buildFilterChip(
                    label: _transactionTypes.firstWhere(
                      (t) => t['value'] == _selectedType)['label']!,
                    onRemove: () {
                      setState(() {
                        _selectedType = 'ALL';
                      });
                      viewModel.loadTransactions(
                        accountId: widget.accountId,
                        startDate: _startDate,
                        endDate: _endDate,
                        refresh: true,
                      );
                    },
                  ),
                if (_startDate != null && _endDate != null)
                  _buildFilterChip(
                    label: '${dateFormat.format(_startDate!)} - ${dateFormat.format(_endDate!)}',
                    onRemove: () {
                      setState(() {
                        _startDate = null;
                        _endDate = null;
                      });
                      viewModel.loadTransactions(
                        accountId: widget.accountId,
                        refresh: true,
                      );
                    },
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _startDate = null;
                _endDate = null;
                _selectedType = 'ALL';
              });
              viewModel.resetFilters();
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({required String label, required VoidCallback onRemove}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(12),
            child: const Icon(
              Icons.close,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, Transaction transaction) {
    final dateFormat = DateFormat('dd MMM, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TransactionDetailScreen(
              transaction: transaction,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
        ),
        child: Row(
          children: [
            // Transaction icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _getTransactionColor(transaction.transactionType, isLight: true),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getTransactionIcon(transaction.transactionType),
                color: _getTransactionColor(transaction.transactionType),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            // Transaction details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.transactionTypeText,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        dateFormat.format(transaction.createdAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeFormat.format(transaction.createdAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (transaction.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      transaction.description!,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // Transaction amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currencyFormat.format(transaction.amount),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: transaction.isDeposit 
                        ? Colors.green[700]
                        : Colors.red[700],
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(transaction.status, isLight: true),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    transaction.statusText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: _getStatusColor(transaction.status),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context, TransactionViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filter Transactions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Transaction type filter
                const Text(
                  'Transaction Type',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _transactionTypes.map((type) {
                    final isSelected = _selectedType == type['value'];
                    return FilterChip(
                      label: Text(type['label']!),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedType = type['value'];
                        });
                      },
                      backgroundColor: Colors.grey[200],
                      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                      checkmarkColor: AppTheme.primaryColor,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                
                // Date range filter
                const Text(
                  'Date Range',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await _selectDate(context, _startDate);
                          if (date != null) {
                            setState(() {
                              _startDate = date;
                              if (_endDate != null && _endDate!.isBefore(_startDate!)) {
                                _endDate = _startDate;
                              }
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[400]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 18,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _startDate == null
                                    ? 'Start Date'
                                    : DateFormat('MMM dd, yyyy').format(_startDate!),
                                style: TextStyle(
                                  color: _startDate == null
                                      ? Colors.grey[600]
                                      : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await _selectDate(context, _endDate);
                          if (date != null) {
                            setState(() {
                              _endDate = date;
                              if (_startDate != null && _startDate!.isAfter(_endDate!)) {
                                _startDate = _endDate;
                              }
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[400]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 18,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _endDate == null
                                    ? 'End Date'
                                    : DateFormat('MMM dd, yyyy').format(_endDate!),
                                style: TextStyle(
                                  color: _endDate == null
                                      ? Colors.grey[600]
                                      : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Quick date filters
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildQuickDateFilter('Today', () {
                      final today = DateTime.now();
                      setState(() {
                        _startDate = DateTime(today.year, today.month, today.day);
                        _endDate = today;
                      });
                    }),
                    _buildQuickDateFilter('Yesterday', () {
                      final today = DateTime.now();
                      final yesterday = today.subtract(const Duration(days: 1));
                      setState(() {
                        _startDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
                        _endDate = DateTime(today.year, today.month, today.day)
                            .subtract(const Duration(milliseconds: 1));
                      });
                    }),
                    _buildQuickDateFilter('This Week', () {
                      final today = DateTime.now();
                      // Find the first day of the week (Sunday in most cultures)
                      final firstDayOfWeek = today.subtract(Duration(days: today.weekday % 7));
                      setState(() {
                        _startDate = DateTime(firstDayOfWeek.year, firstDayOfWeek.month, firstDayOfWeek.day);
                        _endDate = today;
                      });
                    }),
                    _buildQuickDateFilter('This Month', () {
                      final today = DateTime.now();
                      setState(() {
                        _startDate = DateTime(today.year, today.month, 1);
                        _endDate = today;
                      });
                    }),
                    _buildQuickDateFilter('Last Month', () {
                      final today = DateTime.now();
                      final lastMonth = DateTime(today.year, today.month - 1, 1);
                      setState(() {
                        _startDate = lastMonth;
                        _endDate = DateTime(today.year, today.month, 0);
                      });
                    }),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Apply filter button
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    text: 'Apply Filters',
                    onPressed: () {
                      Navigator.of(context).pop();
                      
                      // Apply filters
                      viewModel.loadTransactions(
                        accountId: widget.accountId,
                        startDate: _startDate,
                        endDate: _endDate,
                        refresh: true,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                
                // Reset filters button
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    text: 'Reset Filters',
                    onPressed: () {
                      setState(() {
                        _startDate = null;
                        _endDate = null;
                        _selectedType = 'ALL';
                      });
                    },
                    buttonType: ButtonType.outline,
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickDateFilter(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Future<DateTime?> _selectDate(BuildContext context, DateTime? initialDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    return picked;
  }

  IconData _getTransactionIcon(String transactionType) {
    switch (transactionType) {
      case 'DEPOSIT':
        return Icons.arrow_downward;
      case 'WITHDRAWAL':
        return Icons.arrow_upward;
      case 'LOAN_DISBURSEMENT':
        return Icons.account_balance;
      case 'LOAN_REPAYMENT':
        return Icons.payments;
      case 'TRANSFER':
        return Icons.swap_horiz;
      case 'INTEREST':
        return Icons.trending_up;
      case 'FEE':
        return Icons.money_off;
      default:
        return Icons.receipt;
    }
  }

  Color _getTransactionColor(String transactionType, {bool isLight = false}) {
    switch (transactionType) {
      case 'DEPOSIT':
        return isLight ? Colors.green[100]! : Colors.green[700]!;
      case 'WITHDRAWAL':
        return isLight ? Colors.orange[100]! : Colors.orange[700]!;
      case 'LOAN_DISBURSEMENT':
        return isLight ? Colors.blue[100]! : Colors.blue[700]!;
      case 'LOAN_REPAYMENT':
        return isLight ? Colors.purple[100]! : Colors.purple[700]!;
      case 'TRANSFER':
        return isLight ? Colors.indigo[100]! : Colors.indigo[700]!;
      case 'INTEREST':
        return isLight ? Colors.teal[100]! : Colors.teal[700]!;
      case 'FEE':
        return isLight ? Colors.red[100]! : Colors.red[700]!;
      default:
        return isLight ? Colors.grey[200]! : Colors.grey[700]!;
    }
  }

  Color _getStatusColor(String status, {bool isLight = false}) {
    switch (status) {
      case 'COMPLETED':
        return isLight ? Colors.green[100]! : Colors.green[700]!;
      case 'PENDING':
        return isLight ? Colors.amber[100]! : Colors.amber[700]!;
      case 'FAILED':
        return isLight ? Colors.red[100]! : Colors.red[700]!;
      case 'REVERSED':
        return isLight ? Colors.purple[100]! : Colors.purple[700]!;
      default:
        return isLight ? Colors.grey[200]! : Colors.grey[700]!;
    }
  }
}