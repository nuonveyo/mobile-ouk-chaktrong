import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'app.dart';
import 'services/sound_service.dart';
import 'services/remote_config_service.dart';
import 'services/notification_service.dart';
import 'services/room_lifecycle_service.dart';
import 'core/localization/app_strings.dart';
import 'core/config/env_config.dart';

void main() async {
  // This can be the default entry point (e.g., Production)
  // Or we can leave it empty and use main_prod.dart / main_uat.dart
}

Future<void> runner(EnvConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set global app config for access throughout the app
  appConfig = config;
  
  // Set up global error handler for release mode
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('Flutter error: ${details.exception}');
  };
  
  // Initialize Firebase with environment-specific options
  try {
    await Firebase.initializeApp(
      options: config.firebaseOptions,
    ).timeout(const Duration(seconds: 10), onTimeout: () {
      debugPrint('Firebase init timeout');
      throw Exception('Firebase init timeout');
    });
  } catch (e) {
    debugPrint('Firebase init failed: $e');
    // Continue anyway - app may work partially without Firebase
  }
  
  // Set up background message handler for FCM
  try {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('FCM background handler setup failed: $e');
  }
  
  // Initialize localization with timeout
  try {
    await appStrings.init().timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        debugPrint('appStrings init timeout');
      },
    );
  } catch (e) {
    debugPrint('appStrings init failed: $e');
  }
  
  // Initialize optional services with error handling and timeouts
  try {
    await SoundService().init().timeout(const Duration(seconds: 5));
  } catch (e) {
    debugPrint('SoundService init failed: $e');
  }
  
  try {
    await RemoteConfigService().init().timeout(const Duration(seconds: 15));
  } catch (e) {
    debugPrint('RemoteConfigService init failed: $e');
  }
  
  try {
    await notificationService.init().timeout(const Duration(seconds: 10));
  } catch (e) {
    debugPrint('NotificationService init failed: $e');
  }
  
  // Initialize room lifecycle service for cleanup
  try {
    roomLifecycleService.init();
  } catch (e) {
    debugPrint('RoomLifecycleService init failed: $e');
  }
  
  // Set preferred orientations (portrait only for better gameplay)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF1A0A2E),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(OukChaktrongApp(config: config));
}

