import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sacco_mobile/app/app_theme.dart';
import 'package:sacco_mobile/core/di/service_locator.dart';
import 'package:sacco_mobile/features/loans/viewmodels/loan_application_viewmodel.dart';
import 'package:sacco_mobile/shared/widgets/app_button.dart';
import 'package:sacco_mobile/shared/widgets/app_text_field.dart';
import 'package:sacco_mobile/shared/widgets/loading_indicator.dart';

class LoanApplicationScreen extends StatefulWidget {
  const LoanApplicationScreen({super.key});

  @override
  State<LoanApplicationScreen> createState() => _LoanApplicationScreenState();
}

class _LoanApplicationScreenState extends State<LoanApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  
  // Form controllers
  final _amountController = TextEditingController();
  final _purposeController = TextEditingController();
  final _collateralController = TextEditingController();
  final _employmentDetailsController = TextEditingController();
  final _monthlyIncomeController = TextEditingController();
  
  // Form values
  String? _selectedLoanType;
  int _termMonths = 12;
  
  // Current page and total pages
  int _currentPage = 0;
  final int _totalPages = 3;
  
  // Calculated values
  double _monthlyPayment = 0;
  double _totalInterest = 0;
  double _totalPayable = 0;
  
  // Formatters
  final currencyFormat = NumberFormat.currency(
    symbol: 'UGX ',
    decimalDigits: 0,
  );
  
  @override
  void initState() {
    super.initState();
    // Initialize with default values if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<LoanApplicationViewModel>();
      viewModel.resetState();
    });
  }
  
  @override
  void dispose() {
    _amountController.dispose();
    _purposeController.dispose();
    _collateralController.dispose();
    _employmentDetailsController.dispose();
    _monthlyIncomeController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => getIt<LoanApplicationViewModel>(),
      child: Consumer<LoanApplicationViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Loan Application'),
              actions: [
                if (_currentPage > 0)
                  TextButton(
                    onPressed: () {
                      _previousPage();
                    },
                    child: const Text('Back'),
                  ),
              ],
            ),
            body: _buildBody(viewModel),
          );
        },
      ),
    );
  }

  Widget _buildBody(LoanApplicationViewModel viewModel) {
    if (viewModel.state == LoanApplicationState.submitting) {
      return const Center(
        child: LoadingIndicator(
          message: 'Submitting application...',
        ),
      );
    } else if (viewModel.state == LoanApplicationState.submitted) {
      return _buildSuccessScreen(viewModel);
    } else {
      return _buildApplicationForm(viewModel);
    }
  }

  Widget _buildApplicationForm(LoanApplicationViewModel viewModel) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentPage + 1) / _totalPages,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
          const SizedBox(height: 8),
          
          // Page indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_totalPages, (index) {
              return Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == _currentPage
                      ? AppTheme.primaryColor
                      : Colors.grey[300],
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          
          // Form pages
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                });
              },
              children: [
                _buildLoanTypeAndAmountPage(viewModel),
                _buildPurposeAndCollateralPage(viewModel),
                _buildEmploymentAndSummaryPage(viewModel),
              ],
            ),
          ),
          
          // Navigation and submission buttons
          _buildBottomButtons(viewModel),
        ],
      ),
    );
  }

  Widget _buildLoanTypeAndAmountPage(LoanApplicationViewModel viewModel) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Loan Details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Loan type dropdown
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Loan Type',
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
                  initialValue: _selectedLoanType,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                  ),
                  hint: const Text('Select loan type'),
                  items: viewModel.loanTypes.map((type) {
                    return DropdownMenuItem<String>(
                      value: type['value'],
                      child: Text(type['label']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedLoanType = value;
                      // Reset term months to default value of selected loan type
                      if (value != null) {
                        final loanType = viewModel.loanTypes.firstWhere(
                          (type) => type['value'] == value,
                        );
                        _termMonths = loanType['maxTerm'] as int;
                        
                        // Recalculate loan details if amount is entered
                        if (_amountController.text.isNotEmpty) {
                          _updateLoanCalculations(viewModel);
                        }
                      }
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a loan type';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Amount field
          AppTextField(
            controller: _amountController,
            labelText: 'Loan Amount (UGX)',
            hintText: 'Enter loan amount',
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter loan amount';
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
              if (value.isNotEmpty && _selectedLoanType != null) {
                _updateLoanCalculations(viewModel);
              }
            },
          ),
          const SizedBox(height: 24),
          
          // Term slider
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Loan Term (months)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '$_termMonths months',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Slider(
                value: _termMonths.toDouble(),
                min: 1,
                max: _selectedLoanType != null ? 
                  _getMaxTermForLoanType(_selectedLoanType!, viewModel).toDouble() : 
                  24,
                divisions: _selectedLoanType != null ? 
                  _getMaxTermForLoanType(_selectedLoanType!, viewModel) - 1 : 
                  23,
                label: _termMonths.toString(),
                onChanged: (value) {
                  setState(() {
                    _termMonths = value.toInt();
                    if (_amountController.text.isNotEmpty && _selectedLoanType != null) {
                      _updateLoanCalculations(viewModel);
                    }
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Loan calculation preview (only shown when all fields are filled)
          if (_selectedLoanType != null && _amountController.text.isNotEmpty)
            _buildLoanPreview(viewModel),
        ],
      ),
    );
  }

  Widget _buildPurposeAndCollateralPage(LoanApplicationViewModel viewModel) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Loan Purpose',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Purpose field
          AppTextField(
            controller: _purposeController,
            labelText: 'Purpose of Loan',
            hintText: 'Describe how you plan to use this loan',
            maxLines: 3,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter loan purpose';
              }
              if (value.length < 10) {
                return 'Please provide more details about the loan purpose';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          
          // Collateral field (optional)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Collateral Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(Optional)',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AppTextField(
                controller: _collateralController,
                labelText: 'Collateral Details',
                hintText: 'Describe any assets you are offering as collateral',
                maxLines: 3,
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Info box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Why do we need this information?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'The loan purpose helps us understand how you plan to use the funds and assess your application accordingly. Collateral details, if provided, may improve your chances of approval.',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmploymentAndSummaryPage(LoanApplicationViewModel viewModel) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Employment & Income',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Employment details field
          AppTextField(
            controller: _employmentDetailsController,
            labelText: 'Employment Details',
            hintText: 'Your occupation, employer, and years of employment',
            maxLines: 2,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter employment details';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          
          // Monthly income field
          AppTextField(
            controller: _monthlyIncomeController,
            labelText: 'Monthly Income (UGX)',
            hintText: 'Enter your monthly income',
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter monthly income';
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
          const SizedBox(height: 32),
          
          // Loan summary
          const Text(
            'Loan Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Summary card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSummaryRow(
                    'Loan Type:',
                    _selectedLoanType != null
                        ? _getLoanTypeLabel(_selectedLoanType!, viewModel)
                        : 'Not selected',
                  ),
                  _buildSummaryRow(
                    'Loan Amount:',
                    _amountController.text.isNotEmpty
                        ? currencyFormat.format(double.parse(_amountController.text))
                        : 'Not specified',
                  ),
                  _buildSummaryRow(
                    'Term:',
                    '$_termMonths months',
                  ),
                  _buildSummaryRow(
                    'Interest Rate:',
                    _selectedLoanType != null
                        ? '${_getInterestRateForLoanType(_selectedLoanType!, viewModel)}%'
                        : 'Not specified',
                  ),
                  _buildSummaryRow(
                    'Monthly Payment:',
                    _monthlyPayment > 0
                        ? currencyFormat.format(_monthlyPayment)
                        : 'Not calculated',
                  ),
                  _buildSummaryRow(
                    'Total Interest:',
                    _totalInterest > 0
                        ? currencyFormat.format(_totalInterest)
                        : 'Not calculated',
                  ),
                  _buildSummaryRow(
                    'Total Repayment:',
                    _totalPayable > 0
                        ? currencyFormat.format(_totalPayable)
                        : 'Not calculated',
                    isBold: true,
                  ),
                ],
              ),
            ),
          ),
          
          // Terms and conditions
          const SizedBox(height: 24),
          Row(
            children: [
              Checkbox(
                value: false, // This would be a state variable in a real app
                onChanged: (value) {
                  // Handle terms acceptance
                },
              ),
              Expanded(
                child: Text(
                  'I agree to the terms and conditions of the loan agreement',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ],
          ),
          
          // Error message if there is one
          if (viewModel.errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline, color: Colors.red[700], size: 20),
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
          ],
        ],
      ),
    );
  }

  Widget _buildSuccessScreen(LoanApplicationViewModel viewModel) {
    final application = viewModel.currentApplication!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          
          // Success icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.green[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              size: 80,
              color: Colors.green[700],
            ),
          ),
          const SizedBox(height: 32),
          
          // Success message
          const Text(
            'Application Submitted!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your application for a ${_getLoanTypeLabel(_selectedLoanType!, viewModel)} has been successfully submitted and is now under review.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),
          
          // Application details
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                _buildSuccessDetailRow(
                  'Application Date:',
                  DateFormat('dd MMM, yyyy').format(application.submittedDate),
                ),
                _buildSuccessDetailRow(
                  'Loan Amount:',
                  currencyFormat.format(application.amountRequested),
                ),
                _buildSuccessDetailRow(
                  'Loan Type:',
                  _getLoanTypeLabel(_selectedLoanType!, viewModel),
                ),
                _buildSuccessDetailRow(
                  'Status:',
                  application.statusText,
                  valueColor: Colors.amber[700],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          // What's next information
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Text(
                      'What Happens Next?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTimelineItem(
                  '1',
                  'Application Review',
                  'Our loan officers will review your application',
                ),
                _buildTimelineItem(
                  '2',
                  'Verification',
                  'We may contact you to verify information',
                ),
                _buildTimelineItem(
                  '3',
                  'Decision',
                  'You will receive a decision notification',
                ),
                _buildTimelineItem(
                  '4',
                  'Disbursement',
                  'If approved, funds will be transferred to your account',
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          // Return to dashboard button
          AppButton(
            text: 'Return to Dashboard',
            onPressed: () {
              Navigator.of(context).pop();
            },
            iconData: Icons.home,
          ),
        ],
      ),
    );
  }

  Widget _buildLoanPreview(LoanApplicationViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Loan Preview',
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
                    'Monthly Payment',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormat.format(_monthlyPayment),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Interest',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormat.format(_totalInterest),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Repayment',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormat.format(_totalPayable),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(LoanApplicationViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage > 0)
            Expanded(
              flex: 1,
              child: AppButton(
                text: 'Previous',
                onPressed: () {
                  _previousPage();
                },
                buttonType: ButtonType.outline,
              ),
            )
          else
            const Spacer(),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: AppButton(
              text: _currentPage < _totalPages - 1 ? 'Next' : 'Submit Application',
              onPressed: () {
                if (_currentPage < _totalPages - 1) {
                  _validateAndProceed(viewModel);
                } else {
                  _validateAndSubmit(viewModel);
                }
              },
              iconData: _currentPage < _totalPages - 1 ? null : Icons.send,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              fontSize: isBold ? 16 : 14,
              color: isBold ? AppTheme.primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String step, String title, String description, {bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.blue[700],
            shape: BoxShape.circle,
          ),
          child: Text(
            step,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: Colors.blue[700],
                  fontSize: 12,
                ),
              ),
              if (!isLast)
                Container(
                  margin: const EdgeInsets.only(left: 0, top: 4, bottom: 16),
                  width: 2,
                  height: 24,
                  color: Colors.blue[300],
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _validateAndProceed(LoanApplicationViewModel viewModel) {
    // Validate current page
    if (_currentPage == 0) {
      // Validate loan type and amount page
      if (_selectedLoanType == null) {
        _showValidationError('Please select a loan type');
        return;
      }
      
      if (_amountController.text.isEmpty) {
        _showValidationError('Please enter loan amount');
        return;
      }
      
      try {
        final amount = double.parse(_amountController.text);
        if (amount <= 0) {
          _showValidationError('Loan amount must be greater than zero');
          return;
        }
      } catch (e) {
        _showValidationError('Please enter a valid loan amount');
        return;
      }
    } else if (_currentPage == 1) {
      // Validate purpose page
      if (_purposeController.text.isEmpty) {
        _showValidationError('Please enter loan purpose');
        return;
      }
      
      if (_purposeController.text.length < 10) {
        _showValidationError('Please provide more details about the loan purpose');
        return;
      }
    }
    
    // Proceed to next page
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
  
  void _validateAndSubmit(LoanApplicationViewModel viewModel) {
    // Validate employment and income fields
    if (_employmentDetailsController.text.isEmpty) {
      _showValidationError('Please enter employment details');
      return;
    }
    
    if (_monthlyIncomeController.text.isEmpty) {
      _showValidationError('Please enter monthly income');
      return;
    }
    
    try {
      final income = double.parse(_monthlyIncomeController.text);
      if (income <= 0) {
        _showValidationError('Monthly income must be greater than zero');
        return;
      }
    } catch (e) {
      _showValidationError('Please enter a valid monthly income');
      return;
    }
    
    // Submit application
    _submitApplication(viewModel);
  }
  
  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  void _updateLoanCalculations(LoanApplicationViewModel viewModel) {
    if (_selectedLoanType == null || _amountController.text.isEmpty) {
      return;
    }
    
    try {
      final amount = double.parse(_amountController.text);
      final interestRate = _getInterestRateForLoanType(_selectedLoanType!, viewModel);
      
      _monthlyPayment = viewModel.calculateMonthlyPayment(amount, interestRate, _termMonths);
      _totalInterest = viewModel.calculateTotalInterest(amount, interestRate, _termMonths);
      _totalPayable = amount + _totalInterest;
      
      setState(() {});
    } catch (e) {
      // Handle calculation error
      print('Error calculating loan details: $e');
    }
  }
  
  Future<void> _submitApplication(LoanApplicationViewModel viewModel) async {
    // Prepare application data
    final applicationData = {
      'loan_type': _selectedLoanType,
      'amount_requested': double.parse(_amountController.text),
      'purpose': _purposeController.text,
      'collateral_details': _collateralController.text.isEmpty ? null : _collateralController.text,
      'employment_details': _employmentDetailsController.text,
      'monthly_income': double.parse(_monthlyIncomeController.text),
      'term_months': _termMonths,
    };
    
    // Submit application
    final success = await viewModel.submitLoanApplication(applicationData);
    
    if (!success && mounted) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.errorMessage ?? 'Failed to submit application'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  String _getLoanTypeLabel(String loanType, LoanApplicationViewModel viewModel) {
    final loanTypeInfo = viewModel.loanTypes.firstWhere(
      (type) => type['value'] == loanType,
      orElse: () => {'label': loanType},
    );
    
    return loanTypeInfo['label'] as String;
  }
  
  double _getInterestRateForLoanType(String loanType, LoanApplicationViewModel viewModel) {
    final loanTypeInfo = viewModel.loanTypes.firstWhere(
      (type) => type['value'] == loanType,
      orElse: () => {'interestRate': 0.0},
    );
    
    return loanTypeInfo['interestRate'] as double;
  }
  
  int _getMaxTermForLoanType(String loanType, LoanApplicationViewModel viewModel) {
    final loanTypeInfo = viewModel.loanTypes.firstWhere(
      (type) => type['value'] == loanType,
      orElse: () => {'maxTerm': 24},
    );
    
    return loanTypeInfo['maxTerm'] as int;
  }
}