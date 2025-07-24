import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Import existing pages that we know exist
import '../../features/auth/views/login_screen.dart';
import '../../features/dashboard/views/dashboard_screen.dart';

// Route names
class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const dashboard = '/dashboard';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.login,
  debugLogDiagnostics: true,
  routes: [
    // Authentication
    GoRoute(
      path: AppRoutes.login,
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    
    // Dashboard
    GoRoute(
      path: AppRoutes.dashboard,
      name: 'dashboard',
      builder: (context, state) => const DashboardScreen(),
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
            'The page you are looking for does not exist.',
            style: Theme.of(context).textTheme.bodyMedium,
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

// Navigation extension methods
extension AppNavigationExtension on BuildContext {
  void goToLogin() => go(AppRoutes.login);
  void goToDashboard() => go(AppRoutes.dashboard);
}