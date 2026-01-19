import '../core/constants/game_constants.dart';
import '../models/models.dart';

/// Generates valid moves for chess pieces
class MoveGenerator {
  const MoveGenerator();

  /// Get all valid moves for a piece at a given position
  /// Use gameState version when special moves need to be considered
  List<Move> getValidMoves(BoardState board, Position from, {bool checkLegal = true}) {
    return getValidMovesWithState(board, from, null, checkLegal: checkLegal);
  }

  /// Get all valid moves considering special opening moves
  List<Move> getValidMovesWithState(BoardState board, Position from, GameState? gameState, {bool checkLegal = true}) {
    final piece = board.getPiece(from);
    if (piece == null) return [];

    final moves = <Move>[];

    switch (piece.type) {
      case PieceType.king:
        moves.addAll(_getKingMoves(board, from, piece, gameState));
      case PieceType.maiden:
        moves.addAll(_getMaidenMoves(board, from, piece, gameState));
      case PieceType.elephant:
        moves.addAll(_getElephantMoves(board, from, piece));
      case PieceType.horse:
        moves.addAll(_getHorseMoves(board, from, piece));
      case PieceType.boat:
        moves.addAll(_getBoatMoves(board, from, piece));
      case PieceType.fish:
        moves.addAll(_getFishMoves(board, from, piece));
    }

    // Filter out moves that would leave king in check
    if (checkLegal) {
      return moves.where((move) => !_wouldBeInCheck(board, move, piece.color)).toList();
    }

    return moves;
  }

  /// Get all valid moves for a player
  List<Move> getAllValidMoves(BoardState board, PlayerColor color) {
    final moves = <Move>[];
    for (final (pos, _) in board.getPieces(color)) {
      moves.addAll(getValidMoves(board, pos));
    }
    return moves;
  }

  /// Get all valid moves for a player with special moves
  List<Move> getAllValidMovesWithState(BoardState board, PlayerColor color, GameState gameState) {
    final moves = <Move>[];
    for (final (pos, _) in board.getPieces(color)) {
      moves.addAll(getValidMovesWithState(board, pos, gameState));
    }
    return moves;
  }

  /// King moves - 1 square in any direction + special knight jump on first move
  List<Move> _getKingMoves(BoardState board, Position from, Piece piece, GameState? gameState) {
    final moves = <Move>[];
    
    // Normal moves: 1 square in any direction
    final offsets = [
      (-1, -1), (-1, 0), (-1, 1),
      (0, -1),          (0, 1),
      (1, -1),  (1, 0),  (1, 1),
    ];

    for (final (dr, dc) in offsets) {
      final to = from.offset(dr, dc);
      if (_canMoveTo(board, to, piece.color)) {
        moves.add(_createMove(board, from, to, piece));
      }
    }

    // Special move: Knight jump to 2nd row on first move
    // Cannot capture, cannot be in check, and special ability not lost
    if (gameState != null && gameState.canKingUseSpecial(piece.color)) {
      // Check not in check
      if (!isInCheck(board, piece.color)) {
        // Target row is 1 for white (from row 0), 6 for gold (from row 7)
        final targetRow = piece.color == PlayerColor.white ? 1 : 6;
        
        // Knight jump offsets from king's starting position
        final knightOffsets = [
          (-2, -1), (-2, 1), (-1, -2), (-1, 2),
          (1, -2), (1, 2), (2, -1), (2, 1),
        ];
        
        for (final (dr, dc) in knightOffsets) {
          final to = from.offset(dr, dc);
          // Must be valid, on target row, and empty (no capture)
          if (to.isValid && to.row == targetRow && board.isEmpty(to)) {
            moves.add(_createMove(board, from, to, piece, isSpecialMove: true));
          }
        }
      }
    }

    return moves;
  }

