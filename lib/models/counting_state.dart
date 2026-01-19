import 'package:equatable/equatable.dart';
import '../core/constants/game_constants.dart';

/// Type of counting rule in effect
enum CountingType { 
  none,
  boardHonor,  // ≤3 pieces, limit 64
  pieceHonor,  // No pawns + lone king, variable limit
}

/// State of counting rules during endgame
class CountingState extends Equatable {
  final CountingType type;
  final int currentCount;
  final int limit;
  final PlayerColor? escapingPlayer;
  final bool isActive;

  const CountingState({
    this.type = CountingType.none,
    this.currentCount = 0,
    this.limit = 0,
    this.escapingPlayer,
    this.isActive = false,
  });

  /// Initial state (no counting)
  const CountingState.none() : this();

  /// Start board's honor counting
  factory CountingState.startBoardHonor(PlayerColor escapingPlayer) {
    return CountingState(
      type: CountingType.boardHonor,
      currentCount: 1,
      limit: 64,
      escapingPlayer: escapingPlayer,
      isActive: true,
    );
  }

  /// Start piece's honor counting
  factory CountingState.startPieceHonor({
    required PlayerColor escapingPlayer,
    required int startCount,
    required int limit,
  }) {
    return CountingState(
      type: CountingType.pieceHonor,
      currentCount: startCount,
      limit: limit,
      escapingPlayer: escapingPlayer,
      isActive: true,
    );
  }

  /// Increment the count
  CountingState increment() {
    if (!isActive) return this;
    return CountingState(
      type: type,
      currentCount: currentCount + 1,
      limit: limit,
      escapingPlayer: escapingPlayer,
      isActive: true,
    );
  }

  /// Stop counting (can restart later from 1)
  CountingState stop() {
    return const CountingState.none();
  }

  /// Check if count has reached limit
  bool get hasReachedLimit => isActive && currentCount >= limit;

  /// Get remaining moves until draw
  int get movesRemaining => isActive ? limit - currentCount : 0;

  @override
  List<Object?> get props => [type, currentCount, limit, escapingPlayer, isActive];
}
