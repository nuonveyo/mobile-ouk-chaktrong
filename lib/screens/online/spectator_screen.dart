import 'dart:async' show StreamSubscription;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ouk_chaktrong/widgets/counting_widget.dart';

import '../../blocs/online/online_game_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/game_constants.dart';
import '../../core/localization/app_strings.dart';
import '../../game/components/board_component.dart';
import '../../logic/logic.dart';
import '../../models/models.dart';
import '../../repositories/repositories.dart';
import '../../widgets/player_info_card.dart';
import '../../widgets/reaction_display.dart';

/// Screen for spectating an online game (read-only)
class SpectatorScreen extends StatelessWidget {
  final String roomId;

  const SpectatorScreen({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OnlineGameBloc(
        authRepository: AuthRepository(),
        gameRepository: OnlineGameRepository(),
      )..add(WatchAsSpectatorRequested(roomId)),
      child: _SpectatorContent(roomId: roomId),
    );
  }
}

class _SpectatorContent extends StatefulWidget {
  final String roomId;

  const _SpectatorContent({required this.roomId});

  @override
  State<_SpectatorContent> createState() => _SpectatorContentState();
}

class _SpectatorContentState extends State<_SpectatorContent> {
  SpectatorChessGame? _game;
  final GameRules _rules = const GameRules();
  StreamSubscription? _roomSubscription;
  OnlineGameRepository? _repository;

  final ValueNotifier<GameState?> _gameStateNotifier = ValueNotifier(null);
  final ValueNotifier<int?> _reactionNotifier = ValueNotifier(null);
  
