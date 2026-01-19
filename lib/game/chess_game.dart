import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../logic/logic.dart';
import '../core/constants/constants.dart';
import '../services/sound_service.dart';
import 'components/board_component.dart';
import 'components/piece_component.dart';
import 'components/square_highlight.dart';

/// Main Flame game class for Khmer Chess
class ChessGame extends FlameGame {
  final GameMode gameMode;
  final AiDifficulty? aiDifficulty;
  final void Function(GameState)? onGameStateChanged;

  late GameState _gameState;
  late BoardComponent _board;
  final GameRules _rules = const GameRules();
  final MoveGenerator _moveGenerator = const MoveGenerator();

  Position? _selectedPosition;
  List<Move> _validMoves = [];

  ChessGame({
    required this.gameMode,
    this.aiDifficulty,
    this.onGameStateChanged,
  });

  GameState get gameState => _gameState;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Initialize game state
    _gameState = GameState.initial();

    // Create and add board
    _board = BoardComponent(
      boardSize: size.x < size.y ? size.x : size.y,
      onSquareTapped: _onSquareTapped,
    );
    
    // Center the board
    _board.position = Vector2(
      (size.x - _board.boardSize) / 2,
      (size.y - _board.boardSize) / 2,
    );

    add(_board);

    // Initial piece setup
    _syncPiecesToBoard();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    
    // Resize board when game resizes
    if (children.whereType<BoardComponent>().isNotEmpty) {
      final newSize = size.x < size.y ? size.x : size.y;
      _board.resize(newSize);
      _board.position = Vector2(
        (size.x - _board.boardSize) / 2,
        (size.y - _board.boardSize) / 2,
      );
    }
  }

  /// Handle square tap
  void _onSquareTapped(Position position) {
    final piece = _gameState.board.getPiece(position);

    // If we have a selected piece, try to move
    if (_selectedPosition != null) {
      final move = _validMoves.where((m) => m.to == position).firstOrNull;
      
      if (move != null) {
        // Execute the move
        _executeMove(move);
        return;
      }
    }

    // Select a piece if it belongs to current player
    if (piece != null && piece.color == _gameState.currentTurn) {
      _selectPiece(position);
    } else {
      _clearSelection();
    }
  }

  /// Select a piece and show valid moves
  void _selectPiece(Position position) {
    _clearSelection();
    
    _selectedPosition = position;
    _validMoves = _moveGenerator.getValidMoves(_gameState.board, position);

    // Highlight selected square
    _board.setSelectedSquare(position);

    // Highlight valid moves
    _board.setValidMoves(_validMoves.map((m) => m.to).toList());

    // Animate selected piece
    _board.selectPiece(position);
  }

  /// Clear current selection
  void _clearSelection() {
    _selectedPosition = null;
    _validMoves = [];
    _board.clearHighlights();
  }

  /// Execute a move
  void _executeMove(Move move) {
    // Play appropriate sound
    if (move.isCapture) {
      SoundService().playCapture();
    } else {
      SoundService().playMove();
    }

    // Apply move to game state
    _gameState = _rules.applyMove(_gameState, move);

    // Play check sound if in check
    if (_gameState.isCheck) {
      SoundService().playCheck();
    }

    // Clear selection
    _clearSelection();

    // Animate the move on the board
    _board.animateMove(move);

    // Highlight last move
    _board.setLastMove(move.from, move.to);

    // Notify listeners
    onGameStateChanged?.call(_gameState);

    // Check for game over
    if (_gameState.isGameOver) {
      _handleGameOver();
      return;
    }

    // If playing against AI and it's AI's turn
    if (gameMode == GameMode.vsAi && _gameState.currentTurn == PlayerColor.gold) {
      _makeAiMove();
    }
  }

  /// Make AI move using Minimax engine
  void _makeAiMove() {
    // Add slight delay for UX (so human can see their move)
    Future.delayed(const Duration(milliseconds: 300), () {
      final aiEngine = AiEngine();
      final bestMove = aiEngine.getBestMove(
        _gameState.board,
        PlayerColor.gold,
        difficulty: aiDifficulty ?? AiDifficulty.medium,
      );
      
      if (bestMove != null) {
        _executeMove(bestMove);
      }
    });
  }

  /// Handle game over
  void _handleGameOver() {
    // Play game over sound
    SoundService().playGameOver();
    
    // Will trigger UI update via onGameStateChanged
    onGameStateChanged?.call(_gameState);
  }

  /// Sync pieces to board display
  void _syncPiecesToBoard() {
    _board.syncPieces(_gameState.board);
  }

  /// Undo last move
  void undoMove() {
    final newState = _rules.undoMove(_gameState);
    if (newState != null) {
      _gameState = newState;
      _clearSelection();
      _board.clearHighlights();
      _syncPiecesToBoard();
      onGameStateChanged?.call(_gameState);
    }
  }

  /// Resign the game
  void resign() {
    _gameState = _gameState.copyWith(
      result: _gameState.currentTurn == PlayerColor.white
          ? GameResult.goldWins
          : GameResult.whiteWins,
    );
    onGameStateChanged?.call(_gameState);
  }
}
