import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/game_constants.dart';
import '../models/models.dart';
import 'chess_clock.dart';

/// Player info card with avatar, name, status, and clock
class PlayerInfoCard extends StatelessWidget {
  final String name;
  final PlayerColor color;
  final bool isCurrentTurn;
  final bool isInCheck;
  final int timeRemaining;
  final List<Piece> capturedPieces;

  const PlayerInfoCard({
    super.key,
    required this.name,
    required this.color,
    required this.isCurrentTurn,
    required this.timeRemaining,
    this.isInCheck = false,
    this.capturedPieces = const [],
  });

  @override
  Widget build(BuildContext context) {
    final isLowTime = timeRemaining <= 30;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentTurn
            ? AppColors.templeGold.withValues(alpha: 0.15)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isInCheck 
              ? AppColors.danger 
              : isCurrentTurn 
                  ? AppColors.templeGold 
                  : Colors.transparent,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color == PlayerColor.white 
                  ? AppColors.whitePiece 
                  : AppColors.goldPiece,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.person,
              color: AppColors.deepPurple,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          
          // Name and status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (isInCheck) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'CHECK',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isCurrentTurn ? AppColors.success : AppColors.textMuted,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isCurrentTurn ? 'Your turn' : 'Waiting...',
                      style: TextStyle(
                        fontSize: 12,
                        color: isCurrentTurn ? AppColors.success : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Captured pieces indicator
          if (capturedPieces.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '+${_calculateCapturedValue()}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.templeGold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          // Chess clock
          ChessClockWidget(
            timeRemainingSeconds: timeRemaining,
            isActive: isCurrentTurn,
            isLowTime: isLowTime && isCurrentTurn,
          ),
        ],
      ),
    );
  }

  int _calculateCapturedValue() {
    return capturedPieces.fold(0, (sum, piece) => sum + piece.value);
  }
}
