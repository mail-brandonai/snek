import 'dart:math' as math;

import 'game_state.dart';
import 'vec2.dart';

class SimulationConfig {
  const SimulationConfig({
    this.arenaRadius = 1800,
    this.playerSpeed = 175,
    this.botSpeed = 120,
    this.botTurnRate = 2.2,
    this.botSenseRadius = 320,
    this.botBoundaryBuffer = 360,
    this.botSpawnRadius = 440,
    this.segmentSpacing = 12,
    this.sprintMultiplier = 2.4,
    this.sprintDrainInterval = 0.25,
    this.minimumSprintLength = 4,
    this.initialPellets = 260,
    this.botCount = 3,
    this.initialLength = 12,
  });

  final double arenaRadius;
  final double playerSpeed;
  final double botSpeed;
  final double botTurnRate;
  final double botSenseRadius;
  final double botBoundaryBuffer;
  final double botSpawnRadius;
  final double segmentSpacing;
  final double sprintMultiplier;
  final double sprintDrainInterval;
  final int minimumSprintLength;
  final int initialPellets;
  final int botCount;
  final int initialLength;
}

class GameSimulation {
  GameSimulation({
    this.config = const SimulationConfig(),
    this.seed = 7,
  }) : _random = math.Random(seed) {
    reset();
  }

  final SimulationConfig config;
  final int seed;
  math.Random _random;
  final List<SnakeState> snakes = [];
  final List<FoodPellet> pellets = [];
  final List<FoodPellet> droppedMass = [];
  double elapsed = 0;
  int score = 0;
  bool gameOver = false;
  GameOverReason? gameOverReason;

  SnakeState get player =>
      snakes.firstWhere((snake) => snake.kind == SnakeKind.player);

  int get playerRank {
    final playerLength = player.length;
    final longerSnakes = snakes.where(
      (snake) =>
          snake.alive &&
          snake.kind == SnakeKind.bot &&
          snake.length > playerLength,
    );
    return longerSnakes.length + 1;
  }

  void reset() {
    _random = math.Random(seed);
    snakes.clear();
    pellets.clear();
    droppedMass.clear();
    elapsed = 0;
    score = 0;
    gameOver = false;
    gameOverReason = null;

    snakes.add(
      SnakeState(
        id: 'player',
        kind: SnakeKind.player,
        position: Vec2.zero,
        colorIndex: 0,
        speed: config.playerSpeed,
        initialLength: config.initialLength,
        segmentSpacing: config.segmentSpacing,
      ),
    );

    for (var index = 0; index < config.botCount; index++) {
      snakes.add(
        SnakeState(
          id: 'bot-$index',
          kind: SnakeKind.bot,
          position: _randomPosition(
            minRadius: math.min(300, config.botSpawnRadius * 0.55).toDouble(),
            maxRadius: config.botSpawnRadius,
          ),
          colorIndex: index + 1,
          speed: config.botSpeed,
          initialLength: config.initialLength + index * 2,
          segmentSpacing: config.segmentSpacing,
        ),
      );
    }

    _spawnPellets(config.initialPellets);
  }

