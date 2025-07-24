import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Import screens
import '../../features/auth/views/login_screen.dart';
import '../../features/auth/views/register_screen.dart';
import '../../features/dashboard/views/dashboard_screen.dart';
import '../../features/auth/providers/auth_providers.dart';

// Route names
class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const dashboard = '/dashboard';
  static const profile = '/profile';
  static const loans = '/loans';
  static const savings = '/savings';
  static const transactions = '/transactions';
  static const forgotPassword = '/forgot-password';
}

// Router provider for Riverpod integration
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.login,
    debugLogDiagnostics: true,
    refreshListenable: RouterRefreshNotifier(ref),
    redirect: (context, state) {
      final isAuthenticated = ref.read(authStatusProvider);
      final isAuthRoute = [AppRoutes.login, AppRoutes.register, AppRoutes.forgotPassword]
          .contains(state.matchedLocation);

      // If not authenticated and trying to access protected route, redirect to login
      if (!isAuthenticated && !isAuthRoute) {
        return AppRoutes.login;
      }

      // If authenticated and on auth route, redirect to dashboard
      if (isAuthenticated && isAuthRoute) {
        return AppRoutes.dashboard;
      }

      return null; // No redirect needed
    },
    routes: [
      // Authentication routes
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      
      // Protected routes (require authentication)
      GoRoute(
        path: AppRoutes.dashboard,
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.loans,
        name: 'loans',
        builder: (context, state) => const LoansScreen(),
      ),
      GoRoute(
        path: AppRoutes.savings,
        name: 'savings',
        builder: (context, state) => const SavingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.transactions,
        name: 'transactions',
        builder: (context, state) => const TransactionsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Page Not Found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'The page "${state.matchedLocation}" does not exist.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.dashboard),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    ),
  );
});

// Legacy router for backward compatibility (will be removed after full migration)
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.login,
  routes: [
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: AppRoutes.dashboard,
      builder: (context, state) => const DashboardScreen(),
    ),
  ],
);

// Router refresh notifier for auth state changes
class RouterRefreshNotifier extends ChangeNotifier {
  final Ref _ref;
  
  RouterRefreshNotifier(this._ref) {
    _ref.listen(authStatusProvider, (previous, next) {
      notifyListeners(); // Refresh router when auth state changes
    });
  }
}

// Placeholder screens (to be implemented in Phase 2)
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: const Center(
        child: Text('Forgot Password Screen - Coming Soon'),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const Center(
        child: Text('Profile Screen - Coming Soon'),
      ),
    );
  }
}

class LoansScreen extends StatelessWidget {
  const LoansScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Loans')),
      body: const Center(
        child: Text('Loans Screen - Coming Soon'),
      ),
    );
  }
}

class SavingsScreen extends StatelessWidget {
  const SavingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Savings')),
      body: const Center(
        child: Text('Savings Screen - Coming Soon'),
      ),
    );
  }
}

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: const Center(
        child: Text('Transactions Screen - Coming Soon'),
      ),
    );
  }
}

// Navigation extension methods
extension AppNavigationExtension on BuildContext {
  void goToLogin() => go(AppRoutes.login);
  void goToRegister() => go(AppRoutes.register);
  void goToDashboard() => go(AppRoutes.dashboard);
  void goToProfile() => go(AppRoutes.profile);
  void goToLoans() => go(AppRoutes.loans);
  void goToSavings() => go(AppRoutes.savings);
  void goToTransactions() => go(AppRoutes.transactions);
}