// lib/core/services/notification_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';

import '../storage/secure_storage_service.dart';
import '../errors/app_error.dart';

enum NotificationType {
  transaction,
  loan,
  savings,
  security,
  promotion,
  reminder,
  system,
}

enum NotificationPriority {
  low,
  normal,
  high,
  urgent,
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final NotificationPriority priority;
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  final bool isRead;
  final String? imageUrl;
  final String? actionUrl;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.priority = NotificationPriority.normal,
    this.data,
    required this.createdAt,
    this.isRead = false,
    this.imageUrl,
    this.actionUrl,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'type': type.toString(),
        'priority': priority.toString(),
        'data': data,
        'createdAt': createdAt.toIso8601String(),
        'isRead': isRead,
        'imageUrl': imageUrl,
        'actionUrl': actionUrl,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'],
        title: json['title'],
        body: json['body'],
        type: NotificationType.values.firstWhere(
          (e) => e.toString() == json['type'],
          orElse: () => NotificationType.system,
        ),
        priority: NotificationPriority.values.firstWhere(
          (e) => e.toString() == json['priority'],
          orElse: () => NotificationPriority.normal,
        ),
        data: json['data'],
        createdAt: DateTime.parse(json['createdAt']),
        isRead: json['isRead'] ?? false,
        imageUrl: json['imageUrl'],
        actionUrl: json['actionUrl'],
      );

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    NotificationPriority? priority,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    bool? isRead,
    String? imageUrl,
    String? actionUrl,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      imageUrl: imageUrl ?? this.imageUrl,
      actionUrl: actionUrl ?? this.actionUrl,
    );
  }
}

class NotificationService {
  final FlutterLocalNotificationsPlugin _localNotifications;
  final FirebaseMessaging _firebaseMessaging;
  final SecureStorageService _secureStorage;

  static const String _notificationTokenKey = 'fcm_token';
  static const String _notificationSettingsKey = 'notification_settings';
  static const String _notificationHistoryKey = 'notification_history';

  bool _isInitialized = false;
  final List<AppNotification> _notificationHistory = [];

  NotificationService(
    this._localNotifications,
    this._firebaseMessaging,
    this._secureStorage,
  );

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _initializeLocalNotifications();
      await _initializeFirebaseMessaging();
      await _loadNotificationHistory();
      
