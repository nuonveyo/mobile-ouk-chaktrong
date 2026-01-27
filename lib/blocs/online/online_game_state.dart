import 'package:equatable/equatable.dart';
import '../../models/models.dart';

/// State for online game BLoC
class OnlineGameBlocState extends Equatable {
  final List<OnlineGameRoom> availableRooms;
  final List<OnlineGameRoom> activeGames;  // Games in progress (for spectating)
  final OnlineGameRoom? currentRoom;
  final String? playerId;
  final bool isHost;
  final bool isSpectating;  // True if spectating a game
  final bool isLoading;
  final String? errorMessage;
  final int points;

  const OnlineGameBlocState({
    this.availableRooms = const [],
    this.activeGames = const [],
    this.currentRoom,
    this.playerId,
    this.isHost = false,
    this.isSpectating = false,
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

  /// Check if waiting for opponent (host created room, waiting for join requests)
  bool get isWaitingForOpponent =>
      currentRoom != null && currentRoom!.isWaiting && isHost;

  /// Check if waiting for host approval (guest requested join)
  bool get isWaitingForJoinApproval =>
      currentRoom != null && currentRoom!.isPendingJoin && !isHost;

  /// Check if there's a pending join request (host needs to respond)
  bool get hasPendingJoinRequest =>
      currentRoom != null && currentRoom!.isPendingJoin && isHost;

  /// Get player color (host = white, guest = gold)
  String get playerColor => isHost ? 'white' : 'gold';

  /// Check if it's this player's turn
  bool get isMyTurn {
    if (currentRoom?.gameData == null) return false;
    return currentRoom!.gameData!.currentTurn == playerColor;
  }

  OnlineGameBlocState copyWith({
    List<OnlineGameRoom>? availableRooms,
    List<OnlineGameRoom>? activeGames,
    OnlineGameRoom? currentRoom,
    String? playerId,
    bool? isHost,
    bool? isSpectating,
    bool? isLoading,
    String? errorMessage,
    bool clearRoom = false,
    bool clearError = false,
    int? points,
  }) {
    return OnlineGameBlocState(
      availableRooms: availableRooms ?? this.availableRooms,
      activeGames: activeGames ?? this.activeGames,
      currentRoom: clearRoom ? null : (currentRoom ?? this.currentRoom),
      playerId: playerId ?? this.playerId,
      isHost: isHost ?? this.isHost,
      isSpectating: clearRoom ? false : (isSpectating ?? this.isSpectating),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      points: points ?? this.points,
    );
  }

  @override
  List<Object?> get props => [
    availableRooms,
    activeGames,
    currentRoom,
    playerId,
    isHost,
    isSpectating,
    isLoading,
    errorMessage,
    points,
  ];
}
