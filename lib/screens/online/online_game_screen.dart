import 'dart:async' show Timer, StreamSubscription;
import 'package:flame/game.dart';
import 'package:flame/components.dart' hide Timer;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/game_constants.dart';
import '../../models/models.dart';
import '../../models/online_game.dart';
import '../../logic/game_rules.dart';
import '../../logic/logic.dart';
import '../../blocs/online/online_game_bloc.dart';
import '../../repositories/repositories.dart';
import '../../widgets/player_info_card.dart';
import '../../widgets/counting_widget.dart';
import '../../game/components/board_component.dart';

/// Screen for online multiplayer game
class OnlineGameScreen extends StatelessWidget {
  final String roomId;

  const OnlineGameScreen({
    super.key,
    required this.roomId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OnlineGameBloc(
        authRepository: AuthRepository(),
        gameRepository: OnlineGameRepository(),
      )..add(WatchRoomRequested(roomId)),
      child: _OnlineGameContent(roomId: roomId),
    );
  }
}

class _OnlineGameContent extends StatefulWidget {
  final String roomId;

  const _OnlineGameContent({required this.roomId});

  @override
  State<_OnlineGameContent> createState() => _OnlineGameContentState();
}

class _OnlineGameContentState extends State<_OnlineGameContent> {
  OnlineChessGame? _game;
  final GameRules _rules = const GameRules();
  GameState? _currentGameState;
  StreamSubscription? _roomSubscription;
  OnlineGameRepository? _repository;
  
  String? _localPlayerId;
  PlayerColor? _localPlayerColor;
  bool _isGameInitialized = false;

  @override
  void initState() {
    super.initState();
    _repository = OnlineGameRepository();
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();
    super.dispose();
  }

  void _initGame(OnlineGameRoom room, String localPlayerId) {
    if (_isGameInitialized) return;
    _isGameInitialized = true;
    
    _localPlayerId = localPlayerId;
    
    // Determine local player's color
    // Host plays White, Guest plays Gold
    _localPlayerColor = room.hostPlayerId == localPlayerId 
        ? PlayerColor.white 
        : PlayerColor.gold;

    // Rebuild board from move history if exists
    GameState initialState = GameState.initial(
      timeControl: room.timeControl,
    );
    
    if (room.gameData != null && room.gameData!.moves.isNotEmpty) {
      initialState = _rebuildStateFromMoves(room.gameData!.moves, room.gameData!);
    }

    _game = OnlineChessGame(
      initialState: initialState,
      localPlayerColor: _localPlayerColor!,
      onMoveMade: _onLocalMoveMade,
      onGameStateChanged: (gameState) {
        if (mounted) {
          setState(() {
            _currentGameState = gameState;
          });
          
          if (gameState.isGameOver) {
            _handleGameOver(gameState);
          }
        }
      },
    );
    
    setState(() {
      _currentGameState = initialState;
    });

    // Start listening for room updates
    _startListeningToRoom();
  }

  GameState _rebuildStateFromMoves(List<String> moves, OnlineGameData gameData) {
    GameState state = GameState.initial(timeControl: 600);
    
    for (final moveNotation in moves) {
      final move = _parseMoveNotation(moveNotation, state.board, state.currentTurn);
      if (move != null) {
        state = _rules.applyMove(state, move);
      }
    }
    
    // Update times from server
    return state.copyWith(
      whiteTimeRemaining: gameData.whiteTimeRemaining,
      goldTimeRemaining: gameData.goldTimeRemaining,
    );
  }

  Move? _parseMoveNotation(String notation, BoardState board, PlayerColor turn) {
    // Parse format: "e2-e4" or "e2xe4" (capture)
    try {
      final parts = notation.contains('x') 
          ? notation.split('x') 
          : notation.split('-');
      
      if (parts.length != 2) return null;
      
      final from = _parsePosition(parts[0]);
      final to = _parsePosition(parts[1]);
      
      if (from == null || to == null) return null;
      
      final piece = board.getPiece(from);
      if (piece == null) return null;
      
      final capturedPiece = board.getPiece(to);
      
      return Move(
        from: from,
        to: to,
        piece: piece,
        capturedPiece: capturedPiece,
      );
    } catch (e) {
      return null;
    }
  }

  Position? _parsePosition(String pos) {
    if (pos.length != 2) return null;
    final col = pos.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final row = int.tryParse(pos[1]);
    if (row == null || col < 0 || col > 7 || row < 1 || row > 8) return null;
    return Position(row - 1, col);
  }

  void _startListeningToRoom() {
    _roomSubscription?.cancel();
    _roomSubscription = _repository!.watchRoom(widget.roomId).listen(
      (room) {
        if (room == null || _game == null) return;
        
        // Check if there's a new move from opponent
        final gameData = room.gameData;
        if (gameData != null && gameData.moves.isNotEmpty) {
          final expectedMoves = _currentGameState?.moveHistory.length ?? 0;
          
          if (gameData.moves.length > expectedMoves) {
            // Apply new moves
            for (int i = expectedMoves; i < gameData.moves.length; i++) {
              final moveNotation = gameData.moves[i];
              _applyRemoteMove(moveNotation);
            }
          }
        }
        
        // Check if game ended
        if (room.isFinished && gameData?.result != null) {
          _handleRemoteGameEnd(gameData!.result!);
        }
      },
      onError: (error) {
        debugPrint('Room subscription error: $error');
      },
    );
  }

