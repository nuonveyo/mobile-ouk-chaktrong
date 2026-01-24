import 'package:equatable/equatable.dart';
import '../models/models.dart';
import '../core/constants/game_constants.dart';

/// Model representing an online game room
class OnlineGameRoom extends Equatable {
  final String id;
  final String? hostPlayerId;
  final String? guestPlayerId;
  final String? hostPlayerName;
  final String? guestPlayerName;
  final GameStatus status;
  final int timeControl;
  final DateTime createdAt;
  final DateTime? startedAt;
  final OnlineGameData? gameData;
  final int? latestReactionCode;      // 1-7 for reactions
  final String? latestReactionSender; // player ID who sent reaction
  final int spectatorCount;           // Number of spectators watching

  const OnlineGameRoom({
    required this.id,
    this.hostPlayerId,
    this.guestPlayerId,
    this.hostPlayerName,
    this.guestPlayerName,
    this.status = GameStatus.waiting,
    this.timeControl = 600,
    required this.createdAt,
    this.startedAt,
    this.gameData,
    this.latestReactionCode,
    this.latestReactionSender,
    this.spectatorCount = 0,
  });

  bool get isFull => hostPlayerId != null && guestPlayerId != null;
  bool get isWaiting => status == GameStatus.waiting;
  bool get isPlaying => status == GameStatus.playing;
  bool get isFinished => status == GameStatus.finished;

  factory OnlineGameRoom.fromJson(Map<String, dynamic> json, String docId) {
    return OnlineGameRoom(
      id: docId,
      hostPlayerId: json['hostPlayerId'] as String?,
      guestPlayerId: json['guestPlayerId'] as String?,
      hostPlayerName: json['hostPlayerName'] as String?,
      guestPlayerName: json['guestPlayerName'] as String?,
      status: GameStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => GameStatus.waiting,
      ),
      timeControl: json['timeControl'] as int? ?? 600,
      createdAt: DateTime.parse(json['createdAt'] as String),
      startedAt: json['startedAt'] != null 
          ? DateTime.parse(json['startedAt'] as String) 
          : null,
      gameData: json['gameData'] != null 
          ? OnlineGameData.fromJson(json['gameData'] as Map<String, dynamic>)
          : null,
      latestReactionCode: json['latestReactionCode'] as int?,
      latestReactionSender: json['latestReactionSender'] as String?,
      spectatorCount: json['spectatorCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hostPlayerId': hostPlayerId,
      'guestPlayerId': guestPlayerId,
      'hostPlayerName': hostPlayerName,
      'guestPlayerName': guestPlayerName,
      'status': status.name,
      'timeControl': timeControl,
      'createdAt': createdAt.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'gameData': gameData?.toJson(),
      'latestReactionCode': latestReactionCode,
      'latestReactionSender': latestReactionSender,
      'spectatorCount': spectatorCount,
    };
  }

  OnlineGameRoom copyWith({
    String? id,
    String? hostPlayerId,
    String? guestPlayerId,
    String? hostPlayerName,
    String? guestPlayerName,
    GameStatus? status,
    int? timeControl,
    DateTime? createdAt,
    DateTime? startedAt,
    OnlineGameData? gameData,
    int? latestReactionCode,
    String? latestReactionSender,
    int? spectatorCount,
  }) {
    return OnlineGameRoom(
      id: id ?? this.id,
      hostPlayerId: hostPlayerId ?? this.hostPlayerId,
      guestPlayerId: guestPlayerId ?? this.guestPlayerId,
      hostPlayerName: hostPlayerName ?? this.hostPlayerName,
      guestPlayerName: guestPlayerName ?? this.guestPlayerName,
      status: status ?? this.status,
      timeControl: timeControl ?? this.timeControl,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      gameData: gameData ?? this.gameData,
      latestReactionCode: latestReactionCode ?? this.latestReactionCode,
      latestReactionSender: latestReactionSender ?? this.latestReactionSender,
      spectatorCount: spectatorCount ?? this.spectatorCount,
    );
  }

  @override
  List<Object?> get props => [
        id, hostPlayerId, guestPlayerId, hostPlayerName, guestPlayerName,
        status, timeControl, createdAt, startedAt, gameData,
        latestReactionCode, latestReactionSender, spectatorCount,
      ];
}

/// Game status for online matches
enum GameStatus {
  waiting,
  playing,
  finished,
}

/// Serializable game data for Firestore
class OnlineGameData extends Equatable {
  final String currentTurn; // 'white' or 'gold'
  final List<String> moves; // List of move notations
  final int whiteTimeRemaining;
  final int goldTimeRemaining;
  final String? result; // 'white', 'gold', 'draw', or null
  final String? lastMoveFrom;
  final String? lastMoveTo;

  const OnlineGameData({
    this.currentTurn = 'white',
    this.moves = const [],
    required this.whiteTimeRemaining,
    required this.goldTimeRemaining,
    this.result,
    this.lastMoveFrom,
    this.lastMoveTo,
  });

  factory OnlineGameData.fromJson(Map<String, dynamic> json) {
    return OnlineGameData(
      currentTurn: json['currentTurn'] as String? ?? 'white',
      moves: (json['moves'] as List<dynamic>?)?.cast<String>() ?? [],
      whiteTimeRemaining: json['whiteTimeRemaining'] as int? ?? 600,
      goldTimeRemaining: json['goldTimeRemaining'] as int? ?? 600,
      result: json['result'] as String?,
      lastMoveFrom: json['lastMoveFrom'] as String?,
      lastMoveTo: json['lastMoveTo'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentTurn': currentTurn,
      'moves': moves,
      'whiteTimeRemaining': whiteTimeRemaining,
      'goldTimeRemaining': goldTimeRemaining,
      'result': result,
      'lastMoveFrom': lastMoveFrom,
      'lastMoveTo': lastMoveTo,
    };
  }

  OnlineGameData copyWith({
    String? currentTurn,
    List<String>? moves,
    int? whiteTimeRemaining,
    int? goldTimeRemaining,
    String? result,
    String? lastMoveFrom,
    String? lastMoveTo,
  }) {
    return OnlineGameData(
      currentTurn: currentTurn ?? this.currentTurn,
      moves: moves ?? this.moves,
      whiteTimeRemaining: whiteTimeRemaining ?? this.whiteTimeRemaining,
      goldTimeRemaining: goldTimeRemaining ?? this.goldTimeRemaining,
      result: result ?? this.result,
      lastMoveFrom: lastMoveFrom ?? this.lastMoveFrom,
      lastMoveTo: lastMoveTo ?? this.lastMoveTo,
    );
  }

  @override
  List<Object?> get props => [
        currentTurn, moves, whiteTimeRemaining, goldTimeRemaining,
        result, lastMoveFrom, lastMoveTo,
      ];
}
