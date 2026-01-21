import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

/// Service for managing haptic feedback/vibration with granular controls
class VibrationService {
  static final VibrationService _instance = VibrationService._internal();
  factory VibrationService() => _instance;
  VibrationService._internal();

  // Global toggle
  bool _vibrationEnabled = true;
  
  // Individual toggles (all enabled by default)
  bool _vibrateMoveEnabled = true;
  bool _vibrateCaptureEnabled = true;
  bool _vibrateCheckEnabled = true;
  
  bool _initialized = false;
  bool _hasVibrator = false;

  // Getters
  bool get vibrationEnabled => _vibrationEnabled;
  bool get vibrateMoveEnabled => _vibrateMoveEnabled;
  bool get vibrateCaptureEnabled => _vibrateCaptureEnabled;
  bool get vibrateCheckEnabled => _vibrateCheckEnabled;

  /// Initialize vibration service
  Future<void> init() async {
    if (_initialized) return;
    
    final prefs = await SharedPreferences.getInstance();
    _vibrationEnabled = prefs.getBool('vibrationEnabled') ?? true;
    _vibrateMoveEnabled = prefs.getBool('vibrateMoveEnabled') ?? true;
    _vibrateCaptureEnabled = prefs.getBool('vibrateCaptureEnabled') ?? true;
    _vibrateCheckEnabled = prefs.getBool('vibrateCheckEnabled') ?? true;
    
    // Check if device has vibrator
    _hasVibrator = await Vibration.hasVibrator() ?? false;
    _initialized = true;
  }

  /// Enable or disable global vibration
  Future<void> setVibrationEnabled(bool enabled) async {
    _vibrationEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibrationEnabled', enabled);
  }

  /// Enable or disable move vibration
  Future<void> setVibrateMoveEnabled(bool enabled) async {
    _vibrateMoveEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibrateMoveEnabled', enabled);
  }

  /// Enable or disable capture vibration
  Future<void> setVibrateCaptureEnabled(bool enabled) async {
    _vibrateCaptureEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibrateCaptureEnabled', enabled);
  }

  /// Enable or disable check/checkmate vibration
  Future<void> setVibrateCheckEnabled(bool enabled) async {
    _vibrateCheckEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibrateCheckEnabled', enabled);
  }

  /// Light vibration for piece movement
  void vibrateMove() {
    if (!_canVibrate || !_vibrateMoveEnabled) return;
    Vibration.vibrate(duration: 30);
  }

  /// Medium vibration for capturing a piece
  void vibrateCapture() {
    if (!_canVibrate || !_vibrateCaptureEnabled) return;
    Vibration.vibrate(duration: 50);
  }

  /// Strong vibration for check
  void vibrateCheck() {
    if (!_canVibrate || !_vibrateCheckEnabled) return;
    Vibration.vibrate(duration: 100, amplitude: 200);
  }

  /// Double vibration for checkmate/game over
  void vibrateGameOver() {
    if (!_canVibrate || !_vibrateCheckEnabled) return;
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
