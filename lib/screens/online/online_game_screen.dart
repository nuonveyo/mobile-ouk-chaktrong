import 'dart:async' show Timer, StreamSubscription;
import 'package:flame/game.dart';
import 'package:flame/components.dart' hide Timer;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/game_constants.dart';
import '../../core/localization/app_strings.dart';
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
  StreamSubscription? _roomSubscription;
  OnlineGameRepository? _repository;
  
  // Use ValueNotifier for granular UI updates
  final ValueNotifier<GameState?> _gameStateNotifier = ValueNotifier(null);
  final ValueNotifier<bool> _isMyTurnNotifier = ValueNotifier(false);
  
  // Store room data without triggering widget rebuilds
  OnlineGameRoom? _room;
  
  String? _localPlayerId;
  PlayerColor? _localPlayerColor;
  bool _isGameInitialized = false;
  bool _gameOverDialogShown = false;

  @override
  void initState() {
    super.initState();
    _repository = OnlineGameRepository();
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();
    _gameStateNotifier.dispose();
    _isMyTurnNotifier.dispose();
    super.dispose();
  }

  void _initGame(OnlineGameRoom room, String localPlayerId) {
    if (_isGameInitialized) return;
    _isGameInitialized = true;
    
    _room = room;  // Store room locally
    _localPlayerId = localPlayerId;
    _localPlayerColor = room.hostPlayerId == localPlayerId 
        ? PlayerColor.white 
        : PlayerColor.gold;

    GameState initialState = GameState.initial(timeControl: room.timeControl);
    
    if (room.gameData != null && room.gameData!.moves.isNotEmpty) {
      initialState = _rebuildStateFromMoves(room.gameData!.moves, room.gameData!);
    }

    _game = OnlineChessGame(
      initialState: initialState,
      localPlayerColor: _localPlayerColor!,
      onMoveMade: _onLocalMoveMade,
      onGameStateChanged: _onGameStateChanged,
    );
    
    _gameStateNotifier.value = initialState;
    _isMyTurnNotifier.value = initialState.currentTurn == _localPlayerColor;
    
    // Force one setState to show the game board
    setState(() {});
    
    _startListeningToRoom();
  }

  // Optimized: Only update notifiers, no full rebuild
  void _onGameStateChanged(GameState gameState) {
    _gameStateNotifier.value = gameState;
    _isMyTurnNotifier.value = gameState.currentTurn == _localPlayerColor;
    
    if (gameState.isGameOver && !_gameOverDialogShown) {
      _gameOverDialogShown = true;
      _handleGameOver(gameState);
    }
  }

  GameState _rebuildStateFromMoves(List<String> moves, OnlineGameData gameData) {
    GameState state = GameState.initial(timeControl: 600);
    
    for (final moveNotation in moves) {
      final move = _parseMoveNotation(moveNotation, state.board, state.currentTurn);
      if (move != null) {
        state = _rules.applyMove(state, move);
      }
    }
    
    return state.copyWith(
      whiteTimeRemaining: gameData.whiteTimeRemaining,
      goldTimeRemaining: gameData.goldTimeRemaining,
    );
  }

  Move? _parseMoveNotation(String notation, BoardState board, PlayerColor turn) {
    try {
      // Check for promotion suffix (=M)
      bool isPromotion = notation.contains('=M');
      String cleanNotation = notation.replaceAll('=M', '');
      
      final parts = cleanNotation.contains('x') 
          ? cleanNotation.split('x') 
          : cleanNotation.split('-');
      
      if (parts.length != 2) return null;
      
      final from = _parsePosition(parts[0]);
      final to = _parsePosition(parts[1]);
      
      if (from == null || to == null) return null;
      
      final piece = board.getPiece(from);
      if (piece == null) return null;
      
      // If promotion, create the promoted piece (maiden)
      Piece? promotedTo;
      if (isPromotion) {
        promotedTo = Piece(type: PieceType.maiden, color: piece.color);
      }
      
      return Move(
        from: from,
        to: to,
        piece: piece,
        capturedPiece: board.getPiece(to),
        isPromotion: isPromotion,
        promotedTo: promotedTo,
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
        
        final gameData = room.gameData;
        if (gameData != null && gameData.moves.isNotEmpty) {
          final expectedMoves = _gameStateNotifier.value?.moveHistory.length ?? 0;
          
          if (gameData.moves.length > expectedMoves) {
            for (int i = expectedMoves; i < gameData.moves.length; i++) {
              _applyRemoteMove(gameData.moves[i]);
            }
          }
        }
        
        if (room.isFinished && gameData?.result != null && !_gameOverDialogShown) {
          _handleRemoteGameEnd(gameData!.result!);
        }
      },
      onError: (error) => debugPrint('Room subscription error: $error'),
    );
  }

  void _applyRemoteMove(String moveNotation) {
    if (_game == null || _gameStateNotifier.value == null) return;
    
    final move = _parseMoveNotation(
      moveNotation, 
      _gameStateNotifier.value!.board, 
      _gameStateNotifier.value!.currentTurn,
    );
    
    if (move != null) {
      _game!.applyRemoteMove(move);
    }
  }

  void _onLocalMoveMade(Move move, GameState newState) {
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
    String notation = '$from${move.isCapture ? 'x' : '-'}$to';
    
    // Add promotion suffix: =M for maiden (promoted fish)
    if (move.isPromotion && move.promotedTo != null) {
      notation += '=M';  // M for maiden
    }
    
    return notation;
  }

  String _positionToString(Position pos) {
    return '${String.fromCharCode('a'.codeUnitAt(0) + pos.col)}${pos.row + 1}';
  }

  void _handleGameOver(GameState gameState) {
    String result = gameState.result == GameResult.whiteWins ? 'white'
        : gameState.result == GameResult.goldWins ? 'gold' : 'draw';
    
    _repository!.endGame(roomId: widget.roomId, result: result);
    _showGameOverDialog(gameState);
  }

  void _handleRemoteGameEnd(String result) {
    _gameOverDialogShown = true;
    
    GameResult gameResult = result == 'white' ? GameResult.whiteWins
        : result == 'gold' ? GameResult.goldWins : GameResult.draw;
    
    final newState = _gameStateNotifier.value!.copyWith(result: gameResult);
    _gameStateNotifier.value = newState;
    _showGameOverDialog(newState);
  }

  void _showGameOverDialog(GameState gameState) async {
    final isLocalWinner = 
        (gameState.result == GameResult.whiteWins && _localPlayerColor == PlayerColor.white) ||
        (gameState.result == GameResult.goldWins && _localPlayerColor == PlayerColor.gold);
    
    String title = gameState.result == GameResult.draw ? appStrings.drawResult
        : isLocalWinner ? '🎉 ${appStrings.youWin}' : appStrings.gameOver;
    String message = gameState.result == GameResult.draw ? appStrings.gameEndedInDraw
        : isLocalWinner ? appStrings.congratulations : appStrings.opponentWins;
    
    // Award points for winning
    if (isLocalWinner) {
      final pointsAwarded = await UserRepository().awardWin();
      message += '\n\n${appStrings.pointsAwarded(pointsAwarded)}';
    }
    
    if (!mounted) return;
    
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
              Navigator.of(ctx).pop(); // Close dialog
              context.go('/lobby'); // Navigate back to lobby using GoRouter
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.templeGold),
            child: Text(appStrings.backToLobby),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If game is initialized, don't use BlocConsumer at all - prevents rebuilds
    if (_isGameInitialized && _game != null && _room != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(),
        body: SafeArea(child: _buildGameContent()),
      );
    }
    
    // Only use BlocListener during initialization phase
    return BlocListener<OnlineGameBloc, OnlineGameBlocState>(
      listenWhen: (prev, curr) => prev.currentRoom != curr.currentRoom || prev.playerId != curr.playerId,
      listener: (context, state) {
        if (state.currentRoom != null && state.playerId != null && !_isGameInitialized) {
          _initGame(state.currentRoom!, state.playerId!);
        }
      },
      child: _buildLoadingScreen(),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Online Game'), backgroundColor: AppColors.deepPurple),
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

  // AppBar that rebuilds only when turn changes
  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: ValueListenableBuilder<bool>(
        valueListenable: _isMyTurnNotifier,
        builder: (context, isMyTurn, _) => AppBar(
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
      ),
    );
  }

  Widget _buildGameContent() {
    return Column(
      children: [
        // Opponent info - uses ValueListenableBuilder
        _buildOpponentInfoCard(_room!),
        
        // Opponent counting widget
        _buildCountingWidget(isOpponent: true),
        
        // Chess board - static, doesn't need rebuilding
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: RepaintBoundary(
                child: Container(
                  margin: const EdgeInsets.all(8),
                  child: GameWidget(game: _game!),
                ),
              ),
            ),
          ),
        ),
        
        // Local player info
        _buildLocalPlayerInfoCard(_room!),
        
        // Local counting widget
        _buildCountingWidget(isOpponent: false),
      ],
    );
  }

  Widget _buildOpponentInfoCard(OnlineGameRoom room) {
    final opponentColor = _localPlayerColor == PlayerColor.white ? PlayerColor.gold : PlayerColor.white;
    final opponentName = _localPlayerColor == PlayerColor.white 
        ? (room.guestPlayerName ?? 'Opponent')
        : (room.hostPlayerName ?? 'Opponent');
    
    return ValueListenableBuilder<GameState?>(
      valueListenable: _gameStateNotifier,
      builder: (context, gameState, _) {
        if (gameState == null) return const SizedBox.shrink();
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
      },
    );
  }

  Widget _buildLocalPlayerInfoCard(OnlineGameRoom room) {
    final localName = _localPlayerColor == PlayerColor.white 
        ? (room.hostPlayerName ?? 'You')
        : (room.guestPlayerName ?? 'You');
    
    return ValueListenableBuilder<GameState?>(
      valueListenable: _gameStateNotifier,
      builder: (context, gameState, _) {
        if (gameState == null) return const SizedBox.shrink();
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
      },
    );
  }

  Widget _buildCountingWidget({required bool isOpponent}) {
    final playerColor = isOpponent
        ? (_localPlayerColor == PlayerColor.white ? PlayerColor.gold : PlayerColor.white)
        : _localPlayerColor!;
    
    return ValueListenableBuilder<GameState?>(
      valueListenable: _gameStateNotifier,
      builder: (context, gameState, _) {
        if (gameState == null) return const SizedBox.shrink();
        return CountingWidget(
          gameState: gameState,
          playerColor: playerColor,
          onStartBoardCounting: isOpponent ? null : () => _startBoardCounting(playerColor),
          onStartPieceCounting: isOpponent ? null : () => _startPieceCounting(playerColor),
          onStopCounting: isOpponent ? null : _stopCounting,
          onDeclareDraw: isOpponent ? null : _declareDraw,
        );
      },
    );
  }

  void _showLeaveConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(appStrings.leaveGame, style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(appStrings.ifYouLeaveForfeit, style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(appStrings.stay)),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop(); // Close dialog
              context.read<OnlineGameBloc>().add(const LeaveRoomRequested());
              context.go('/lobby'); // Navigate back to lobby using GoRouter
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: Text(appStrings.leave),
          ),
        ],
      ),
    );
  }

  void _startBoardCounting(PlayerColor escapingPlayer) {
    final newState = _rules.startBoardHonorCounting(_gameStateNotifier.value!, escapingPlayer);
    _game!.updateGameState(newState);
  }

  void _startPieceCounting(PlayerColor escapingPlayer) {
    final newState = _rules.startPieceHonorCounting(_gameStateNotifier.value!, escapingPlayer);
    _game!.updateGameState(newState);
  }

  void _stopCounting() {
    final newState = _rules.stopCounting(_gameStateNotifier.value!);
    _game!.updateGameState(newState);
  }

  void _declareDraw() {
    final newState = _rules.declareDraw(_gameStateNotifier.value!);
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

  void applyRemoteMove(Move move) {
    _gameState = _rules.applyMove(_gameState, move);
    _board.animateMove(move);
    _board.setLastMove(move.from, move.to);
    // Don't call syncPieces - animateMove already handles piece updates smoothly
    onGameStateChanged?.call(_gameState);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _board = BoardComponent(
      boardSize: size.x < size.y ? size.x : size.y,
      onSquareTapped: _onSquareTapped,
      flipBoard: localPlayerColor == PlayerColor.gold, // Flip for Gold player
    );
    
    _board.position = Vector2(
      (size.x - _board.boardSize) / 2,
      (size.y - _board.boardSize) / 2,
    );

    add(_board);
    _board.syncPieces(_gameState.board);
    
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
    
    onMoveMade?.call(move, newState);
    onGameStateChanged?.call(_gameState);
  }
}
