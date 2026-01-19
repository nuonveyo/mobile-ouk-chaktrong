import 'package:equatable/equatable.dart';
import '../core/constants/game_constants.dart';
import 'position.dart';
import 'piece.dart';
import 'move.dart';

/// Represents the complete state of the chess board
class BoardState extends Equatable {
  /// 8x8 grid of pieces (null for empty squares)
  /// Index [row][col] where row 0 is white's home rank
  final List<List<Piece?>> _squares;

  BoardState._(this._squares);

  /// Create initial board setup for Khmer Chess
  factory BoardState.initial() {
    final squares = List.generate(8, (_) => List<Piece?>.filled(8, null));

    // White pieces (bottom, rows 0-1)
    _setupRank(squares, 0, PlayerColor.white);
    _setupFishRank(squares, 1, PlayerColor.white);

    // Gold pieces (top, rows 6-7)
    _setupFishRank(squares, 6, PlayerColor.gold);
    _setupRank(squares, 7, PlayerColor.gold);

    return BoardState._(squares);
  }

  /// Create empty board
  factory BoardState.empty() {
    return BoardState._(
      List.generate(8, (_) => List<Piece?>.filled(8, null)),
    );
  }

  /// Setup main rank pieces
  static void _setupRank(List<List<Piece?>> squares, int row, PlayerColor color) {
    // Boat (Rook) at corners
    squares[row][0] = Piece(type: PieceType.boat, color: color);
    squares[row][7] = Piece(type: PieceType.boat, color: color);
    
    // Horse (Knight) next to boats
    squares[row][1] = Piece(type: PieceType.horse, color: color);
    squares[row][6] = Piece(type: PieceType.horse, color: color);
    
    // Elephant next to horses
    squares[row][2] = Piece(type: PieceType.elephant, color: color);
    squares[row][5] = Piece(type: PieceType.elephant, color: color);
    
    // Maiden and King in center
    // In Khmer chess, King is on e-file for both sides
    if (color == PlayerColor.white) {
      squares[row][3] = Piece(type: PieceType.maiden, color: color);
      squares[row][4] = Piece(type: PieceType.king, color: color);
    } else {
      squares[row][3] = Piece(type: PieceType.maiden, color: color);
      squares[row][4] = Piece(type: PieceType.king, color: color);
    }
  }

  /// Setup fish (pawn) rank
  static void _setupFishRank(List<List<Piece?>> squares, int row, PlayerColor color) {
    for (var col = 0; col < 8; col++) {
      squares[row][col] = Piece(type: PieceType.fish, color: color);
    }
  }

  /// Get piece at position
  Piece? getPiece(Position pos) {
    if (!pos.isValid) return null;
    return _squares[pos.row][pos.col];
  }

  /// Get piece at row and column
  Piece? getPieceAt(int row, int col) {
    if (row < 0 || row >= 8 || col < 0 || col >= 8) return null;
    return _squares[row][col];
  }

  /// Check if a position is empty
  bool isEmpty(Position pos) => getPiece(pos) == null;

  /// Check if a position has an enemy piece
  bool hasEnemy(Position pos, PlayerColor friendlyColor) {
    final piece = getPiece(pos);
    return piece != null && piece.color != friendlyColor;
  }

  /// Check if a position has a friendly piece
  bool hasFriendly(Position pos, PlayerColor friendlyColor) {
    final piece = getPiece(pos);
    return piece != null && piece.color == friendlyColor;
  }

  /// Check if a path is clear (no pieces in between)
  bool isPathClear(Position from, Position to) {
    for (final pos in from.positionsBetween(to)) {
      if (!isEmpty(pos)) return false;
    }
    return true;
  }

  /// Find the king's position for a given color
  Position? findKing(PlayerColor color) {
    for (var row = 0; row < 8; row++) {
      for (var col = 0; col < 8; col++) {
        final piece = _squares[row][col];
        if (piece != null && piece.type == PieceType.king && piece.color == color) {
          return Position(row, col);
        }
      }
    }
    return null;
  }

  /// Get all pieces of a given color with their positions
  List<(Position, Piece)> getPieces(PlayerColor color) {
    final pieces = <(Position, Piece)>[];
    for (var row = 0; row < 8; row++) {
      for (var col = 0; col < 8; col++) {
        final piece = _squares[row][col];
        if (piece != null && piece.color == color) {
          pieces.add((Position(row, col), piece));
        }
      }
    }
    return pieces;
  }

  /// Apply a move and return the new board state
  BoardState applyMove(Move move) {
    final newSquares = _squares.map((row) => row.toList()).toList();
    
    // Remove piece from origin
    newSquares[move.from.row][move.from.col] = null;
    
    // Place piece at destination (handle promotion)
    if (move.isPromotion && move.promotedTo != null) {
      newSquares[move.to.row][move.to.col] = move.promotedTo;
    } else {
      newSquares[move.to.row][move.to.col] = move.piece;
    }
    
    return BoardState._(newSquares);
  }

  /// Create a copy of the board with a piece placed at a position
  BoardState setPiece(Position pos, Piece? piece) {
    final newSquares = _squares.map((row) => row.toList()).toList();
    newSquares[pos.row][pos.col] = piece;
    return BoardState._(newSquares);
  }

  @override
  List<Object?> get props => [_squares];

  /// Debug print the board
  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('  a b c d e f g h');
    for (var row = 7; row >= 0; row--) {
      buffer.write('${row + 1} ');
      for (var col = 0; col < 8; col++) {
        final piece = _squares[row][col];
        buffer.write(piece?.symbol ?? '.');
        buffer.write(' ');
      }
      buffer.writeln('${row + 1}');
    }
    buffer.writeln('  a b c d e f g h');
    return buffer.toString();
  }
}
