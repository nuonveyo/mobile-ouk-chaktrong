import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../models/position.dart';
import '../../core/constants/app_colors.dart';

/// Highlight component for valid moves
class SquareHighlight extends PositionComponent {
  final Position boardPosition;
  double _squareSize;
  final bool isCapture;

  SquareHighlight({
    required this.boardPosition,
    required double squareSize,
    this.isCapture = false,
  }) : _squareSize = squareSize {
    size = Vector2.all(squareSize);
  }

  void updateSize(double newSize) {
    _squareSize = newSize;
    size = Vector2.all(newSize);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final center = Offset(_squareSize / 2, _squareSize / 2);

    if (isCapture) {
      // Capture indicator - ring around the square
      canvas.drawCircle(
        center,
        _squareSize * 0.45,
        Paint()
          ..color = AppColors.danger.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    } else {
      // Move indicator - small dot
      canvas.drawCircle(
        center,
        _squareSize * 0.15,
        Paint()..color = AppColors.validMove,
      );
    }
  }
}
