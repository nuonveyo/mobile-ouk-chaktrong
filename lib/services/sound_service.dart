import 'package:flame_audio/flame_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing game sounds
class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  bool _soundEnabled = true;
  bool _initialized = false;

  bool get soundEnabled => _soundEnabled;

  /// Initialize sound service
  Future<void> init() async {
    if (_initialized) return;
    
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool('soundEnabled') ?? true;
    _initialized = true;

    // Preload sounds for better performance
    if (_soundEnabled) {
      await _preloadSounds();
    }
  }

  Future<void> _preloadSounds() async {
    try {
      // These would be actual audio files in assets/audio/
      // For now, we'll use placeholder logic
      await FlameAudio.audioCache.loadAll([
        'move.mp3',
        'capture.mp3',
        'check.mp3',
        'game_over.mp3',
        'button.mp3',
      ]);
    } catch (e) {
      // Sounds may not exist yet - that's okay
    }
  }

  /// Enable or disable sounds
  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('soundEnabled', enabled);
  }

  /// Play move sound
  void playMove() {
    if (!_soundEnabled) return;
    _playSound('move.mp3');
  }

  /// Play capture sound
  void playCapture() {
    if (!_soundEnabled) return;
    _playSound('capture.mp3');
  }

  /// Play check sound
  void playCheck() {
    if (!_soundEnabled) return;
    _playSound('check.mp3');
  }

  /// Play game over sound
  void playGameOver() {
    if (!_soundEnabled) return;
    _playSound('game_over.mp3');
  }

  /// Play button click sound
  void playButton() {
    if (!_soundEnabled) return;
    _playSound('button.mp3');
  }

  void _playSound(String fileName) {
    try {
      FlameAudio.play(fileName);
    } catch (e) {
      // Sound file may not exist - silently ignore
    }
  }

  /// Dispose resources
  void dispose() {
    FlameAudio.audioCache.clearAll();
  }
}
