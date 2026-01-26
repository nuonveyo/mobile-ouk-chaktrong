import 'main.dart';
import 'core/config/env_config.dart';
import 'firebase_options_prod.dart';

void main() async {
  final config = EnvConfig(
    environment: Environment.prod,
    appName: 'Sdach Ouk',
    apiBaseUrl: 'https://api.example.com', // Replace with your PROD API URL
    firebaseOptions: DefaultFirebaseOptions.currentPlatform,
  );

  await runner(config);
}
