import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

/// Reaction data with code and Khmer text
class ReactionData {
  final int code;
  final String khmerText;
  final int point;

  const ReactionData({
    required this.code,
    required this.khmerText,
    required this.point,
  });
}

/// All available reactions
const List<ReactionData> reactions = [
  ReactionData(code: 1, khmerText: 'អុក', point: 0),
  ReactionData(code: 2, khmerText: 'ដេញទូក', point: 10),
  ReactionData(code: 3, khmerText: 'ដេញសេស', point: 10),
  ReactionData(code: 4, khmerText: 'ស្មើរហើយ', point: 10),
  ReactionData(code: 5, khmerText: 'យូម្លេះ', point: 15),
  ReactionData(code: 6, khmerText: 'រត់ទៅ', point: 15),
  ReactionData(code: 7, khmerText: 'សុំចាញ់ទៅ', point: 20),
  ReactionData(code: 8, khmerText: 'រាប់ឲ្យហើយទៅ', point: 20),
  ReactionData(code: 20, khmerText: '😡', point: 10),
  ReactionData(code: 21, khmerText: '😱', point: 10),
  ReactionData(code: 22, khmerText: '😂', point: 10),
  ReactionData(code: 23, khmerText: '😘', point: 20),
  ReactionData(code: 24, khmerText: '💋', point: 20),
  ReactionData(code: 25, khmerText: '🙏', point: 20),
  ReactionData(code: 26, khmerText: '👍', point: 20),
];

/// Modal bottom sheet for selecting reactions
class ReactionPicker extends StatelessWidget {
  final void Function(int reactionCode, int reactionPoints) onReactionSelected;
  int currentPoint;

  ReactionPicker({
    super.key,
    required this.onReactionSelected,
    required this.currentPoint,
  });

  static Future<void> show(
    BuildContext context, {
    required void Function(int reactionCode, int reactionPoints)
    onReactionSelected,
    required int currentPoint,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ReactionPicker(
        currentPoint: currentPoint,
        onReactionSelected: (code, reactionPoints) {
          Navigator.of(context).pop();
          onReactionSelected(code, reactionPoints);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade600,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          const Text(
            'Send Reaction',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 16),

          // Reaction grid
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: reactions
                .map((reaction) => _buildReactionButton(reaction))
                .toList(),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildReactionButton(ReactionData reaction) {
    final isEnabled;
    if (currentPoint < 0) {
      isEnabled = false;
    } else {
      final reactionPoints = reaction.point;
      isEnabled = currentPoint >= reactionPoints;
      currentPoint = currentPoint - reactionPoints;
    }

    final points;
    if (reaction.point == 0) {
      points = " (0coins)";
    } else {
      points = " (-${reaction.point}coins)";
    }
    return InkWell(
      onTap: () =>
      isEnabled ? onReactionSelected(reaction.code, reaction.point) : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.templeGold.withValues(alpha: 0.5),
          ),
        ),
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isEnabled ? AppColors.textPrimary : AppColors.textMuted,
            ), // Default style for this block
            children: <TextSpan>[
              TextSpan(text: reaction.khmerText),
              TextSpan(
                text: points,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isEnabled ? AppColors.textPrimary : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
