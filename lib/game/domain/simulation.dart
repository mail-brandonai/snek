import 'dart:math' as math;

import 'game_state.dart';
import 'vec2.dart';

class SimulationConfig {
  const SimulationConfig({
    this.arenaRadius = 1800,
    this.playerSpeed = 175,
    this.botSpeed = 120,
    this.initialPellets = 260,
    this.botCount = 3,
    this.initialLength = 12,
  });

  final double arenaRadius;
  final double playerSpeed;
  final double botSpeed;
  final int initialPellets;
  final int botCount;
  final int initialLength;
}

class GameSimulation {
  GameSimulation({
    SimulationConfig config = const SimulationConfig(),
    int seed = 7,
  })  : config = config,
        _random = math.Random(seed) {
    reset();
  }

  final SimulationConfig config;
  final math.Random _random;
  final List<SnakeState> snakes = [];
  final List<FoodPellet> pellets = [];
  final List<FoodPellet> droppedMass = [];
  double elapsed = 0;
  int score = 0;
  bool gameOver = false;

  SnakeState get player =>
      snakes.firstWhere((snake) => snake.kind == SnakeKind.player);

  void reset() {
    snakes.clear();
    pellets.clear();
    droppedMass.clear();
    elapsed = 0;
    score = 0;
    gameOver = false;

    snakes.add(
      SnakeState(
        id: 'player',
        kind: SnakeKind.player,
        position: Vec2.zero,
        colorIndex: 0,
        speed: config.playerSpeed,
        initialLength: config.initialLength,
      ),
    );

    for (var index = 0; index < config.botCount; index++) {
      snakes.add(
        SnakeState(
          id: 'bot-$index',
          kind: SnakeKind.bot,
          position: _randomPosition(minRadius: 300),
          colorIndex: index + 1,
          speed: config.botSpeed,
          initialLength: config.initialLength + index * 2,
        ),
      );
    }

    _spawnPellets(config.initialPellets);
  }

  void update(double dt, Vec2 steering) {
    if (gameOver || dt <= 0) return;

    var remaining = dt;
    while (remaining > 0 && !gameOver) {
      final step = math.min(remaining, 0.05).toDouble();
      elapsed += step;
      _steerPlayer(steering, step);
      _steerBots(step);

      for (final snake in snakes.where((item) => item.alive)) {
        _moveSnake(snake, step);
        _collectPellets(snake);
      }
      _resolveCollisions();

      if (pellets.length < config.initialPellets ~/ 2) {
        _spawnPellets(config.initialPellets - pellets.length);
      }
      remaining -= step;
    }
  }

  void restart() => reset();

  void _steerPlayer(Vec2 steering, double dt) {
    if (steering.length == 0) return;
    final target = steering.angle;
    final current = player.heading.angle;
    final delta = _shortestAngle(target - current);
    final maxTurn = 6.0 * dt;
    player.heading = Vec2.fromAngle(
      current + (delta.clamp(-maxTurn, maxTurn) as double),
    );
  }

  void _steerBots(double dt) {
    for (final bot in snakes.where(
      (snake) => snake.kind == SnakeKind.bot && snake.alive,
    )) {
      final target = Vec2(
        math.cos(elapsed * 0.35 + bot.colorIndex),
        math.sin(elapsed * 0.27 + bot.colorIndex * 1.7),
      );
      final desired = target.angle;
      final current = bot.heading.angle;
      final delta = _shortestAngle(desired - current);
      bot.heading = Vec2.fromAngle(
        current + (delta.clamp(-2.2 * dt, 2.2 * dt) as double),
      );
    }
  }

  void _moveSnake(SnakeState snake, double dt) {
    final nextHead = snake.head + snake.heading * (snake.speed * dt);
    snake.body.insert(0, nextHead);

    final desiredSegments = snake.length;
    while (snake.body.length > desiredSegments) {
      snake.body.removeLast();
    }
    if (snake.growth > 0) snake.growth--;

    if (nextHead.length > config.arenaRadius - snake.radius) {
      snake.alive = false;
      if (snake.kind == SnakeKind.player) gameOver = true;
    }
  }

  void _collectPellets(SnakeState snake) {
    for (var index = pellets.length - 1; index >= 0; index--) {
      final pellet = pellets[index];
      if (snake.head.distanceTo(pellet.position) <= snake.radius + 6) {
        pellets.removeAt(index);
        snake.grow(pellet.value);
        if (snake.kind == SnakeKind.player) score += pellet.value;
      }
    }
  }

  void _resolveCollisions() {
    final playerSnake = player;
    if (!playerSnake.alive) return;

    for (final other in snakes.where(
      (snake) => snake.id != playerSnake.id && snake.alive,
    )) {
      for (final segment in other.body.skip(2)) {
        if (playerSnake.head.distanceTo(segment) <
            playerSnake.radius + other.radius) {
          _defeat(playerSnake);
          return;
        }
      }
    }

    for (final segment in playerSnake.body.skip(8)) {
      if (playerSnake.head.distanceTo(segment) < playerSnake.radius * 1.7) {
        _defeat(playerSnake);
        return;
      }
    }
  }

  void _defeat(SnakeState snake) {
    snake.alive = false;
    if (snake.kind == SnakeKind.player) gameOver = true;
    for (var index = 0; index < snake.body.length; index += 3) {
      droppedMass.add(FoodPellet(position: snake.body[index], value: 2));
    }
  }

  void _spawnPellets(int count) {
    for (var index = 0; index < count; index++) {
      pellets.add(FoodPellet(position: _randomPosition()));
    }
  }

  Vec2 _randomPosition({double minRadius = 0}) {
    final radius =
        minRadius + _random.nextDouble() * (config.arenaRadius - minRadius);
    final angle = _random.nextDouble() * math.pi * 2;
    return Vec2(math.cos(angle) * radius, math.sin(angle) * radius);
  }

  static double _shortestAngle(double angle) {
    while (angle > math.pi) angle -= math.pi * 2;
    while (angle < -math.pi) angle += math.pi * 2;
    return angle;
  }
}
