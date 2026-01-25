import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repositories/repositories.dart';
import 'online_game_event.dart';
import 'online_game_state.dart';

export 'online_game_event.dart';
export 'online_game_state.dart';

/// BLoC for managing online multiplayer games
class OnlineGameBloc extends Bloc<OnlineGameEvent, OnlineGameBlocState> {
  final AuthRepository _authRepository;
  final OnlineGameRepository _gameRepository;
  final UserRepository _userRepository;

  StreamSubscription? _roomSubscription;
  StreamSubscription? _availableRoomsSubscription;
  StreamSubscription? _activeGamesSubscription;

  OnlineGameBloc({
    required AuthRepository authRepository,
    required OnlineGameRepository gameRepository,
    UserRepository? userRepository,
  }) : _authRepository = authRepository,
       _gameRepository = gameRepository,
       _userRepository = userRepository ?? UserRepository(),
       super(OnlineGameBlocState.initial()) {
    on<CreateRoomRequested>(_onCreateRoom);
    on<JoinRoomRequested>(_onJoinRoom);
    on<LeaveRoomRequested>(_onLeaveRoom);
    on<RoomUpdated>(_onRoomUpdated);
    on<OnlineMoveExecuted>(_onMoveExecuted);
    on<OnlineGameEnded>(_onGameEnded);
    on<RefreshRoomsRequested>(_onRefreshRooms);
    on<WatchRoomRequested>(_onWatchRoom);
    on<DeductPointsRequested>(_deductUserPoint);
    on<WatchAsSpectatorRequested>(_onWatchAsSpectator);
    on<LeaveSpectatingRequested>(_onLeaveSpectating);
    on<ActiveGamesUpdated>(_onActiveGamesUpdated);

    // Sign in and then start listening to rooms
    _initializeAndListen();
  }

  Future<void> _initializeAndListen() async {
    try {
      // Ensure user is signed in before listening to Firestore
      final user = await _authRepository.ensureSignedIn();
      final localUser = await _userRepository.getUser();
      emit(state.copyWith(playerId: user.uid, points: localUser.points));

      // Now safe to listen to rooms
      _startListeningToRooms();
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to sign in: $e'));
    }
  }

  @override
  Future<void> close() {
    _roomSubscription?.cancel();
    _availableRoomsSubscription?.cancel();
    _activeGamesSubscription?.cancel();
    return super.close();
  }

  void _startListeningToRooms() {
    _availableRoomsSubscription?.cancel();
    _availableRoomsSubscription = _gameRepository.getAvailableRooms().listen(
      (rooms) {
        if (!state.isInRoom) {
          emit(state.copyWith(availableRooms: rooms));
        }
      },
      onError: (error) {
        emit(state.copyWith(errorMessage: 'Failed to load rooms: $error'));
      },
    );
    
    // Also listen to active games for spectating
    _startListeningToActiveGames();
  }

  void _startListeningToActiveGames() {
    _activeGamesSubscription?.cancel();
    _activeGamesSubscription = _gameRepository.getActiveGames().listen(
      (games) => add(ActiveGamesUpdated(games)),
      onError: (error) {
        // Silently handle - not critical if active games fail
      },
    );
  }

