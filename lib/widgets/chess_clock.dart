import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Chess clock widget that displays time remaining
class ChessClockWidget extends StatelessWidget {
  final int timeRemainingSeconds;
  final bool isActive;
  final bool isLowTime;

  const ChessClockWidget({
    super.key,
    required this.timeRemainingSeconds,
    this.isActive = false,
    this.isLowTime = false,
  });

  @override
  Widget build(BuildContext context) {
    final minutes = timeRemainingSeconds ~/ 60;
    final seconds = timeRemainingSeconds % 60;
    final timeString = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isActive 
            ? (isLowTime ? AppColors.danger.withValues(alpha: 0.2) : AppColors.templeGold.withValues(alpha: 0.2))
            : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive 
              ? (isLowTime ? AppColors.danger : AppColors.templeGold)
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: Text(
        timeString,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
          color: isLowTime ? AppColors.danger : AppColors.textPrimary,
        ),
      ),
    );
  }
}
