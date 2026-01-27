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
  List<Object?> get props => [
    moveNotation,
    lastMoveFrom,
    lastMoveTo,
    whiteTime,
    goldTime,
  ];
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

/// Update user point when send reaction
class DeductPointsRequested extends OnlineGameEvent {
  final int points;

  const DeductPointsRequested({this.points = 0});

  @override
  List<Object?> get props => [points];
}

/// Watch a game as a spectator (read-only)
class WatchAsSpectatorRequested extends OnlineGameEvent {
  final String roomId;

  const WatchAsSpectatorRequested(this.roomId);

  @override
  List<Object?> get props => [roomId];
}

/// Leave spectating a game
class LeaveSpectatingRequested extends OnlineGameEvent {
  const LeaveSpectatingRequested();
}

/// Active games list updated (for spectating)
class ActiveGamesUpdated extends OnlineGameEvent {
  final List<OnlineGameRoom> games;

  const ActiveGamesUpdated(this.games);

  @override
  List<Object?> get props => [games];
}

/// Request to join a room (new flow - host must approve)
class RequestJoinRoomEvent extends OnlineGameEvent {
  final String roomId;

  const RequestJoinRoomEvent(this.roomId);

  @override
  List<Object?> get props => [roomId];
}

/// Host accepts a join request
class AcceptJoinRequestEvent extends OnlineGameEvent {
  final String roomId;

  const AcceptJoinRequestEvent(this.roomId);

  @override
  List<Object?> get props => [roomId];
}

/// Host declines a join request (cancels room)
class DeclineJoinRequestEvent extends OnlineGameEvent {
  final String roomId;

  const DeclineJoinRequestEvent(this.roomId);

  @override
  List<Object?> get props => [roomId];
}

/// Notification received that someone wants to join
class JoinRequestReceived extends OnlineGameEvent {
  final String roomId;
  final String guestName;

  const JoinRequestReceived({required this.roomId, required this.guestName});

  @override
  List<Object?> get props => [roomId, guestName];
}
