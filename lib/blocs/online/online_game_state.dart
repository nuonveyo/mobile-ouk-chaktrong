import 'package:equatable/equatable.dart';
import '../../models/models.dart';

/// State for online game BLoC
class OnlineGameBlocState extends Equatable {
  final List<OnlineGameRoom> availableRooms;
  final OnlineGameRoom? currentRoom;
  final String? playerId;
  final bool isHost;
  final bool isLoading;
  final String? errorMessage;
  final int points;

  const OnlineGameBlocState({
    this.availableRooms = const [],
    this.currentRoom,
    this.playerId,
    this.isHost = false,
    this.isLoading = false,
    this.errorMessage,
    this.points = 0,
  });

  /// Initial state
  factory OnlineGameBlocState.initial() {
    return const OnlineGameBlocState();
  }

  /// Check if currently in a room
  bool get isInRoom => currentRoom != null;

  /// Check if game has started
  bool get isGameStarted => currentRoom?.isPlaying == true;

  /// Check if waiting for opponent
  bool get isWaitingForOpponent =>
      currentRoom != null && currentRoom!.isWaiting && isHost;

  /// Get player color (host = white, guest = gold)
  String get playerColor => isHost ? 'white' : 'gold';

  /// Check if it's this player's turn
  bool get isMyTurn {
    if (currentRoom?.gameData == null) return false;
    return currentRoom!.gameData!.currentTurn == playerColor;
  }

  OnlineGameBlocState copyWith({
    List<OnlineGameRoom>? availableRooms,
    OnlineGameRoom? currentRoom,
    String? playerId,
    bool? isHost,
    bool? isLoading,
    String? errorMessage,
    bool clearRoom = false,
    bool clearError = false,
    int? points,
  }) {
    return OnlineGameBlocState(
      availableRooms: availableRooms ?? this.availableRooms,
      currentRoom: clearRoom ? null : (currentRoom ?? this.currentRoom),
      playerId: playerId ?? this.playerId,
      isHost: isHost ?? this.isHost,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      points: points ?? this.points,
    );
  }

  @override
  List<Object?> get props => [
    availableRooms,
    currentRoom,
    playerId,
    isHost,
    isLoading,
    errorMessage,
    points,
  ];
}