  Future<void> _onCreateRoom(
    CreateRoomRequested event,
    Emitter<OnlineGameBlocState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final user = await _authRepository.ensureSignedIn();

      // Get player name from local database
      final localUser = await _userRepository.getUser();
      final playerName = localUser.name;

      final room = await _gameRepository.createRoom(
        hostPlayerId: user.uid,
        hostPlayerName: playerName,
        timeControl: event.timeControl,
      );

      emit(
        state.copyWith(
          currentRoom: room,
          playerId: user.uid,
          isHost: true,
          isLoading: false,
        ),
      );

      // Start listening to room updates
      _startListeningToRoom(room.id);
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to create room: $e',
        ),
      );
    }
  }

  Future<void> _onJoinRoom(
    JoinRoomRequested event,
    Emitter<OnlineGameBlocState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final user = await _authRepository.ensureSignedIn();

      // Get player name from local database
      final localUser = await _userRepository.getUser();
      final playerName = localUser.name;

      final room = await _gameRepository.joinRoom(
        roomId: event.roomId,
        guestPlayerId: user.uid,
        guestPlayerName: playerName,
      );

      if (room == null) {
        emit(
          state.copyWith(isLoading: false, errorMessage: 'Room not available'),
        );
        return;
      }

      emit(
        state.copyWith(
          currentRoom: room,
          playerId: user.uid,
          isHost: false,
          isLoading: false,
        ),
      );

      // Start listening to room updates
      _startListeningToRoom(room.id);
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to join room: $e',
        ),
      );
    }
  }

  void _startListeningToRoom(String roomId) {
    _roomSubscription?.cancel();
    _roomSubscription = _gameRepository
        .watchRoom(roomId)
        .listen(
          (room) => add(RoomUpdated(room)),
          onError: (error) {
            emit(state.copyWith(errorMessage: 'Connection error: $error'));
          },
        );
  }

  void _onRoomUpdated(RoomUpdated event, Emitter<OnlineGameBlocState> emit) {
    if (event.room == null) {
      // Room was deleted
      emit(state.copyWith(clearRoom: true));
      _roomSubscription?.cancel();
      _startListeningToRooms();
    } else {
      emit(state.copyWith(currentRoom: event.room));
    }
  }

  Future<void> _onLeaveRoom(
    LeaveRoomRequested event,
    Emitter<OnlineGameBlocState> emit,
  ) async {
    if (state.currentRoom != null && state.playerId != null) {
      await _gameRepository.leaveRoom(state.currentRoom!.id, state.playerId!);
    }

    _roomSubscription?.cancel();
    emit(state.copyWith(clearRoom: true));
    _startListeningToRooms();
  }

  Future<void> _onMoveExecuted(
    OnlineMoveExecuted event,
    Emitter<OnlineGameBlocState> emit,
  ) async {
    if (state.currentRoom == null) return;

    final nextTurn = state.playerColor == 'white' ? 'gold' : 'white';

    await _gameRepository.makeMove(
      roomId: state.currentRoom!.id,
      moveNotation: event.moveNotation,
      nextTurn: nextTurn,
      whiteTime: event.whiteTime,
      goldTime: event.goldTime,
      lastMoveFrom: event.lastMoveFrom,
      lastMoveTo: event.lastMoveTo,
    );
  }

  Future<void> _onGameEnded(
    OnlineGameEnded event,
    Emitter<OnlineGameBlocState> emit,
  ) async {
    if (state.currentRoom == null) return;

    await _gameRepository.endGame(
      roomId: state.currentRoom!.id,
      result: event.result,
    );
  }

  Future<void> _onRefreshRooms(
    RefreshRoomsRequested event,
    Emitter<OnlineGameBlocState> emit,
  ) async {
    // Re-authenticate and listen
    await _initializeAndListen();
  }

  /// Watch a room that's already been joined (used by game screen)
  Future<void> _onWatchRoom(
    WatchRoomRequested event,
    Emitter<OnlineGameBlocState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      // Ensure user is signed in
      final user = await _authRepository.ensureSignedIn();
      emit(state.copyWith(playerId: user.uid));

      // Start listening to the room - the room data will come from the stream
      _startListeningToRoom(event.roomId);

      // Determine if we're the host based on the room data
      // This will be updated when RoomUpdated event is received
      emit(state.copyWith(isLoading: false));
    } catch (e) {
      emit(
        state.copyWith(isLoading: false, errorMessage: 'Failed to connect: $e'),
      );
    }
  }

  Future<void> _deductUserPoint(
    DeductPointsRequested event,
    Emitter<OnlineGameBlocState> emit,
  ) async {
    if (state.points == 0) return;
    final deductPoints = state.points - event.points;
    await _userRepository.updateProfile(points: deductPoints);
    emit(state.copyWith(points: deductPoints));
  }

  /// Watch a game as a spectator (read-only)
  Future<void> _onWatchAsSpectator(
    WatchAsSpectatorRequested event,
    Emitter<OnlineGameBlocState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      // Join as spectator (increment count)
      await _gameRepository.joinAsSpectator(event.roomId);

      emit(state.copyWith(
        isSpectating: true,
        isLoading: false,
      ));

      // Start listening to room updates
      _startListeningToRoom(event.roomId);
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to join as spectator: $e',
      ));
    }
  }

  /// Leave spectating a game
  Future<void> _onLeaveSpectating(
    LeaveSpectatingRequested event,
    Emitter<OnlineGameBlocState> emit,
  ) async {
    if (state.currentRoom != null) {
      await _gameRepository.leaveAsSpectator(state.currentRoom!.id);
    }

    _roomSubscription?.cancel();
    emit(state.copyWith(clearRoom: true, isSpectating: false));
    _startListeningToRooms();
  }

  /// Handle active games list update
  void _onActiveGamesUpdated(
    ActiveGamesUpdated event,
    Emitter<OnlineGameBlocState> emit,
  ) {
    if (!state.isInRoom && !state.isSpectating) {
      emit(state.copyWith(activeGames: event.games));
    }
  }
}
