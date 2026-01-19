import 'package:equatable/equatable.dart';
import '../../models/models.dart';

/// Base class for all game events
sealed class GameEvent extends Equatable {
  const GameEvent();

  @override
  List<Object?> get props => [];
}

/// Initialize a new game
class GameStarted extends GameEvent {
  final int timeControlSeconds;

  const GameStarted({this.timeControlSeconds = 600});

  @override
  List<Object?> get props => [timeControlSeconds];
}

/// A square was tapped on the board
class SquareTapped extends GameEvent {
  final Position position;

  const SquareTapped(this.position);

  @override
  List<Object?> get props => [position];
}

/// Execute a move
class MoveExecuted extends GameEvent {
  final Move move;

  const MoveExecuted(this.move);

  @override
  List<Object?> get props => [move];
}

/// Undo the last move
class UndoRequested extends GameEvent {
  const UndoRequested();
}

/// Resign the game
class ResignRequested extends GameEvent {
  const ResignRequested();
}

/// Timer tick (called every second)
class TimerTicked extends GameEvent {
  const TimerTicked();
}

/// Pause the game timer
class GamePaused extends GameEvent {
  const GamePaused();
}

/// Resume the game timer
class GameResumed extends GameEvent {
  const GameResumed();
}

/// Offer a draw
class DrawOffered extends GameEvent {
  const DrawOffered();
}

/// Accept a draw offer
class DrawAccepted extends GameEvent {
  const DrawAccepted();
}

/// Decline a draw offer
class DrawDeclined extends GameEvent {
  const DrawDeclined();
}
