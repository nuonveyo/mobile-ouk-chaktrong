import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Reaction data with code and Khmer text
class ReactionData {
  final int code;
  final String khmerText;

  const ReactionData({
    required this.code,
    required this.khmerText,
  });
}

/// All available reactions
const List<ReactionData> reactions = [
  ReactionData(code: 1, khmerText: 'អុក'),
  ReactionData(code: 2, khmerText: 'ដេញទូក'),
  ReactionData(code: 3, khmerText: 'ដេញសេស'),
  ReactionData(code: 4, khmerText: 'រត់ទៅ'),
  ReactionData(code: 5, khmerText: 'សុំចាញ់ទៅ'),
  ReactionData(code: 6, khmerText: 'ស្មើរហើយ'),
  ReactionData(code: 7, khmerText: 'រាប់ឲ្យហើយទៅ'),
  ReactionData(code: 8, khmerText: 'យូម្លេះ'),
  ReactionData(code: 20, khmerText: '😡'),
  ReactionData(code: 21, khmerText: '😱'),
  ReactionData(code: 22, khmerText: '😂'),
  ReactionData(code: 23, khmerText: '😘'),
  ReactionData(code: 24, khmerText: '💋'),
  ReactionData(code: 25, khmerText: '🙏'),
  ReactionData(code: 26, khmerText: '👍'),
];

/// Modal bottom sheet for selecting reactions
class ReactionPicker extends StatelessWidget {
  final void Function(int reactionCode) onReactionSelected;

  const ReactionPicker({
    super.key,
    required this.onReactionSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required void Function(int reactionCode) onReactionSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ReactionPicker(
        onReactionSelected: (code) {
          Navigator.of(context).pop();
          onReactionSelected(code);
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
            children: reactions.map((reaction) => _buildReactionButton(reaction)).toList(),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildReactionButton(ReactionData reaction) {
    return InkWell(
      onTap: () => onReactionSelected(reaction.code),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.templeGold.withValues(alpha: 0.5)),
        ),
        child: Text(
          reaction.khmerText,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
