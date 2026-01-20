import '../models/user.dart';
import '../services/database_service.dart';

/// Repository for user data operations
class UserRepository {
  final DatabaseService _dbService = DatabaseService();
  static const String _tableName = 'user';

  /// Get current user (creates default if none exists)
  Future<User> getUser() async {
    final db = await _dbService.database;
    final maps = await db.query(_tableName, limit: 1);

    if (maps.isEmpty) {
      // Create default user
      final defaultUser = User.defaultUser();
      final id = await db.insert(_tableName, defaultUser.toMap());
      return defaultUser.copyWith(id: id);
    }

    return User.fromMap(maps.first);
  }

  /// Get user points
  Future<int> getPoints() async {
    final user = await getUser();
    return user.points;
  }

  /// Add points to user
  Future<void> addPoints(int points) async {
    final user = await getUser();
    final updatedUser = user.copyWith(
      points: user.points + points,
    );
    
    await _updateUser(updatedUser);
  }

  /// Award win bonus (100 points)
  Future<int> awardWin() async {
    const winBonus = 100;
    await addPoints(winBonus);
    return winBonus;
  }

  /// Update username
  Future<void> updateUsername(String name) async {
    final user = await getUser();
    final updatedUser = user.copyWith(name: name);
    await _updateUser(updatedUser);
  }

  /// Update user profile
  Future<void> updateProfile({
    String? name,
    String? avatarUrl,
    String? phoneNumber,
    String? email,
  }) async {
    final user = await getUser();
    final updatedUser = User(
      id: user.id,
      name: name ?? user.name,
      points: user.points,
      avatarUrl: avatarUrl ?? user.avatarUrl,
      phoneNumber: phoneNumber ?? user.phoneNumber,
      email: email ?? user.email,
      createdAt: user.createdAt,
      updatedAt: DateTime.now(),
    );
    await _updateUser(updatedUser);
  }

  /// Internal update method
  Future<void> _updateUser(User user) async {
    final db = await _dbService.database;
    await db.update(
      _tableName,
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }
}
