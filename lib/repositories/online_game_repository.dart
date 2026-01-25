import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/online_game.dart';

/// Repository for managing online games with Firestore
class OnlineGameRepository {
  final FirebaseFirestore _firestore;
  static const String _collection = 'games';

  OnlineGameRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _gamesRef =>
      _firestore.collection(_collection);

  /// Create a new game room
  Future<OnlineGameRoom> createRoom({
    required String hostPlayerId,
    String? hostPlayerName,
    int timeControl = 600,
  }) async {
    final docRef = _gamesRef.doc();
    final room = OnlineGameRoom(
      id: docRef.id,
      hostPlayerId: hostPlayerId,
      hostPlayerName: hostPlayerName ?? 'Player 1',
      status: GameStatus.waiting,
      timeControl: timeControl,
      createdAt: DateTime.now(),
      gameData: OnlineGameData(
        whiteTimeRemaining: timeControl,
        goldTimeRemaining: timeControl,
      ),
    );

    await docRef.set(room.toJson());
    return room;
  }

  /// Join an existing game room
  Future<OnlineGameRoom?> joinRoom({
    required String roomId,
    required String guestPlayerId,
    String? guestPlayerName,
  }) async {
    final docRef = _gamesRef.doc(roomId);
    
    return _firestore.runTransaction<OnlineGameRoom?>((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return null;

      final room = OnlineGameRoom.fromJson(snapshot.data()!, roomId);
      if (room.isFull || !room.isWaiting) return null;

      final updatedRoom = room.copyWith(
        guestPlayerId: guestPlayerId,
        guestPlayerName: guestPlayerName ?? 'Player 2',
        status: GameStatus.playing,
        startedAt: DateTime.now(),
      );

      transaction.update(docRef, updatedRoom.toJson());
      return updatedRoom;
    });
  }

  /// Get available rooms (waiting for players)
  Stream<List<OnlineGameRoom>> getAvailableRooms() {
    return _gamesRef
        .where('status', isEqualTo: GameStatus.waiting.name)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OnlineGameRoom.fromJson(doc.data(), doc.id))
            .toList());
  }

  /// Listen to room updates
  Stream<OnlineGameRoom?> watchRoom(String roomId) {
    return _gamesRef.doc(roomId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return OnlineGameRoom.fromJson(snapshot.data()!, roomId);
    });
  }

  /// Update game data (make a move)
  Future<void> updateGameData({
    required String roomId,
    required OnlineGameData gameData,
  }) async {
    await _gamesRef.doc(roomId).update({
      'gameData': gameData.toJson(),
    });
  }

  /// Add a move to the game
  Future<void> makeMove({
    required String roomId,
    required String moveNotation,
    required String nextTurn,
    required int whiteTime,
    required int goldTime,
    String? lastMoveFrom,
    String? lastMoveTo,
  }) async {
    final docRef = _gamesRef.doc(roomId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      final gameData = data['gameData'] as Map<String, dynamic>;
      final moves = List<String>.from(gameData['moves'] ?? []);
      
      // Append the new move
      moves.add(moveNotation);

      transaction.update(docRef, {
        'gameData.moves': moves,
        'gameData.currentTurn': nextTurn,
        'gameData.whiteTimeRemaining': whiteTime,
        'gameData.goldTimeRemaining': goldTime,
        'gameData.lastMoveFrom': lastMoveFrom,
        'gameData.lastMoveTo': lastMoveTo,
      });
    });
  }

  /// End the game with a result
  Future<void> endGame({
    required String roomId,
    required String result, // 'white', 'gold', or 'draw'
  }) async {
    await _gamesRef.doc(roomId).update({
      'status': GameStatus.finished.name,
      'gameData.result': result,
    });
  }

  /// Send a reaction to the opponent
  Future<void> sendReaction({
    required String roomId,
    required int reactionCode, // 1-7
    required String senderId,
  }) async {
    await _gamesRef.doc(roomId).update({
      'latestReactionCode': reactionCode,
      'latestReactionSender': senderId,
    });
  }

  /// Leave/cancel a game room
  Future<void> leaveRoom(String roomId, String userId) async {
    final docRef = _gamesRef.doc(roomId);
    final snapshot = await docRef.get();
    
    if (snapshot.exists) {
      final room = OnlineGameRoom.fromJson(snapshot.data()!, roomId);
      if (room.isWaiting) {
        // Delete if still waiting
        await docRef.delete();
      } else if (room.isPlaying) {
        // Mark as finished if playing and set winner as the person who didn't leave
        final winner = room.hostPlayerId == userId ? 'gold' : 'white';
        await docRef.update({
          'status': GameStatus.finished.name,
          'gameData.result': winner,
        });
      }
    }
  }

  /// Delete old/stale rooms (cleanup)
  Future<void> cleanupOldRooms() async {
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    final query = await _gamesRef
        .where('createdAt', isLessThan: cutoff.toIso8601String())
        .get();

    final batch = _firestore.batch();
    for (final doc in query.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  /// Get active games (currently playing) for spectating
  Stream<List<OnlineGameRoom>> getActiveGames() {
    return _gamesRef
        .where('status', isEqualTo: GameStatus.playing.name)
        .orderBy('createdAt', descending: true)  // Using createdAt for consistent indexing
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OnlineGameRoom.fromJson(doc.data(), doc.id))
            .toList());
  }

  /// Join a game as a spectator (increment spectator count)
  Future<void> joinAsSpectator(String roomId) async {
    await _gamesRef.doc(roomId).update({
      'spectatorCount': FieldValue.increment(1),
    });
  }

  /// Leave spectating a game (decrement spectator count)
  Future<void> leaveAsSpectator(String roomId) async {
    await _gamesRef.doc(roomId).update({
      'spectatorCount': FieldValue.increment(-1),
    });
  }
}
