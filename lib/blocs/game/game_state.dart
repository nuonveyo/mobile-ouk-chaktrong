import 'package:equatable/equatable.dart';
import '../../models/models.dart';
import '../../core/constants/game_constants.dart';

/// Game BLoC state
class GameBlocState extends Equatable {
  final GameState gameState;
  final Position? selectedPosition;
  final List<Move> validMoves;
  final bool isPaused;
  final bool drawOffered;
  final bool isLoading;
  final String? errorMessage;

  const GameBlocState({
    required this.gameState,
    this.selectedPosition,
    this.validMoves = const [],
    this.isPaused = false,
    this.drawOffered = false,
    this.isLoading = false,
    this.errorMessage,
  });

  /// Initial state
  factory GameBlocState.initial({int timeControlSeconds = 600}) {
    return GameBlocState(
      gameState: GameState.initial(timeControl: timeControlSeconds),
    );
  }

  /// Current player's turn
  PlayerColor get currentTurn => gameState.currentTurn;

  /// Check if game is over
  bool get isGameOver => gameState.isGameOver;

  /// Game result
  GameResult get result => gameState.result;

  /// Check if a position has a valid move
  bool hasValidMoveTo(Position position) {
    return validMoves.any((m) => m.to == position);
  }

  /// Get the move to a position if valid
  Move? getMoveToPosition(Position position) {
    try {
      return validMoves.firstWhere((m) => m.to == position);
    } catch (_) {
      return null;
    }
  }

  /// Copy with new values
  GameBlocState copyWith({
    GameState? gameState,
    Position? selectedPosition,
    List<Move>? validMoves,
    bool? isPaused,
    bool? drawOffered,
    bool? isLoading,
    String? errorMessage,
    bool clearSelection = false,
    bool clearError = false,
  }) {
    return GameBlocState(
      gameState: gameState ?? this.gameState,
      selectedPosition: clearSelection ? null : (selectedPosition ?? this.selectedPosition),
      validMoves: clearSelection ? const [] : (validMoves ?? this.validMoves),
      isPaused: isPaused ?? this.isPaused,
      drawOffered: drawOffered ?? this.drawOffered,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        gameState,
        selectedPosition,
        validMoves,
        isPaused,
        drawOffered,
        isLoading,
        errorMessage,
      ];
}
