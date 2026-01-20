import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Service for managing SQLite database
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Future<Database> get database async {
    _database ??= await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ouk_chaktrong.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create user table
    await db.execute('''
      CREATE TABLE user(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL DEFAULT 'Player',
        points INTEGER NOT NULL DEFAULT 0,
        avatar_url TEXT,
        phone_number TEXT,
        email TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  /// Close database connection
  Future<void> close() async {
    final db = await database;
    db.close();
    _database = null;
  }
}
