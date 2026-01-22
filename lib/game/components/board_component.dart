import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/models.dart';
import '../../core/constants/constants.dart';
import 'piece_component.dart';
import 'square_highlight.dart';

/// The chess board component that renders the 8x8 grid
class BoardComponent extends PositionComponent with TapCallbacks, HasGameReference {
  double _boardSize;
  final void Function(Position) onSquareTapped;
  final bool flipBoard; // If true, flip board so Gold is at bottom

  final Map<Position, PieceComponent> _pieces = {};
  final List<SquareHighlight> _highlights = [];
  
  Position? _selectedSquare;
  Position? _lastMoveFrom;
  Position? _lastMoveTo;
  Position? _checkPosition; // Position of King in check
  ui.Image? _boardImage;

  // Board image has a wooden frame - this is the padding ratio on each side
  // Adjust this value to match your board image's border
  static const double _boardPaddingRatio = 0.025; // 2.5% padding on each side

  BoardComponent({
    required double boardSize,
    required this.onSquareTapped,
    this.flipBoard = false,
  }) : _boardSize = boardSize {
    size = Vector2.all(boardSize);
  }

  double get boardSize => _boardSize;
  
  /// The padding around the playable area (wooden frame)
  double get boardPadding => _boardSize * _boardPaddingRatio;
  
  /// The actual playable area size (excluding the frame)
  double get playableSize => _boardSize - (boardPadding * 2);
  
  /// Size of each square in the playable area
  double get squareSize => playableSize / 8;

