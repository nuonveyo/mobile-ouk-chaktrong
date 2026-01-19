import 'package:equatable/equatable.dart';

/// Represents a position on the chess board
/// Uses 0-indexed coordinates where (0,0) is the bottom-left (a1 in chess notation)
class Position extends Equatable {
  final int row;
  final int col;

  const Position(this.row, this.col);

  /// Create position from chess notation (e.g., "e4")
  factory Position.fromNotation(String notation) {
    assert(notation.length == 2);
    final col = notation.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final row = int.parse(notation[1]) - 1;
    return Position(row, col);
  }

  /// Check if position is within the board bounds
  bool get isValid => row >= 0 && row < 8 && col >= 0 && col < 8;

  /// Convert to chess notation (e.g., "e4")
  String get notation {
    final colChar = String.fromCharCode('a'.codeUnitAt(0) + col);
    return '$colChar${row + 1}';
  }

  /// Get position offset by delta row and column
  Position offset(int deltaRow, int deltaCol) {
    return Position(row + deltaRow, col + deltaCol);
  }

  /// Get all positions between this and target (exclusive)
  /// Returns empty list if not on same row, column, or diagonal
  List<Position> positionsBetween(Position target) {
    final positions = <Position>[];
    
    final rowDiff = target.row - row;
    final colDiff = target.col - col;
    
    // Check if positions are on same line
    if (rowDiff != 0 && colDiff != 0 && rowDiff.abs() != colDiff.abs()) {
      return positions;
    }
    
    final rowStep = rowDiff == 0 ? 0 : (rowDiff > 0 ? 1 : -1);
    final colStep = colDiff == 0 ? 0 : (colDiff > 0 ? 1 : -1);
    
    var currentRow = row + rowStep;
    var currentCol = col + colStep;
    
    while (currentRow != target.row || currentCol != target.col) {
      positions.add(Position(currentRow, currentCol));
      currentRow += rowStep;
      currentCol += colStep;
    }
    
    return positions;
  }

  @override
  List<Object?> get props => [row, col];

  @override
  String toString() => notation;
}
