import 'package:flutter/material.dart';

enum RunPhase { menu, playing, paused, gameOver }

enum Feel { none, collect, shield, hit }

class Star {
  Star({
    required this.nx,
    required this.ny,
    required this.speed,
    required this.size,
    required this.depth,
  });

  final double nx;
  double ny;
  final double speed;
  final double size;
  final double depth;
}

class Rock {
  Rock({
    required this.x,
    required this.y,
    required this.radius,
    required this.spin,
    required this.spinSpeed,
    required this.seed,
  });

  double x;
  double y;
  double radius;
  double spin;
  double spinSpeed;
  int seed;
  bool passed = false;
}

class Crystal {
  Crystal({
    required this.x,
    required this.y,
    required this.radius,
    required this.spin,
  });

  double x;
  double y;
  final double radius;
  double spin;
}

class Particle {
  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.maxLife,
    required this.size,
    required this.color,
  });

  double x;
  double y;
  double vx;
  double vy;
  double life;
  double maxLife;
  double size;
  Color color;
}

class Floater {
  Floater({
    required this.text,
    required this.x,
    required this.y,
    required this.color,
  });

  final String text;
  double x;
  double y;
  double life = 0.9;
  final Color color;
}
