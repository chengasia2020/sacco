// lib/features/auth/views/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sacco_mobile/app/app_constants.dart';
import 'package:sacco_mobile/features/auth/providers/auth_providers.dart';
import 'package:sacco_mobile/shared/widgets/app_button.dart';
import 'package:sacco_mobile/shared/widgets/app_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for form fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(registerProvider.notifier).resetState();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Validation methods
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final RegExp emailRegex = RegExp(AppConstants.emailPattern);
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    if (!RegExp(r'^\+256[0-9]{9}$').hasMatch(value)) {
      return 'Enter valid phone number (+256XXXXXXXXX)';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final registerState = ref.watch(registerProvider);

    // Listen for successful registration
    ref.listen(registerProvider, (previous, next) {
      if (next.isSuccess && mounted) {
        _showSuccessDialog();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Text(
                  'Join SACCO',
                  style: Theme.of(context).textTheme.displayMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your account to get started',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Error message
                if (registerState.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Text(
                      registerState.errorMessage!,
                      style: TextStyle(color: Colors.red[800]),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Personal Information Section
                Text(
                  'Personal Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),

                // First Name
                AppTextField(
                  controller: _firstNameController,
                  labelText: 'First Name',
                  hintText: 'Enter your first name',
                  prefixIcon: const Icon(Icons.person_outline),
                  textCapitalization: TextCapitalization.words,
                  validator: _validateName,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Last Name
                AppTextField(
                  controller: _lastNameController,
                  labelText: 'Last Name',
                  hintText: 'Enter your last name',
                  prefixIcon: const Icon(Icons.person_outline),
                  textCapitalization: TextCapitalization.words,
                  validator: _validateName,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Phone Number
                AppTextField(
                  controller: _phoneController,
                  labelText: 'Phone Number',
                  hintText: '+256XXXXXXXXX',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  keyboardType: TextInputType.phone,
                  validator: _validatePhone,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 24),

                // Account Information Section
                Text(
                  'Account Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),

                // Email
                AppTextField(
                  controller: _emailController,
                  labelText: 'Email Address',
                  hintText: 'Enter your email address',
                  prefixIcon: const Icon(Icons.email_outlined),
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Password
                AppTextField(
                  controller: _passwordController,
                  labelText: 'Password',
                  hintText: 'Create a strong password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  obscureText: !_isPasswordVisible,
                  validator: _validatePassword,
                  textInputAction: TextInputAction.next,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Confirm Password
                AppTextField(
                  controller: _confirmPasswordController,
                  labelText: 'Confirm Password',
                  hintText: 'Re-enter your password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  obscureText: !_isConfirmPasswordVisible,
                  validator: _validateConfirmPassword,
                  textInputAction: TextInputAction.done,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 32),

                // Register Button
                AppButton(
                  text: 'Create Account',
                  isLoading: registerState.isLoading,
                  onPressed: registerState.isLoading ? null : _handleRegister,
                ),
                const SizedBox(height: 16),

                // Terms and conditions
                Text(
                  'By creating an account, you agree to our Terms of Service and Privacy Policy.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 16),

                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account?',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('Sign In'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    final registerData = {
      'email': _emailController.text.trim(),
      'password': _passwordController.text,
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'phoneNumber': _phoneController.text.trim(),
    };

    await ref.read(registerProvider.notifier).register(registerData);
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Account Created!'),
        content: const Text(
          'Your account has been successfully created. You can now sign in to access the app.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              context.go('/login'); // Navigate to login
            },
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }
}
