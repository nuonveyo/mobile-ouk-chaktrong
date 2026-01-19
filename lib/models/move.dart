import 'package:equatable/equatable.dart';
import '../core/constants/game_constants.dart';
import 'position.dart';
import 'piece.dart';

/// Represents a chess move
class Move extends Equatable {
  final Position from;
  final Position to;
  final Piece piece;
  final Piece? capturedPiece;
  final bool isPromotion;
  final Piece? promotedTo;

  const Move({
    required this.from,
    required this.to,
    required this.piece,
    this.capturedPiece,
    this.isPromotion = false,
    this.promotedTo,
  });

  /// Check if this move captures a piece
  bool get isCapture => capturedPiece != null;

  /// Get move in algebraic notation
  String get notation {
    final buffer = StringBuffer();
    
    // Piece symbol (empty for fish)
    if (piece.type != PieceType.fish) {
      buffer.write(piece.type.name[0].toUpperCase());
    }
    
    // Origin square (simplified)
    buffer.write(from.notation);
    
    // Capture indicator
    if (isCapture) {
      buffer.write('x');
    } else {
      buffer.write('-');
    }
    
    // Target square
    buffer.write(to.notation);
    
    // Promotion indicator
    if (isPromotion) {
      buffer.write('=M'); // Always promotes to Maiden
    }
    
    return buffer.toString();
  }

  @override
  List<Object?> get props => [from, to, piece, capturedPiece, isPromotion, promotedTo];

  @override
  String toString() => notation;
}
