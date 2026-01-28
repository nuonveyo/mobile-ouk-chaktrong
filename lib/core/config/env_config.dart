import 'package:firebase_core/firebase_core.dart';

enum Environment { prod, uat }

class EnvConfig {
  final Environment environment;
  final String appName;
  final String apiBaseUrl;
  final FirebaseOptions firebaseOptions;

  EnvConfig({
    required this.environment,
    required this.appName,
    required this.apiBaseUrl,
    required this.firebaseOptions,
  });

  bool get isProd => environment == Environment.prod;
  bool get isUat => environment == Environment.uat;
}

/// Global app config - set during app initialization
late EnvConfig appConfig;
