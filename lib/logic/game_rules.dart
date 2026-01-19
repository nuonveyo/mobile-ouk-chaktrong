import '../core/constants/game_constants.dart';
import '../models/models.dart';
import 'move_generator.dart';

/// Game rules and state management logic
class GameRules {
  final MoveGenerator _moveGenerator;

  const GameRules({MoveGenerator? moveGenerator})
      : _moveGenerator = moveGenerator ?? const MoveGenerator();

  /// Apply a move to the game state and return the new state
  GameState applyMove(GameState state, Move move) {
    // Apply move to board
    final newBoard = state.board.applyMove(move);
    
    // Switch turn
    final newTurn = state.currentTurn == PlayerColor.white
        ? PlayerColor.gold
        : PlayerColor.white;
    
    // Check if opponent is in check
    final isCheck = _moveGenerator.isInCheck(newBoard, newTurn);
    
    // Check game result
    GameResult result = GameResult.ongoing;
    
    // Check if counting player checkmated - that's a draw!
    if (_moveGenerator.isCheckmate(newBoard, newTurn)) {
      if (state.counting.isActive && state.counting.escapingPlayer == state.currentTurn) {
        // Counting player checkmated their opponent - draw
        result = GameResult.draw;
      } else {
        result = state.currentTurn == PlayerColor.white
            ? GameResult.whiteWins
            : GameResult.goldWins;
      }
    } else if (_moveGenerator.isStalemate(newBoard, newTurn)) {
      result = GameResult.draw;
    }
    
    // Add move to history
    final newHistory = [...state.moveHistory, move];
    
    // Track special move flags
    bool whiteKingMoved = state.whiteKingMoved;
    bool goldKingMoved = state.goldKingMoved;
    bool whiteMaidenMoved = state.whiteMaidenMoved;
    bool goldMaidenMoved = state.goldMaidenMoved;
    bool whiteKingSpecialLost = state.whiteKingSpecialLost;
    bool goldKingSpecialLost = state.goldKingSpecialLost;
    
    // Update moved flags based on piece type
    if (move.piece.type == PieceType.king) {
      if (move.piece.color == PlayerColor.white) {
        whiteKingMoved = true;
      } else {
        goldKingMoved = true;
      }
    } else if (move.piece.type == PieceType.maiden) {
      if (move.piece.color == PlayerColor.white) {
        whiteMaidenMoved = true;
      } else {
        goldMaidenMoved = true;
      }
    }
    
    // Check if a rook move causes opponent's king to lose special ability
    if (move.piece.type == PieceType.boat) {
      if (move.piece.color == PlayerColor.white) {
        if (_moveGenerator.doesRookSeeKing(newBoard, move.to, PlayerColor.gold)) {
          goldKingSpecialLost = true;
        }
      } else {
        if (_moveGenerator.doesRookSeeKing(newBoard, move.to, PlayerColor.white)) {
          whiteKingSpecialLost = true;
        }
      }
    }
    
    // Handle counting - increment if active and it's escaping player's move
    CountingState newCounting = state.counting;
    if (state.counting.isActive && state.counting.escapingPlayer == state.currentTurn) {
      newCounting = state.counting.increment();
      
      // Check if count reached limit - draw
      if (newCounting.hasReachedLimit && result == GameResult.ongoing) {
        result = GameResult.draw;
      }
    }
    
    return state.copyWith(
      board: newBoard,
      currentTurn: newTurn,
      moveHistory: newHistory,
      isCheck: isCheck,
      result: result,
      whiteKingMoved: whiteKingMoved,
      goldKingMoved: goldKingMoved,
      whiteMaidenMoved: whiteMaidenMoved,
      goldMaidenMoved: goldMaidenMoved,
      whiteKingSpecialLost: whiteKingSpecialLost,
      goldKingSpecialLost: goldKingSpecialLost,
      counting: newCounting,
    );
  }

  /// Check if a move is valid for the current game state
  bool isMoveValid(GameState state, Position from, Position to) {
    final piece = state.board.getPiece(from);
    if (piece == null || piece.color != state.currentTurn) return false;
    
    final validMoves = _moveGenerator.getValidMovesWithState(state.board, from, state);
    return validMoves.any((m) => m.to == to);
  }

  /// Get all valid moves for the current player
  List<Move> getValidMoves(GameState state, Position from) {
    final piece = state.board.getPiece(from);
    if (piece == null || piece.color != state.currentTurn) return [];
    
    return _moveGenerator.getValidMovesWithState(state.board, from, state);
  }

  /// Get all valid moves for the current player
  List<Move> getAllValidMoves(GameState state) {
    return _moveGenerator.getAllValidMovesWithState(state.board, state.currentTurn, state);
  }

  /// Create a move from positions
  Move? createMove(GameState state, Position from, Position to) {
    final validMoves = getValidMoves(state, from);
    try {
      return validMoves.firstWhere((m) => m.to == to);
    } catch (_) {
      return null;
    }
  }

  /// Undo the last move
  GameState? undoMove(GameState state) {
    if (state.moveHistory.isEmpty) return null;
    
    var newState = GameState.initial(
      timeControl: state.whiteTimeRemaining + state.goldTimeRemaining ~/ 2,
    );
    
    for (var i = 0; i < state.moveHistory.length - 1; i++) {
      newState = applyMove(newState, state.moveHistory[i]);
    }
    
    return newState;
  }

