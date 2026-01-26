import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'services/sound_service.dart';
import 'services/remote_config_service.dart';
import 'core/localization/app_strings.dart';
import 'core/config/env_config.dart';

void main() async {
  // This can be the default entry point (e.g., Production)
  // Or we can leave it empty and use main_prod.dart / main_uat.dart
}

Future<void> runner(EnvConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with environment-specific options
  await Firebase.initializeApp(
    options: config.firebaseOptions,
  );
  
  // Initialize localization
  await appStrings.init();
  
  // Initialize sound service
  await SoundService().init();
  
  // Initialize remote config
  await RemoteConfigService().init();
  
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