  OnlineGameRoom? _room;
  int? _lastReactionTimestamp; // To prevent showing same reaction twice
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
    _reactionNotifier.dispose();
    // Leave spectating when closing
    if (mounted) {
      context.read<OnlineGameBloc>().add(const LeaveSpectatingRequested());
    }
    super.dispose();
  }

  void _initGame(OnlineGameRoom room) {
    if (_isGameInitialized) return;
    _isGameInitialized = true;

    _room = room;

    GameState initialState = GameState.initial(timeControl: room.timeControl);

    if (room.gameData != null && room.gameData!.moves.isNotEmpty) {
      initialState = _rebuildStateFromMoves(
        room.gameData!.moves,
        room.gameData!,
      );
    }

    _game = SpectatorChessGame(
      initialState: initialState,
      onGameStateChanged: _onGameStateChanged,
    );

    _gameStateNotifier.value = initialState;

    setState(() {});

    _startListeningToRoom();
  }

  void _onGameStateChanged(GameState gameState) {
    _gameStateNotifier.value = gameState;

    if (gameState.isGameOver && !_gameOverDialogShown) {
      _gameOverDialogShown = true;
      _handleGameOver(gameState);
    }
  }

  GameState _rebuildStateFromMoves(
    List<String> moves,
    OnlineGameData gameData,
  ) {
    GameState state = GameState.initial(timeControl: 600);

    for (final moveNotation in moves) {
      final move = _parseMoveNotation(
        moveNotation,
        state.board,
        state.currentTurn,
      );
      if (move != null) {
        state = _rules.applyMove(state, move);
      }
    }

    return state.copyWith(
      whiteTimeRemaining: gameData.whiteTimeRemaining,
      goldTimeRemaining: gameData.goldTimeRemaining,
    );
  }

  Move? _parseMoveNotation(
    String notation,
    BoardState board,
    PlayerColor turn,
  ) {
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
    _roomSubscription = _repository!.watchRoom(widget.roomId).listen((room) {
      if (room == null) {
        // Room deleted
        if (mounted) context.go('/lobby');
        return;
      }

      _room = room;

      // Apply new moves from remote
      if (room.gameData != null && _game != null) {
        final remoteMoves = room.gameData!.moves;
        final localMoves = _gameStateNotifier.value?.moveHistory.length ?? 0;

        if (remoteMoves.length > localMoves) {
          // New moves from players
          for (int i = localMoves; i < remoteMoves.length; i++) {
            final currentState = _gameStateNotifier.value!;
            final move = _parseMoveNotation(
              remoteMoves[i],
              currentState.board,
              currentState.currentTurn,
            );
            if (move != null) {
              _game!.applyRemoteMove(move);
            }
          }
        }

        // Update time
        _gameStateNotifier.value = _gameStateNotifier.value?.copyWith(
          whiteTimeRemaining: room.gameData!.whiteTimeRemaining,
          goldTimeRemaining: room.gameData!.goldTimeRemaining,
        );

        // Handle remote game end
        if (room.isFinished && room.gameData?.result != null && !_gameOverDialogShown) {
          _handleRemoteGameEnd(room.gameData!.result!);
        }

        // Handle incoming reactions from players
        if (room.latestReactionCode != null &&
            room.latestReactionSender != null) {
          final reactionKey =
              room.latestReactionCode.hashCode ^
              room.latestReactionSender.hashCode;
          if (_lastReactionTimestamp != reactionKey) {
            _lastReactionTimestamp = reactionKey;
            _reactionNotifier.value = room.latestReactionCode;
          }
        }
      }
    });
  }

  void _handleRemoteGameEnd(String result) {
    _gameOverDialogShown = true;

    GameResult gameResult = result == 'white'
        ? GameResult.whiteWins
        : result == 'gold'
        ? GameResult.goldWins
        : GameResult.draw;

    final newState = _gameStateNotifier.value!.copyWith(result: gameResult);
    _gameStateNotifier.value = newState;
    _showGameOverDialog(newState);
  }

  void _handleGameOver(GameState gameState) {
    _showGameOverDialog(gameState);
  }

  void _showGameOverDialog(GameState gameState) {
    String title;
    String message;

    if (gameState.result == GameResult.whiteWins) {
      title = appStrings.checkmate;
      message = appStrings.whiteWins;
    } else if (gameState.result == GameResult.goldWins) {
      title = appStrings.checkmate;
      message = appStrings.goldWins;
    } else if (gameState.result == GameResult.draw) {
      title = appStrings.drawResult;
      message = appStrings.gameEndedInDraw;
    } else {
      title = appStrings.gameOver;
      message = '';
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
              Navigator.of(ctx).pop();
              context.go('/lobby');
            },
            child: Text(appStrings.backToLobby),
          ),
        ],
      ),
    );
  }

  void _showLeaveDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(appStrings.leaveGame, style: const TextStyle(color: AppColors.textPrimary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(appStrings.stay),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/lobby');
            },
            child: Text(appStrings.leave),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OnlineGameBloc, OnlineGameBlocState>(
      listenWhen: (previous, current) =>
          previous.currentRoom != current.currentRoom,
      listener: (context, state) {
        if (state.currentRoom != null && !_isGameInitialized) {
          _initGame(state.currentRoom!);
        }
      },
      buildWhen: (previous, current) =>
          previous.isLoading != current.isLoading ||
          previous.currentRoom != current.currentRoom,
      builder: (context, state) {
        if (state.isLoading || _game == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(title: Text(appStrings.spectating)),
            body: const Center(
              child: CircularProgressIndicator(color: AppColors.templeGold),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Row(
              children: [
                const Icon(Icons.live_tv, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Text(appStrings.spectating),
              ],
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _showLeaveDialog,
            ),
            actions: [
              // Spectator count badge
              if (_room != null && _room!.spectatorCount > 0)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.visibility, size: 18),
                      const SizedBox(width: 4),
                      Text('${_room!.spectatorCount}'),
                    ],
                  ),
                ),
            ],
          ),
          body: SafeArea(
            child: Stack(
              children: [
                ValueListenableBuilder<GameState?>(
                  valueListenable: _gameStateNotifier,
                  builder: (context, gameState, _) {
                    if (gameState == null) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.templeGold),
                      );
                    }

                    return Column(
                      children: [
                        // Gold player info (top)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: PlayerInfoCard(
                            name: _room?.guestPlayerName ?? 'Gold',
                            color: PlayerColor.gold,
                            isCurrentTurn: gameState.currentTurn == PlayerColor.gold,
                            isInCheck: gameState.isCheck && gameState.currentTurn == PlayerColor.gold,
                            timeRemaining: gameState.goldTimeRemaining,
                            showReaction: false, // Spectators can't send reactions
                          ),
                        ),

                        // Gold counting widget (read-only for spectators)
                        _buildSpectatorCountingWidget(gameState, PlayerColor.gold),

                        // Game board (read-only)
                        Expanded(
                          child: Center(
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: GameWidget(game: _game!),
                            ),
                          ),
                        ),

                        // White player info (bottom)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: PlayerInfoCard(
                            name: _room?.hostPlayerName ?? 'White',
                            color: PlayerColor.white,
                            isCurrentTurn: gameState.currentTurn == PlayerColor.white,
                            isInCheck: gameState.isCheck && gameState.currentTurn == PlayerColor.white,
                            timeRemaining: gameState.whiteTimeRemaining,
                            showReaction: false, // Spectators can't send reactions
                          ),
                        ),

                        // White counting widget (read-only for spectators)
                        _buildSpectatorCountingWidget(gameState, PlayerColor.white),
                      ],
                    );
                  },
                ),
                
                // Reaction display overlay
                ValueListenableBuilder<int?>(
                  valueListenable: _reactionNotifier,
                  builder: (context, reactionCode, _) {
                    if (reactionCode == null) return const SizedBox.shrink();

                    final isFromWhite = _room?.hostPlayerId == _room?.latestReactionSender;

                    return Positioned(
                      top: isFromWhite ? null : 100, // Top for gold, bottom for white
                      bottom: isFromWhite ? 100 : null,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: ReactionDisplay(
                          reactionCode: reactionCode,
                          isFromOpponent: false, // In spectator view, we just show it
                          onDismissed: () {
                            _reactionNotifier.value = null;
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSpectatorCountingWidget(GameState gameState, PlayerColor playerColor) {
    return CountingWidget(
      gameState: gameState,
      playerColor: playerColor,
      // Pass null for all callbacks to disable interaction for spectators
      onStartBoardCounting: null,
      onStartPieceCounting: null,
      onStopCounting: null,
      onDeclareDraw: null,
    );
  }
}

/// A read-only chess game for spectators
class SpectatorChessGame extends FlameGame {
  final GameState initialState;
  final void Function(GameState) onGameStateChanged;

  late BoardComponent _board;
  late GameState _gameState;
  final GameRules _rules = const GameRules();

  SpectatorChessGame({
    required this.initialState,
    required this.onGameStateChanged,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _gameState = initialState;

    _board = BoardComponent(
      boardSize: size.x < size.y ? size.x : size.y,
      onSquareTapped: (_) {}, // No interaction for spectators
    );

    _board.position = Vector2(
      (size.x - _board.boardSize) / 2,
      (size.y - _board.boardSize) / 2,
    );

    add(_board);
    _board.syncPieces(_gameState.board);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);

    if (children.whereType<BoardComponent>().isNotEmpty) {
      final newSize = size.x < size.y ? size.x : size.y;
      _board.resize(newSize);
      _board.position = Vector2(
        (size.x - _board.boardSize) / 2,
        (size.y - _board.boardSize) / 2,
      );
    }
  }

  /// Apply a move received from the server
  void applyRemoteMove(Move move) {
    _gameState = _rules.applyMove(_gameState, move);
    _board.syncPieces(_gameState.board);
    onGameStateChanged(_gameState);
  }
}
