import 'dart:math';

import 'package:game_2248/game/aether_world.dart';
import 'package:game_2248/game/game_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every wave leaves a flyable gap', () {
    for (final width in [320.0, 360.0, 420.0]) {
      for (final seed in List.generate(25, (index) => index)) {
        final world = AetherWorld(random: Random(seed));
        world.layout(Size(width, 780));
        world.start();
        for (final distance in [0.0, 2200.0, 9000.0]) {
          world.distance = distance;
          world.rocks.clear();
          world.crystals.clear();
          world.spawnWaveNow();
          expect(
            world.gapIsClear(),
            isTrue,
            reason: 'width $width seed $seed distance $distance',
          );
        }
      }
    }
  });

  test('a rock strike ends the run and keeps the score', () {
    var saved = 0;
    final world = AetherWorld(
      random: Random(4),
      onNewBest: (value) => saved = value,
    );
    world.layout(const Size(400, 800));
    world.start();
    world.score = 40;
    world.rocks.add(
      Rock(
        x: world.playerX,
        y: world.playerY,
        radius: 30,
        spin: 0,
        spinSpeed: 0,
        seed: 1,
      ),
    );

    world.update(1 / 60);

    expect(world.phase, RunPhase.gameOver);
    expect(world.best, greaterThanOrEqualTo(40));
    expect(saved, world.best);
  });

  test('shield clears a rock and then cools down', () {
    final world = AetherWorld(random: Random(2));
    world.layout(const Size(400, 800));
    world.start();
    world.rocks.add(
      Rock(
        x: world.playerX,
        y: world.playerY,
        radius: 28,
        spin: 0,
        spinSpeed: 0,
        seed: 3,
      ),
    );

    world.tryShield();

    expect(world.rocks, isEmpty);
    expect(world.shieldCooldown, AetherWorld.shieldCooldownMax);

    world.tryShield();

    expect(world.shieldCooldown, AetherWorld.shieldCooldownMax);
  });
}
