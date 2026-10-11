import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'game_models.dart';

class AetherWorld extends ChangeNotifier {
  AetherWorld({math.Random? random, this.onNewBest})
    : _random = random ?? math.Random() {
    _seedStars();
  }

  static const shieldCooldownMax = 3.2;
  static const _hitScale = 0.72;
  static const _gapPad = 12.0;

  final math.Random _random;
  final void Function(int score)? onNewBest;
  int? _uiSignature;

  final stars = <Star>[];
  final rocks = <Rock>[];
  final crystals = <Crystal>[];
  final particles = <Particle>[];
  final floaters = <Floater>[];
  final trail = <Offset>[];

  RunPhase phase = RunPhase.menu;
  Feel feel = Feel.none;

  double width = 0;
  double height = 0;
  double time = 0;
  double distance = 0;
  double score = 0;
  int best = 0;
  bool newBest = false;
  int combo = 1;
  double comboTimer = 0;
  int waveCount = 0;

  double playerX = 0;
  double playerY = 0;
  double playerRadius = 18;
  double targetX = 0;
  double basePlayerY = 0;
  bool pointerActive = false;
  double keyboardAxis = 0;

  double shieldCooldown = 0;
  double shieldFlash = 0;
  double shake = 0;
  double flash = 0;

  double gapLeft = 0;
  double gapRight = 0;

  bool _committed = false;
  double _spawnTimer = 0;

  double get pressure => (distance / 4200).clamp(0.0, 1.0).toDouble();

  double get speed => _lerp(230, 540, pressure);

  double get shieldRadius => math.min(width * 0.34, 150.0);

  bool get shieldReady =>
      phase == RunPhase.playing && shieldCooldown <= 0 && width > 0;

  Feel consumeFeel() {
    final current = feel;
    feel = Feel.none;
    return current;
  }

  void layout(Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final changed =
        (size.width - width).abs() > 0.5 || (size.height - height).abs() > 0.5;
    width = size.width;
    height = size.height;
    playerRadius = (math.min(width, height) * 0.042)
        .clamp(15.0, 26.0)
        .toDouble();
    basePlayerY =
        height *
        (height < 480
            ? 0.58
            : height < 640
            ? 0.68
            : 0.74);
    if (phase != RunPhase.menu) {
      playerY = basePlayerY;
    }
    if (phase == RunPhase.menu && (changed || playerX == 0)) {
      _placeMenuShip();
    }
    final lo = _minX;
    final hi = _maxX;
    playerX = playerX.clamp(lo, hi).toDouble();
    targetX = targetX.clamp(lo, hi).toDouble();
  }

  void steerTo(double x) {
    if (phase != RunPhase.playing || width <= 0) return;
    targetX = x.clamp(_minX, _maxX).toDouble();
  }

  void start() {
    rocks.clear();
    crystals.clear();
    particles.clear();
    floaters.clear();
    trail.clear();
    score = 0;
    distance = 0;
    combo = 1;
    comboTimer = 0;
    waveCount = 0;
    _spawnTimer = 0.45;
    shieldCooldown = 0;
    shieldFlash = 0;
    shake = 0;
    flash = 0;
    newBest = false;
    _committed = false;
    feel = Feel.none;
    pointerActive = false;
    phase = RunPhase.playing;
    playerX = width > 0 ? width / 2 : 0;
    targetX = playerX;
    playerY = basePlayerY;
    gapLeft = 0;
    gapRight = 0;
  }

  void togglePause() {
    if (phase == RunPhase.playing) {
      phase = RunPhase.paused;
      pointerActive = false;
    } else if (phase == RunPhase.paused) {
      phase = RunPhase.playing;
    }
  }

  void exitToMenu() {
    _commitBest();
    phase = RunPhase.menu;
    rocks.clear();
    crystals.clear();
    particles.clear();
    floaters.clear();
    trail.clear();
    score = 0;
    distance = 0;
    combo = 1;
    waveCount = 0;
    flash = 0;
    shake = 0;
    shieldFlash = 0;
    pointerActive = false;
    if (width > 0) _placeMenuShip();
  }

  void back() {
    switch (phase) {
      case RunPhase.playing:
        togglePause();
      case RunPhase.paused:
      case RunPhase.gameOver:
        exitToMenu();
      case RunPhase.menu:
        break;
    }
  }