  void _applyRemoteMove(String moveNotation) {
    if (_game == null || _currentGameState == null) return;
    
    final move = _parseMoveNotation(
      moveNotation, 
      _currentGameState!.board, 
      _currentGameState!.currentTurn,
    );
    
    if (move != null) {
      _game!.applyRemoteMove(move);
    }
  }

  void _onLocalMoveMade(Move move, GameState newState) {
    // Convert move to notation and send to Firestore
    final notation = _moveToNotation(move);
    
    _repository!.makeMove(
      roomId: widget.roomId,
      moveNotation: notation,
      nextTurn: newState.currentTurn == PlayerColor.white ? 'white' : 'gold',
      whiteTime: newState.whiteTimeRemaining,
      goldTime: newState.goldTimeRemaining,
      lastMoveFrom: _positionToString(move.from),
      lastMoveTo: _positionToString(move.to),
    );
  }

  String _moveToNotation(Move move) {
    final from = _positionToString(move.from);
    final to = _positionToString(move.to);
    final separator = move.isCapture ? 'x' : '-';
    return '$from$separator$to';
  }

  String _positionToString(Position pos) {
    final col = String.fromCharCode('a'.codeUnitAt(0) + pos.col);
    final row = (pos.row + 1).toString();
    return '$col$row';
  }

  void _handleGameOver(GameState gameState) {
    String result;
    if (gameState.result == GameResult.whiteWins) {
      result = 'white';
    } else if (gameState.result == GameResult.goldWins) {
      result = 'gold';
    } else {
      result = 'draw';
    }
    
    _repository!.endGame(roomId: widget.roomId, result: result);
    _showGameOverDialog(gameState);
  }

  void _handleRemoteGameEnd(String result) {
    if (_currentGameState?.isGameOver == true) return;
    
    GameResult gameResult;
    if (result == 'white') {
      gameResult = GameResult.whiteWins;
    } else if (result == 'gold') {
      gameResult = GameResult.goldWins;
    } else {
      gameResult = GameResult.draw;
    }
    
    final newState = _currentGameState!.copyWith(result: gameResult);
    setState(() {
      _currentGameState = newState;
    });
    _showGameOverDialog(newState);
  }

  void _showGameOverDialog(GameState gameState) {
    String title;
    String message;
    
    final isLocalWinner = 
        (gameState.result == GameResult.whiteWins && _localPlayerColor == PlayerColor.white) ||
        (gameState.result == GameResult.goldWins && _localPlayerColor == PlayerColor.gold);
    
    if (gameState.result == GameResult.draw) {
      title = 'Draw';
      message = 'The game ended in a draw.';
    } else if (isLocalWinner) {
      title = '🎉 You Win!';
      message = 'Congratulations on your victory!';
    } else {
      title = 'Game Over';
      message = 'Your opponent wins. Better luck next time!';
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title, style: const TextStyle(color: AppColors.templeGold)),
        content: Text(message, style: const TextStyle(color: AppColors.textPrimary)),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop(); // Back to lobby
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.templeGold),
            child: const Text('Back to Lobby'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OnlineGameBloc, OnlineGameBlocState>(
      listenWhen: (previous, current) => 
          previous.currentRoom != current.currentRoom ||
          previous.playerId != current.playerId,
      listener: (context, state) {
        if (state.currentRoom != null && state.playerId != null && !_isGameInitialized) {
          _initGame(state.currentRoom!, state.playerId!);
        }
      },
      builder: (context, state) {
        if (!_isGameInitialized || _game == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: const Text('Online Game'),
              backgroundColor: AppColors.deepPurple,
            ),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.templeGold),
                  SizedBox(height: 16),
                  Text('Connecting...', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
          );
        }

        final room = state.currentRoom!;
        final gameState = _currentGameState ?? _game!.gameState;
        final isMyTurn = gameState.currentTurn == _localPlayerColor;
        
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(isMyTurn ? 'Your Turn' : "Opponent's Turn"),
            backgroundColor: isMyTurn ? AppColors.templeGold : AppColors.deepPurple,
            foregroundColor: isMyTurn ? AppColors.deepPurple : Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.exit_to_app),
                onPressed: () => _showLeaveConfirmation(context),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Opponent info (top)
                _buildOpponentInfo(room, gameState),
                
                // Counting widget for opponent
                CountingWidget(
                  gameState: gameState,
                  playerColor: _localPlayerColor == PlayerColor.white 
                      ? PlayerColor.gold 
                      : PlayerColor.white,
                  onStartBoardCounting: null,
                  onStartPieceCounting: null,
                  onStopCounting: null,
                  onDeclareDraw: null,
                ),
                