  /// Update time for the current player
  GameState tickTime(GameState state, {int seconds = 1}) {
    if (state.currentTurn == PlayerColor.white) {
      final newTime = state.whiteTimeRemaining - seconds;
      if (newTime <= 0) {
        return state.copyWith(
          whiteTimeRemaining: 0,
          result: GameResult.goldWins,
        );
      }
      return state.copyWith(whiteTimeRemaining: newTime);
    } else {
      final newTime = state.goldTimeRemaining - seconds;
      if (newTime <= 0) {
        return state.copyWith(
          goldTimeRemaining: 0,
          result: GameResult.whiteWins,
        );
      }
      return state.copyWith(goldTimeRemaining: newTime);
    }
  }

  // ============ COUNTING RULES ============

  /// Check if a player can start Board's Honor counting
  /// Requires: ≤3 pieces
  bool canStartBoardHonorCounting(BoardState board, PlayerColor player) {
    final pieces = board.getPieces(player);
    return pieces.length <= 3;
  }

  /// Check if a player can start Piece's Honor counting
  /// Requires: No unpromoted pawns AND player has only King
  bool canStartPieceHonorCounting(BoardState board, PlayerColor player) {
    final playerPieces = board.getPieces(player);
    
    // Player must have only King
    if (playerPieces.length != 1) return false;
    if (playerPieces.first.$2.type != PieceType.king) return false;
    
    // No unpromoted pawns (fish) on the board
    final opponent = player == PlayerColor.white ? PlayerColor.gold : PlayerColor.white;
    final opponentPieces = board.getPieces(opponent);
    
    final hasUnpromotedPawns = opponentPieces.any((p) => p.$2.type == PieceType.fish);
    
    return !hasUnpromotedPawns;
  }

  /// Start Board's Honor counting for a player
  GameState startBoardHonorCounting(GameState state, PlayerColor escapingPlayer) {
    return state.copyWith(
      counting: CountingState.startBoardHonor(escapingPlayer),
    );
  }

  /// Start Piece's Honor counting for a player
  GameState startPieceHonorCounting(GameState state, PlayerColor escapingPlayer) {
    final board = state.board;
    
    // Calculate total pieces on board (including both kings)
    final whitePieces = board.getPieces(PlayerColor.white);
    final goldPieces = board.getPieces(PlayerColor.gold);
    final totalPieces = whitePieces.length + goldPieces.length;
    
    // Count starts from totalPieces + 1
    final startCount = totalPieces + 1;
    
    // Calculate limit based on chasing player's material
    final chasingPlayer = escapingPlayer == PlayerColor.white ? PlayerColor.gold : PlayerColor.white;
    final limit = _calculatePieceHonorLimit(board, chasingPlayer);
    
    return state.copyWith(
      counting: CountingState.startPieceHonor(
        escapingPlayer: escapingPlayer,
        startCount: startCount,
        limit: limit,
      ),
    );
  }

  /// Calculate Piece's Honor limit based on chasing player's material
  int _calculatePieceHonorLimit(BoardState board, PlayerColor chasingPlayer) {
    final pieces = board.getPieces(chasingPlayer);
    
    int boatCount = 0;
    int elephantCount = 0;
    int horseCount = 0;
    bool hasOnlyMaidens = true;
    
    for (final (_, piece) in pieces) {
      switch (piece.type) {
        case PieceType.boat:
          boatCount++;
          hasOnlyMaidens = false;
        case PieceType.elephant:
          elephantCount++;
          hasOnlyMaidens = false;
        case PieceType.horse:
          horseCount++;
          hasOnlyMaidens = false;
        case PieceType.king:
          break; // King doesn't affect limit
        case PieceType.maiden:
          break; // Maidens are included in "only maidens" check
        case PieceType.fish:
          hasOnlyMaidens = false;
      }
    }
    
    // Return minimum applicable limit
    if (boatCount >= 2) return 8;
    if (boatCount >= 1) return 16;
    if (elephantCount >= 2) return 22;
    if (horseCount >= 2) return 32;
    if (elephantCount >= 1) return 44;
    if (horseCount >= 1) return 64;
    if (hasOnlyMaidens) return 64;
    
    return 64; // Default
  }

  /// Stop counting (can restart from 1 later)
  GameState stopCounting(GameState state) {
    return state.copyWith(
      counting: const CountingState.none(),
    );
  }

  /// Chasing player declares draw
  GameState declareDraw(GameState state) {
    if (!state.counting.isActive) return state;
    return state.copyWith(result: GameResult.draw);
  }

  /// Check for insufficient material (draw)
  bool hasInsufficientMaterial(BoardState board) {
    final whitePieces = board.getPieces(PlayerColor.white);
    final goldPieces = board.getPieces(PlayerColor.gold);
    
    if (whitePieces.length == 1 && goldPieces.length == 1) {
      return true;
    }
    
    if ((whitePieces.length == 2 && goldPieces.length == 1) ||
        (whitePieces.length == 1 && goldPieces.length == 2)) {
      final pieces = whitePieces.length == 2 ? whitePieces : goldPieces;
      final nonKing = pieces.where((p) => p.$2.type != PieceType.king).first.$2;
      if (nonKing.type == PieceType.elephant || nonKing.type == PieceType.horse) {
        return true;
      }
    }
    
    return false;
  }
}
