import 'package:equatable/equatable.dart';
import '../core/constants/game_constants.dart';
import 'position.dart';

/// Represents a chess piece
class Piece extends Equatable {
  final PieceType type;
  final PlayerColor color;

  const Piece({
    required this.type,
    required this.color,
  });

  /// Get the Khmer name of this piece
  String get khmerName {
    switch (type) {
      case PieceType.king:
        return 'ស្ដេច';
      case PieceType.maiden:
        return 'នាង';
      case PieceType.elephant:
        return 'គោល';
      case PieceType.horse:
        return 'សេះ';
      case PieceType.boat:
        return 'ទូក';
      case PieceType.fish:
        return 'ត្រី';
    }
  }

  /// Get the English name of this piece
  String get englishName {
    switch (type) {
      case PieceType.king:
        return 'King';
      case PieceType.maiden:
        return 'Maiden';
      case PieceType.elephant:
        return 'Elephant';
      case PieceType.horse:
        return 'Horse';
      case PieceType.boat:
        return 'Boat';
      case PieceType.fish:
        return 'Fish';
    }
  }

  /// Get the symbol for this piece (for display/debugging)
  String get symbol {
    const symbols = {
      PieceType.king: 'K',
      PieceType.maiden: 'M',
      PieceType.elephant: 'E',
      PieceType.horse: 'H',
      PieceType.boat: 'B',
      PieceType.fish: 'F',
    };
    final s = symbols[type]!;
    return color == PlayerColor.white ? s : s.toLowerCase();
  }

  /// Get the relative value of this piece (for AI evaluation)
  int get value {
    switch (type) {
      case PieceType.king:
        return 10000; // King is invaluable
      case PieceType.boat:
        return 500;
      case PieceType.maiden:
        return 300;
      case PieceType.elephant:
        return 300;
      case PieceType.horse:
        return 300;
      case PieceType.fish:
        return 100;
    }
  }

  /// Check if this piece can move to a target position based on its movement rules
  /// This does NOT check for blocking pieces or check situations
  bool canMovePattern(Position from, Position to) {
    final rowDiff = to.row - from.row;
    final colDiff = to.col - from.col;
    final absRowDiff = rowDiff.abs();
    final absColDiff = colDiff.abs();

    switch (type) {
      case PieceType.king:
        // Moves 1 square in any direction
        return absRowDiff <= 1 && absColDiff <= 1 && (absRowDiff > 0 || absColDiff > 0);

      case PieceType.maiden:
        // Moves 1 square diagonally only
        return absRowDiff == 1 && absColDiff == 1;

      case PieceType.elephant:
        // Moves 1 square diagonally only (same as maiden in Khmer chess)
        return absRowDiff == 1 && absColDiff == 1;

      case PieceType.horse:
        // L-shape: 2 squares in one direction, 1 square perpendicular
        return (absRowDiff == 2 && absColDiff == 1) || 
               (absRowDiff == 1 && absColDiff == 2);

      case PieceType.boat:
        // Moves any distance horizontally or vertically
        return (absRowDiff == 0 && absColDiff > 0) || 
               (absRowDiff > 0 && absColDiff == 0);

      case PieceType.fish:
        // Moves 1 forward only, captures diagonally
        final direction = color == PlayerColor.white ? 1 : -1;
        // Forward move (1 square only, no 2-square first move)
        if (colDiff == 0 && rowDiff == direction) {
          return true;
        }
        // Diagonal capture (handled separately with capture check)
        if (absColDiff == 1 && rowDiff == direction) {
          return true;
        }
        return false;
    }
  }

  /// Check if this piece type requires a clear path (no pieces in between)
  bool get requiresClearPath {
    switch (type) {
      case PieceType.boat:
        return true;
      case PieceType.king:
      case PieceType.maiden:
      case PieceType.elephant:
      case PieceType.horse:
      case PieceType.fish:
        return false;
    }
  }

  /// Create a copy with different type (for promotion)
  Piece copyWith({PieceType? type}) {
    return Piece(
      type: type ?? this.type,
      color: color,
    );
  }

  @override
  List<Object?> get props => [type, color];

  @override
  String toString() => '${color.name} ${type.name}';
}
