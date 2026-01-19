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
    await _gamesRef.doc(roomId).update({
      'gameData.moves': FieldValue.arrayUnion([moveNotation]),
      'gameData.currentTurn': nextTurn,
      'gameData.whiteTimeRemaining': whiteTime,
      'gameData.goldTimeRemaining': goldTime,
      'gameData.lastMoveFrom': lastMoveFrom,
      'gameData.lastMoveTo': lastMoveTo,
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

  /// Leave/cancel a game room
  Future<void> leaveRoom(String roomId) async {
    final docRef = _gamesRef.doc(roomId);
    final snapshot = await docRef.get();
    
    if (snapshot.exists) {
      final room = OnlineGameRoom.fromJson(snapshot.data()!, roomId);
      if (room.isWaiting) {
        // Delete if still waiting
        await docRef.delete();
      } else {
        // Mark as finished if playing
        await docRef.update({
          'status': GameStatus.finished.name,
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
}
