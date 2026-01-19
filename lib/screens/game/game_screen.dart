import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/game_constants.dart';
import '../../models/models.dart';
import '../../logic/game_rules.dart';
import '../../blocs/game/game_bloc.dart';
import '../../game/chess_game.dart';
import '../../widgets/player_info_card.dart';
import '../../widgets/counting_widget.dart';

/// Game screen with Flame game widget and BLoC state management
class GameScreen extends StatelessWidget {
  final GameMode gameMode;
  final AiDifficulty? aiDifficulty;
  final int? timeControl;

  const GameScreen({
    super.key,
    required this.gameMode,
    this.aiDifficulty,
    this.timeControl,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GameBloc(
        timeControlSeconds: timeControl ?? GameConstants.defaultTimeControl,
      )..add(GameStarted(
          timeControlSeconds: timeControl ?? GameConstants.defaultTimeControl,
        )),
      child: _GameScreenContent(
        gameMode: gameMode,
        aiDifficulty: aiDifficulty,
      ),
    );
  }
}

class _GameScreenContent extends StatefulWidget {
  final GameMode gameMode;
  final AiDifficulty? aiDifficulty;

  const _GameScreenContent({
    required this.gameMode,
    this.aiDifficulty,
  });

  @override
  State<_GameScreenContent> createState() => _GameScreenContentState();
}

