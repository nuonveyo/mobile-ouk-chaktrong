import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../core/constants/constants.dart';
import 'piece_component.dart';
import 'square_highlight.dart';

/// The chess board component that renders the 8x8 grid
class BoardComponent extends PositionComponent with TapCallbacks {
  double _boardSize;
  final void Function(Position) onSquareTapped;

  final Map<Position, PieceComponent> _pieces = {};
  final List<SquareHighlight> _highlights = [];
  
  Position? _selectedSquare;
  Position? _lastMoveFrom;
  Position? _lastMoveTo;

  BoardComponent({
    required double boardSize,
    required this.onSquareTapped,
  }) : _boardSize = boardSize {
    size = Vector2.all(boardSize);
  }

  double get boardSize => _boardSize;
  double get squareSize => _boardSize / 8;

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
  void render(Canvas canvas) {
    super.render(canvas);
    _renderBoard(canvas);
  }

  void _renderBoard(Canvas canvas) {
    final lightPaint = Paint()..color = AppColors.lightSquare;
    final darkPaint = Paint()..color = AppColors.darkSquare;
    final selectedPaint = Paint()..color = AppColors.selectedSquare;
    final lastMovePaint = Paint()..color = AppColors.lastMove;

    for (var row = 0; row < 8; row++) {
      for (var col = 0; col < 8; col++) {
        final isLight = (row + col) % 2 == 0;
        final rect = Rect.fromLTWH(
          col * squareSize,
          (7 - row) * squareSize, // Flip row for display
          squareSize,
          squareSize,
        );

        // Base square color
        canvas.drawRect(rect, isLight ? lightPaint : darkPaint);

        // Last move highlight
        final pos = Position(row, col);
        if (pos == _lastMoveFrom || pos == _lastMoveTo) {
          canvas.drawRect(rect, lastMovePaint);
        }

        // Selected square highlight
        if (pos == _selectedSquare) {
          canvas.drawRect(rect, selectedPaint);
        }
      }
    }

    // Draw board border
    final borderPaint = Paint()
      ..color = AppColors.templeGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, _boardSize, _boardSize),
      borderPaint,
    );

    // Draw coordinates
    _renderCoordinates(canvas);
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
    final col = (localPos.x / squareSize).floor();
    final row = 7 - (localPos.y / squareSize).floor(); // Flip for board coords

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
    return Vector2(
      pos.col * squareSize,
      (7 - pos.row) * squareSize,
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
