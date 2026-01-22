import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import 'reaction_picker.dart';

/// Animated comment bubble that displays a reaction
/// Anchored to show which player sent it
class ReactionDisplay extends StatefulWidget {
  final int reactionCode;
  final bool isFromOpponent;
  final VoidCallback? onDismissed;

  const ReactionDisplay({
    super.key,
    required this.reactionCode,
    this.isFromOpponent = false,
    this.onDismissed,
  });

  @override
  State<ReactionDisplay> createState() => _ReactionDisplayState();
}

class _ReactionDisplayState extends State<ReactionDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Scale: pop in then stay
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.1).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.1, end: 1.0),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: 55,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.9),
        weight: 20,
      ),
    ]).animate(_controller);

    // Slide in from the side
    _slideAnimation = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween(
          begin: Offset(widget.isFromOpponent ? 0.0 : 0.0, widget.isFromOpponent ? -0.5 : 0.5),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: ConstantTween(Offset.zero),
        weight: 80,
      ),
    ]).animate(_controller);

    // Fade: hold then fade out
    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: 65,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0),
        weight: 25,
      ),
    ]).animate(_controller);

    _controller.forward().then((_) {
      widget.onDismissed?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  ReactionData? get _reactionData {
    try {
      return reactions.firstWhere((r) => r.code == widget.reactionCode);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reaction = _reactionData;
    if (reaction == null) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: SlideTransition(
            position: _slideAnimation,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            ),
          ),
        );
      },
      child: _buildCommentBubble(reaction),
    );
  }

  Widget _buildCommentBubble(ReactionData reaction) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Arrow pointing up (if from opponent - top of screen)
        if (widget.isFromOpponent)
          CustomPaint(
            size: const Size(20, 10),
            painter: _BubbleArrowPainter(
              color: AppColors.templeGold,
              isPointingUp: true,
            ),
          ),
        
        // Main bubble
        Container(
          constraints: const BoxConstraints(maxWidth: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.templeGold,
                AppColors.templeGold.withValues(alpha: 0.85),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.templeGold.withValues(alpha: 0.4),
                blurRadius: 16,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Chat icon
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat_bubble,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              // Reaction text
              Flexible(
                child: Text(
                  reaction.khmerText,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 2,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Arrow pointing down (if from local player - bottom of screen)
        if (!widget.isFromOpponent)
          CustomPaint(
            size: const Size(20, 10),
            painter: _BubbleArrowPainter(
              color: AppColors.templeGold,
              isPointingUp: false,
            ),
          ),
      ],
    );
  }
}

/// Custom painter for the bubble arrow/tail
class _BubbleArrowPainter extends CustomPainter {
  final Color color;
  final bool isPointingUp;

  _BubbleArrowPainter({
    required this.color,
    required this.isPointingUp,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    
    if (isPointingUp) {
      // Triangle pointing up
      path.moveTo(size.width / 2, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else {
      // Triangle pointing down
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width / 2, size.height);
    }
    
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