  void tryShield() {
    if (!shieldReady) return;
    shieldCooldown = shieldCooldownMax;
    shieldFlash = 0.36;
    shake = math.max(shake, 0.4);
    feel = Feel.shield;

    final reach = shieldRadius;
    var destroyed = 0;
    rocks.removeWhere((rock) {
      if (_within(rock.x, rock.y, reach + rock.radius)) {
        destroyed += 1;
        return true;
      }
      return false;
    });

    final grabbed = <Crystal>[];
    crystals.removeWhere((crystal) {
      final hit = _within(crystal.x, crystal.y, reach + crystal.radius);
      if (hit) grabbed.add(crystal);
      return hit;
    });

    var points = 25 * destroyed * combo;
    for (final crystal in grabbed) {
      points += 40 * combo;
      _burst(crystal.x, crystal.y, AppColors.accent, 8);
    }
    if (destroyed > 0) {
      _burst(playerX, playerY, AppColors.primary, 12);
    }
    if (points > 0) {
      score += points;
      combo = math.min(12, combo + 1);
      comboTimer = 2.6;
      floaters.add(
        Floater(
          text: '+${points.floor()}',
          x: playerX,
          y: playerY - playerRadius - 18,
          color: AppColors.primary,
        ),
      );
    }
  }

  void update(double dt) {
    if (dt <= 0 || width <= 0 || height <= 0) return;
    dt = math.min(dt, 0.033);
    if (phase == RunPhase.paused) return;

    time += dt;
    final starScale = switch (phase) {
      RunPhase.playing => 1 + pressure * 0.9,
      RunPhase.menu => 0.35,
      RunPhase.gameOver => 0.2,
      RunPhase.paused => 0.0,
    };
    _updateStars(dt * starScale);
    _updateParticles(dt);
    _updateFloaters(dt);
    shake = math.max(0.0, shake - dt * 1.8);
    flash = math.max(0.0, flash - dt * 1.5);
    if (shieldFlash > 0) shieldFlash -= dt;

    if (phase == RunPhase.gameOver) {
      notifyListeners();
      return;
    }
    if (phase == RunPhase.menu) {
      _updateMenu();
      notifyListeners();
      return;
    }

    distance += speed * dt;
    score += speed * dt * 0.11;
    if (shieldCooldown > 0) {
      shieldCooldown = math.max(0.0, shieldCooldown - dt);
    }
    if (combo > 1) {
      comboTimer -= dt;
      if (comboTimer <= 0) combo = 1;
    }

    _steer(dt);
    _spawnEngine();
    _recordTrail();
    _moveHazards(dt);
    _collect();
    if (_collide()) {
      _die();
      notifyListeners();
      return;
    }
    _nearMisses();
    _cull();
    _maybeSpawn(dt);
    notifyListeners();
  }

  bool takeUiTick() {
    final signature = Object.hash(
      phase,
      score.floor(),
      combo,
      best,
      newBest,
      shieldCooldown <= 0,
      (shieldCooldown * 30).round(),
      (pressure * 40).round(),
    );
    if (signature == _uiSignature) return false;
    _uiSignature = signature;
    return true;
  }

  @visibleForTesting
  void spawnWaveNow() => _spawnWave();

  @visibleForTesting
  bool gapIsClear() {
    if (gapRight - gapLeft < playerRadius * 3.4) return false;
    for (final rock in rocks) {
      if (rock.y > 8) continue;
      final nearest = rock.x.clamp(gapLeft, gapRight).toDouble();
      if ((nearest - rock.x).abs() < rock.radius - 0.01) return false;
    }
    return true;
  }

  double get _minX => playerRadius + 6;

  double get _maxX => math.max(_minX, width - playerRadius - 6);

  void _seedStars() {
    stars.clear();
    for (var i = 0; i < 80; i++) {
      final depth = _random.nextDouble();
      stars.add(
        Star(
          nx: _random.nextDouble(),
          ny: _random.nextDouble(),
          speed: 0.025 + depth * 0.12,
          size: 0.5 + _random.nextDouble() * 1.6,
          depth: depth,
        ),
      );
    }
  }

  void _updateMenu() {
    _placeMenuShip();
    if (playerY > height) return;
    if (_random.nextDouble() < 0.45) _spawnEngine();
    _recordTrail();
  }

