import 'package:flutter/material.dart';
import '../repositories/online_game_repository.dart';
import '../repositories/auth_repository.dart';

/// Service to manage room lifecycle when app is terminated
/// Cleans up pending rooms when the app is killed
class RoomLifecycleService with WidgetsBindingObserver {
  static final RoomLifecycleService _instance = RoomLifecycleService._internal();
  factory RoomLifecycleService() => _instance;
  RoomLifecycleService._internal();

  final OnlineGameRepository _gameRepository = OnlineGameRepository();
  final AuthRepository _authRepository = AuthRepository();
  
  String? _currentPendingRoomId;
  bool _initialized = false;

  /// Initialize the service and start listening to app lifecycle
  void init() {
    if (_initialized) return;
    WidgetsBinding.instance.addObserver(this);
    _initialized = true;
  }

  /// Dispose the service
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _initialized = false;
  }

  /// Set the current pending room ID (call when creating a room)
  void setCurrentPendingRoom(String? roomId) {
    _currentPendingRoomId = roomId;
  }

  /// Get the current pending room ID
  String? get currentPendingRoomId => _currentPendingRoomId;

  /// Check if user has a pending room and restore it
  Future<void> checkAndRestorePendingRoom() async {
    final userId = _authRepository.userId;
    if (userId == null) return;

    final pendingRoom = await _gameRepository.getUserPendingRoom(userId);
    if (pendingRoom != null) {
      _currentPendingRoomId = pendingRoom.id;
    }
  }

  /// Cancel the current pending room (call when user explicitly cancels)
  Future<void> cancelCurrentRoom() async {
    if (_currentPendingRoomId != null) {
      await _gameRepository.cancelRoom(_currentPendingRoomId!);
      _currentPendingRoomId = null;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Note: On app termination, we cannot reliably run async cleanup code
    // The room will be cleaned up via:
    // 1. Firestore TTL (expiresAt field) - automatic 24h cleanup
    // 2. User reopening the app and checking for stale rooms
    // 3. Guest receiving cancelled notification when room expires
    
    if (state == AppLifecycleState.detached) {
      // App is being terminated - attempt cleanup
      // Note: This may not complete if app is forcefully killed
      _attemptCleanup();
    }
  }

  void _attemptCleanup() {
    // Fire and forget - we can't await in detached state
    if (_currentPendingRoomId != null) {
      _gameRepository.cancelRoom(_currentPendingRoomId!);
      _currentPendingRoomId = null;
    }
  }
}

/// Global instance for easy access
final roomLifecycleService = RoomLifecycleService();
