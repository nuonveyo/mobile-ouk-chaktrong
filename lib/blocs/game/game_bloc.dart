import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/models.dart';
import '../../logic/logic.dart';
import '../../core/constants/game_constants.dart';
import 'game_event.dart';
import 'game_state.dart';

export 'game_event.dart';
export 'game_state.dart';

/// Game BLoC for managing chess game state
class GameBloc extends Bloc<GameEvent, GameBlocState> {
  final GameRules _rules = const GameRules();
  final MoveGenerator _moveGenerator = const MoveGenerator();
  
  Timer? _timer;
  final int _timeControlSeconds;

  GameBloc({int timeControlSeconds = 600})
      : _timeControlSeconds = timeControlSeconds,
        super(GameBlocState.initial(timeControlSeconds: timeControlSeconds)) {
    on<GameStarted>(_onGameStarted);
    on<SquareTapped>(_onSquareTapped);
    on<MoveExecuted>(_onMoveExecuted);
    on<UndoRequested>(_onUndoRequested);
    on<ResignRequested>(_onResignRequested);
    on<TimerTicked>(_onTimerTicked);
    on<GamePaused>(_onGamePaused);
    on<GameResumed>(_onGameResumed);
    on<DrawOffered>(_onDrawOffered);
    on<DrawAccepted>(_onDrawAccepted);
    on<DrawDeclined>(_onDrawDeclined);
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!state.isPaused && !state.isGameOver) {
        add(const TimerTicked());
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _onGameStarted(GameStarted event, Emitter<GameBlocState> emit) {
    emit(GameBlocState.initial(timeControlSeconds: event.timeControlSeconds));
    _startTimer();
  }

  void _onSquareTapped(SquareTapped event, Emitter<GameBlocState> emit) {
    if (state.isGameOver || state.isPaused) return;

    final position = event.position;
    final piece = state.gameState.board.getPiece(position);

    // If we have a selected piece and tapped a valid move destination
    if (state.selectedPosition != null) {
      final move = state.getMoveToPosition(position);
      if (move != null) {
        add(MoveExecuted(move));
        return;
      }
    }

    // Select a piece if it belongs to current player
    if (piece != null && piece.color == state.currentTurn) {
      final validMoves = _moveGenerator.getValidMoves(state.gameState.board, position);
      emit(state.copyWith(
        selectedPosition: position,
        validMoves: validMoves,
      ));
    } else {
      // Clear selection
      emit(state.copyWith(clearSelection: true));
    }
  }

  void _onMoveExecuted(MoveExecuted event, Emitter<GameBlocState> emit) {
    if (state.isGameOver) return;

    final newGameState = _rules.applyMove(state.gameState, event.move);
    
    emit(state.copyWith(
      gameState: newGameState,
      clearSelection: true,
      drawOffered: false,
    ));

    // Stop timer if game is over
    if (newGameState.isGameOver) {
      _stopTimer();
    }
  }

  void _onUndoRequested(UndoRequested event, Emitter<GameBlocState> emit) {
    if (state.gameState.moveHistory.isEmpty) return;

    final newGameState = _rules.undoMove(state.gameState);
    if (newGameState != null) {
      emit(state.copyWith(
        gameState: newGameState,
        clearSelection: true,
      ));
    }
  }

  void _onResignRequested(ResignRequested event, Emitter<GameBlocState> emit) {
    if (state.isGameOver) return;

    final result = state.currentTurn == PlayerColor.white
        ? GameResult.goldWins
        : GameResult.whiteWins;

    emit(state.copyWith(
      gameState: state.gameState.copyWith(result: result),
      clearSelection: true,
    ));
    
    _stopTimer();
  }

  void _onTimerTicked(TimerTicked event, Emitter<GameBlocState> emit) {
    if (state.isGameOver || state.isPaused) return;

    final newGameState = _rules.tickTime(state.gameState);
    emit(state.copyWith(gameState: newGameState));

    // Check if time ran out
    if (newGameState.isGameOver) {
      _stopTimer();
    }
  }

  void _onGamePaused(GamePaused event, Emitter<GameBlocState> emit) {
    emit(state.copyWith(isPaused: true));
  }

  void _onGameResumed(GameResumed event, Emitter<GameBlocState> emit) {
    emit(state.copyWith(isPaused: false));
  }

  void _onDrawOffered(DrawOffered event, Emitter<GameBlocState> emit) {
    if (state.isGameOver) return;
    emit(state.copyWith(drawOffered: true));
  }

  void _onDrawAccepted(DrawAccepted event, Emitter<GameBlocState> emit) {
    if (!state.drawOffered || state.isGameOver) return;
    
    emit(state.copyWith(
      gameState: state.gameState.copyWith(result: GameResult.draw),
      drawOffered: false,
    ));
    
    _stopTimer();
  }

  void _onDrawDeclined(DrawDeclined event, Emitter<GameBlocState> emit) {
    emit(state.copyWith(drawOffered: false));
  }
}
