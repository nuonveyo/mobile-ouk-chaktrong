import 'dart:math';
import '../models/models.dart';
import '../core/constants/game_constants.dart';
import 'move_generator.dart';
import 'board_evaluator.dart';

/// AI chess engine using Minimax with Alpha-Beta pruning
class AiEngine {
  final MoveGenerator _moveGenerator;
  final BoardEvaluator _evaluator;
  final Random _random = Random();

  // Track nodes evaluated for debugging
  int _nodesEvaluated = 0;

  AiEngine({
    MoveGenerator? moveGenerator,
    BoardEvaluator? evaluator,
  })  : _moveGenerator = moveGenerator ?? const MoveGenerator(),
        _evaluator = evaluator ?? const BoardEvaluator();

  /// Get the best move for the given player
  Move? getBestMove(
    BoardState board,
    PlayerColor player, {
    AiDifficulty difficulty = AiDifficulty.medium,
  }) {
    _nodesEvaluated = 0;
    
    final depth = _getDepthForDifficulty(difficulty);
    final isMaximizing = player == PlayerColor.white;
    
    final moves = _moveGenerator.getAllValidMoves(board, player);
    if (moves.isEmpty) return null;

    // For easy difficulty, sometimes make random moves
    if (difficulty == AiDifficulty.easy && _random.nextDouble() < 0.3) {
      return moves[_random.nextInt(moves.length)];
    }

    Move? bestMove;
    int bestScore = isMaximizing ? -999999 : 999999;

    // Shuffle moves for variety when scores are equal
    moves.shuffle(_random);

    for (final move in moves) {
      final newBoard = board.applyMove(move);
      final score = _minimax(
        newBoard,
        depth - 1,
        -999999,
        999999,
        !isMaximizing,
        player == PlayerColor.white ? PlayerColor.gold : PlayerColor.white,
      );

      if (isMaximizing) {
        if (score > bestScore) {
          bestScore = score;
          bestMove = move;
        }
      } else {
        if (score < bestScore) {
          bestScore = score;
          bestMove = move;
        }
      }
    }

    return bestMove;
  }

  /// Minimax algorithm with alpha-beta pruning
  int _minimax(
    BoardState board,
    int depth,
    int alpha,
    int beta,
    bool isMaximizing,
    PlayerColor currentPlayer,
  ) {
    _nodesEvaluated++;

    // Terminal conditions
    if (depth == 0) {
      return _evaluator.evaluate(board);
    }

    final moves = _moveGenerator.getAllValidMoves(board, currentPlayer);
    
    // No moves = checkmate or stalemate
    if (moves.isEmpty) {
      if (_moveGenerator.isInCheck(board, currentPlayer)) {
        // Checkmate - very bad/good depending on who's checkmated
        return isMaximizing ? -100000 + depth : 100000 - depth;
      }
      // Stalemate
      return 0;
    }

    final nextPlayer = currentPlayer == PlayerColor.white 
        ? PlayerColor.gold 
        : PlayerColor.white;

    if (isMaximizing) {
      int maxEval = -999999;
      for (final move in moves) {
        final newBoard = board.applyMove(move);
        final eval = _minimax(newBoard, depth - 1, alpha, beta, false, nextPlayer);
        maxEval = max(maxEval, eval);
        alpha = max(alpha, eval);
        if (beta <= alpha) break; // Beta cutoff
      }
      return maxEval;
    } else {
      int minEval = 999999;
      for (final move in moves) {
        final newBoard = board.applyMove(move);
        final eval = _minimax(newBoard, depth - 1, alpha, beta, true, nextPlayer);
        minEval = min(minEval, eval);
        beta = min(beta, eval);
        if (beta <= alpha) break; // Alpha cutoff
      }
      return minEval;
    }
  }

  /// Get search depth based on difficulty
  int _getDepthForDifficulty(AiDifficulty difficulty) {
    switch (difficulty) {
      case AiDifficulty.easy:
        return GameConstants.aiEasyDepth;
      case AiDifficulty.medium:
        return GameConstants.aiMediumDepth;
      case AiDifficulty.hard:
        return GameConstants.aiHardDepth;
    }
  }

  /// Get number of nodes evaluated in last search (for debugging)
  int get nodesEvaluated => _nodesEvaluated;
}
