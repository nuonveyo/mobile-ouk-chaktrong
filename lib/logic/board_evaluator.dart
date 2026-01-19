import '../models/models.dart';
import '../core/constants/game_constants.dart';

/// Evaluates board positions for the AI
class BoardEvaluator {
  const BoardEvaluator();

  /// Piece-square tables for positional evaluation
  /// Higher values = better positions for that piece
  
  // King should stay protected (center is dangerous)
  static const List<List<int>> _kingTable = [
    [ 20,  30,  10,   0,   0,  10,  30,  20],
    [ 20,  20,   0,   0,   0,   0,  20,  20],
    [-10, -20, -20, -20, -20, -20, -20, -10],
    [-20, -30, -30, -40, -40, -30, -30, -20],
    [-30, -40, -40, -50, -50, -40, -40, -30],
    [-30, -40, -40, -50, -50, -40, -40, -30],
    [-30, -40, -40, -50, -50, -40, -40, -30],
    [-30, -40, -40, -50, -50, -40, -40, -30],
  ];

  // Maiden (weak queen) - control center diagonals
  static const List<List<int>> _maidenTable = [
    [-20, -10, -10,  -5,  -5, -10, -10, -20],
    [-10,   0,   5,   0,   0,   0,   0, -10],
    [-10,   5,   5,   5,   5,   5,   0, -10],
    [  0,   0,   5,   5,   5,   5,   0,  -5],
    [ -5,   0,   5,   5,   5,   5,   0,  -5],
    [-10,   0,   5,   5,   5,   5,   0, -10],
    [-10,   0,   0,   0,   0,   0,   0, -10],
    [-20, -10, -10,  -5,  -5, -10, -10, -20],
  ];

  // Elephant (diagonal mover) - similar to maiden
  static const List<List<int>> _elephantTable = [
    [-20, -10, -10, -10, -10, -10, -10, -20],
    [-10,   5,   0,   0,   0,   0,   5, -10],
    [-10,  10,  10,  10,  10,  10,  10, -10],
    [-10,   0,  10,  10,  10,  10,   0, -10],
    [-10,   5,   5,  10,  10,   5,   5, -10],
    [-10,   0,   5,  10,  10,   5,   0, -10],
    [-10,   0,   0,   0,   0,   0,   0, -10],
    [-20, -10, -10, -10, -10, -10, -10, -20],
  ];

  // Horse (knight) - control center
  static const List<List<int>> _horseTable = [
    [-50, -40, -30, -30, -30, -30, -40, -50],
    [-40, -20,   0,   5,   5,   0, -20, -40],
    [-30,   5,  10,  15,  15,  10,   5, -30],
    [-30,   0,  15,  20,  20,  15,   0, -30],
    [-30,   5,  15,  20,  20,  15,   5, -30],
    [-30,   0,  10,  15,  15,  10,   0, -30],
    [-40, -20,   0,   0,   0,   0, -20, -40],
    [-50, -40, -30, -30, -30, -30, -40, -50],
  ];

  // Boat (rook) - control open files, 7th rank
  static const List<List<int>> _boatTable = [
    [  0,   0,   0,   5,   5,   0,   0,   0],
    [ -5,   0,   0,   0,   0,   0,   0,  -5],
    [ -5,   0,   0,   0,   0,   0,   0,  -5],
    [ -5,   0,   0,   0,   0,   0,   0,  -5],
    [ -5,   0,   0,   0,   0,   0,   0,  -5],
    [ -5,   0,   0,   0,   0,   0,   0,  -5],
    [  5,  10,  10,  10,  10,  10,  10,   5],
    [  0,   0,   0,   0,   0,   0,   0,   0],
  ];

  // Fish (pawn) - advance towards promotion
  static const List<List<int>> _fishTable = [
    [  0,   0,   0,   0,   0,   0,   0,   0],
    [ 50,  50,  50,  50,  50,  50,  50,  50],
    [ 10,  10,  20,  30,  30,  20,  10,  10],
    [  5,   5,  10,  25,  25,  10,   5,   5],
    [  0,   0,   0,  20,  20,   0,   0,   0],
    [  5,  -5, -10,   0,   0, -10,  -5,   5],
    [  5,  10,  10, -20, -20,  10,  10,   5],
    [  0,   0,   0,   0,   0,   0,   0,   0],
  ];

  /// Evaluate the board position
  /// Positive score = good for white, negative = good for gold
  int evaluate(BoardState board) {
    int score = 0;

    // Material and positional evaluation
    for (var row = 0; row < 8; row++) {
      for (var col = 0; col < 8; col++) {
        final piece = board.getPieceAt(row, col);
        if (piece == null) continue;

        int pieceValue = _evaluatePiece(piece, row, col);
        
        if (piece.color == PlayerColor.white) {
          score += pieceValue;
        } else {
          score -= pieceValue;
        }
      }
    }

    return score;
  }

  /// Evaluate a single piece (material + position)
  int _evaluatePiece(Piece piece, int row, int col) {
    int materialValue = piece.value;
    int positionalValue = _getPositionalValue(piece, row, col);
    return materialValue + positionalValue;
  }

  /// Get positional bonus for a piece
  int _getPositionalValue(Piece piece, int row, int col) {
    // Flip table for gold pieces (they play from opposite side)
    final tableRow = piece.color == PlayerColor.white ? row : 7 - row;

    switch (piece.type) {
      case PieceType.king:
        return _kingTable[tableRow][col];
      case PieceType.maiden:
        return _maidenTable[tableRow][col];
      case PieceType.elephant:
        return _elephantTable[tableRow][col];
      case PieceType.horse:
        return _horseTable[tableRow][col];
      case PieceType.boat:
        return _boatTable[tableRow][col];
      case PieceType.fish:
        return _fishTable[tableRow][col];
    }
  }

  /// Evaluate mobility (number of legal moves)
  int evaluateMobility(BoardState board, PlayerColor color, int moveCount) {
    // Each legal move is worth a small amount
    return moveCount * 5;
  }

  /// Check if position seems equal (for draw detection)
  bool isLikelyDraw(BoardState board) {
    final whitePieces = board.getPieces(PlayerColor.white);
    final goldPieces = board.getPieces(PlayerColor.gold);

    // King vs King
    if (whitePieces.length == 1 && goldPieces.length == 1) {
      return true;
    }

    // King + minor piece vs King
    if ((whitePieces.length <= 2 && goldPieces.length == 1) ||
        (whitePieces.length == 1 && goldPieces.length <= 2)) {
      final pieces = whitePieces.length > goldPieces.length ? whitePieces : goldPieces;
      if (pieces.length == 2) {
        final nonKing = pieces.where((p) => p.$2.type != PieceType.king).first.$2;
        if (nonKing.type == PieceType.elephant || 
            nonKing.type == PieceType.maiden ||
            nonKing.type == PieceType.horse) {
          return true;
        }
      }
    }

    return false;
  }
}
