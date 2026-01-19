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
    if (_moveGenerator.isCheckmate(newBoard, newTurn)) {
      result = state.currentTurn == PlayerColor.white
          ? GameResult.whiteWins
          : GameResult.goldWins;
    } else if (_moveGenerator.isStalemate(newBoard, newTurn)) {
      result = GameResult.draw;
    }
    
    // Add move to history
    final newHistory = [...state.moveHistory, move];
    
    return state.copyWith(
      board: newBoard,
      currentTurn: newTurn,
      moveHistory: newHistory,
      isCheck: isCheck,
      result: result,
    );
  }

  /// Check if a move is valid for the current game state
  bool isMoveValid(GameState state, Position from, Position to) {
    final piece = state.board.getPiece(from);
    if (piece == null || piece.color != state.currentTurn) return false;
    
    final validMoves = _moveGenerator.getValidMoves(state.board, from);
    return validMoves.any((m) => m.to == to);
  }

  /// Get all valid moves for the current player
  List<Move> getValidMoves(GameState state, Position from) {
    final piece = state.board.getPiece(from);
    if (piece == null || piece.color != state.currentTurn) return [];
    
    return _moveGenerator.getValidMoves(state.board, from);
  }

  /// Get all valid moves for the current player
  List<Move> getAllValidMoves(GameState state) {
    return _moveGenerator.getAllValidMoves(state.board, state.currentTurn);
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
    
    // Rebuild game state from scratch up to the second-to-last move
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

  /// Check for insufficient material (draw)
  bool hasInsufficientMaterial(BoardState board) {
    final whitePieces = board.getPieces(PlayerColor.white);
    final goldPieces = board.getPieces(PlayerColor.gold);
    
    // King vs King
    if (whitePieces.length == 1 && goldPieces.length == 1) {
      return true;
    }
    
    // King + minor piece vs King
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