class _GameScreenContentState extends State<_GameScreenContent> {
  ChessGame? _game;
  final GameRules _rules = const GameRules();
  GameState? _currentGameState; // Track Flame game's state for UI

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    _game = ChessGame(
      gameMode: widget.gameMode,
      aiDifficulty: widget.aiDifficulty,
      onGameStateChanged: (gameState) {
        // Sync Flame game state to widget state
        setState(() {
          _currentGameState = gameState;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _showExitConfirmDialog(context),
        ),
        title: Text(_getGameModeTitle()),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _confirmNewGame(context),
          ),
        ],
      ),
      body: BlocConsumer<GameBloc, GameBlocState>(
        listenWhen: (previous, current) => 
            previous.gameState.result != current.gameState.result,
        listener: (context, state) {
          if (state.isGameOver) {
            _showGameOverDialog(context, state);
          }
        },
        builder: (context, state) {
          final gameState = state.gameState;
          
          return SafeArea(
            child: Column(
              children: [
                // Opponent info (Gold player at top)
                PlayerInfoCard(
                  name: widget.gameMode == GameMode.vsAi
                      ? 'AI (${_getDifficultyLabel()})'
                      : 'Player 2',
                  color: PlayerColor.gold,
                  isCurrentTurn: gameState.currentTurn == PlayerColor.gold,
                  isInCheck: gameState.isCheck && gameState.currentTurn == PlayerColor.gold,
                  timeRemaining: gameState.goldTimeRemaining,
                  capturedPieces: _getCapturedPieces(gameState, PlayerColor.white),
                ),
                
                // Counting widget for Gold player
                if (_currentGameState != null || _game?.gameState != null)
                  CountingWidget(
                    gameState: _currentGameState ?? _game!.gameState,
                    playerColor: PlayerColor.gold,
                    onStartBoardCounting: () => _startBoardCounting(PlayerColor.gold),
                    onStartPieceCounting: () => _startPieceCounting(PlayerColor.gold),
                    onStopCounting: _stopCounting,
                    onDeclareDraw: _declareDraw,
                  ),
                
                // Chess board with Flame
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _game != null 
                              ? GameWidget(game: _game!)
                              : const Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.templeGold,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Player info (White player at bottom)
                PlayerInfoCard(
                  name: 'You',
                  color: PlayerColor.white,
                  isCurrentTurn: gameState.currentTurn == PlayerColor.white,
                  isInCheck: gameState.isCheck && gameState.currentTurn == PlayerColor.white,
                  timeRemaining: gameState.whiteTimeRemaining,
                  capturedPieces: _getCapturedPieces(gameState, PlayerColor.gold),
                ),
                
                // Counting widget for White (human player)
                // Use Flame game's state for counting eligibility check
                if (_currentGameState != null || _game?.gameState != null)
                  CountingWidget(
                    gameState: _currentGameState ?? _game!.gameState,
                    playerColor: PlayerColor.white,
                    onStartBoardCounting: () => _startBoardCounting(PlayerColor.white),
                    onStartPieceCounting: () => _startPieceCounting(PlayerColor.white),
                    onStopCounting: _stopCounting,
                    onDeclareDraw: _declareDraw,
                  ),
                
                // Action buttons
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        Icons.undo,
                        'Undo',
                        gameState.moveHistory.isNotEmpty,
                        () => _game?.undoMove(),
                      ),
                      _buildActionButton(
                        Icons.flag_outlined,
                        'Resign',
                        !gameState.isGameOver,
                        () => _confirmResign(context),
                      ),
                      _buildActionButton(
                        Icons.handshake_outlined,
                        'Draw',
                        !gameState.isGameOver && widget.gameMode != GameMode.vsAi,
                        () => _offerDraw(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getGameModeTitle() {
    switch (widget.gameMode) {
      case GameMode.vsAi:
        return 'vs AI';
      case GameMode.local2Player:
        return 'Local Game';
      case GameMode.online:
        return 'Online Match';
    }
  }

  String _getDifficultyLabel() {
    switch (widget.aiDifficulty) {
      case AiDifficulty.easy:
        return 'Easy';
      case AiDifficulty.medium:
        return 'Medium';
      case AiDifficulty.hard:
        return 'Hard';
      case null:
        return 'Medium';
    }
  }

  List<Piece> _getCapturedPieces(GameState gameState, PlayerColor capturedFrom) {
    // Calculate captured pieces from move history
    return gameState.moveHistory
        .where((m) => m.capturedPiece != null && m.capturedPiece!.color == capturedFrom)
        .map((m) => m.capturedPiece!)
        .toList();
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    bool enabled,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: enabled ? 1.0 : 0.4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: AppColors.templeGold),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============ COUNTING HANDLERS ============

  void _startBoardCounting(PlayerColor escapingPlayer) {
    if (_game?.gameState != null) {
      final newState = _rules.startBoardHonorCounting(_game!.gameState, escapingPlayer);
      _game?.updateGameState(newState);
    }
  }

  void _startPieceCounting(PlayerColor escapingPlayer) {
    if (_game?.gameState != null) {
      final newState = _rules.startPieceHonorCounting(_game!.gameState, escapingPlayer);
      _game?.updateGameState(newState);
    }
  }

  void _stopCounting() {
    if (_game?.gameState != null) {
      final newState = _rules.stopCounting(_game!.gameState);
      _game?.updateGameState(newState);
    }
  }

  void _declareDraw() {
    if (_game?.gameState != null) {
      final newState = _rules.declareDraw(_game!.gameState);
      _game?.updateGameState(newState);
    }
  }

  void _showExitConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Leave Game?'),
        content: const Text('Your progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            child: const Text('Leave', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  void _confirmResign(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Resign?'),
        content: const Text('Are you sure you want to resign this game?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _game?.resign();
            },
            child: const Text('Resign', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  void _offerDraw(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Offer Draw?'),
        content: const Text('Do you want to offer a draw to your opponent?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              // In local 2-player, show draw acceptance dialog
              _showDrawAcceptDialog(context);
            },
            child: const Text('Offer Draw'),
          ),
        ],
      ),
    );
  }

  void _showDrawAcceptDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Draw Offered'),
        content: const Text('Your opponent offers a draw. Do you accept?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Decline'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<GameBloc>().add(const DrawAccepted());
            },
            child: const Text('Accept Draw'),
          ),
        ],
      ),
    );
  }

  void _confirmNewGame(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('New Game?'),
        content: const Text('Start a new game? Current progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              setState(() {
                _initGame();
              });
              context.read<GameBloc>().add(const GameStarted());
            },
            child: const Text('New Game'),
          ),
        ],
      ),
    );
  }

  void _showGameOverDialog(BuildContext context, GameBlocState state) {
    String title;
    String message;
    
    switch (state.result) {
      case GameResult.whiteWins:
        title = '🎉 White Wins!';
        message = widget.gameMode == GameMode.vsAi 
            ? 'Congratulations! You defeated the AI!'
            : 'White player wins by checkmate!';
      case GameResult.goldWins:
        title = '🏆 Gold Wins!';
        message = widget.gameMode == GameMode.vsAi 
            ? 'The AI wins. Better luck next time!'
            : 'Gold player wins by checkmate!';
      case GameResult.draw:
        title = '🤝 Draw';
        message = 'The game ended in a draw.';
      case GameResult.ongoing:
        return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title, textAlign: TextAlign.center),
        content: Text(message, textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              setState(() {
                _initGame();
              });
              context.read<GameBloc>().add(const GameStarted());
            },
            child: const Text('Play Again'),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}
