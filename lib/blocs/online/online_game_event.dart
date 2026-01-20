import 'package:equatable/equatable.dart';
import '../../models/models.dart';

/// Base class for online game events
sealed class OnlineGameEvent extends Equatable {
  const OnlineGameEvent();

  @override
  List<Object?> get props => [];
}

/// Create a new game room
class CreateRoomRequested extends OnlineGameEvent {
  final int timeControl;
  
  const CreateRoomRequested({this.timeControl = 600});
  
  @override
  List<Object?> get props => [timeControl];
}

/// Join an existing room
class JoinRoomRequested extends OnlineGameEvent {
  final String roomId;
  
  const JoinRoomRequested(this.roomId);
  
  @override
  List<Object?> get props => [roomId];
}

/// Leave current room
class LeaveRoomRequested extends OnlineGameEvent {
  const LeaveRoomRequested();
}

/// Room data updated (from Firestore stream)
class RoomUpdated extends OnlineGameEvent {
  final OnlineGameRoom? room;
  
  const RoomUpdated(this.room);
  
  @override
  List<Object?> get props => [room];
}

/// Make a move in online game
class OnlineMoveExecuted extends OnlineGameEvent {
  final String moveNotation;
  final String lastMoveFrom;
  final String lastMoveTo;
  final int whiteTime;
  final int goldTime;
  
  const OnlineMoveExecuted({
    required this.moveNotation,
    required this.lastMoveFrom,
    required this.lastMoveTo,
    required this.whiteTime,
    required this.goldTime,
  });
  
  @override
  List<Object?> get props => [moveNotation, lastMoveFrom, lastMoveTo, whiteTime, goldTime];
}

/// End the online game
class OnlineGameEnded extends OnlineGameEvent {
  final String result; // 'white', 'gold', 'draw'
  
  const OnlineGameEnded(this.result);
  
  @override
  List<Object?> get props => [result];
}

/// Refresh available rooms list
class RefreshRoomsRequested extends OnlineGameEvent {
  const RefreshRoomsRequested();
}

/// Watch a room that's already been joined (for game screen)
class WatchRoomRequested extends OnlineGameEvent {
  final String roomId;
  
  const WatchRoomRequested(this.roomId);
  
  @override
  List<Object?> get props => [roomId];
}
