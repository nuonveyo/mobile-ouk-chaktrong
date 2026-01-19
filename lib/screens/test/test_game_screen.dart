import 'dart:async' show Timer;
import 'package:flame/game.dart';
import 'package:flame/components.dart' hide Timer;
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/game_constants.dart';
import '../../models/models.dart';
import '../../logic/game_rules.dart';
import '../../logic/logic.dart';
import '../../widgets/counting_widget.dart';
import '../../widgets/player_info_card.dart';
import '../../game/components/board_component.dart';
import 'test_scenarios_screen.dart';

/// Game screen for testing with preset board states
class TestGameScreen extends StatefulWidget {
  final TestScenario scenario;

  const TestGameScreen({
    super.key,
    required this.scenario,
  });

  @override
  State<TestGameScreen> createState() => _TestGameScreenState();
}

class _TestGameScreenState extends State<TestGameScreen> {
  late TestChessGame _game;
  final GameRules _rules = const GameRules();
  GameState? _currentGameState;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    final presetBoard = getScenarioBoardState(widget.scenario);
    _game = TestChessGame(
      initialBoard: presetBoard,
      onGameStateChanged: (gameState) {
        setState(() {
          _currentGameState = gameState;
        });
        
        // Check if game ended due to counting limit
        if (gameState.isGameOver && mounted) {
          _showDrawDialog(context, gameState);
        }
      },
    );
  }
  
  void _showDrawDialog(BuildContext context, GameState gameState) {
    String title;
    String message;
    
    if (gameState.result == GameResult.draw) {
      if (gameState.counting.hasReachedLimit) {
        title = 'Draw - Counting Limit Reached';
        final typeLabel = gameState.counting.type == CountingType.boardHonor 
            ? "Board's Honor" 
            : "Piece's Honor";
        message = '$typeLabel counting reached ${gameState.counting.limit} moves.\nThe game is a draw!';
      } else {
        title = 'Draw';
        message = 'The game ended in a draw.';
      }
    } else if (gameState.result == GameResult.whiteWins) {
      title = 'White Wins!';
      message = 'Congratulations!';
    } else if (gameState.result == GameResult.goldWins) {
      title = 'Gold Wins!';
      message = 'Congratulations!';
    } else {
      return; // Game not over
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          title,
          style: const TextStyle(color: AppColors.templeGold),
        ),
        content: Text(
          message,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop(); // Go back to test list
            },
            child: const Text('Back'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _initGame(); // Restart game
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.templeGold,
            ),
            child: const Text('Restart'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameState = _currentGameState ?? _game.gameState;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      // appBar: AppBar(
      //   title: Text(_getScenarioTitle()),
      //   backgroundColor: AppColors.deepPurple,
      //   actions: [
      //     IconButton(
      //       icon: const Icon(Icons.refresh),
      //       onPressed: () {
      //         setState(() {
      //           _initGame();
      //         });
      //       },
      //     ),
      //   ],
      // ),
      body: SafeArea(
        child: Column(
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(12),
              color: AppColors.surface,
              child: Text(
                _getScenarioDescription(),
                style: const TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
            
            // Gold player info
            PlayerInfoCard(
              name: 'Gold',
              color: PlayerColor.gold,
              isCurrentTurn: gameState.currentTurn == PlayerColor.gold,
              isInCheck: gameState.isCheck && gameState.currentTurn == PlayerColor.gold,
              timeRemaining: gameState.goldTimeRemaining,
              capturedPieces: const [],
            ),
            
            // Counting widget for Gold
            CountingWidget(
              gameState: gameState,
              playerColor: PlayerColor.gold,
              onStartBoardCounting: () => _startBoardCounting(PlayerColor.gold),
              onStartPieceCounting: () => _startPieceCounting(PlayerColor.gold),
              onStopCounting: _stopCounting,
              onDeclareDraw: _declareDraw,
            ),
            
            // Chess board
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    child: GameWidget(game: _game),
                  ),
                ),
              ),
            ),
            
            // White player info
            PlayerInfoCard(
              name: 'White',
              color: PlayerColor.white,
              isCurrentTurn: gameState.currentTurn == PlayerColor.white,
              isInCheck: gameState.isCheck && gameState.currentTurn == PlayerColor.white,
              timeRemaining: gameState.whiteTimeRemaining,
              capturedPieces: const [],
            ),
            
            // Counting widget for White
            CountingWidget(
              gameState: gameState,
              playerColor: PlayerColor.white,
              onStartBoardCounting: () => _startBoardCounting(PlayerColor.white),
              onStartPieceCounting: () => _startPieceCounting(PlayerColor.white),
              onStopCounting: _stopCounting,
              onDeclareDraw: _declareDraw,
            ),
            
            // Debug info
            Container(
              padding: const EdgeInsets.all(8),
              color: AppColors.deepPurple,
              child: Text(
                _getDebugInfo(gameState),
                style: const TextStyle(color: Colors.white, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getScenarioTitle() {
    switch (widget.scenario) {
      case TestScenario.whiteBoardHonor3Pieces:
        return 'Board Honor: White 3 pieces';
      case TestScenario.whiteBoardHonor2Pieces:
        return 'Board Honor: White 2 pieces';
      case TestScenario.goldBoardHonor3Pieces:
        return 'Board Honor: Gold 3 pieces';
      case TestScenario.whitePieceHonor2Boats:
        return 'Piece Honor: 2 Boats (Limit 8)';
      case TestScenario.whitePieceHonor1Boat:
        return 'Piece Honor: 1 Boat (Limit 16)';
      case TestScenario.whitePieceHonor2Elephants:
        return 'Piece Honor: 2 Elephants (Limit 22)';
      case TestScenario.whitePieceHonor2Horses:
        return 'Piece Honor: 2 Horses (Limit 32)';
      case TestScenario.whitePieceHonor1Maiden:
        return 'Piece Honor: 1 Maiden (Limit 64)';
      case TestScenario.bothCanCount:
        return 'Both Can Count';
      case TestScenario.nearPromotion:
        return 'Near Promotion';
    }
  }

  String _getScenarioDescription() {
    final whitePieces = _game.gameState.board.getPieces(PlayerColor.white).length;
    final goldPieces = _game.gameState.board.getPieces(PlayerColor.gold).length;
    return 'White: $whitePieces pieces | Gold: $goldPieces pieces';
  }

  String _getDebugInfo(GameState gameState) {
    final counting = gameState.counting;
    if (counting.isActive) {
      return 'Counting: ${counting.type.name} | ${counting.currentCount}/${counting.limit} | Escaping: ${counting.escapingPlayer?.name ?? "none"}';
    }
    
    final whiteCanBoard = _rules.canStartBoardHonorCounting(gameState.board, PlayerColor.white);
    final goldCanBoard = _rules.canStartBoardHonorCounting(gameState.board, PlayerColor.gold);
    final whiteCanPiece = _rules.canStartPieceHonorCounting(gameState.board, PlayerColor.white);
    final goldCanPiece = _rules.canStartPieceHonorCounting(gameState.board, PlayerColor.gold);
    
    return 'Board Honor: W=$whiteCanBoard G=$goldCanBoard | Piece Honor: W=$whiteCanPiece G=$goldCanPiece';
  }

  void _startBoardCounting(PlayerColor escapingPlayer) {
    final newState = _rules.startBoardHonorCounting(_game.gameState, escapingPlayer);
    _game.updateGameState(newState);
  }

  void _startPieceCounting(PlayerColor escapingPlayer) {
    final newState = _rules.startPieceHonorCounting(_game.gameState, escapingPlayer);
    _game.updateGameState(newState);
  }

  void _stopCounting() {
    final newState = _rules.stopCounting(_game.gameState);
    _game.updateGameState(newState);
  }

  void _declareDraw() {
    final newState = _rules.declareDraw(_game.gameState);
    _game.updateGameState(newState);
  }
}

// Simplified ChessGame for testing
class TestChessGame extends FlameGame {
  final BoardState initialBoard;
  final void Function(GameState)? onGameStateChanged;

  GameState _gameState;
  late BoardComponent _board;
  final GameRules _rules = const GameRules();
  final MoveGenerator _moveGenerator = const MoveGenerator();

  Position? _selectedPosition;
  List<Move> _validMoves = [];
  Timer? _timer;

  TestChessGame({
    required this.initialBoard,
    this.onGameStateChanged,
  }) : _gameState = GameState(
         board: initialBoard,
         currentTurn: PlayerColor.white,
         moveHistory: const [],
         result: GameResult.ongoing,
         isCheck: false,
         whiteTimeRemaining: 600,
         goldTimeRemaining: 600,
       );

  GameState get gameState => _gameState;

  void updateGameState(GameState newState) {
    _gameState = newState;
    onGameStateChanged?.call(_gameState);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _board = BoardComponent(
      boardSize: size.x < size.y ? size.x : size.y,
      onSquareTapped: _onSquareTapped,
    );
    
    _board.position = Vector2(
      (size.x - _board.boardSize) / 2,
      (size.y - _board.boardSize) / 2,
    );

    add(_board);
    _board.syncPieces(_gameState.board);
    
    // Start timer
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_gameState.isGameOver) {
        _gameState = _rules.tickTime(_gameState);
        onGameStateChanged?.call(_gameState);
      }
    });
  }

  @override
  void onRemove() {
    _timer?.cancel();
    super.onRemove();
  }

  void _onSquareTapped(Position position) {
    final piece = _gameState.board.getPiece(position);

    if (_selectedPosition != null) {
      final move = _validMoves.where((m) => m.to == position).firstOrNull;
      
      if (move != null) {
        _executeMove(move);
        return;
      }
    }

    if (piece != null && piece.color == _gameState.currentTurn) {
      _selectPiece(position);
    } else {
      _clearSelection();
    }
  }

  void _selectPiece(Position position) {
    _clearSelection();
    
    _selectedPosition = position;
    _validMoves = _moveGenerator.getValidMovesWithState(_gameState.board, position, _gameState);

    _board.setSelectedSquare(position);
    _board.setValidMoves(_validMoves.map((m) => m.to).toList());
    _board.selectPiece(position);
  }

  void _clearSelection() {
    _selectedPosition = null;
    _validMoves = [];
    _board.clearHighlights();
  }

  void _executeMove(Move move) {
    _gameState = _rules.applyMove(_gameState, move);
    _clearSelection();
    _board.animateMove(move);
    _board.setLastMove(move.from, move.to);
    onGameStateChanged?.call(_gameState);
  }
}
