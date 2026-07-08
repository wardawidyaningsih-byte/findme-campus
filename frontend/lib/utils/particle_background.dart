import 'dart:math';
import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Highly-optimized Snow/Starfield particle background widget.
/// Uses a CustomPainter with an animation repaint listener to animate particles
/// without triggering widget builds (avoids rebuilding form fields/children).
class ParticleBackground extends StatefulWidget {
  final int particleCount;
  final Widget child;

  const ParticleBackground({
    super.key,
    this.particleCount = 50,
    required this.child,
  });

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_ParticleData> _particles;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _particles = List.generate(widget.particleCount, (_) => _generateParticle());
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  _ParticleData _generateParticle() {
    final size = 1.0 + _random.nextDouble() * 4.0;
    final speed = 0.0004 + _random.nextDouble() * 0.0012;
    final drift = (_random.nextDouble() - 0.5) * 0.0003;
    final maxOpacity = 0.15 + _random.nextDouble() * 0.65;
    final phase = _random.nextDouble() * pi * 2;
    
    // 80% white, 20% soft cyan/accent tinted particles
    Color color = Colors.white;
    if (_random.nextDouble() > 0.8) {
      color = AppTheme.accent.withValues(alpha: 0.8);
    }

    return _ParticleData(
      x: _random.nextDouble(),
      y: _random.nextDouble(),
      size: size,
      speed: speed,
      drift: drift,
      maxOpacity: maxOpacity,
      opacity: _random.nextDouble() * maxOpacity,
      phase: phase,
      color: color,
      isStar: _random.nextDouble() > 0.75, // 25% stars with halos, 75% snow circles
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Ensure child is outside of the CustomPaint repaint boundary so it never rebuilds
        widget.child,
        
        // RepaintBoundary blocks repaint propagation, and CustomPaint handles its own repaints
        IgnorePointer(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _OptimizedParticlePainter(
                particles: _particles,
                repaint: _controller,
              ),
              size: Size.infinite,
            ),
          ),
        ),
      ],
    );
  }
}

class _ParticleData {
  double x;
  double y;
  double size;
  double speed;
  double drift;
  double opacity;
  double maxOpacity;
  double phase;
  Color color;
  bool isStar;

  _ParticleData({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.drift,
    required this.maxOpacity,
    required this.opacity,
    required this.phase,
    required this.color,
    required this.isStar,
  });
}

class _OptimizedParticlePainter extends CustomPainter {
  final List<_ParticleData> particles;
  final Random _random = Random();

  _OptimizedParticlePainter({
    required this.particles,
    required Listenable repaint,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;

    // A slow changing global wind modifier based on time
    final timeMs = DateTime.now().millisecondsSinceEpoch;
    final globalWind = sin(timeMs / 4000.0) * 0.0002;

    for (var p in particles) {
      // 1. Update Positions
      p.y += p.speed;
      p.x += p.drift + globalWind + (sin(p.y * 4.0 + p.phase) * 0.0002);
      
      // Twinkle opacity oscillation
      p.opacity = (p.maxOpacity * (0.3 + 0.7 * sin(timeMs / 1000.0 + p.phase))).clamp(0.05, 1.0);

      // Reset when falling out of bounds
      if (p.y > 1.05) {
        p.y = -0.05;
        p.x = _random.nextDouble();
      }
      if (p.x > 1.05) p.x = -0.05;
      if (p.x < -0.05) p.x = 1.05;

      // 2. Draw Particles
      final center = Offset(p.x * size.width, p.y * size.height);

      if (p.isStar) {
        // Draw Soft Glow Halo behind the star
        final glowPaint = Paint()
          ..color = p.color.withValues(alpha: p.opacity * 0.25)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3); // Blur for glowing effect
        canvas.drawCircle(center, p.size * 2.2, glowPaint);

        // Draw 4-Pointed Star
        final starPaint = Paint()
          ..color = p.color.withValues(alpha: p.opacity)
          ..style = PaintingStyle.fill;

        final starPath = Path();
        final radius = p.size * 1.6;
        starPath.moveTo(center.dx, center.dy - radius);
        starPath.quadraticBezierTo(center.dx, center.dy, center.dx + radius, center.dy);
        starPath.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + radius);
        starPath.quadraticBezierTo(center.dx, center.dy, center.dx - radius, center.dy);
        starPath.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - radius);
        starPath.close();
        
        canvas.drawPath(starPath, starPaint);
      } else {
        // Draw Soft Snow Circle
        final snowPaint = Paint()
          ..color = p.color.withValues(alpha: p.opacity)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(center, p.size * 0.85, snowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _OptimizedParticlePainter oldDelegate) => true;
}