  void _placeMenuShip() {
    const contentHeight = 470.0;
    final floor = height - playerRadius - 18;
    final ceiling = contentHeight + playerRadius;
    playerX = width / 2 + math.sin(time * 0.7) * math.min(36.0, width * 0.08);
    playerX = playerX.clamp(_minX, _maxX).toDouble();
    targetX = playerX;
    if (floor - ceiling < playerRadius * 2.2) {
      playerY = height + 120;
      return;
    }
    playerY = (ceiling + floor) / 2 + math.sin(time * 2.1) * 6;
  }

  void _steer(double dt) {
    final maxSpeed = width * 1.45;
    if (keyboardAxis != 0 && !pointerActive) {
      playerX = (playerX + keyboardAxis * maxSpeed * dt)
          .clamp(_minX, _maxX)
          .toDouble();
      targetX = playerX;
      return;
    }
    final delta = targetX - playerX;
    final step = maxSpeed * dt;
    if (delta.abs() <= step) {
      playerX = targetX;
    } else {
      playerX += step * delta.sign;
    }
    playerX = playerX.clamp(_minX, _maxX).toDouble();
  }

  void _maybeSpawn(double dt) {
    _spawnTimer += dt;
    if (_spawnTimer < _lerp(1.05, 0.56, pressure)) return;
    if (!_topClear() || rocks.length >= 10) return;
    _spawnTimer = 0;
    _spawnWave();
  }

  bool _topClear() {
    for (final rock in rocks) {
      if (rock.y < rock.radius + 24) return false;
    }
    for (final crystal in crystals) {
      if (crystal.y < crystal.radius + 24) return false;
    }
    return true;
  }

  void _spawnWave() {
    waveCount += 1;
    final breathe = waveCount % 6 == 0;
    final desired = playerRadius * (breathe ? 6.2 : _lerp(5.4, 3.6, pressure));
    final minGap = playerRadius * 3.4;
    final maxGap = width - 8;
    final gapWidth = maxGap <= minGap
        ? math.max(0.0, maxGap)
        : desired.clamp(minGap, maxGap).toDouble();
    final half = gapWidth / 2;
    final reach = (_random.nextDouble() - 0.5) * width * 0.5;
    final raw = (width > 0 ? playerX : width / 2) + reach;
    final lo = half + 4;
    final hi = width - half - 4;
    final gapCenter = lo <= hi ? raw.clamp(lo, hi).toDouble() : width / 2;
    gapLeft = gapCenter - half;
    gapRight = gapCenter + half;

    final spawnBoth = _random.nextDouble() < 0.72;
    final leftSide = _random.nextBool();
    if (spawnBoth || leftSide) {
      _spawnRock(left: true);
    }
    if (spawnBoth || !leftSide) {
      _spawnRock(left: false);
    }

    if (half > 18 && (breathe || _random.nextDouble() < 0.7)) {
      crystals.add(
        Crystal(
          x: gapCenter,
          y: -_rand(18, 46),
          radius: 12,
          spin: _rand(0, math.pi),
        ),
      );
    }
  }

  void _spawnRock({required bool left}) {
    final radius = _rand(_lerp(24, 32, pressure), _lerp(46, 64, pressure));
    final double x;
    if (left) {
      final maxCenter = gapLeft - _gapPad - radius;
      final minCenter = radius * 0.15;
      if (maxCenter <= minCenter) return;
      x = _rand(minCenter, maxCenter);
    } else {
      final minCenter = gapRight + _gapPad + radius;
      final maxCenter = width - radius * 0.15;
      if (minCenter >= maxCenter) return;
      x = _rand(minCenter, maxCenter);
    }
    rocks.add(
      Rock(
        x: x,
        y: -radius - _rand(0, 32),
        radius: radius,
        spin: _rand(0, math.pi * 2),
        spinSpeed: _rand(-1.5, 1.5),
        seed: _random.nextInt(9999),
      ),
    );
  }

  void _moveHazards(double dt) {
    final dy = speed * dt;
    for (final rock in rocks) {
      rock.y += dy;
      rock.spin += rock.spinSpeed * dt;
    }
    for (final crystal in crystals) {
      crystal.y += dy;
      crystal.spin += dt * 1.8;
    }
  }

