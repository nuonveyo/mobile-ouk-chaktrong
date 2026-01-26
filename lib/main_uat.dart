import 'main.dart';
import 'core/config/env_config.dart';
import 'firebase_options_uat.dart';

void main() async {
  final config = EnvConfig(
    environment: Environment.uat,
    appName: 'Sdach Ouk UAT',
    apiBaseUrl: 'https://uat-api.example.com', // Replace with your UAT API URL
    firebaseOptions: DefaultFirebaseOptions.currentPlatform,
  );

  await runner(config);
}
