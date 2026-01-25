import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A celebratory animation widget that shows a shower of gold coins/sparkles.
class WinAnimation extends StatefulWidget {
  final VoidCallback? onAnimationComplete;

  const WinAnimation({super.key, this.onAnimationComplete});

  @override
  State<WinAnimation> createState() => _WinAnimationState();
}

class _WinAnimationState extends State<WinAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    // Initial particles
    _createParticles();

    _controller.addListener(() {
      _updateParticles();
      if (_controller.isCompleted) {
        widget.onAnimationComplete?.call();
      }
    });

    _controller.forward();
  }

  void _createParticles() {
    for (int i = 0; i < 50; i++) {
      _particles.add(Particle(
        x: _random.nextDouble(),
        y: -0.1 - _random.nextDouble() * 2,
        speed: 0.005 + _random.nextDouble() * 0.015,
        size: 5 + _random.nextDouble() * 15,
        angle: _random.nextDouble() * 2 * math.pi,
        rotationSpeed: (_random.nextDouble() - 0.5) * 0.2,
        color: _random.nextBool()
            ? const Color(0xFFD4AF37) // templeGold
            : const Color(0xFFFFD700), // warmGold
      ));
    }
  }

  void _updateParticles() {
    setState(() {
      for (var particle in _particles) {
        particle.y += particle.speed;
        particle.angle += particle.rotationSpeed;
        
        // Horizontal drift
        particle.x += math.sin(_controller.value * 10 + particle.speed * 100) * 0.001;

        // Reset particle if it goes off screen
        if (particle.y > 1.2) {
          particle.y = -0.1;
          particle.x = _random.nextDouble();
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: ParticlePainter(particles: _particles),
        size: Size.infinite,
      ),
    );
  }
}

class Particle {
  double x; // 0.0 to 1.0 (screen width)
  double y; // -0.2 to 1.2 (screen height)
  double speed;
  double size;
  double angle;
  double rotationSpeed;
  Color color;

  Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.angle,
    required this.rotationSpeed,
    required this.color,
  });
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;

  ParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()
        ..color = particle.color
        ..style = PaintingStyle.fill;

      // Draw a "coin" (ellipse with some thickness effect)
      final center = Offset(particle.x * size.width, particle.y * size.height);
      
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(particle.angle);

      // Draw shadow/edge
      final edgePaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(const Offset(2, 2), particle.size / 2, edgePaint);

      // Draw the "coin" face
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: particle.size,
          height: particle.size * 0.8, // Slightly squashed for perspective
        ),
        paint,
      );
      
      // Draw a sparkle or pattern
      final shinePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.4)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(-particle.size * 0.2, -particle.size * 0.2), particle.size * 0.1, shinePaint);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
