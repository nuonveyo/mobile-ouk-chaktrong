/// Game constants for Khmer Chess rules
class GameConstants {
  GameConstants._();

  // Board dimensions
  static const int boardSize = 8;
  static const int totalSquares = boardSize * boardSize;

  // Fish promotion rank (0-indexed, so rank 5 = 6th row from bottom)
  static const int fishPromotionRank = 5;

  // AI difficulty depths (higher = stronger but slower)
  static const int aiEasyDepth = 2;
  static const int aiMediumDepth = 3;  // Reduced for smoother gameplay
  static const int aiHardDepth = 5;    // Reduced from 6 - depth 6 takes too long

  // Time controls (in seconds)
  static const int defaultTimeControl = 600; // 10 minutes
  static const int blitzTimeControl = 300; // 5 minutes
  static const int bulletTimeControl = 60; // 1 minute

  // Animation durations
  static const Duration pieceMoveDuration = Duration(milliseconds: 200);
  static const Duration pieceSelectDuration = Duration(milliseconds: 100);
  static const Duration highlightFadeDuration = Duration(milliseconds: 150);
}

/// Piece type identifiers
enum PieceType {
  king, // Sdech (ស្ដេច)
  maiden, // Neang (នាង)
  elephant, // Koul (គោល)
  horse, // Seh (សេះ)
  boat, // Tuk (ទូក)
  fish, // Trei (ត្រី)
}

/// Player colors
enum PlayerColor {
  white,
  gold,
}

/// Game mode types
enum GameMode {
  vsAi,
  local2Player,
  online,
}

/// AI difficulty levels
enum AiDifficulty {
  easy,
  medium,
  hard,
}

/// Game result
enum GameResult {
  ongoing,
  whiteWins,
  goldWins,
  draw,
}
