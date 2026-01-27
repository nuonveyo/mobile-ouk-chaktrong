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

  /// Create a new game room with FCM token for notifications
  Future<OnlineGameRoom> createRoom({
    required String hostPlayerId,
    String? hostPlayerName,
    String? hostFcmToken,
    int timeControl = 600,
  }) async {
    final docRef = _gamesRef.doc();
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(hours: 24)); // TTL: 24 hours
    
    final room = OnlineGameRoom(
      id: docRef.id,
      hostPlayerId: hostPlayerId,
      hostPlayerName: hostPlayerName ?? 'Player 1',
      hostFcmToken: hostFcmToken,
      status: GameStatus.waiting,
      timeControl: timeControl,
      createdAt: now,
      expiresAt: expiresAt,
      gameData: OnlineGameData(
        whiteTimeRemaining: timeControl,
        goldTimeRemaining: timeControl,
      ),
    );

    await docRef.set(room.toJson());
    return room;
  }

  /// Request to join a room (sets pendingJoin status, host must approve)
  Future<OnlineGameRoom?> requestJoinRoom({
    required String roomId,
    required String guestPlayerId,
    String? guestPlayerName,
  }) async {
    final docRef = _gamesRef.doc(roomId);
    
    return _firestore.runTransaction<OnlineGameRoom?>((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return null;

      final room = OnlineGameRoom.fromJson(snapshot.data()!, roomId);
      // Only allow joining if room is waiting (not already pending or playing)
      if (!room.isWaiting) return null;

      // Set pending join status - host must approve
      transaction.update(docRef, {
        'status': GameStatus.pendingJoin.name,
        'pendingGuestId': guestPlayerId,
        'pendingGuestName': guestPlayerName ?? 'Player 2',
      });
      
      return room.copyWith(
        status: GameStatus.pendingJoin,
        pendingGuestId: guestPlayerId,
        pendingGuestName: guestPlayerName ?? 'Player 2',
      );
    });
  }

  /// Host accepts join request - game starts
  Future<OnlineGameRoom?> acceptJoinRequest(String roomId) async {
    final docRef = _gamesRef.doc(roomId);
    
    return _firestore.runTransaction<OnlineGameRoom?>((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return null;

      final room = OnlineGameRoom.fromJson(snapshot.data()!, roomId);
      if (!room.isPendingJoin || room.pendingGuestId == null) return null;

      // Move pending guest to actual guest and start game
      transaction.update(docRef, {
        'status': GameStatus.playing.name,
        'guestPlayerId': room.pendingGuestId,
        'guestPlayerName': room.pendingGuestName ?? 'Player 2',
        'startedAt': DateTime.now().toIso8601String(),
        'pendingGuestId': null,
        'pendingGuestName': null,
      });
      
      return room.copyWith(
        status: GameStatus.playing,
        guestPlayerId: room.pendingGuestId,
        guestPlayerName: room.pendingGuestName ?? 'Player 2',
        startedAt: DateTime.now(),
        pendingGuestId: null,
        pendingGuestName: null,
      );
    });
  }

  /// Host declines join request - room is cancelled
  Future<void> declineJoinRequest(String roomId) async {
    await _gamesRef.doc(roomId).update({
      'status': GameStatus.cancelled.name,
      'pendingGuestId': null,
      'pendingGuestName': null,
    });
  }

  /// Get user's pending room (if any) - for enforcing one room per host
  Future<OnlineGameRoom?> getUserPendingRoom(String userId) async {
    final query = await _gamesRef
        .where('hostPlayerId', isEqualTo: userId)
        .where('status', whereIn: [GameStatus.waiting.name, GameStatus.pendingJoin.name])
        .limit(1)
        .get();
    
    if (query.docs.isEmpty) return null;
    return OnlineGameRoom.fromJson(query.docs.first.data(), query.docs.first.id);
  }

  /// Cancel a room (delete it)
  Future<void> cancelRoom(String roomId) async {
    await _gamesRef.doc(roomId).delete();
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
