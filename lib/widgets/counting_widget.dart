import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/game_constants.dart';
import '../models/models.dart';
import '../logic/game_rules.dart';

/// Widget showing counting status and controls during endgame
class CountingWidget extends StatelessWidget {
  final GameState gameState;
  final PlayerColor playerColor; // Which player's side this widget is on
  final VoidCallback? onStartBoardCounting;
  final VoidCallback? onStartPieceCounting;
  final VoidCallback? onStopCounting;
  final VoidCallback? onDeclareDraw;

  const CountingWidget({
    super.key,
    required this.gameState,
    required this.playerColor,
    this.onStartBoardCounting,
    this.onStartPieceCounting,
    this.onStopCounting,
    this.onDeclareDraw,
  });

  @override
  Widget build(BuildContext context) {
    final counting = gameState.counting;
    final rules = const GameRules();
    
    // Check if this player can start Board's Honor counting (manual)
    // Piece's Honor is automatic and doesn't need a button
    final canStartBoard = !counting.isActive && 
        rules.canStartBoardHonorCounting(gameState.board, playerColor);
    
    // Check if this player is the escaping player (can stop counting)
    final isEscapingPlayer = counting.escapingPlayer == playerColor;
    
    // Check if this player is the chasing player (can declare draw)
    final isChasingPlayer = counting.isActive && counting.escapingPlayer != playerColor;

    // PRIORITY 1: If counting is active and this is the escaping player's side, show count + stop
    if (counting.isActive && isEscapingPlayer) {
      return _buildActiveCountingDisplay(counting);
    }

    // PRIORITY 2: If counting is active and this is the chasing player's side, show declare draw
    if (isChasingPlayer) {
      return _buildChasingPlayerUI();
    }

    // PRIORITY 3: If no counting active and can start Board's Honor, show start button
    // (Piece's Honor starts automatically, no button needed)
    if (canStartBoard) {
      return _buildStartCountingButton();
    }

    // Hide if nothing to show
    return const SizedBox.shrink();
  }

  Widget _buildActiveCountingDisplay(CountingState counting) {
    final typeLabel = counting.type == CountingType.boardHonor 
        ? "Board's Honor" 
        : "Piece's Honor";
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.templeGold.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.templeGold, width: 2),
      ),
      child: Row(
        children: [
          // Count display
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  typeLabel,
                  style: const TextStyle(
                    color: AppColors.templeGold,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${counting.currentCount} / ${counting.limit}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
          ),
          // Remaining moves
          Column(
            children: [
              Text(
                '${counting.movesRemaining}',
                style: const TextStyle(
                  color: AppColors.warning,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const Text(
                'left',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Stop button (only if callback provided)
          if (onStopCounting != null)
            ElevatedButton(
              onPressed: onStopCounting,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Stop'),
            ),
        ],
      ),
    );
  }

  Widget _buildChasingPlayerUI() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton.icon(
        onPressed: onDeclareDraw,
        icon: const Icon(Icons.handshake),
        label: const Text('Declare Draw'),
        style: ElevatedButton.styleFrom(
          backgroundColor: onDeclareDraw == null ? AppColors.surface : AppColors.warning,
          foregroundColor: onDeclareDraw == null ? AppColors.textMuted : AppColors.deepPurple,
          minimumSize: const Size(double.infinity, 44),
        ),
      ),
    );
  }

  /// Build start button for Board's Honor counting only
  /// (Piece's Honor starts automatically, no button needed)
  Widget _buildStartCountingButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton(
        onPressed: onStartBoardCounting,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.surface,
          minimumSize: const Size(double.infinity, 44),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Start Counting',
              style: TextStyle(
                fontSize: 14,
                color: onStartBoardCounting == null ? AppColors.textMuted : AppColors.textPrimary,
              ),
            ),
            const Text(
              "Board's Honor (64 moves)",
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
