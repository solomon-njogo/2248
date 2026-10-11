import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'aether_world.dart';
import 'game_models.dart';

class GamePainter extends CustomPainter {
  GamePainter({required this.world, required this.field})
    : super(repaint: world);

  final AetherWorld world;
  final Rect field;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    _drawBackdrop(canvas, size);
    _drawStars(canvas, size);
    _drawMargins(canvas, size);
    if (field.width <= 0 || field.height <= 0) return;

    canvas.save();
    canvas.clipRect(field);
    final mag = world.shake * 7;
    canvas.translate(
      field.left + math.sin(world.time * 47) * mag,
      field.top + math.cos(world.time * 39) * mag,
    );
    _drawLane(canvas);
    _drawStreaks(canvas);
    _drawTrail(canvas);
    _drawParticles(canvas);
    _drawRocks(canvas);
    _drawCrystals(canvas);
    _drawShield(canvas);
    _drawShip(canvas);
    _drawFloaters(canvas);
    if (world.flash > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, field.width, field.height),
        Paint()..color = AppColors.text.withValues(alpha: world.flash * 0.28),
      );
    }
    canvas.restore();
    _drawLaneEdge(canvas, size);
  }

  void _drawBackdrop(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.65, -0.55),
          radius: 1.15,
          colors: [Color(0xFF16324A), Color(0xFF1A1030), AppColors.background],
          stops: [0, 0.42, 1],
        ).createShader(rect),
    );
  }

  void _drawStars(Canvas canvas, Size size) {
    final paint = Paint();
    for (final star in world.stars) {
      paint.color = AppColors.text.withValues(alpha: 0.2 + star.depth * 0.65);
      canvas.drawCircle(
        Offset(star.nx * size.width, star.ny * size.height),
        star.size * (0.55 + star.depth),
        paint,
      );
    }
  }

  void _drawMargins(Canvas canvas, Size size) {
    if (field.left <= 12) return;
    final dim = Paint()..color = AppColors.background.withValues(alpha: 0.55);
    canvas.drawRect(Rect.fromLTWH(0, 0, field.left, size.height), dim);
    canvas.drawRect(
      Rect.fromLTWH(field.right, 0, size.width - field.right, size.height),
      dim,
    );
  }

  void _drawLane(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, field.width, field.height);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.fieldTop, AppColors.fieldBottom],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment(0, world.playerY / field.height * 2 - 1),
          radius: 0.85,
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            const Color(0x00000000),
          ],
        ).createShader(rect),
    );
  }

  void _drawStreaks(Canvas canvas) {
    if (world.phase != RunPhase.playing || world.pressure < 0.25) return;
    final paint = Paint()
      ..color = AppColors.primary.withValues(
        alpha: 0.04 + world.pressure * 0.06,
      )
      ..strokeWidth = 1.2;
    const count = 7;
    for (var i = 0; i < count; i++) {
      final x = (i + 0.5) * field.width / count;
      final shift =
          (world.time * (90 + world.pressure * 220) + i * 53) % field.height;
      canvas.drawLine(
        Offset(x, shift),
        Offset(x, shift + 18 + world.pressure * 46),
        paint,
      );
    }
  }

  void _drawTrail(Canvas canvas) {
    final paint = Paint();
    for (var i = 0; i < world.trail.length; i++) {
      final t = (i + 1) / world.trail.length;
      paint.color = _hull.withValues(alpha: 0.05 + t * 0.22);
      canvas.drawCircle(
        world.trail[i],
        world.playerRadius * (0.18 + t * 0.28),
        paint,
      );
    }
  }

  void _drawParticles(Canvas canvas) {
    final paint = Paint();
    for (final particle in world.particles) {
      final fade = particle.maxLife <= 0
          ? 0.0
          : (particle.life / particle.maxLife).clamp(0.0, 1.0).toDouble();
      paint.color = particle.color.withValues(alpha: fade);
      canvas.drawCircle(Offset(particle.x, particle.y), particle.size, paint);
    }
  }

  void _drawRocks(Canvas canvas) {
    final rim = Color.lerp(
      AppColors.rockEdge,
      AppColors.secondary,
      world.pressure * 0.7,
    )!;
    final fill = Paint()..color = AppColors.rock;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = rim;
    for (final rock in world.rocks) {
      final path = _rockPath(rock);
      canvas.drawPath(path, fill);
      canvas.drawPath(path, stroke);
    }
  }

  void _drawCrystals(Canvas canvas) {
    final fill = Paint()..color = AppColors.accent;
    final glow = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    for (final crystal in world.crystals) {
      final pulse = 1 + math.sin(world.time * 5 + crystal.spin) * 0.08;
      canvas.save();
      canvas.translate(crystal.x, crystal.y);
      canvas.rotate(crystal.spin);
      canvas.scale(pulse);
      final path = Path()
        ..moveTo(0, -crystal.radius)
        ..lineTo(crystal.radius * 0.72, 0)
        ..lineTo(0, crystal.radius)
        ..lineTo(-crystal.radius * 0.72, 0)
        ..close();
      canvas.drawCircle(Offset.zero, crystal.radius * 1.35, glow);
      canvas.drawPath(path, fill);
      canvas.restore();
    }
  }

  void _drawShield(Canvas canvas) {
    if (world.shieldFlash <= 0) return;
    final t = 1 - (world.shieldFlash / 0.36).clamp(0.0, 1.0).toDouble();
    final radius = world.playerRadius * 1.4 + world.shieldRadius * t;
    canvas.drawCircle(
      Offset(world.playerX, world.playerY),
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = AppColors.accent.withValues(alpha: (1 - t) * 0.85),
    );
  }

  void _drawShip(Canvas canvas) {
    final x = world.playerX;
    final y = world.playerY;
    final r = world.playerRadius;
    canvas.drawCircle(
      Offset(x, y),
      r * 1.35,
      Paint()
        ..color = _hull.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    final path = Path()
      ..moveTo(x, y - r * 1.35)
      ..quadraticBezierTo(x + r * 1.05, y + r * 0.15, x + r * 0.72, y + r)
      ..lineTo(x, y + r * 0.42)
      ..lineTo(x - r * 0.72, y + r)
      ..quadraticBezierTo(x - r * 1.05, y + r * 0.15, x, y - r * 1.35)
      ..close();
    canvas.drawPath(path, Paint()..color = _hull);
    canvas.drawCircle(
      Offset(x, y - r * 0.15),
      r * 0.28,
      Paint()..color = AppColors.text,
    );
    canvas.drawCircle(
      Offset(x, y + r * 0.72),
      r * 0.22,
      Paint()..color = AppColors.accent.withValues(alpha: 0.9),
    );
  }

  void _drawFloaters(Canvas canvas) {
    for (final floater in world.floaters) {
      final alpha = (floater.life / 0.9).clamp(0.0, 1.0).toDouble();
      final painter = TextPainter(
        text: TextSpan(
          text: floater.text,
          style: TextStyle(
            color: floater.color.withValues(alpha: alpha),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        Offset(floater.x - painter.width / 2, floater.y - painter.height),
      );
      painter.dispose();
    }
  }

  void _drawLaneEdge(Canvas canvas, Size size) {
    if (field.left <= 12) return;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primary.withValues(alpha: 0),
          AppColors.primary.withValues(alpha: 0.55),
          AppColors.secondary.withValues(alpha: 0.35),
          AppColors.primary.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 2;
    canvas.drawLine(field.topLeft, field.bottomLeft, paint);
    canvas.drawLine(field.topRight, field.bottomRight, paint);
  }

  Color get _hull =>
      Color.lerp(AppColors.primary, AppColors.secondary, world.pressure) ??
      AppColors.primary;

  Path _rockPath(Rock rock) {
    final path = Path();
    const points = 8;
    for (var i = 0; i < points; i++) {
      final angle = rock.spin + i * math.pi * 2 / points;
      final jitter = 0.78 + _unit(rock.seed, i) * 0.28;
      final px = rock.x + math.cos(angle) * rock.radius * jitter;
      final py = rock.y + math.sin(angle) * rock.radius * jitter;
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    path.close();
    return path;
  }

  double _unit(int seed, int index) {
    final value = math.sin(seed * 12.9898 + index * 78.233) * 43758.5453;
    return value - value.floorToDouble();
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) {
    return oldDelegate.world != world || oldDelegate.field != field;
  }
}
