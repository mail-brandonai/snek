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
    this.pelletRefillThreshold = 0.65,
    this.pelletRefillRate = 10,
    this.botCount = 3,
    this.initialLength = 12,
    this.botRespawnDelay = 3,
    this.botRespawnSafeDistance = 520,
    this.botRespawnAttempts = 32,
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
  final double pelletRefillThreshold;
  final double pelletRefillRate;
  final int botCount;
  final int initialLength;
  final double botRespawnDelay;
  final double botRespawnSafeDistance;
  final int botRespawnAttempts;
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
  final Map<String, double> _botRespawnTimers = {};
  double elapsed = 0;
  double _pelletRefillAccumulator = 0;
  int score = 0;
  bool gameOver = false;
  GameOverReason? gameOverReason;
  RunStats? finalStats;

  SnakeState get player =>
      snakes.firstWhere((snake) => snake.kind == SnakeKind.player);

  int get playerRank {
    return _rankForLength(player.length);
  }

  List<LeaderboardEntry> get leaderboard {
    final living = snakes.where((snake) => snake.alive).toList()
      ..sort((left, right) {
        final lengthOrder = right.length.compareTo(left.length);
        if (lengthOrder != 0) return lengthOrder;
        final leftPlayerOrder = left.kind == SnakeKind.player ? 1 : 0;
        final rightPlayerOrder = right.kind == SnakeKind.player ? 1 : 0;
        final tieOrder = rightPlayerOrder.compareTo(leftPlayerOrder);
        if (tieOrder != 0) return tieOrder;
        return left.id.compareTo(right.id);
      });

    return [
      for (var index = 0; index < math.min(5, living.length); index++)
        LeaderboardEntry(
          id: living[index].id,
          kind: living[index].kind,
          colorIndex: living[index].colorIndex,
          length: living[index].length,
          rank: index + 1,
        ),
    ];
  }

  RunStats get currentRunStats => RunStats(
        score: score,
        length: player.length,
        survivalSeconds: elapsed,
        rank: playerRank,
      );

  bool get canSprint =>
      !gameOver && player.alive && player.length > config.minimumSprintLength;

  void reset() {
    _random = math.Random(seed);
    snakes.clear();
    pellets.clear();
    droppedMass.clear();
    _botRespawnTimers.clear();
    elapsed = 0;
    _pelletRefillAccumulator = 0;
    score = 0;
    gameOver = false;
    gameOverReason = null;
    finalStats = null;

    snakes.add(
      SnakeState(
        id: 'player',
        kind: SnakeKind.player,
        position: Vec2.zero,
        colorIndex: 0,
        speed: config.playerSpeed,
        initialLength: config.minimumSprintLength,
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

    player.sprinting = sprinting && canSprint;
    if (!player.sprinting) player.sprintDrainAccumulator = 0;

    var remaining = dt;
    while (remaining > 0 && !gameOver) {
      final step = math.min(remaining, 0.05).toDouble();
      elapsed += step;
      _steerPlayer(steering, step);
      _steerBots(step);

      for (final snake in snakes.where((item) => item.alive)) {
        _moveSnake(snake, step);
        if (!snake.alive) continue;
        _collectPellets(snake);
        _collectDroppedMass(snake);
      }
      _resolveCollisions();
      _advanceBotRespawns(step);
      _maintainPelletDensity(step);
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
      snake.movementTrail.insert(0, nextHead);
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
    final maximumDistance =
        ((snake.body.length - 1) * snake.segmentSpacing).toDouble();
    _trimMovementTrail(
      snake,
      maximumDistance + snake.segmentSpacing * 2,
    );

    for (var index = 1; index < snake.body.length; index++) {
      snake.body[index] = _sampleMovementTrail(
        snake,
        index * snake.segmentSpacing,
      );
    }
  }

  void _trimMovementTrail(SnakeState snake, double maximumDistance) {
    if (snake.movementTrail.length < 3) return;

    var distance = 0.0;
    for (var index = 0; index < snake.movementTrail.length - 1; index++) {
      distance += snake.movementTrail[index].distanceTo(
        snake.movementTrail[index + 1],
      );
      if (distance > maximumDistance) {
        final removeFrom = index + 2;
        if (removeFrom < snake.movementTrail.length) {
          snake.movementTrail.removeRange(
            removeFrom,
            snake.movementTrail.length,
          );
        }
        return;
      }
    }
  }

  Vec2 _sampleMovementTrail(SnakeState snake, double distance) {
    var travelled = 0.0;
    final trail = snake.movementTrail;
    for (var index = 0; index < trail.length - 1; index++) {
      final start = trail[index];
      final end = trail[index + 1];
      final segmentLength = start.distanceTo(end);
      if (segmentLength == 0) continue;
      if (travelled + segmentLength >= distance) {
        final fraction = (distance - travelled) / segmentLength;
        return start + (end - start) * fraction;
      }
      travelled += segmentLength;
    }

    final last = trail.last;
    if (trail.length < 2) return last;

    final tailDirection = last - trail[trail.length - 2];
    final normalized = tailDirection.length == 0
        ? snake.heading * -1
        : tailDirection.normalized();
    return last + normalized * (distance - travelled);
  }

  void _drainSprint(SnakeState snake, double dt) {
    snake.sprintDrainAccumulator += dt;
    while (snake.sprintDrainAccumulator >= config.sprintDrainInterval) {
      snake.sprintDrainAccumulator -= config.sprintDrainInterval;
      final position = snake.shedMass(
        minimumLength: config.minimumSprintLength,
      );
      if (position == null) {
        snake.sprinting = false;
        snake.sprintDrainAccumulator = 0;
        return;
      }
      droppedMass.add(FoodPellet(position: position, value: 1));
      if (snake.length <= config.minimumSprintLength) {
        snake.sprinting = false;
        snake.sprintDrainAccumulator = 0;
        return;
      }
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
      finalStats = RunStats(
        score: score,
        length: snake.length,
        survivalSeconds: elapsed,
        rank: _rankForLength(snake.length),
      );
      gameOver = true;
      gameOverReason = reason;
    } else {
      _botRespawnTimers[snake.id] = config.botRespawnDelay;
    }
    for (var index = 0; index < snake.body.length; index += 3) {
      droppedMass.add(FoodPellet(position: snake.body[index], value: 2));
    }
  }

  void _spawnPellets(int count) {
    if (count <= 0) return;
    for (var index = 0; index < count; index++) {
      pellets.add(FoodPellet(position: _randomPosition()));
    }
  }

  void _maintainPelletDensity(double dt) {
    final target = config.initialPellets;
    if (target <= 0 || pellets.length >= target) {
      _pelletRefillAccumulator = 0;
      return;
    }

    final threshold = target * config.pelletRefillThreshold;
    if (pellets.length >= threshold) return;

    _pelletRefillAccumulator += dt * config.pelletRefillRate;
    final requested = _pelletRefillAccumulator.floor();
    if (requested == 0) return;

    final count = math.min(requested, target - pellets.length).toInt();
    _spawnPellets(count);
    _pelletRefillAccumulator -= count;
  }

  void _advanceBotRespawns(double dt) {
    if (_botRespawnTimers.isEmpty) return;

    final due = <String>[];
    for (final entry in _botRespawnTimers.entries.toList()) {
      final remaining = entry.value - dt;
      if (remaining <= 0) {
        due.add(entry.key);
      } else {
        _botRespawnTimers[entry.key] = remaining;
      }
    }

    for (final id in due) {
      final bot = snakes.firstWhere((snake) => snake.id == id);
      if (!gameOver && !bot.alive) {
        bot.resetAt(_findBotSpawnPosition(bot));
      }
      _botRespawnTimers.remove(id);
    }
  }

  Vec2 _findBotSpawnPosition(SnakeState bot) {
    final spawnRadius = math
        .max(
          0.0,
          config.arenaRadius - config.botBoundaryBuffer,
        )
        .toDouble();
    Vec2? bestPosition;
    var bestClearance = -double.infinity;

    for (var attempt = 0; attempt < config.botRespawnAttempts; attempt++) {
      final candidate = _randomPosition(maxRadius: spawnRadius);
      final clearance = _spawnClearance(candidate, bot);
      if (clearance > bestClearance) {
        bestPosition = candidate;
        bestClearance = clearance;
      }
      if (clearance >= config.botRespawnSafeDistance) return candidate;
    }

    return bestPosition ?? _randomPosition(maxRadius: spawnRadius);
  }

  double _spawnClearance(Vec2 candidate, SnakeState bot) {
    var clearance = double.infinity;
    for (final snake in snakes.where((item) => item.alive)) {
      for (var index = 0; index < bot.spawnLength; index++) {
        final candidateSegment =
            candidate - Vec2(index * bot.segmentSpacing, 0);
        for (final segment in snake.body) {
          clearance = math.min(
            clearance,
            candidateSegment.distanceTo(segment),
          );
        }
      }
    }
    return clearance;
  }

  int _rankForLength(int length) {
    final longerSnakes = snakes.where(
      (snake) =>
          snake.alive && snake.kind == SnakeKind.bot && snake.length > length,
    );
    return longerSnakes.length + 1;
  }

  Vec2 _randomPosition({double minRadius = 0, double? maxRadius}) {
    final upperRadius = math
        .min(
          config.arenaRadius,
          maxRadius ?? config.arenaRadius,
        )
        .clamp(0.0, double.infinity)
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
