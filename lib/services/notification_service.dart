import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service to handle Firebase Cloud Messaging for join request notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  String? _fcmToken;
  bool _initialized = false;
  
  // Callbacks for notification actions
  void Function(String roomId)? onJoinNowTapped;
  void Function(String roomId)? onCancelTapped;
  void Function(String roomId, String guestName)? onForegroundJoinRequest;

  /// Get the FCM token for this device
  String? get fcmToken => _fcmToken;

  /// Initialize FCM and local notifications
  Future<void> init() async {
    if (_initialized) return;
    
    // Request notification permissions
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      
      // Get FCM token
      _fcmToken = await _messaging.getToken();
      debugPrint('FCM Token: $_fcmToken');
      
      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        debugPrint('FCM Token refreshed: $newToken');
      });
      
      // Initialize local notifications
      await _initLocalNotifications();
      
      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      
      // Handle notification taps when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
      
      // Check if app was opened from a notification
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }
    }
    
    _initialized = true;
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Received foreground message: ${message.data}');
    
    // When in foreground, call the callback to show alert dialog
    if (message.data['type'] == 'join_request') {
      final roomId = message.data['roomId'] ?? '';
      final guestName = message.data['guestName'] ?? 'Someone';
      onForegroundJoinRequest?.call(roomId, guestName);
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.data}');
    
    final roomId = message.data['roomId'];
    if (roomId != null && message.data['type'] == 'join_request') {
      // Navigate to game or show accept dialog
      onJoinNowTapped?.call(roomId);
    }
  }

  void _handleNotificationResponse(NotificationResponse response) {
    if (response.payload == null) return;
    
    try {
      final data = json.decode(response.payload!);
      final roomId = data['roomId'] as String?;
      
      if (roomId != null) {
        if (response.actionId == 'join_now') {
          onJoinNowTapped?.call(roomId);
        } else if (response.actionId == 'cancel') {
          onCancelTapped?.call(roomId);
        } else {
          // Default tap - treat as join
          onJoinNowTapped?.call(roomId);
        }
      }
    } catch (e) {
      debugPrint('Error parsing notification payload: $e');
    }
  }

  Future<void> _showJoinRequestNotification({
    required String roomId,
    required String guestName,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'join_requests',
      'Join Requests',
      channelDescription: 'Notifications when someone wants to join your game',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      actions: [
        AndroidNotificationAction('join_now', 'Join Now', showsUserInterface: true),
        AndroidNotificationAction('cancel', 'Cancel', showsUserInterface: true),
      ],
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _localNotifications.show(
      id: roomId.hashCode, // Use room ID hash as notification ID
      title: 'Join Request',
      body: '$guestName wants to join your game',
      notificationDetails: details,
      payload: json.encode({'roomId': roomId, 'guestName': guestName}),
    );
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message: ${message.data}');
  // Background notifications are handled by the system
}

/// Global instance for easy access
final notificationService = NotificationService();