      _isInitialized = true;
      debugPrint('NotificationService: Initialized successfully');
    } catch (e) {
      throw AppError(
        message: 'Failed to initialize notification service: ${e.toString()}',
        userFriendlyMessage: 'Failed to set up notifications',
      );
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions for iOS
    if (Platform.isIOS) {
      await _requestIOSPermissions();
    }
  }

  /// Initialize Firebase messaging
  Future<void> _initializeFirebaseMessaging() async {
    // Request permission for notifications
    await _requestNotificationPermissions();

    // Get FCM token
    final token = await _firebaseMessaging.getToken();
    if (token != null) {
      await _secureStorage.write(_notificationTokenKey, token);
      debugPrint('FCM Token: $token');
    }

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      await _secureStorage.write(_notificationTokenKey, newToken);
      debugPrint('FCM Token refreshed: $newToken');
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    // Handle notification taps when app is terminated
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check if app was opened from a notification
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  /// Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Received foreground message: ${message.messageId}');
    
    final notification = _createAppNotificationFromRemote(message);
    await _addToHistory(notification);
    
    // Show local notification if app is in foreground
    await _showLocalNotification(notification);
  }

  /// Handle background messages
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('Received background message: ${message.messageId}');
    // Handle background processing here
  }

  /// Handle notification tap
  Future<void> _handleNotificationTap(RemoteMessage message) async {
    debugPrint('Notification tapped: ${message.messageId}');
    
    final notification = _createAppNotificationFromRemote(message);
    await _addToHistory(notification);
    
    // Navigate to appropriate screen based on notification data
    if (notification.actionUrl != null) {
      // Handle deep linking here
      debugPrint('Navigate to: ${notification.actionUrl}');
    }
  }

  /// Show local notification
  Future<void> showLocalNotification({
    required String title,
    required String body,
    NotificationType type = NotificationType.system,
    NotificationPriority priority = NotificationPriority.normal,
    Map<String, dynamic>? data,
    String? imageUrl,
    String? actionUrl,
  }) async {
    if (!_isInitialized) await initialize();

    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      type: type,
      priority: priority,
      data: data,
      createdAt: DateTime.now(),
      imageUrl: imageUrl,
      actionUrl: actionUrl,
    );

    await _showLocalNotification(notification);
    await _addToHistory(notification);
  }

  /// Internal method to show local notification
  Future<void> _showLocalNotification(AppNotification notification) async {
    final androidDetails = AndroidNotificationDetails(
      _getChannelId(notification.type),
      _getChannelName(notification.type),
      channelDescription: _getChannelDescription(notification.type),
      importance: _getImportance(notification.priority),
      priority: _getPriority(notification.priority),
      icon: '@mipmap/ic_launcher',
      largeIcon: notification.imageUrl != null
          ? FilePathAndroidBitmap(notification.imageUrl!)
          : null,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      int.parse(notification.id) % 2147483647, // Ensure ID fits in int32
      notification.title,
      notification.body,
      details,
      payload: jsonEncode(notification.toJson()),
    );
  }

  /// Handle local notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Local notification tapped: ${response.id}');
    
    if (response.payload != null) {
      try {
        final notificationData = jsonDecode(response.payload!);
        final notification = AppNotification.fromJson(notificationData);
        
        // Mark as read
        _markAsRead(notification.id);
        
        // Handle navigation
        if (notification.actionUrl != null) {
          debugPrint('Navigate to: ${notification.actionUrl}');
        }
      } catch (e) {
        debugPrint('Error parsing notification payload: $e');
      }
    }
  }

  /// Get FCM token
  Future<String?> getFCMToken() async {
    try {
      return await _secureStorage.read(_notificationTokenKey);
    } catch (e) {
      return null;
    }
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      throw AppError(
        message: 'Failed to subscribe to topic: ${e.toString()}',
        userFriendlyMessage: 'Failed to subscribe to notifications',
      );
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      throw AppError(
        message: 'Failed to unsubscribe from topic: ${e.toString()}',
        userFriendlyMessage: 'Failed to unsubscribe from notifications',
      );
    }
  }

  /// Get notification history
  List<AppNotification> getNotificationHistory() {
    return List.unmodifiable(_notificationHistory);
  }

  /// Get unread notifications count
  int getUnreadCount() {
    return _notificationHistory.where((n) => !n.isRead).length;
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _markAsRead(notificationId);
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    for (int i = 0; i < _notificationHistory.length; i++) {
      if (!_notificationHistory[i].isRead) {
        _notificationHistory[i] = _notificationHistory[i].copyWith(isRead: true);
      }
    }
    await _saveNotificationHistory();
  }

  /// Clear notification history
  Future<void> clearHistory() async {
    _notificationHistory.clear();
    await _saveNotificationHistory();
  }

  /// Internal methods
  Future<void> _addToHistory(AppNotification notification) async {
    _notificationHistory.insert(0, notification);
    
    // Keep only last 100 notifications
    if (_notificationHistory.length > 100) {
      _notificationHistory.removeRange(100, _notificationHistory.length);
    }
    
    await _saveNotificationHistory();
  }

  Future<void> _markAsRead(String notificationId) async {
    final index = _notificationHistory.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notificationHistory[index] = _notificationHistory[index].copyWith(isRead: true);
      await _saveNotificationHistory();
    }
  }

  Future<void> _saveNotificationHistory() async {
    try {
      final jsonList = _notificationHistory.map((n) => n.toJson()).toList();
      await _secureStorage.write(_notificationHistoryKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving notification history: $e');
    }
  }

  Future<void> _loadNotificationHistory() async {
    try {
      final jsonString = await _secureStorage.read(_notificationHistoryKey);
      if (jsonString != null) {
        final jsonList = jsonDecode(jsonString) as List;
        _notificationHistory.clear();
        _notificationHistory.addAll(
          jsonList.map((json) => AppNotification.fromJson(json)).toList(),
        );
      }
    } catch (e) {
      debugPrint('Error loading notification history: $e');
    }
  }

  AppNotification _createAppNotificationFromRemote(RemoteMessage message) {
    return AppNotification(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: message.notification?.title ?? 'Notification',
      body: message.notification?.body ?? '',
      type: _getNotificationTypeFromData(message.data),
      priority: _getPriorityFromData(message.data),
      data: message.data,
      createdAt: DateTime.now(),
      imageUrl: message.notification?.android?.imageUrl,
      actionUrl: message.data['action_url'],
    );
  }

  NotificationType _getNotificationTypeFromData(Map<String, dynamic> data) {
    final typeString = data['type'] as String?;
    return NotificationType.values.firstWhere(
      (e) => e.toString().split('.').last == typeString,
      orElse: () => NotificationType.system,
    );
  }

  NotificationPriority _getPriorityFromData(Map<String, dynamic> data) {
    final priorityString = data['priority'] as String?;
    return NotificationPriority.values.firstWhere(
      (e) => e.toString().split('.').last == priorityString,
      orElse: () => NotificationPriority.normal,
    );
  }

  String _getChannelId(NotificationType type) {
    switch (type) {
      case NotificationType.transaction:
        return 'transactions';
      case NotificationType.loan:
        return 'loans';
      case NotificationType.savings:
        return 'savings';
      case NotificationType.security:
        return 'security';
      case NotificationType.promotion:
        return 'promotions';
      case NotificationType.reminder:
        return 'reminders';
      case NotificationType.system:
      default:
        return 'system';
    }
  }

  String _getChannelName(NotificationType type) {
    switch (type) {
      case NotificationType.transaction:
        return 'Transactions';
      case NotificationType.loan:
        return 'Loans';
      case NotificationType.savings:
        return 'Savings';
      case NotificationType.security:
        return 'Security';
      case NotificationType.promotion:
        return 'Promotions';
      case NotificationType.reminder:
        return 'Reminders';
      case NotificationType.system:
      default:
        return 'System';
    }
  }

  String _getChannelDescription(NotificationType type) {
    switch (type) {
      case NotificationType.transaction:
        return 'Transaction notifications and updates';
      case NotificationType.loan:
        return 'Loan applications and payment reminders';
      case NotificationType.savings:
        return 'Savings goals and deposit confirmations';
      case NotificationType.security:
        return 'Security alerts and login notifications';
      case NotificationType.promotion:
        return 'Promotional offers and announcements';
      case NotificationType.reminder:
        return 'Payment reminders and important dates';
      case NotificationType.system:
      default:
        return 'System notifications and updates';
    }
  }

  Importance _getImportance(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.urgent:
        return Importance.max;
      case NotificationPriority.high:
        return Importance.high;
      case NotificationPriority.normal:
        return Importance.defaultImportance;
      case NotificationPriority.low:
        return Importance.low;
    }
  }

  Priority _getPriority(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.urgent:
        return Priority.max;
      case NotificationPriority.high:
        return Priority.high;
      case NotificationPriority.normal:
        return Priority.defaultPriority;
      case NotificationPriority.low:
        return Priority.low;
    }
  }

  Future<void> _requestNotificationPermissions() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('Notification permission status: ${settings.authorizationStatus}');
  }

  Future<void> _requestIOSPermissions() async {
    await _localNotifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }
}