  void _collect() {
    crystals.removeWhere((crystal) {
      final reach = crystal.radius + playerRadius * 0.95;
      if (!_within(crystal.x, crystal.y, reach)) return false;
      _award(40, crystal.x, crystal.y);
      _burst(crystal.x, crystal.y, AppColors.accent, 10);
      feel = Feel.collect;
      return true;
    });
  }

  bool _collide() {
    final hitR = playerRadius * _hitScale;
    for (final rock in rocks) {
      if (_within(rock.x, rock.y, rock.radius + hitR)) return true;
    }
    return false;
  }

  void _nearMisses() {
    for (final rock in rocks) {
      if (rock.passed || rock.y <= playerY) continue;
      rock.passed = true;
      final clearance =
          (rock.x - playerX).abs() - rock.radius - playerRadius * _hitScale;
      if (clearance > 0 && clearance < playerRadius * 0.95) {
        _award(15, rock.x, playerY - 20);
        shake = math.max(shake, 0.18);
      }
    }
  }

  void _cull() {
    final limit = height + 80;
    rocks.removeWhere((rock) => rock.y - rock.radius > limit);
    crystals.removeWhere((crystal) => crystal.y - crystal.radius > limit);
  }

  void _die() {
    phase = RunPhase.gameOver;
    feel = Feel.hit;
    shake = 1;
    flash = 0.9;
    pointerActive = false;
    _burst(playerX, playerY, AppColors.secondary, 16);
    _burst(playerX, playerY, AppColors.primary, 12);
    _commitBest();
  }

  void _commitBest() {
    if (_committed || phase == RunPhase.menu) return;
    _committed = true;
    final value = score.floor();
    newBest = value > best;
    if (!newBest) return;
    best = value;
    onNewBest?.call(value);
  }

  void _award(int base, double x, double y) {
    final gained = base * combo;
    score += gained;
    combo = math.min(12, combo + 1);
    comboTimer = 2.6;
    floaters.add(
      Floater(
        text: '+$gained',
        x: x,
        y: y,
        color: base >= 40 ? AppColors.accent : AppColors.primary,
      ),
    );
    if (floaters.length > 12) {
      floaters.removeRange(0, floaters.length - 12);
    }
  }

  bool _within(double x, double y, double radius) {
    final dx = x - playerX;
    final dy = y - playerY;
    return dx * dx + dy * dy <= radius * radius;
  }

  void _spawnEngine() {
    final life = _rand(0.22, 0.48);
    _addParticle(
      Particle(
        x: playerX + _rand(-3, 3),
        y: playerY + playerRadius * 0.85,
        vx: _rand(-14, 14),
        vy: _rand(30, 110),
        life: life,
        maxLife: life,
        size: _rand(1.6, 3.4),
        color: AppColors.primary,
      ),
    );
  }

  void _burst(double x, double y, Color color, int count) {
    for (var i = 0; i < count; i++) {
      final angle = _rand(0, math.pi * 2);
      final speed = _rand(40, 180);
      final life = _rand(0.25, 0.6);
      _addParticle(
        Particle(
          x: x,
          y: y,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed,
          life: life,
          maxLife: life,
          size: _rand(1.5, 3.6),
          color: color,
        ),
      );
    }
  }

  void _addParticle(Particle particle) {
    particles.add(particle);
    if (particles.length > 160) {
      particles.removeRange(0, particles.length - 160);
    }
  }

  void _recordTrail() {
    trail.add(Offset(playerX, playerY + playerRadius * 0.35));
    if (trail.length > 14) trail.removeAt(0);
  }

  void _updateStars(double scaledDt) {
    for (final star in stars) {
      star.ny += star.speed * scaledDt;
      if (star.ny > 1) star.ny -= 1;
    }
  }

  void _updateParticles(double dt) {
    for (final particle in particles) {
      particle.x += particle.vx * dt;
      particle.y += particle.vy * dt;
      particle.vy += 18 * dt;
      particle.life -= dt;
    }
    particles.removeWhere((particle) => particle.life <= 0);
  }

  void _updateFloaters(double dt) {
    for (final floater in floaters) {
      floater.y -= 36 * dt;
      floater.life -= dt;
    }
    floaters.removeWhere((floater) => floater.life <= 0);
  }

  double _rand(double a, double b) {
    if (b <= a) return a;
    return a + _random.nextDouble() * (b - a);
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;
}
