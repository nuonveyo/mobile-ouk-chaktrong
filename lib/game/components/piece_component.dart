import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../core/constants/constants.dart';

/// A single chess piece component
class PieceComponent extends PositionComponent {
  final Piece piece;
  Position boardPosition;
  double _squareSize;
  bool _isSelected = false;

  PieceComponent({
    required this.piece,
    required this.boardPosition,
    required double squareSize,
  }) : _squareSize = squareSize {
    size = Vector2.all(squareSize);
    anchor = Anchor.topLeft;
  }

  void updateSquareSize(double newSize) {
    _squareSize = newSize;
    size = Vector2.all(newSize);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _renderPiece(canvas);
  }

  void _renderPiece(Canvas canvas) {
    final isWhite = piece.color == PlayerColor.white;
    final pieceColor = isWhite ? AppColors.whitePiece : AppColors.goldPiece;
    final shadowColor = isWhite ? AppColors.whitePieceShadow : AppColors.goldPieceShadow;

    // Piece circle background
    final center = Offset(_squareSize / 2, _squareSize / 2);
    final radius = _squareSize * 0.38;

    // Shadow
    canvas.drawCircle(
      center + const Offset(2, 2),
      radius,
      Paint()..color = Colors.black.withValues(alpha: 0.3),
    );

    // Base circle with gradient
    final gradient = RadialGradient(
      colors: [pieceColor, shadowColor],
      stops: const [0.5, 1.0],
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      ),
    );

    // Border
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = isWhite ? Colors.grey.shade600 : AppColors.goldPieceShadow
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Selected glow
    if (_isSelected) {
      canvas.drawCircle(
        center,
        radius + 4,
        Paint()
          ..color = AppColors.warmGold.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }

    // Piece symbol
    _renderSymbol(canvas, center);
  }

  void _renderSymbol(Canvas canvas, Offset center) {
    final isWhite = piece.color == PlayerColor.white;
    final symbolColor = isWhite ? AppColors.deepPurple : AppColors.deepPurple;
    
    // Get the piece symbol/icon
    final symbol = _getPieceSymbol();
    
    final textPainter = TextPainter(
      text: TextSpan(
        text: symbol,
        style: TextStyle(
          fontSize: _squareSize * 0.35,
          fontWeight: FontWeight.bold,
          color: symbolColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  String _getPieceSymbol() {
    switch (piece.type) {
      case PieceType.king:
        return 'ស'; // Khmer letter for Sdech
      case PieceType.maiden:
        return 'ន'; // Khmer letter for Neang
      case PieceType.elephant:
        return 'គ'; // Khmer letter for Koul
      case PieceType.horse:
        return 'ស'; // Khmer letter for Seh (different rendering)
      case PieceType.boat:
        return 'ទ'; // Khmer letter for Tuk
      case PieceType.fish:
        return '○'; // Simple circle for Fish
    }
  }

  /// Select this piece (visual feedback)
  void select() {
    _isSelected = true;
    
    // Add scale effect
    add(
      ScaleEffect.by(
        Vector2.all(1.1),
        EffectController(duration: 0.1),
      ),
    );
  }

  /// Deselect this piece
  void deselect() {
    _isSelected = false;
    scale = Vector2.all(1.0);
  }

  /// Animate moving to a new position
  void animateMoveTo(Vector2 newPosition, Position newBoardPosition) {
    boardPosition = newBoardPosition;
    
    add(
      MoveEffect.to(
        newPosition,
        EffectController(
          duration: 0.2,
          curve: Curves.easeOutQuad,
        ),
      ),
    );
  }
}
