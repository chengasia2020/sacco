import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sacco_mobile/app/app_theme.dart';
import 'package:sacco_mobile/core/di/service_locator.dart';
import 'package:sacco_mobile/features/loans/models/loan.dart';
import 'package:sacco_mobile/features/loans/viewmodels/loan_repayment_viewmodel.dart';
import 'package:sacco_mobile/shared/widgets/app_button.dart';
import 'package:sacco_mobile/shared/widgets/app_text_field.dart';
import 'package:sacco_mobile/shared/widgets/loading_indicator.dart';

class LoanRepaymentScreen extends StatefulWidget {
  final Loan loan;

  const LoanRepaymentScreen({
    super.key,
    required this.loan,
  });

  @override
  State<LoanRepaymentScreen> createState() => _LoanRepaymentScreenState();
}

class _LoanRepaymentScreenState extends State<LoanRepaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedPaymentMethod;
  final List<Map<String, String>> _paymentMethods = [
    {'value': 'CASH', 'label': 'Cash'},
    {'value': 'MOBILE_MONEY', 'label': 'Mobile Money'},
    {'value': 'BANK_TRANSFER', 'label': 'Bank Transfer'},
    {'value': 'CHEQUE', 'label': 'Cheque'},
  ];

  final currencyFormat = NumberFormat.currency(
    symbol: 'UGX ',
    decimalDigits: 0,
  );

  double _repaymentAmount = 0;
  double _penaltyAmount = 0;

  @override
  void initState() {
    super.initState();

    // Set default repayment amount to monthly payment
    _repaymentAmount = widget.loan.outstandingBalance > 0
        ? _calculateMonthlyPayment(widget.loan)
        : 0;

    // Set controller value
    _amountController.text = _repaymentAmount.toStringAsFixed(0);

    // Initialize view model
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<LoanRepaymentViewModel>();
      viewModel.setSelectedLoan(widget.loan);

      // Calculate penalty if any
      _penaltyAmount = viewModel.calculatePenalty(widget.loan);
      setState(() {});
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => getIt<LoanRepaymentViewModel>(),
      child: Consumer<LoanRepaymentViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Loan Repayment'),
            ),
            body: _buildBody(viewModel),
          );
        },
      ),
    );
  }

  Widget _buildBody(LoanRepaymentViewModel viewModel) {
    if (viewModel.state == LoanRepaymentState.processing) {
      return const Center(
        child: LoadingIndicator(
          message: 'Processing payment...',
        ),
      );
    } else if (viewModel.state == LoanRepaymentState.processed) {
      return _buildSuccessScreen(viewModel);
    } else {
      return _buildRepaymentForm(viewModel);
    }
  }

  Widget _buildRepaymentForm(LoanRepaymentViewModel viewModel) {
    final loan = widget.loan;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Loan information card
            _buildLoanInfoCard(loan),
            const SizedBox(height: 24),

            // Payment amount section
            const Text(
              'Payment Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Amount field
            AppTextField(
              controller: _amountController,
              labelText: 'Amount (UGX)',
              hintText: 'Enter payment amount',
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter payment amount';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid amount';
                }
                if (double.parse(value) <= 0) {
                  return 'Amount must be greater than zero';
                }
                return null;
              },
              onChanged: (value) {
                if (value.isNotEmpty) {
                  _repaymentAmount = double.tryParse(value) ?? 0;
                }
              },
            ),
            const SizedBox(height: 8),

            // Quick amount buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickAmountButton(
                  'Minimum',
                  _calculateMonthlyPayment(loan),
                ),
                _buildQuickAmountButton(
                  'Half Loan',
                  loan.outstandingBalance / 2,
                ),
                _buildQuickAmountButton(
                  'Full Loan',
                  loan.outstandingBalance,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Payment method
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payment Method',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedPaymentMethod,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                    ),
                    hint: const Text('Select payment method'),
                    items: _paymentMethods.map((item) {
                      return DropdownMenuItem<String>(
                        value: item['value'],
                        child: Text(item['label']!),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPaymentMethod = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a payment method';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Description field
            AppTextField(
              controller: _descriptionController,
              labelText: 'Description (Optional)',
              hintText: 'Add payment notes',
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Payment summary
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Payment Summary',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSummaryRow(
                      'Payment Amount:',
                      currencyFormat.format(_repaymentAmount),
                    ),
                    if (_penaltyAmount > 0) ...[
                      _buildSummaryRow(
                        'Penalty Amount:',
                        currencyFormat.format(_penaltyAmount),
                        valueColor: Colors.red[700],
                      ),
                      _buildSummaryRow(
                        'Total Due:',
                        currencyFormat
                            .format(_repaymentAmount + _penaltyAmount),
                        isBold: true,
                      ),
                    ],
                    const Divider(height: 24),
                    _buildSummaryRow(
                      'Remaining Balance After Payment:',
                      currencyFormat.format(_calculateRemainingBalance()),
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Error message
            if (viewModel.errorMessage != null)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        viewModel.errorMessage!,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              ),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: 'Make Payment',
                onPressed: viewModel.state == LoanRepaymentState.processing
                    ? null
                    : () => _submitPayment(viewModel),
                isLoading: viewModel.state == LoanRepaymentState.processing,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessScreen(LoanRepaymentViewModel viewModel) {
    final loan = viewModel.selectedLoan!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 32),

          // Success icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.green[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              size: 64,
              color: Colors.green[700],
            ),
          ),
          const SizedBox(height: 24),

          // Success message
          const Text(
            'Payment Successful!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Your payment of ${currencyFormat.format(_repaymentAmount)} has been successfully processed.',
            style: const TextStyle(
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Receipt card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Payment Receipt',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Ref: ${viewModel.referenceNumber ?? "N/A"}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildReceiptRow('Date:',
                      DateFormat('dd MMM, yyyy').format(DateTime.now())),
                  _buildReceiptRow(
                      'Time:', DateFormat('hh:mm a').format(DateTime.now())),
                  _buildReceiptRow('Payment Method:',
                      _getPaymentMethodText(_selectedPaymentMethod!)),
                  _buildReceiptRow(
                      'Amount:', currencyFormat.format(_repaymentAmount)),
                  if (_penaltyAmount > 0)
                    _buildReceiptRow(
                        'Penalty:', currencyFormat.format(_penaltyAmount)),
                  const Divider(height: 24),
                  _buildReceiptRow('Loan Reference:', loan.reference),
                  _buildReceiptRow('Previous Balance:',
                      currencyFormat.format(loan.outstandingBalance)),
                  _buildReceiptRow(
                    'New Balance:',
                    currencyFormat.format(_calculateRemainingBalance()),
                    isBold: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {
                  // TODO: Implement receipt download
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Receipt download not implemented yet')),
                  );
                },
                icon: const Icon(Icons.download),
                tooltip: 'Download Receipt',
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: () {
                  // TODO: Implement receipt sharing
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Receipt sharing not implemented yet')),
                  );
                },
                icon: const Icon(Icons.share),
                tooltip: 'Share Receipt',
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: () {
                  // TODO: Implement receipt printing
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Receipt printing not implemented yet')),
                  );
                },
                icon: const Icon(Icons.print),
                tooltip: 'Print Receipt',
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Return button
          SizedBox(
            width: double.infinity,
            child: AppButton(
              text: 'Return to Loan Details',
              onPressed: () {
                Navigator.of(context).pop();
              },
              buttonType: ButtonType.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoanInfoCard(Loan loan) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Loan #${loan.reference}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(loan.status, light: true),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    loan.statusText,
                    style: TextStyle(
                      color: _getStatusColor(loan.status),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Balance',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormat.format(loan.outstandingBalance),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Monthly Payment',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormat.format(_calculateMonthlyPayment(loan)),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: loan.progressPercentage / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getStatusColor(loan.status),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${loan.progressPercentage.toStringAsFixed(1)}% Paid',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            if (loan.nextPaymentDate != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: _isPaymentDueSoon(loan.nextPaymentDate!)
                        ? Colors.red[700]
                        : Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Next payment due: ${DateFormat('MMM dd, yyyy').format(loan.nextPaymentDate!)}',
                    style: TextStyle(
                      color: _isPaymentDueSoon(loan.nextPaymentDate!)
                          ? Colors.red[700]
                          : Colors.grey[600],
                      fontSize: 14,
                      fontWeight: _isPaymentDueSoon(loan.nextPaymentDate!)
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ],
            if (_penaltyAmount > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.red[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Late Payment Penalty',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'A penalty of ${currencyFormat.format(_penaltyAmount)} has been added due to late payment.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAmountButton(String label, double amount) {
    return InkWell(
      onTap: () {
        setState(() {
          _amountController.text = amount.toStringAsFixed(0);
          _repaymentAmount = amount;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          '$label (${currencyFormat.format(amount)})',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {Color? valueColor, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitPayment(LoanRepaymentViewModel viewModel) async {
    if (_formKey.currentState?.validate() ?? false) {
      // Hide keyboard
      FocusScope.of(context).unfocus();

      final amount = double.parse(_amountController.text);
      final paymentMethod = _selectedPaymentMethod!;
      final description = _descriptionController.text.isNotEmpty
          ? _descriptionController.text
          : null;

      // Confirm payment
      final confirmed = await _showConfirmationDialog(amount);
      if (!confirmed) return;

      // Process payment
      final success = await viewModel.makeRepayment(
        loanId: widget.loan.id,
        amount: amount,
        paymentMethod: paymentMethod,
        description: description,
      );

      if (!success && mounted) {
        // Error handling is already handled by the viewModel
        // and displayed in the UI through errorMessage
      }
    }
  }

  Future<bool> _showConfirmationDialog(double amount) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to make a payment of ${currencyFormat.format(amount)}?',
              ),
              const SizedBox(height: 12),
              Text(
                'This action cannot be undone.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
              ),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  // Helper method to calculate monthly payment
  double _calculateMonthlyPayment(Loan loan) {
    // Simple calculation for monthly payment
    // In a real app, this would likely be provided by the API
    return loan.totalAmountPayable / loan.termMonths;
  }

  // Helper method to calculate remaining balance after payment
  double _calculateRemainingBalance() {
    return widget.loan.outstandingBalance - _repaymentAmount;
  }

  // Helper method to check if payment is due soon (within 7 days)
  bool _isPaymentDueSoon(DateTime paymentDate) {
    final now = DateTime.now();
    final difference = paymentDate.difference(now).inDays;
    return difference <= 7 && difference >= 0;
  }

  // Helper method to get payment method display text
  String _getPaymentMethodText(String method) {
    final item = _paymentMethods.firstWhere(
      (item) => item['value'] == method,
      orElse: () => {'label': method},
    );
    return item['label']!;
  }

  // Helper method to get status color
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
