import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/models.dart';
import '../../core/constants/constants.dart';

/// A single chess piece component with PNG support
class PieceComponent extends PositionComponent {
  final Piece piece;
  Position boardPosition;
  double _squareSize;
  bool _isSelected = false;
  ui.Image? _pngImage;

  // bool _usePng = false;
  bool _usePng = true;

  PieceComponent({
    required this.piece,
    required this.boardPosition,
    required double squareSize,
  }) : _squareSize = squareSize {
    size = Vector2.all(squareSize);
    anchor = Anchor.topLeft;

    // Use PNG for back row pieces (not unpromoted fish)
    // _usePng = piece.type != PieceType.fish;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    if (_usePng) {
      await _loadPngImage();
    }
  }

  Future<void> _loadPngImage() async {
    final colorFolder = piece.color == PlayerColor.white ? 'white' : 'black';
    final pieceName = _getPieceName();
    final assetPath = 'assets/pieces-2/$colorFolder/$pieceName.png';

    try {
      final byteData = await rootBundle.load(assetPath);
      final codec = await ui.instantiateImageCodec(
        byteData.buffer.asUint8List(),
      );
      final frame = await codec.getNextFrame();
      _pngImage = frame.image;
    } catch (e) {
      // Fallback to text rendering if PNG fails
      _usePng = false;
    }
  }

  String _getPieceName() {
    switch (piece.type) {
      case PieceType.king:
        return 'King';
      case PieceType.maiden:
        return 'Maiden';
      case PieceType.elephant:
        return 'Elephant';
      case PieceType.horse:
        return 'Horse';
      case PieceType.boat:
        return 'Boat';
      case PieceType.fish:
        return 'Fish';
    }
  }

  void updateSquareSize(double newSize) {
    _squareSize = newSize;
    size = Vector2.all(newSize);
    // Reload PNG at new size
    if (_usePng) {
      _loadPngImage();
    }
  }

  /// Set this piece to use PNG (for promoted fish)
  void enablePng() {
    if (!_usePng) {
      _usePng = true;
      _loadPngImage();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _renderPiece(canvas);
  }

  void _renderPiece(Canvas canvas) {
    // final isWhite = piece.color == PlayerColor.white;
    // final pieceColor = isWhite ? AppColors.whitePiece : AppColors.goldPiece;
    // final shadowColor = isWhite ? AppColors.whitePieceShadow : AppColors.goldPieceShadow;

    // Piece circle background - increased size for better visibility
    final center = Offset(_squareSize / 2, _squareSize / 2);
    final radius = _squareSize * 0.44;

    // Shadow
    // canvas.drawCircle(
    //   center + const Offset(2, 2),
    //   radius,
    //   Paint()..color = Colors.black.withValues(alpha: 0.3),
    // );

    // Base circle with gradient
    // final gradient = RadialGradient(
    //   colors: [pieceColor, shadowColor],
    //   stops: const [0.5, 1.0],
    // );
    // canvas.drawCircle(
    //   center,
    //   radius,
    //   Paint()..shader = gradient.createShader(
    //     Rect.fromCircle(center: center, radius: radius),
    //   ),
    // );

    // Border
    // canvas.drawCircle(
    //   center,
    //   radius,
    //   Paint()
    //     ..color = isWhite ? Colors.grey.shade600 : AppColors.goldPieceShadow
    //     ..style = PaintingStyle.stroke
    //     ..strokeWidth = 2,
    // );

    // Selected glow
    // if (_isSelected) {
    //   canvas.drawCircle(
    //     center,
    //     radius + 4,
    //     Paint()
    //       ..color = AppColors.warmGold.withValues(alpha: 0.5)
    //       ..style = PaintingStyle.stroke
    //       ..strokeWidth = 3,
    //   );
    // }

    // Piece symbol (PNG or text)
    if (_usePng && _pngImage != null) {
      _renderPngImage(canvas, center);
    } else {
      _renderSymbol(canvas, center);
    }
  }

  void _renderPngImage(Canvas canvas, Offset center) {
    if (_pngImage == null) return;

    // Increased display size for bigger pieces
    final imageSize = _squareSize * 0.65;
    final offset = Offset(center.dx - imageSize / 2, center.dy - imageSize / 2);

    double drawPngWidth = _pngImage!.width.toDouble();
    double drawPngHeight = _pngImage!.height.toDouble();
    double paddingLeft = 0;
    if(piece.type == PieceType.king){
      drawPngWidth = drawPngWidth * 1.3;
      paddingLeft = -12;
      drawPngHeight = drawPngHeight * 0.98;
    }
    else if (piece.type == PieceType.maiden ||
        piece.type == PieceType.elephant) {
      drawPngWidth = drawPngWidth * 1.8;
      paddingLeft = -40;
    }

    canvas.drawImageRect(
      _pngImage!,
      Rect.fromLTWH(paddingLeft, 0, drawPngWidth, drawPngHeight),
      Rect.fromLTWH(offset.dx, offset.dy, imageSize, imageSize),
      Paint()..filterQuality = FilterQuality.high,
    );
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
    add(ScaleEffect.by(Vector2.all(1.1), EffectController(duration: 0.1)));
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
        EffectController(duration: 0.2, curve: Curves.easeOutQuad),
      ),
    );
  }
}
