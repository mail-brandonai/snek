import 'dart:math' as math;

import 'game_state.dart';
import 'vec2.dart';

class SimulationConfig {
  const SimulationConfig({
    this.arenaRadius = 1800,
    this.arenaBoundaryWarningBuffer = 260,
    this.playerSpeed = 175,
    this.botSpeed = 120,
    this.botTurnRate = 2.2,
    this.botSenseRadius = 320,
    this.botBoundaryBuffer = 360,
    this.botSpawnRadius = 440,
    this.segmentSpacing = 12,
    this.growthExpressionRate = 0.05,
    this.sprintMultiplier = 2.4,
    this.sprintDrainInterval = 0.35,
    this.naturalPelletValue = 1,
    this.sprintDropValue = 1,
    this.defeatDropValue = 3,
    this.minimumSprintLength = 4,
    this.initialPellets = 260,
    this.pelletRefillThreshold = 0.65,
    this.pelletRefillRate = 10,
    this.botCount = 3,
    this.maxBotCount = 10,
    this.initialLength = 12,
    this.botRespawnDelay = 3,
    this.botRespawnSafeDistance = 520,
    this.botRespawnAttempts = 32,
    this.botPopulationInterval = 11,
    this.botPressureRadius = 840,
    this.botPressureWeight = 2.0,
    this.botInterceptLeadTime = 1.45,
    this.botDroppedMassWeight = 2.3,
    this.botGrowthMultiplier = 1.35,
    this.botRetreatLength = 78,
    this.botRetreatBoundaryBuffer = 150,
    this.botRetreatWeight = 6,
    this.botSizeSpeedPenalty = 0.003,
    this.collisionPingDuration = 0.9,
  });

  final double arenaRadius;
  final double arenaBoundaryWarningBuffer;
  final double playerSpeed;
  final double botSpeed;
  final double botTurnRate;
  final double botSenseRadius;
  final double botBoundaryBuffer;
  final double botSpawnRadius;
  final double segmentSpacing;

  /// Fraction of head travel that expresses pending length at the tail.
  ///
  /// Growth is represented by a fractional terminal segment, so this value
  /// controls the cadence of the extension without deforming existing body
  /// spacing. Lower values create a slower, softer growth transition.
  final double growthExpressionRate;
  final double sprintMultiplier;
  final double sprintDrainInterval;
  final int naturalPelletValue;
  final int sprintDropValue;
  final int defeatDropValue;
  final int minimumSprintLength;
  final int initialPellets;
  final double pelletRefillThreshold;
  final double pelletRefillRate;
  final int botCount;
  final int maxBotCount;
  final int initialLength;
  final double botRespawnDelay;
  final double botRespawnSafeDistance;
  final int botRespawnAttempts;
  final double botPopulationInterval;
  final double botPressureRadius;
  final double botPressureWeight;
  final double botInterceptLeadTime;
  final double botDroppedMassWeight;
  final double botGrowthMultiplier;
  final int botRetreatLength;
  final double botRetreatBoundaryBuffer;
  final double botRetreatWeight;
  final double botSizeSpeedPenalty;
  final double collisionPingDuration;
}

class _BotProfile {
  const _BotProfile({
    required this.disposition,
    required this.lengthBonus,
    required this.speedMultiplier,
  });

  final BotDisposition disposition;
  final int lengthBonus;
  final double speedMultiplier;
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
  final List<CollisionPing> collisionPings = [];
  final Map<String, double> _botRespawnTimers = {};
  double elapsed = 0;
  double _pelletRefillAccumulator = 0;
  double _botPopulationAccumulator = 0;
  int score = 0;
  bool gameOver = false;
  GameOverReason? gameOverReason;
  RunStats? finalStats;

  SnakeState get player =>
      snakes.firstWhere((snake) => snake.kind == SnakeKind.player);

  int get playerRank {
    return _rankForLength(player.length);
  }

  int get livingBotCount => snakes.where((snake) {
        return snake.kind == SnakeKind.bot && snake.alive;
      }).length;

  int get totalBotCount =>
      snakes.where((snake) => snake.kind == SnakeKind.bot).length;

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
    collisionPings.clear();
    _botRespawnTimers.clear();
    elapsed = 0;
    _pelletRefillAccumulator = 0;
    _botPopulationAccumulator = 0;
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