  /// Resize the board
  void resize(double newSize) {
    _boardSize = newSize;
    size = Vector2.all(newSize);
    
    // Resize all pieces
    for (final piece in _pieces.values) {
      piece.updateSquareSize(squareSize);
    }
    
    // Resize all highlights
    for (final highlight in _highlights) {
      highlight.updateSize(squareSize);
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _loadBoardImage();
  }

  Future<void> _loadBoardImage() async {
    try {
      final data = await rootBundle.load('assets/boards/board-1.png');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      _boardImage = frame.image;
    } catch (e) {
      debugPrint('Failed to load board image: $e');
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _renderBoard(canvas);
  }

  void _renderBoard(Canvas canvas) {
    // Draw board image as background
    if (_boardImage != null) {
      canvas.drawImageRect(
        _boardImage!,
        Rect.fromLTWH(0, 0, _boardImage!.width.toDouble(), _boardImage!.height.toDouble()),
        Rect.fromLTWH(0, 0, _boardSize, _boardSize),
        Paint()..filterQuality = FilterQuality.high,
      );
    } else {
      // Fallback to painted squares if image not loaded
      final lightPaint = Paint()..color = AppColors.lightSquare;
      final darkPaint = Paint()..color = AppColors.darkSquare;
      for (var row = 0; row < 8; row++) {
        for (var col = 0; col < 8; col++) {
          final isLight = (row + col) % 2 == 0;
          final pos = Position(row, col);
          final screenPos = _positionToVector(pos);
          final rect = Rect.fromLTWH(screenPos.x, screenPos.y, squareSize, squareSize);
          canvas.drawRect(rect, isLight ? lightPaint : darkPaint);
        }
      }
    }

    final selectedPaint = Paint()..color = AppColors.selectedSquare;
    final lastMovePaint = Paint()..color = AppColors.lastMove;

    for (var row = 0; row < 8; row++) {
      for (var col = 0; col < 8; col++) {
        final pos = Position(row, col);
        final screenPos = _positionToVector(pos);
        
        final rect = Rect.fromLTWH(
          screenPos.x,
          screenPos.y,
          squareSize,
          squareSize,
        );

        // Last move highlight (light gold)
        if (pos == _lastMoveFrom || pos == _lastMoveTo) {
          canvas.drawRect(rect, lastMovePaint);
        }

        // Check highlight (light red on King in check)
        if (pos == _checkPosition) {
          final checkPaint = Paint()..color = AppColors.checkHighlight;
          canvas.drawRect(rect, checkPaint);
        }

        // Selected square highlight
        if (pos == _selectedSquare) {
          canvas.drawRect(rect, selectedPaint);
        }
      }
    }
    // Note: Coordinates removed - board image has its own frame and markings
  }

  void _renderCoordinates(Canvas canvas) {
    const style = TextStyle(
      color: AppColors.textMuted,
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );

    // Column letters (a-h)
    for (var col = 0; col < 8; col++) {
      final letter = String.fromCharCode('a'.codeUnitAt(0) + col);
      final textPainter = TextPainter(
        text: TextSpan(text: letter, style: style),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          col * squareSize + squareSize / 2 - textPainter.width / 2,
          _boardSize - 12,
        ),
      );
    }

    // Row numbers (1-8)
    for (var row = 0; row < 8; row++) {
      final number = (row + 1).toString();
      final textPainter = TextPainter(
        text: TextSpan(text: number, style: style),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(4, (7 - row) * squareSize + squareSize / 2 - textPainter.height / 2),
      );
    }
  }

  @override
  bool onTapDown(TapDownEvent event) {
    final localPos = event.localPosition;
    
    // Account for board padding when calculating tap position
    final adjustedX = localPos.x - boardPadding;
    final adjustedY = localPos.y - boardPadding;
    
    int col = (adjustedX / squareSize).floor();
    int row = 7 - (adjustedY / squareSize).floor(); // Flip for board coords
    
    // If board is flipped, invert coordinates
    if (flipBoard) {
      col = 7 - col;
      row = 7 - row;
    }

    if (col >= 0 && col < 8 && row >= 0 && row < 8) {
      onSquareTapped(Position(row, col));
    }
    return true;
  }

  /// Sync pieces from board state
  void syncPieces(BoardState board) {
    // Remove all existing pieces
    for (final piece in _pieces.values) {
      piece.removeFromParent();
    }
    _pieces.clear();

    // Add pieces from board state
    for (var row = 0; row < 8; row++) {
      for (var col = 0; col < 8; col++) {
        final piece = board.getPieceAt(row, col);
        if (piece != null) {
          final pos = Position(row, col);
          _addPiece(pos, piece);
        }
      }
    }
  }

  void _addPiece(Position pos, Piece piece) {
    final pieceComponent = PieceComponent(
      piece: piece,
      boardPosition: pos,
      squareSize: squareSize,
    );
    pieceComponent.position = _positionToVector(pos);
    _pieces[pos] = pieceComponent;
    add(pieceComponent);
  }

  Vector2 _positionToVector(Position pos) {
    // Add board padding offset to align pieces with actual grid cells
    if (flipBoard) {
      // Flip both row and column for Gold player
      return Vector2(
        boardPadding + (7 - pos.col) * squareSize,
        boardPadding + pos.row * squareSize,
      );
    }
    return Vector2(
      boardPadding + pos.col * squareSize,
      boardPadding + (7 - pos.row) * squareSize,
    );
  }

  /// Set selected square highlight
  void setSelectedSquare(Position? position) {
    _selectedSquare = position;
  }

  /// Set last move highlights
  void setLastMove(Position from, Position to) {
    _lastMoveFrom = from;
    _lastMoveTo = to;
  }

  /// Set check highlight on King position (null to clear)
  void setCheckPosition(Position? position) {
    _checkPosition = position;
  }

  /// Set valid move highlights
  void setValidMoves(List<Position> positions) {
    // Clear existing highlights
    for (final highlight in _highlights) {
      highlight.removeFromParent();
    }
    _highlights.clear();

    // Add new highlights
    for (final pos in positions) {
      final highlight = SquareHighlight(
        boardPosition: pos,
        squareSize: squareSize,
        isCapture: _pieces.containsKey(pos),
      );
      highlight.position = _positionToVector(pos);
      _highlights.add(highlight);
      add(highlight);
    }
  }

  /// Clear all highlights
  void clearHighlights() {
    _selectedSquare = null;
    
    for (final highlight in _highlights) {
      highlight.removeFromParent();
    }
    _highlights.clear();
    
    // Deselect all pieces
    for (final piece in _pieces.values) {
      piece.deselect();
    }
  }

  /// Select a piece (animate it)
  void selectPiece(Position position) {
    final piece = _pieces[position];
    piece?.select();
  }

  /// Animate a move
  void animateMove(Move move) {
    final piece = _pieces[move.from];
    if (piece == null) return;

    // Remove captured piece if any
    if (move.capturedPiece != null) {
      final capturedPiece = _pieces[move.to];
      capturedPiece?.removeFromParent();
      _pieces.remove(move.to);
    }

    // Move piece to new position
    _pieces.remove(move.from);
    
    // Handle promotion
    if (move.isPromotion && move.promotedTo != null) {
      piece.removeFromParent();
      _addPiece(move.to, move.promotedTo!);
    } else {
      piece.animateMoveTo(_positionToVector(move.to), move.to);
      _pieces[move.to] = piece;
    }
  }
}
