import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app/app.dart';
import 'app/app_config.dart';
import 'core/providers/service_providers.dart';
import 'firebase_options.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set app environment
  AppConfig.setEnvironment(Environment.development);

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Create provider container for early initialization
  final container = ProviderContainer();

  try {
    // Initialize core services
    await _initializeServices(container);
    
    // Run the app with Riverpod
    runApp(
      UncontrolledProviderScope(
        container: container,
        child: const SaccoApp(),
      ),
    );
  } catch (e) {
    // If initialization fails, run with basic error handling
    debugPrint('Service initialization failed: $e');
    runApp(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Failed to initialize app services'),
                  const SizedBox(height: 8),
                  Text('Error: $e'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => main(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _initializeServices(ProviderContainer container) async {
  // Initialize cache service first (needed by other services)
  final cacheService = container.read(cacheServiceProvider);
  await cacheService.initialize();

  // Initialize notification service
  final notificationService = container.read(notificationServiceProvider);
  await notificationService.initialize();

  // Initialize API client analytics
  final apiClient = container.read(apiClientProvider);
  await apiClient.initializeAnalytics();

  debugPrint('All services initialized successfully');
}