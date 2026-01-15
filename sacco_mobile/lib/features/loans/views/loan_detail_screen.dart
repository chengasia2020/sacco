import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sacco_mobile/app/app_theme.dart';
import 'package:sacco_mobile/core/di/service_locator.dart';
import 'package:sacco_mobile/features/loans/models/loan.dart';
import 'package:sacco_mobile/features/loans/viewmodels/loan_list_viewmodel.dart';
import 'package:sacco_mobile/features/loans/views/loan_repayment_screen.dart';
import 'package:sacco_mobile/shared/widgets/app_button.dart';
import 'package:sacco_mobile/shared/widgets/error_widget.dart';
import 'package:sacco_mobile/shared/widgets/loading_indicator.dart';

class LoanDetailScreen extends StatefulWidget {
  final int loanId;

  const LoanDetailScreen({
    super.key,
    required this.loanId,
  });

  @override
  State<LoanDetailScreen> createState() => _LoanDetailScreenState();
}

class _LoanDetailScreenState extends State<LoanDetailScreen> {
  Loan? _loan;
  
  final currencyFormat = NumberFormat.currency(
    symbol: 'UGX ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    // Load loan data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final viewModel = context.read<LoanListViewModel>();
      if (viewModel.state != LoanListState.success) {
        await viewModel.loadLoans();
      }
      final loan = await viewModel.getLoanById(widget.loanId);
      if (mounted) {
        setState(() {
          _loan = loan;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => getIt<LoanListViewModel>(),
      child: Consumer<LoanListViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Loan Details'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () async {
                    await viewModel.refreshLoans();
                    if (mounted) {
                      final loan = await viewModel.getLoanById(widget.loanId);
                      setState(() {
                        _loan = loan;
                      });
                    }
                  },
                ),
              ],
            ),
            body: _buildBody(viewModel),
            bottomNavigationBar: _loan?.isActive == true ? _buildBottomBar() : null,
          );
        },
      ),
    );
  }

  Widget _buildBody(LoanListViewModel viewModel) {
    if (viewModel.state == LoanListState.loading || _loan == null) {
      return const Center(
        child: LoadingIndicator(
          message: 'Loading loan details...',
        ),
      );
    } else if (viewModel.state == LoanListState.error) {
      return AppErrorWidget(
        message: viewModel.errorMessage ?? 'Failed to load loan details',
        onRetry: () => viewModel.refreshLoans(),
      );
    } else if (_loan != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLoanHeader(_loan!),
            const SizedBox(height: 24),
            _buildLoanSummaryCard(_loan!),
            const SizedBox(height: 24),
            _buildPaymentDetailsCard(_loan!),
            const SizedBox(height: 24),
            _buildLoanActivityCard(_loan!),
          ],
        ),
      );
    } else {
      return const Center(
        child: Text('Loan not found'),
      );
    }
  }

  Widget _buildLoanHeader(Loan loan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getLoanTypeText(loan.loanType),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Reference: ${loan.reference}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: _getStatusColor(loan.status, light: true),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                loan.statusText,
                style: TextStyle(
                  color: _getStatusColor(loan.status),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        LinearProgressIndicator(
          value: loan.progressPercentage / 100,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(
            _getStatusColor(loan.status),
          ),
          minHeight: 8,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${loan.progressPercentage.toStringAsFixed(1)}% paid',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _getStatusColor(loan.status),
              ),
            ),
            Text(
              loan.isCompleted ? 'Completed' : '${loan.progressPercentage.toStringAsFixed(1)}% remaining',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoanSummaryCard(Loan loan) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Loan Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Principal',
                    currencyFormat.format(loan.amount),
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Interest Rate',
                    '${loan.interestRate}%',
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Term',
                    '${loan.termMonths} months',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Total Interest',
                    currencyFormat.format(loan.totalInterest),
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Total Payable',
                    currencyFormat.format(loan.totalAmountPayable),
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Outstanding',
                    currencyFormat.format(loan.outstandingBalance),
                    valueColor: loan.outstandingBalance > 0 ? AppTheme.primaryColor : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Application Date',
                    DateFormat('MMM dd, yyyy').format(loan.applicationDate),
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    loan.approvalDate != null ? 'Approval Date' : 'Status',
                    loan.approvalDate != null
                        ? DateFormat('MMM dd, yyyy').format(loan.approvalDate!)
                        : loan.statusText,
                  ),
                ),
              ],
            ),
            if (loan.disbursementDate != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      'Disbursement Date',
                      DateFormat('MMM dd, yyyy').format(loan.disbursementDate!),
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      loan.isCompleted ? 'Completion Date' : 'Expected End Date',
                      loan.isCompleted && loan.lastPaymentDate != null
                          ? DateFormat('MMM dd, yyyy').format(loan.lastPaymentDate!)
                          : DateFormat('MMM dd, yyyy').format(
                              loan.disbursementDate!.add(Duration(days: 30 * loan.termMonths)),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetailsCard(Loan loan) {
    // Only show for active loans
    if (!loan.isActive) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (loan.nextPaymentDate != null) ...[
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _isPaymentDueSoon(loan.nextPaymentDate!)
                          ? Colors.red[100]
                          : Colors.amber[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.calendar_today,
                      color: _isPaymentDueSoon(loan.nextPaymentDate!)
                          ? Colors.red[700]
                          : Colors.amber[700],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Next Payment Due',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('EEEE, MMMM dd, yyyy').format(loan.nextPaymentDate!),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: _isPaymentDueSoon(loan.nextPaymentDate!)
                                ? Colors.red[700]
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            
            // Estimated monthly payment
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Monthly Payment',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    currencyFormat.format(_calculateMonthlyPayment(loan)),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            if (loan.missedPaymentsCount > 0) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red[700],
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Late Payment Alert',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700],
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'You have ${loan.missedPaymentsCount} missed payment${loan.missedPaymentsCount > 1 ? 's' : ''}. '
                            'Please make a payment as soon as possible to avoid additional penalties.',
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Payment button
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: 'Make Payment',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => LoanRepaymentScreen(
                        loan: loan,
                      ),
                    ),
                  );
                },
                iconData: Icons.payment,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanActivityCard(Loan loan) {
    // This would typically show a list of repayments or transactions
    // For now, it's just a placeholder
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Loan Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to loan activity screen
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Sample activities
            // In a real app, these would be fetched from the API
            _buildActivityItem(
              title: 'Loan Approved',
              date: loan.approvalDate ?? loan.applicationDate,
              icon: Icons.check_circle,
              iconColor: Colors.green,
            ),
            if (loan.disbursementDate != null)
              _buildActivityItem(
                title: 'Loan Disbursed',
                date: loan.disbursementDate!,
                amount: loan.amount,
                icon: Icons.account_balance,
                iconColor: Colors.blue,
              ),
            if (loan.lastPaymentDate != null)
              _buildActivityItem(
                title: 'Last Payment',
                date: loan.lastPaymentDate!,
                amount: _calculateMonthlyPayment(loan),
                icon: Icons.payment,
                iconColor: AppTheme.primaryColor,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem({
    required String title,
    required DateTime date,
    double? amount,
    required IconData icon,
    required Color iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd MMM, yyyy').format(date),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (amount != null)
            Text(
              currencyFormat.format(amount),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    if (_loan == null || !_loan!.isActive) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Outstanding Balance',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currencyFormat.format(_loan!.outstandingBalance),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 150,
            child: AppButton(
              text: 'Make Payment',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => LoanRepaymentScreen(
                      loan: _loan!,
                    ),
                  ),
                );
              },
              height: 48,
            ),
          ),
        ],
      ),
    );
  }

  // Helper function to check if payment is due soon (within 7 days)
  bool _isPaymentDueSoon(DateTime paymentDate) {
    final now = DateTime.now();
    final difference = paymentDate.difference(now).inDays;
    return difference <= 7 && difference >= 0;
  }

  // Helper function to calculate monthly payment
  double _calculateMonthlyPayment(Loan loan) {
    // Simple calculation for monthly payment
    // In a real app, this would likely be provided by the API
    return loan.totalAmountPayable / loan.termMonths;
  }

  String _getLoanTypeText(String loanType) {
    switch (loanType) {
      case 'PERSONAL':
        return 'Personal Loan';
      case 'BUSINESS':
        return 'Business Loan';
      case 'EDUCATION':
        return 'Education Loan';
      case 'EMERGENCY':
        return 'Emergency Loan';
      default:
        return loanType;
    }
  }

  Color _getStatusColor(String status, {bool light = false}) {
    switch (status) {
      case 'PENDING':
        return light ? Colors.amber[100]! : Colors.amber[700]!;
      case 'APPROVED':
        return light ? Colors.blue[100]! : Colors.blue[700]!;
      case 'REJECTED':
        return light ? Colors.red[100]! : Colors.red[700]!;
      case 'DISBURSED':
        return light ? Colors.green[100]! : Colors.green[700]!;
      case 'COMPLETED':
        return light ? Colors.indigo[100]! : Colors.indigo[700]!;
      case 'DEFAULTED':
        return light ? Colors.deepOrange[100]! : Colors.deepOrange[700]!;
      default:
        return light ? Colors.grey[200]! : Colors.grey[700]!;
    }
  }
}