  void update(double dt, Vec2 steering, {bool sprinting = false}) {
    if (gameOver || dt <= 0) return;

    player.sprinting = sprinting;
    if (!sprinting) player.sprintDrainAccumulator = 0;

    var remaining = dt;
    while (remaining > 0 && !gameOver) {
      final step = math.min(remaining, 0.05).toDouble();
      elapsed += step;
      _steerPlayer(steering, step);
      _steerBots(step);

      for (final snake in snakes.where((item) => item.alive)) {
        _moveSnake(snake, step);
        _collectPellets(snake);
        _collectDroppedMass(snake);
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
      current + delta.clamp(-maxTurn, maxTurn).toDouble(),
    );
  }

  void _steerBots(double dt) {
    for (final bot in snakes.where(
      (snake) => snake.kind == SnakeKind.bot && snake.alive,
    )) {
      final wander = Vec2(
        math.cos(elapsed * 0.35 + bot.colorIndex),
        math.sin(elapsed * 0.27 + bot.colorIndex * 1.7),
      );
      final boundary = _boundaryAvoidance(bot);
      final threat = _nearbyThreat(bot);
      final interest = _nearestFood(bot);
      final intent = (wander + boundary + threat + interest).normalized();
      final desired = intent.length == 0 ? bot.heading.angle : intent.angle;
      final current = bot.heading.angle;
      final delta = _shortestAngle(desired - current);
      final turnLimit = config.botTurnRate * dt;
      final turn = delta.clamp(-turnLimit, turnLimit).toDouble();
      bot.heading = Vec2.fromAngle(current + turn);
    }
  }

  Vec2 _boundaryAvoidance(SnakeState snake) {
    final distance = snake.head.length;
    final threshold = config.arenaRadius - config.botBoundaryBuffer;
    if (distance <= threshold || distance == 0) return Vec2.zero;

    final double urgency = ((distance - threshold) / config.botBoundaryBuffer)
        .clamp(0.0, 1.0)
        .toDouble();
    return snake.head.normalized() * (-urgency * 3);
  }

  Vec2 _nearbyThreat(SnakeState snake) {
    var avoidance = Vec2.zero;
    for (final other in snakes.where(
      (candidate) => candidate.id != snake.id && candidate.alive,
    )) {
      for (final segment in other.body.skip(1)) {
        final offset = snake.head - segment;
        final distance = offset.length;
        if (distance == 0 || distance > config.botSenseRadius) continue;
        final double urgency =
            (config.botSenseRadius - distance) / config.botSenseRadius;
        avoidance += offset.normalized() * (urgency * urgency * 4);
      }
    }
    return avoidance;
  }

  Vec2 _nearestFood(SnakeState snake) {
    FoodPellet? nearest;
    var nearestDistance = config.botSenseRadius;
    for (final source in [droppedMass, pellets]) {
      for (final pellet in source) {
        final distance = snake.head.distanceTo(pellet.position);
        if (distance < nearestDistance) {
          nearest = pellet;
          nearestDistance = distance;
        }
      }
    }
    if (nearest == null) return Vec2.zero;
    return (nearest.position - snake.head).normalized() * 1.5;
  }

  void _moveSnake(SnakeState snake, double dt) {
    final currentHead = snake.head;
    final movementMultiplier = snake.kind == SnakeKind.player && snake.sprinting
        ? config.sprintMultiplier
        : 1.0;
    final nextHead =
        snake.head + snake.heading * (snake.speed * movementMultiplier * dt);
    final hasMoved = nextHead.distanceTo(currentHead) > 0;
    final growsThisStep = snake.growth > 0;
    if (hasMoved) {
      snake.body.insert(0, nextHead);
      if (!growsThisStep) snake.body.removeLast();
      if (growsThisStep) snake.growth--;
      _reflowBody(snake);
    }

    if (snake.kind == SnakeKind.player && snake.sprinting) {
      _drainSprint(snake, dt);
    }

    if (nextHead.length > config.arenaRadius - snake.radius) {
      _defeat(snake, GameOverReason.boundary);
    }
  }

  void _reflowBody(SnakeState snake) {
    for (var index = 1; index < snake.body.length; index++) {
      final previous = snake.body[index - 1];
      var direction = snake.body[index] - previous;
      if (direction.length == 0) {
        direction = index == 1
            ? snake.heading * -1
            : snake.body[index - 1] - snake.body[index - 2];
      }
      final normalized =
          direction.length == 0 ? snake.heading * -1 : direction.normalized();
      snake.body[index] = previous + normalized * snake.segmentSpacing;
    }
  }

  void _drainSprint(SnakeState snake, double dt) {
    snake.sprintDrainAccumulator += dt;
    while (snake.sprintDrainAccumulator >= config.sprintDrainInterval) {
      snake.sprintDrainAccumulator -= config.sprintDrainInterval;
      final position = snake.shedMass(
        minimumLength: config.minimumSprintLength,
      );
      if (position == null) {
        snake.sprintDrainAccumulator = 0;
        return;
      }
      droppedMass.add(FoodPellet(position: position, value: 1));
    }
  }

  void _collectPellets(SnakeState snake) {
    _collectFood(snake, pellets);
  }

  void _collectDroppedMass(SnakeState snake) {
    _collectFood(snake, droppedMass);
  }

  void _collectFood(SnakeState snake, List<FoodPellet> source) {
    for (var index = source.length - 1; index >= 0; index--) {
      final pellet = source[index];
      if (snake.head.distanceTo(pellet.position) <= snake.radius + 6) {
        source.removeAt(index);
        snake.grow(pellet.value);
        if (snake.kind == SnakeKind.player) score += pellet.value;
      }
    }
  }

  void _resolveCollisions() {
    for (final snake in snakes.where((item) => item.alive)) {
      for (final other in snakes.where(
        (item) => item.id != snake.id && item.alive,
      )) {
        for (final segment in other.body.skip(2)) {
          if (snake.head.distanceTo(segment) < snake.radius + other.radius) {
            _defeat(snake, GameOverReason.bodyCollision);
            break;
          }
        }
        if (!snake.alive) break;
      }
    }
  }

  void _defeat(SnakeState snake, GameOverReason reason) {
    if (!snake.alive) return;
    snake.alive = false;
    if (snake.kind == SnakeKind.player) {
      gameOver = true;
      gameOverReason = reason;
    }
    for (var index = 0; index < snake.body.length; index += 3) {
      droppedMass.add(FoodPellet(position: snake.body[index], value: 2));
    }
  }

  void _spawnPellets(int count) {
    for (var index = 0; index < count; index++) {
      pellets.add(FoodPellet(position: _randomPosition()));
    }
  }

  Vec2 _randomPosition({double minRadius = 0, double? maxRadius}) {
    final upperRadius = math
        .min(
          config.arenaRadius,
          maxRadius ?? config.arenaRadius,
        )
        .toDouble();
    final lowerRadius = math.min(minRadius, upperRadius).toDouble();
    final radius =
        lowerRadius + _random.nextDouble() * (upperRadius - lowerRadius);
    final angle = _random.nextDouble() * math.pi * 2;
    return Vec2(math.cos(angle) * radius, math.sin(angle) * radius);
  }

  static double _shortestAngle(double angle) {
    while (angle > math.pi) {
      angle -= math.pi * 2;
    }
    while (angle < -math.pi) {
      angle += math.pi * 2;
    }
    return angle;
  }
}
