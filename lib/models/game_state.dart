import 'package:equatable/equatable.dart';
import '../core/constants/game_constants.dart';
import 'board_state.dart';
import 'move.dart';

/// Represents the complete state of a chess game
class GameState extends Equatable {
  final BoardState board;
  final PlayerColor currentTurn;
  final List<Move> moveHistory;
  final GameResult result;
  final bool isCheck;
  
  // Time control (in seconds remaining)
  final int whiteTimeRemaining;
  final int goldTimeRemaining;

  const GameState({
    required this.board,
    required this.currentTurn,
    required this.moveHistory,
    required this.result,
    required this.isCheck,
    required this.whiteTimeRemaining,
    required this.goldTimeRemaining,
  });

  /// Create initial game state
  factory GameState.initial({int timeControl = GameConstants.defaultTimeControl}) {
    return GameState(
      board: BoardState.initial(),
      currentTurn: PlayerColor.white,
      moveHistory: const [],
      result: GameResult.ongoing,
      isCheck: false,
      whiteTimeRemaining: timeControl,
      goldTimeRemaining: timeControl,
    );
  }

  /// Check if the game is over
  bool get isGameOver => result != GameResult.ongoing;

  /// Get the number of moves played
  int get moveCount => moveHistory.length;

  /// Get the last move played
  Move? get lastMove => moveHistory.isEmpty ? null : moveHistory.last;

  /// Get the opponent's color
  PlayerColor get opponentTurn =>
      currentTurn == PlayerColor.white ? PlayerColor.gold : PlayerColor.white;

  /// Get formatted time string for a player
  String getTimeString(PlayerColor color) {
    final seconds = color == PlayerColor.white ? whiteTimeRemaining : goldTimeRemaining;
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// Create a copy with updated fields
  GameState copyWith({
    BoardState? board,
    PlayerColor? currentTurn,
    List<Move>? moveHistory,
    GameResult? result,
    bool? isCheck,
    int? whiteTimeRemaining,
    int? goldTimeRemaining,
  }) {
    return GameState(
      board: board ?? this.board,
      currentTurn: currentTurn ?? this.currentTurn,
      moveHistory: moveHistory ?? this.moveHistory,
      result: result ?? this.result,
      isCheck: isCheck ?? this.isCheck,
      whiteTimeRemaining: whiteTimeRemaining ?? this.whiteTimeRemaining,
      goldTimeRemaining: goldTimeRemaining ?? this.goldTimeRemaining,
    );
  }

  @override
  List<Object?> get props => [
        board,
        currentTurn,
        moveHistory,
        result,
        isCheck,
        whiteTimeRemaining,
        goldTimeRemaining,
      ];
}
