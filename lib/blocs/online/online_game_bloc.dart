import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/models.dart';
import '../../repositories/repositories.dart';
import 'online_game_event.dart';
import 'online_game_state.dart';

export 'online_game_event.dart';
export 'online_game_state.dart';

/// BLoC for managing online multiplayer games
class OnlineGameBloc extends Bloc<OnlineGameEvent, OnlineGameBlocState> {
  final AuthRepository _authRepository;
  final OnlineGameRepository _gameRepository;
  
  StreamSubscription? _roomSubscription;
  StreamSubscription? _availableRoomsSubscription;

  OnlineGameBloc({
    required AuthRepository authRepository,
    required OnlineGameRepository gameRepository,
  })  : _authRepository = authRepository,
        _gameRepository = gameRepository,
        super(OnlineGameBlocState.initial()) {
    on<CreateRoomRequested>(_onCreateRoom);
    on<JoinRoomRequested>(_onJoinRoom);
    on<LeaveRoomRequested>(_onLeaveRoom);
    on<RoomUpdated>(_onRoomUpdated);
    on<OnlineMoveExecuted>(_onMoveExecuted);
    on<OnlineGameEnded>(_onGameEnded);
    on<RefreshRoomsRequested>(_onRefreshRooms);
    
    // Sign in and then start listening to rooms
    _initializeAndListen();
  }

  Future<void> _initializeAndListen() async {
    try {
      // Ensure user is signed in before listening to Firestore
      final user = await _authRepository.ensureSignedIn();
      emit(state.copyWith(playerId: user.uid));
      
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
  }

  Future<void> _onCreateRoom(
    CreateRoomRequested event,
    Emitter<OnlineGameBlocState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final user = await _authRepository.ensureSignedIn();
      
      final room = await _gameRepository.createRoom(
        hostPlayerId: user.uid,
        hostPlayerName: 'Player ${user.uid.substring(0, 4)}',
        timeControl: event.timeControl,
      );

      emit(state.copyWith(
        currentRoom: room,
        playerId: user.uid,
        isHost: true,
        isLoading: false,
      ));

      // Start listening to room updates
      _startListeningToRoom(room.id);
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to create room: $e',
      ));
    }
  }

  Future<void> _onJoinRoom(
    JoinRoomRequested event,
    Emitter<OnlineGameBlocState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final user = await _authRepository.ensureSignedIn();
      
      final room = await _gameRepository.joinRoom(
        roomId: event.roomId,
        guestPlayerId: user.uid,
        guestPlayerName: 'Player ${user.uid.substring(0, 4)}',
      );

      if (room == null) {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Room not available',
        ));
        return;
      }

      emit(state.copyWith(
        currentRoom: room,
        playerId: user.uid,
        isHost: false,
        isLoading: false,
      ));

      // Start listening to room updates
      _startListeningToRoom(room.id);
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to join room: $e',
      ));
    }
  }

  void _startListeningToRoom(String roomId) {
    _roomSubscription?.cancel();
    _roomSubscription = _gameRepository.watchRoom(roomId).listen(
      (room) => add(RoomUpdated(room)),
      onError: (error) {
        emit(state.copyWith(errorMessage: 'Connection error: $error'));
      },
    );
  }

  void _onRoomUpdated(
    RoomUpdated event,
    Emitter<OnlineGameBlocState> emit,
  ) {
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
    if (state.currentRoom != null) {
      await _gameRepository.leaveRoom(state.currentRoom!.id);
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
}
