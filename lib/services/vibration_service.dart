import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

/// Service for managing haptic feedback/vibration
class VibrationService {
  static final VibrationService _instance = VibrationService._internal();
  factory VibrationService() => _instance;
  VibrationService._internal();

  bool _vibrationEnabled = true;
  bool _initialized = false;
  bool _hasVibrator = false;

  bool get vibrationEnabled => _vibrationEnabled;

  /// Initialize vibration service
  Future<void> init() async {
    if (_initialized) return;
    
    final prefs = await SharedPreferences.getInstance();
    _vibrationEnabled = prefs.getBool('vibrationEnabled') ?? true;
    
    // Check if device has vibrator
    _hasVibrator = await Vibration.hasVibrator() ?? false;
    _initialized = true;
  }

  /// Enable or disable vibration
  Future<void> setVibrationEnabled(bool enabled) async {
    _vibrationEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibrationEnabled', enabled);
  }

  /// Light vibration for piece movement
  void vibrateMove() {
    if (!_canVibrate) return;
    Vibration.vibrate(duration: 30);
  }

  /// Medium vibration for capturing a piece
  void vibrateCapture() {
    if (!_canVibrate) return;
    Vibration.vibrate(duration: 50);
  }

  /// Strong vibration for check
  void vibrateCheck() {
    if (!_canVibrate) return;
    Vibration.vibrate(duration: 100, amplitude: 200);
  }

  /// Double vibration for checkmate/game over
  void vibrateGameOver() {
    if (!_canVibrate) return;
    Vibration.vibrate(pattern: [0, 100, 100, 100], intensities: [0, 200, 0, 200]);
  }

  /// Light tap for button press
  void vibrateButton() {
    if (!_canVibrate) return;
    Vibration.vibrate(duration: 20);
  }

  /// Warning vibration for low time
  void vibrateWarning() {
    if (!_canVibrate) return;
    Vibration.vibrate(duration: 200, amplitude: 150);
  }

  bool get _canVibrate => _vibrationEnabled && _hasVibrator;
}