  /// Maiden moves - 4 diagonal only + special 2 forward on first move
  List<Move> _getMaidenMoves(BoardState board, Position from, Piece piece, GameState? gameState) {
    final moves = <Move>[];
    
    // Normal moves: 4 diagonal
    final diagonalOffsets = [(-1, -1), (-1, 1), (1, -1), (1, 1)];
    for (final (dr, dc) in diagonalOffsets) {
      final to = from.offset(dr, dc);
      if (_canMoveTo(board, to, piece.color)) {
        moves.add(_createMove(board, from, to, piece));
      }
    }

    // Special move: 2 squares forward on first move (no capture)
    if (gameState != null && gameState.canMaidenUseSpecial(piece.color)) {
      final direction = piece.color == PlayerColor.white ? 1 : -1;
      final to = from.offset(direction * 2, 0);
      
      // Must be valid and empty (no capture)
      if (to.isValid && board.isEmpty(to)) {
        // Also check the square in between is empty
        final inBetween = from.offset(direction, 0);
        if (board.isEmpty(inBetween)) {
          moves.add(_createMove(board, from, to, piece, isSpecialMove: true));
        }
      }
    }

    return moves;
  }

  /// Diagonal 1 square moves (for backward compatibility)
  List<Move> _getDiagonalOneMoves(BoardState board, Position from, Piece piece) {
    final moves = <Move>[];
    final offsets = [(-1, -1), (-1, 1), (1, -1), (1, 1)];

    for (final (dr, dc) in offsets) {
      final to = from.offset(dr, dc);
      if (_canMoveTo(board, to, piece.color)) {
        moves.add(_createMove(board, from, to, piece));
      }
    }
    return moves;
  }

  /// Elephant moves - 4 diagonal + 1 forward
  List<Move> _getElephantMoves(BoardState board, Position from, Piece piece) {
    final moves = <Move>[];
    final direction = piece.color == PlayerColor.white ? 1 : -1;
    
    // 4 diagonal moves
    final diagonalOffsets = [(-1, -1), (-1, 1), (1, -1), (1, 1)];
    for (final (dr, dc) in diagonalOffsets) {
      final to = from.offset(dr, dc);
      if (_canMoveTo(board, to, piece.color)) {
        moves.add(_createMove(board, from, to, piece));
      }
    }
    
    // 1 forward move
    final forward = from.offset(direction, 0);
    if (_canMoveTo(board, forward, piece.color)) {
      moves.add(_createMove(board, from, forward, piece));
    }
    
    return moves;
  }

  /// Horse moves - L-shape
  List<Move> _getHorseMoves(BoardState board, Position from, Piece piece) {
    final moves = <Move>[];
    final offsets = [
      (-2, -1), (-2, 1), (-1, -2), (-1, 2),
      (1, -2), (1, 2), (2, -1), (2, 1),
    ];

    for (final (dr, dc) in offsets) {
      final to = from.offset(dr, dc);
      if (_canMoveTo(board, to, piece.color)) {
        moves.add(_createMove(board, from, to, piece));
      }
    }
    return moves;
  }

  /// Boat moves - straight lines (like Rook)
  List<Move> _getBoatMoves(BoardState board, Position from, Piece piece) {
    final moves = <Move>[];
    final directions = [(-1, 0), (1, 0), (0, -1), (0, 1)];

    for (final (dr, dc) in directions) {
      var to = from.offset(dr, dc);
      while (to.isValid) {
        final targetPiece = board.getPiece(to);
        if (targetPiece == null) {
          moves.add(_createMove(board, from, to, piece));
        } else if (targetPiece.color != piece.color) {
          moves.add(_createMove(board, from, to, piece));
          break;
        } else {
          break;
        }
        to = to.offset(dr, dc);
      }
    }
    return moves;
  }