    final initialBotCount = math.min(
      config.botCount,
      math.max(0, config.maxBotCount),
    );
    for (var index = 0; index < initialBotCount; index++) {
      snakes.add(_createBot(index));
    }

    _spawnPellets(config.initialPellets);
  }

  void update(double dt, Vec2 steering, {bool sprinting = false}) {
    if (dt <= 0) return;
    if (gameOver) {
      _advanceCollisionPings(dt);
      return;
    }

    player.sprinting = sprinting && canSprint;
    if (!player.sprinting) player.sprintDrainAccumulator = 0;

    var remaining = dt;
    while (remaining > 0 && !gameOver) {
      final step = math.min(remaining, 0.05).toDouble();
      _advanceCollisionPings(step);
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
      _advanceBotPopulation(step);
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
      if (!bot.retreating && bot.length >= config.botRetreatLength) {
        bot.retreating = true;
      }
      if (bot.retreating) {
        _turnBotToward(bot, _retreatDirection(bot), dt);
        continue;
      }

      final wander = Vec2(
        math.cos(elapsed * 0.35 + bot.colorIndex),
        math.sin(elapsed * 0.27 + bot.colorIndex * 1.7),
      );
      final boundary = _boundaryAvoidance(bot);
      final threat = _nearbyThreat(bot);
      final interest = _nearestFood(bot);
      final droppedMassInterest = _nearestDroppedMass(bot);
      final pressure = _playerPressure(bot);
      final intent = (wander * _wanderWeight(bot) +
              boundary * _boundaryWeight(bot) +
              threat * _threatWeight(bot) +
              interest * _foodWeight(bot) +
              droppedMassInterest * _droppedMassWeight(bot) +
              pressure * _pressureWeight(bot))
          .normalized();
      _turnBotToward(bot, intent, dt);
    }
  }

  void _turnBotToward(SnakeState bot, Vec2 intent, double dt) {
    final desired = intent.length == 0 ? bot.heading.angle : intent.angle;
    final current = bot.heading.angle;
    final delta = _shortestAngle(desired - current);
    final turnLimit = config.botTurnRate * dt;
    final turn = delta.clamp(-turnLimit, turnLimit).toDouble();
    bot.heading = Vec2.fromAngle(current + turn);
  }

  Vec2 _retreatDirection(SnakeState bot) {
    final direction =
        bot.head.length == 0 ? bot.heading : bot.head.normalized();
    final target = direction *
        math.max(
          0.0,
          config.arenaRadius - config.botRetreatBoundaryBuffer,
        );
    return (target - bot.head).normalized() * config.botRetreatWeight;
  }

  double _wanderWeight(SnakeState bot) {
    switch (bot.disposition) {
      case BotDisposition.defensive:
        return 0.85;
      case BotDisposition.aggressive:
        return 0.55;
      case BotDisposition.opportunistic:
        return 0.7;
      case BotDisposition.wanderer:
        return 1.35;
    }
  }

  double _boundaryWeight(SnakeState bot) {
    switch (bot.disposition) {
      case BotDisposition.defensive:
        return 1.35;
      case BotDisposition.aggressive:
        return 0.85;
      case BotDisposition.opportunistic:
        return 1.0;
      case BotDisposition.wanderer:
        return 1.0;
    }
  }

  double _threatWeight(SnakeState bot) {
    switch (bot.disposition) {
      case BotDisposition.defensive:
        return 1.7;
      case BotDisposition.aggressive:
        return 0.55;
      case BotDisposition.opportunistic:
        return 0.9;
      case BotDisposition.wanderer:
        return 1.15;
    }
  }

  double _foodWeight(SnakeState bot) {
    switch (bot.disposition) {
      case BotDisposition.defensive:
        return 0.85;
      case BotDisposition.aggressive:
        return 0.75;
      case BotDisposition.opportunistic:
        return 1.45;
      case BotDisposition.wanderer:
        return 0.7;
    }
  }

  double _droppedMassWeight(SnakeState bot) {
    switch (bot.disposition) {
      case BotDisposition.defensive:
        return 0.8;
      case BotDisposition.aggressive:
        return 1.35;
      case BotDisposition.opportunistic:
        return 2.1;
      case BotDisposition.wanderer:
        return 0.65;
    }
  }

  double _pressureWeight(SnakeState bot) {
    switch (bot.disposition) {
      case BotDisposition.defensive:
        return 0.25;
      case BotDisposition.aggressive:
        return 1.7;
      case BotDisposition.opportunistic:
        return 0.8;
      case BotDisposition.wanderer:
        return 0.4;
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

  Vec2 _nearestDroppedMass(SnakeState snake) {
    FoodPellet? nearest;
    var nearestDistance = config.botSenseRadius;
    for (final pellet in droppedMass) {
      final distance = snake.head.distanceTo(pellet.position);
      if (distance < nearestDistance) {
        nearest = pellet;
        nearestDistance = distance;
      }
    }
    if (nearest == null) return Vec2.zero;
    return (nearest.position - snake.head).normalized() *
        config.botDroppedMassWeight;
  }

  Vec2 _playerPressure(SnakeState bot) {
    if (!player.alive) return Vec2.zero;

    final distance = bot.head.distanceTo(player.head);
    if (distance > config.botPressureRadius) return Vec2.zero;

    final leadDistance = player.speed * config.botInterceptLeadTime;
    final interceptPoint = player.head + player.heading * leadDistance;
    final direction = interceptPoint - bot.head;
    if (direction.length == 0) return Vec2.zero;

    final proximity =
        ((config.botPressureRadius - distance) / config.botPressureRadius)
            .clamp(0.0, 1.0)
            .toDouble();
    final sizeFactor = bot.length >= player.length ? 1.25 : 0.8;
    return direction.normalized() *
        (config.botPressureWeight * (0.65 + proximity * 0.35) * sizeFactor);
  }

  void _moveSnake(SnakeState snake, double dt) {
    final currentHead = snake.head;
    final movementMultiplier = snake.kind == SnakeKind.player && snake.sprinting
        ? config.sprintMultiplier
        : 1.0;
    var speed = snake.speed;
    if (snake.kind == SnakeKind.bot) {
      final excessLength = math.max(0, snake.length - snake.spawnLength);
      final mobilityPenalty = (excessLength * config.botSizeSpeedPenalty)
          .clamp(0.0, 0.28)
          .toDouble();
      speed *= 1 - mobilityPenalty;
    }
    final nextHead =
        snake.head + snake.heading * (speed * movementMultiplier * dt);
    final hasMoved = nextHead.distanceTo(currentHead) > 0;
    if (hasMoved) {
      final travelled = nextHead.distanceTo(currentHead);
      snake.body.insert(0, nextHead);
      snake.movementTrail.insert(0, nextHead);
      snake.body.removeLast();
      if (snake.growthExpressionRemaining > 0) {
        snake.expressGrowth(travelled * config.growthExpressionRate);
      }
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
    final fullLength = snake.fullyExpressedLength;
    final extension = snake.growthExtensionDistance;
    final maximumDistance = fullLength <= 0
        ? extension
        : ((fullLength - 1) * snake.segmentSpacing + extension).toDouble();
    _trimMovementTrail(
      snake,
      maximumDistance + snake.segmentSpacing * 2,
    );

    final visibleBody = <Vec2>[];
    for (var index = 0; index < fullLength; index++) {
      visibleBody.add(
        _sampleMovementTrail(snake, index * snake.segmentSpacing),
      );
    }
    if (extension > 0.0001 && visibleBody.isNotEmpty) {
      visibleBody.add(
        _sampleMovementTrail(
          snake,
          (fullLength - 1) * snake.segmentSpacing + extension,
        ),
      );
    }
    snake.body
      ..clear()
      ..addAll(visibleBody);
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
      droppedMass.add(
        FoodPellet(
          position: position,
          value: config.sprintDropValue,
          kind: FoodPelletKind.sprintDrop,
          sourceColorIndex: snake.colorIndex,
        ),
      );
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
        final growth = snake.kind == SnakeKind.bot
            ? (pellet.value * config.botGrowthMultiplier)
                .round()
                .clamp(1, double.infinity)
                .toInt()
            : pellet.value;
        snake.grow(growth);
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
    if (reason == GameOverReason.bodyCollision) {
      collisionPings.add(
        CollisionPing(
          position: snake.head,
          durationSeconds: config.collisionPingDuration,
        ),
      );
    }
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
    if (reason == GameOverReason.bodyCollision) {
      for (var index = 0; index < snake.body.length; index += 3) {
        droppedMass.add(
          FoodPellet(
            position: snake.body[index],
            value: config.defeatDropValue,
            kind: FoodPelletKind.defeatDrop,
            sourceColorIndex: snake.colorIndex,
          ),
        );
      }
    }
  }

  void _advanceCollisionPings(double dt) {
    for (final ping in collisionPings) {
      ping.remainingSeconds -= dt;
    }
    collisionPings.removeWhere((ping) => ping.remainingSeconds <= 0);
  }

  void _spawnPellets(int count) {
    if (count <= 0) return;
    for (var index = 0; index < count; index++) {
      pellets.add(
        FoodPellet(
          position: _randomPosition(),
          value: config.naturalPelletValue,
        ),
      );
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

  void _advanceBotPopulation(double dt) {
    if (config.botCount <= 0 ||
        config.maxBotCount <= totalBotCount ||
        config.botPopulationInterval <= 0) {
      return;
    }

    _botPopulationAccumulator += dt;
    while (_botPopulationAccumulator >= config.botPopulationInterval &&
        totalBotCount < config.maxBotCount) {
      _botPopulationAccumulator -= config.botPopulationInterval;
      _spawnAdditionalBot(totalBotCount);
    }
  }

  void _spawnAdditionalBot(int index) {
    final bot = _createBot(index, safeSpawn: true);
    snakes.add(bot);
  }

  SnakeState _createBot(int index, {bool safeSpawn = false}) {
    final profile = _profileForBot(index);
    final bot = SnakeState(
      id: 'bot-$index',
      kind: SnakeKind.bot,
      position: Vec2.zero,
      colorIndex: index + 1,
      disposition: profile.disposition,
      speed: config.botSpeed * profile.speedMultiplier,
      initialLength: config.initialLength + profile.lengthBonus,
      segmentSpacing: config.segmentSpacing,
    );

    final position = safeSpawn
        ? _findBotSpawnPosition(bot)
        : _randomPosition(
            minRadius: math.min(300, config.botSpawnRadius * 0.55).toDouble(),
            maxRadius: config.botSpawnRadius,
          );
    bot.resetAt(position);
    return bot;
  }

  _BotProfile _profileForBot(int index) {
    const profiles = [
      _BotProfile(
        disposition: BotDisposition.defensive,
        lengthBonus: 0,
        speedMultiplier: 1.0,
      ),
      _BotProfile(
        disposition: BotDisposition.aggressive,
        lengthBonus: 10,
        speedMultiplier: 1.0,
      ),
      _BotProfile(
        disposition: BotDisposition.opportunistic,
        lengthBonus: 24,
        speedMultiplier: 0.9,
      ),
      _BotProfile(
        disposition: BotDisposition.wanderer,
        lengthBonus: 4,
        speedMultiplier: 1.05,
      ),
      _BotProfile(
        disposition: BotDisposition.defensive,
        lengthBonus: 18,
        speedMultiplier: 0.95,
      ),
      _BotProfile(
        disposition: BotDisposition.aggressive,
        lengthBonus: 36,
        speedMultiplier: 0.88,
      ),
      _BotProfile(
        disposition: BotDisposition.opportunistic,
        lengthBonus: 12,
        speedMultiplier: 0.98,
      ),
      _BotProfile(
        disposition: BotDisposition.defensive,
        lengthBonus: 58,
        speedMultiplier: 0.8,
      ),
      _BotProfile(
        disposition: BotDisposition.aggressive,
        lengthBonus: 2,
        speedMultiplier: 1.02,
      ),
      _BotProfile(
        disposition: BotDisposition.opportunistic,
        lengthBonus: 44,
        speedMultiplier: 0.86,
      ),
    ];
    return profiles[index % profiles.length];
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
