import 'package:firebase_auth/firebase_auth.dart';

/// Repository for handling authentication
class AuthRepository {
  final FirebaseAuth _auth;

  AuthRepository({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Check if user is signed in
  bool get isSignedIn => currentUser != null;

  /// Get user ID
  String? get userId => currentUser?.uid;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in anonymously
  Future<User?> signInAnonymously() async {
    try {
      final result = await _auth.signInAnonymously();
      return result.user;
    } catch (e) {
      throw AuthException('Failed to sign in anonymously: $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Ensure user is signed in (sign in anonymously if not)
  Future<User> ensureSignedIn() async {
    if (currentUser != null) {
      return currentUser!;
    }
    final user = await signInAnonymously();
    if (user == null) {
      throw AuthException('Failed to sign in');
    }
    return user;
  }
}

/// Exception for auth errors
class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  
  @override
  String toString() => message;
}