                // Chess board
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        child: GameWidget(game: _game!),
                      ),
                    ),
                  ),
                ),
                
                // Local player info (bottom)
                _buildLocalPlayerInfo(room, gameState),
                
                // Counting widget for local player
                CountingWidget(
                  gameState: gameState,
                  playerColor: _localPlayerColor!,
                  onStartBoardCounting: () => _startBoardCounting(_localPlayerColor!),
                  onStartPieceCounting: () => _startPieceCounting(_localPlayerColor!),
                  onStopCounting: _stopCounting,
                  onDeclareDraw: _declareDraw,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOpponentInfo(OnlineGameRoom room, GameState gameState) {
    final opponentColor = _localPlayerColor == PlayerColor.white 
        ? PlayerColor.gold 
        : PlayerColor.white;
    final opponentName = _localPlayerColor == PlayerColor.white 
        ? (room.guestPlayerName ?? 'Opponent')
        : (room.hostPlayerName ?? 'Opponent');
    
    return PlayerInfoCard(
      name: opponentName,
      color: opponentColor,
      isCurrentTurn: gameState.currentTurn == opponentColor,
      isInCheck: gameState.isCheck && gameState.currentTurn == opponentColor,
      timeRemaining: opponentColor == PlayerColor.white 
          ? gameState.whiteTimeRemaining 
          : gameState.goldTimeRemaining,
      capturedPieces: const [],
    );
  }

  Widget _buildLocalPlayerInfo(OnlineGameRoom room, GameState gameState) {
    final localName = _localPlayerColor == PlayerColor.white 
        ? (room.hostPlayerName ?? 'You')
        : (room.guestPlayerName ?? 'You');
    
    return PlayerInfoCard(
      name: '$localName (You)',
      color: _localPlayerColor!,
      isCurrentTurn: gameState.currentTurn == _localPlayerColor,
      isInCheck: gameState.isCheck && gameState.currentTurn == _localPlayerColor,
      timeRemaining: _localPlayerColor == PlayerColor.white 
          ? gameState.whiteTimeRemaining 
          : gameState.goldTimeRemaining,
      capturedPieces: const [],
    );
  }

  void _showLeaveConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Leave Game?', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'If you leave, you will forfeit the game.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Stay'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<OnlineGameBloc>().add(const LeaveRoomRequested());
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  void _startBoardCounting(PlayerColor escapingPlayer) {
    final newState = _rules.startBoardHonorCounting(_currentGameState!, escapingPlayer);
    _game!.updateGameState(newState);
  }

  void _startPieceCounting(PlayerColor escapingPlayer) {
    final newState = _rules.startPieceHonorCounting(_currentGameState!, escapingPlayer);
    _game!.updateGameState(newState);
  }

  void _stopCounting() {
    final newState = _rules.stopCounting(_currentGameState!);
    _game!.updateGameState(newState);
  }

  void _declareDraw() {
    final newState = _rules.declareDraw(_currentGameState!);
    _game!.updateGameState(newState);
  }
}

/// Chess game for online play with remote move support
class OnlineChessGame extends FlameGame {
  final GameState initialState;
  final PlayerColor localPlayerColor;
  final void Function(Move move, GameState newState)? onMoveMade;
  final void Function(GameState)? onGameStateChanged;

  GameState _gameState;
  late BoardComponent _board;
  final GameRules _rules = const GameRules();
  final MoveGenerator _moveGenerator = const MoveGenerator();

  Position? _selectedPosition;
  List<Move> _validMoves = [];
  Timer? _timer;

  OnlineChessGame({
    required this.initialState,
    required this.localPlayerColor,
    this.onMoveMade,
    this.onGameStateChanged,
  }) : _gameState = initialState;

  GameState get gameState => _gameState;

  void updateGameState(GameState newState) {
    _gameState = newState;
    onGameStateChanged?.call(_gameState);
  }

  /// Apply a move received from the remote opponent
  void applyRemoteMove(Move move) {
    _gameState = _rules.applyMove(_gameState, move);
    _board.animateMove(move);
    _board.setLastMove(move.from, move.to);
    _board.syncPieces(_gameState.board);
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
    // Only allow moves when it's local player's turn
    if (_gameState.currentTurn != localPlayerColor) return;
    
    final piece = _gameState.board.getPiece(position);

    if (_selectedPosition != null) {
      final move = _validMoves.where((m) => m.to == position).firstOrNull;
      
      if (move != null) {
        _executeMove(move);
        return;
      }
    }

    if (piece != null && piece.color == localPlayerColor) {
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
    final newState = _rules.applyMove(_gameState, move);
    _gameState = newState;
    
    _clearSelection();
    _board.animateMove(move);
    _board.setLastMove(move.from, move.to);
    
    // Notify parent about the move
    onMoveMade?.call(move, newState);
    onGameStateChanged?.call(_gameState);
  }
}
