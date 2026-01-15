import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sacco_mobile/app/app_theme.dart';
import 'package:sacco_mobile/core/di/service_locator.dart';
import 'package:sacco_mobile/features/savings/viewmodels/savings_account_viewmodel.dart';
import 'package:sacco_mobile/shared/widgets/app_button.dart';
import 'package:sacco_mobile/shared/widgets/app_text_field.dart';
import 'package:sacco_mobile/shared/widgets/loading_indicator.dart';

class DepositScreen extends StatefulWidget {
  const DepositScreen({super.key});

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedPaymentMethod;
  final List<Map<String, String>> _paymentMethods = [
    {'value': 'CASH', 'label': 'Cash'},
    {'value': 'MOBILE_MONEY', 'label': 'Mobile Money'},
    {'value': 'BANK_TRANSFER', 'label': 'Bank Transfer'},
  ];

  final currencyFormat = NumberFormat.currency(
    symbol: 'UGX ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    // Load savings account data if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<SavingsAccountViewModel>();
      if (viewModel.savingsAccount == null) {
        viewModel.loadSavingsAccount();
      }
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
      create: (_) => getIt<SavingsAccountViewModel>(),
      child: Consumer<SavingsAccountViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Make Deposit'),
            ),
            body: _buildBody(viewModel),
          );
        },
      ),
    );
  }

  Widget _buildBody(SavingsAccountViewModel viewModel) {
    if (viewModel.state == SavingsAccountState.loading) {
      return const Center(
        child: LoadingIndicator(
          message: 'Processing...',
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account information card
            if (viewModel.savingsAccount != null)
              _buildAccountInfoCard(viewModel),

            const SizedBox(height: 24),

            // Deposit form
            const Text(
              'Deposit Details',
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
              hintText: 'Enter deposit amount',
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid amount';
                }
                if (double.parse(value) <= 0) {
                  return 'Amount must be greater than zero';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Payment method dropdown
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payment Method',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
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
            const SizedBox(height: 16),

            // Description field
            AppTextField(
              controller: _descriptionController,
              labelText: 'Description (Optional)',
              hintText: 'Enter description or purpose',
              maxLines: 2,
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
                text: 'Deposit',
                onPressed: viewModel.state == SavingsAccountState.loading
                    ? null
                    : () => _submitDeposit(viewModel),
                isLoading: viewModel.state == SavingsAccountState.loading,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountInfoCard(SavingsAccountViewModel viewModel) {
    final account = viewModel.savingsAccount!;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account Number',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      account.accountNumber,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Balance',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormat.format(account.balance),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitDeposit(SavingsAccountViewModel viewModel) async {
    if (_formKey.currentState?.validate() ?? false) {
      // Hide keyboard
      FocusScope.of(context).unfocus();

      final amount = double.parse(_amountController.text);
      final paymentMethod = _selectedPaymentMethod!;
      final description = _descriptionController.text.isNotEmpty
          ? _descriptionController.text
          : null;

      final success = await viewModel.makeDeposit(
        amount: amount,
        paymentMethod: paymentMethod,
        description: description,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Successfully deposited ${currencyFormat.format(amount)}'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }
}