  /// Fish moves - 1 forward, diagonal capture, promotion at opponent's fish starting row
  List<Move> _getFishMoves(BoardState board, Position from, Piece piece) {
    final moves = <Move>[];
    final direction = piece.color == PlayerColor.white ? 1 : -1;
    // White fish promotes at row 5 (where Gold fish starts)
    // Gold fish promotes at row 2 (where White fish starts)
    final promotionRank = piece.color == PlayerColor.white ? 5 : 2;

    // Forward move (no 2-square first move in Khmer chess)
    final forwardOne = from.offset(direction, 0);
    if (forwardOne.isValid && board.isEmpty(forwardOne)) {
      moves.add(_createFishMove(board, from, forwardOne, piece, promotionRank));
    }

    // Diagonal captures
    for (final dc in [-1, 1]) {
      final diagonal = from.offset(direction, dc);
      if (diagonal.isValid && board.hasEnemy(diagonal, piece.color)) {
        moves.add(_createFishMove(board, from, diagonal, piece, promotionRank));
      }
    }

    return moves;
  }

  /// Create a fish move with potential promotion
  Move _createFishMove(BoardState board, Position from, Position to, Piece piece, int promotionRank) {
    final isPromotion = to.row == promotionRank;
    final promotedTo = isPromotion
        ? Piece(type: PieceType.maiden, color: piece.color)
        : null;

    return Move(
      from: from,
      to: to,
      piece: piece,
      capturedPiece: board.getPiece(to),
      isPromotion: isPromotion,
      promotedTo: promotedTo,
    );
  }

  /// Create a standard move
  Move _createMove(BoardState board, Position from, Position to, Piece piece, {bool isSpecialMove = false}) {
    return Move(
      from: from,
      to: to,
      piece: piece,
      capturedPiece: board.getPiece(to),
      isSpecialMove: isSpecialMove,
    );
  }

  /// Check if a piece can move to a position
  bool _canMoveTo(BoardState board, Position to, PlayerColor color) {
    if (!to.isValid) return false;
    final piece = board.getPiece(to);
    return piece == null || piece.color != color;
  }

  /// Check if a move would leave the king in check
  bool _wouldBeInCheck(BoardState board, Move move, PlayerColor color) {
    final newBoard = board.applyMove(move);
    return isInCheck(newBoard, color);
  }

  /// Check if a player's king is in check
  bool isInCheck(BoardState board, PlayerColor color) {
    final kingPos = board.findKing(color);
    if (kingPos == null) return false;

    final opponent = color == PlayerColor.white ? PlayerColor.gold : PlayerColor.white;
    
    // Check if any opponent piece can capture the king
    for (final (pos, piece) in board.getPieces(opponent)) {
      final moves = getValidMoves(board, pos, checkLegal: false);
      if (moves.any((m) => m.to == kingPos)) {
        return true;
      }
    }
    return false;
  }

  /// Check if a player is in checkmate
  bool isCheckmate(BoardState board, PlayerColor color) {
    if (!isInCheck(board, color)) return false;
    return getAllValidMoves(board, color).isEmpty;
  }

  /// Check if the game is a stalemate
  bool isStalemate(BoardState board, PlayerColor color) {
    if (isInCheck(board, color)) return false;
    return getAllValidMoves(board, color).isEmpty;
  }

  /// Check if a rook can "see" the king (for losing king special ability)
  bool doesRookSeeKing(BoardState board, Position rookPos, PlayerColor kingColor) {
    final kingPos = board.findKing(kingColor);
    if (kingPos == null) return false;
    
    // Check if on same row or column
    if (rookPos.row != kingPos.row && rookPos.col != kingPos.col) {
      return false;
    }
    
    // Check if path is clear (rook can "see" king)
    if (rookPos.row == kingPos.row) {
      final minCol = rookPos.col < kingPos.col ? rookPos.col : kingPos.col;
      final maxCol = rookPos.col > kingPos.col ? rookPos.col : kingPos.col;
      for (var c = minCol + 1; c < maxCol; c++) {
        if (board.getPieceAt(rookPos.row, c) != null) return false;
      }
      return true;
    } else {
      final minRow = rookPos.row < kingPos.row ? rookPos.row : kingPos.row;
      final maxRow = rookPos.row > kingPos.row ? rookPos.row : kingPos.row;
      for (var r = minRow + 1; r < maxRow; r++) {
        if (board.getPieceAt(r, rookPos.col) != null) return false;
      }
      return true;
    }
  }
}
