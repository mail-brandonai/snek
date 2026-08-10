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
    this.botSprintMultiplier = 1.85,
    this.botSprintDuration = 0.75,
    this.botSprintCooldown = 2.4,
    this.botSprintMinimumLength = 8,
    this.botSprintTriggerDistance = 320,
    this.botMaximumLength = 120,
    this.collisionPingDuration = 0.9,
    this.sprintAnticipationDuration = 0.16,
    this.sprintPulseDuration = 0.42,
    this.telegraphEventDuration = 1.1,
    this.telegraphEventLimit = 24,
    this.threatProjectionSeconds = 1.2,
    this.threatRadius = 300,
    this.threatCommitmentThreshold = 0.55,
    this.botTacticDecisionMin = 0.7,
    this.botTacticDecisionMax = 1.55,
    this.botTacticTurnVariance = 0.8,
    this.botTacticSpeedBoost = 1.22,
    this.botTacticBrakeMultiplier = 0.68,
    this.botTacticWeaveStrength = 190,
    this.botCutoffLeadTime = 2.15,
    this.botFlankDistance = 180,
    this.botEncircleGapDistance = 110,
    this.botBaitDistance = 135,
    this.botEngagementRadius = 1150,
    this.botEngagementLeadTime = 2.75,
    this.botEngagementWeight = 2.8,
    this.botCollisionLookahead = 1.2,
    this.botCollisionSampleCount = 6,
    this.botCollisionAvoidanceRadius = 150,
    this.botCollisionAvoidanceWeight = 4.8,
    this.botPeerSeparationRadius = 260,
    this.botPeerSeparationWeight = 2.4,
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
  final double botSprintMultiplier;
  final double botSprintDuration;
  final double botSprintCooldown;
  final int botSprintMinimumLength;
  final double botSprintTriggerDistance;
  final int botMaximumLength;
  final double collisionPingDuration;
  final double sprintAnticipationDuration;
  final double sprintPulseDuration;
  final double telegraphEventDuration;
  final int telegraphEventLimit;
  final double threatProjectionSeconds;
  final double threatRadius;
  final double threatCommitmentThreshold;
  final double botTacticDecisionMin;
  final double botTacticDecisionMax;
  final double botTacticTurnVariance;
  final double botTacticSpeedBoost;
  final double botTacticBrakeMultiplier;
  final double botTacticWeaveStrength;
  final double botCutoffLeadTime;
  final double botFlankDistance;
  final double botEncircleGapDistance;
  final double botBaitDistance;
  final double botEngagementRadius;
  final double botEngagementLeadTime;
  final double botEngagementWeight;
  final double botCollisionLookahead;
  final int botCollisionSampleCount;
  final double botCollisionAvoidanceRadius;
  final double botCollisionAvoidanceWeight;
  final double botPeerSeparationRadius;
  final double botPeerSeparationWeight;
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

enum _BotTactic { feint, cutoff, flank, encircle, bait, disengage, weave }

class _BotTacticState {
  _BotTactic mode = _BotTactic.weave;
  double remaining = 0;
  double sign = 1;
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
  final List<TelegraphEvent> telegraphEvents = [];
  final Map<String, double> _botRespawnTimers = {};
  final Map<String, _BotTacticState> _botTactics = {};
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

  List<ActorTelegraph> get telegraphs => [
        for (final snake in snakes)
          if (snake.alive) _telegraphFor(snake),
      ];

  List<ThreatSignal> get playerThreats {
    final signals = <ThreatSignal>[];
    for (final actor in snakes.where(
      (snake) => snake.id != player.id && snake.alive,
    )) {
      final offset = actor.head - player.head;
      final distance = offset.length;
      if (distance == 0) continue;

      final actorTowardPlayer =
          _alignment(actor.heading, player.head - actor.head);
      final playerTowardActor = _alignment(player.heading, offset);
      final actorSpeed = _effectiveSpeed(actor);
      final playerSpeed = _effectiveSpeed(player);
      final projectedActor = actor.head +
          actor.heading * (actorSpeed * config.threatProjectionSeconds);
      final projectedPlayer = player.head +
          player.heading * (playerSpeed * config.threatProjectionSeconds);
      final projectedDistance = projectedActor.distanceTo(projectedPlayer);
      final projectedPath = actorTowardPlayer >= 0.2 &&
          playerTowardActor >= -0.35 &&
          projectedDistance <= config.threatRadius;
      final closeApproach =
          distance <= config.threatRadius && actorTowardPlayer >= -0.15;
      if (!projectedPath && !closeApproach && !actor.sprinting) continue;

      final nearestDistance = math.min(distance, projectedDistance).toDouble();
      final proximity = (1 - nearestDistance / config.threatRadius)
          .clamp(0.0, 1.0)
          .toDouble();
      final sprintBoost = actor.sprinting
          ? 0.45
          : actor.sprintAnticipating
              ? 0.25
              : 0.0;
      final pathBoost = projectedPath ? 0.25 : 0.0;
      final urgency =
          (proximity + sprintBoost + pathBoost).clamp(0.0, 1.0).toDouble();
      signals.add(
        ThreatSignal(
          actorId: actor.id,
          direction: offset.normalized(),
          distance: distance,
          urgency: urgency,
          actorLength: actor.length,
          playerLength: player.length,
          projectedPath: projectedPath,
          intent: actor.publicIntent,
          sprintAnticipating: actor.sprintAnticipating,
          sprinting: actor.sprinting,
        ),
      );
    }
    signals.sort((left, right) => right.urgency.compareTo(left.urgency));
    return signals;
  }

  ThreatSignal? get primaryPlayerThreat {
    final threats = playerThreats;
    return threats.isEmpty ? null : threats.first;
  }

  bool get canSprint =>
      !gameOver && player.alive && player.length > config.minimumSprintLength;

  void reset() {
    _random = math.Random(seed);
    snakes.clear();
    pellets.clear();
    droppedMass.clear();
    collisionPings.clear();
    telegraphEvents.clear();
    _botRespawnTimers.clear();
    _botTactics.clear();
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
      _advanceTelegraphEvents(dt);
      return;
    }

    if (sprinting && canSprint) {
      _requestSprint(player);
    } else {
      _cancelSprintRequest(player);
    }

    var remaining = dt;
    while (remaining > 0 && !gameOver) {
      final step = math.min(remaining, 0.05).toDouble();
      _advanceCollisionPings(step);
      _advanceTelegraphEvents(step);
      elapsed += step;
      _advancePlayerSprint(step);
      _steerPlayer(steering, step);
      _steerBots(step);

      for (final snake in snakes.where((item) => item.alive)) {
        _moveSnake(snake, step);
        if (!snake.alive) continue;
        _collectPellets(snake);
        _collectDroppedMass(snake);
      }
      _resolveCollisions();
      _refreshPublicTelegraphs();
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
    player.headingChange = delta.abs().clamp(0.0, math.pi).toDouble();
    player.movementCommitment =
        (1 - player.headingChange / math.pi).clamp(0.0, 1.0).toDouble();
    player.heading = Vec2.fromAngle(
      current + delta.clamp(-maxTurn, maxTurn).toDouble(),
    );
  }

  void _requestSprint(SnakeState actor) {
    if (actor.sprintRequested || actor.sprinting) {
      actor.sprintRequested = true;
      return;
    }
    actor.sprintRequested = true;
    actor.sprintAnticipationRemaining = config.sprintAnticipationDuration;
    _recordTelegraphEvent(actor, TelegraphEventKind.sprintAnticipation);
  }

  void _cancelSprintRequest(SnakeState actor) {
    actor.sprintRequested = false;
    actor.sprintAnticipationRemaining = 0;
    if (actor.sprinting) {
      if (actor.kind == SnakeKind.bot) {
        _stopBotSprint(actor);
      } else {
        actor.sprinting = false;
        actor.sprintPulseRemaining = 0;
        actor.sprintDrainAccumulator = 0;
        _recordTelegraphEvent(actor, TelegraphEventKind.sprintEnded);
      }
    } else {
      actor.sprintDrainAccumulator = 0;
    }
  }

  void _advancePlayerSprint(double dt) {
    _advanceSprintTelegraph(player, dt);
  }

  void _advanceSprintTelegraph(SnakeState actor, double dt) {
    actor.sprintPulseRemaining =
        math.max(0, actor.sprintPulseRemaining - dt).toDouble();
    if (!actor.sprintRequested) {
      actor.sprinting = false;
      actor.sprintAnticipationRemaining = 0;
      actor.sprintDrainAccumulator = 0;
      return;
    }
    if (actor.sprinting) return;
    actor.sprintAnticipationRemaining =
        math.max(0, actor.sprintAnticipationRemaining - dt).toDouble();
    if (actor.sprintAnticipationRemaining > 0) return;

    actor.sprinting = true;
    actor.sprintPulseRemaining = config.sprintPulseDuration;
    _recordTelegraphEvent(actor, TelegraphEventKind.sprintStarted);
  }

  void _steerBots(double dt) {
    for (final bot in snakes.where(
      (snake) => snake.kind == SnakeKind.bot && snake.alive,
    )) {
      _advanceBotSprint(bot, dt);
      final tactic = _advanceBotTactic(bot, dt);
      _applyTacticalMotion(bot, tactic, dt);
      if (!bot.retreating && bot.length >= config.botRetreatLength) {
        bot.retreating = true;
      }
      if (bot.retreating) {
        _turnBotToward(bot, _retreatDirection(bot), dt);
        _decideBotSprint(bot);
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
      final tactical = _tacticalIntent(bot, tactic);
      final predictiveAvoidance = _predictiveCollisionAvoidance(bot);
      final peerSeparation = _peerSeparation(bot);
      final intent = (wander * _wanderWeight(bot) +
              boundary * _boundaryWeight(bot) +
              threat * _threatWeight(bot) +
              interest * _foodWeight(bot) +
              droppedMassInterest * _droppedMassWeight(bot) +
              pressure * _pressureWeight(bot) +
              tactical * 1.55 +
              predictiveAvoidance * config.botCollisionAvoidanceWeight +
              peerSeparation * config.botPeerSeparationWeight)
          .normalized();
      _turnBotToward(bot, intent, dt);
      _decideBotSprint(bot);
    }
  }

  _BotTactic _advanceBotTactic(SnakeState bot, double dt) {
    final state = _botTactics.putIfAbsent(bot.id, _BotTacticState.new);
    state.remaining -= dt;
    if (state.remaining > 0) return state.mode;

    state.mode = _selectBotTactic(bot);
    final minimum = math.max(0.1, config.botTacticDecisionMin);
    final maximum = math.max(minimum, config.botTacticDecisionMax);
    state.remaining = minimum + _random.nextDouble() * (maximum - minimum);
    state.sign = _random.nextBool() ? 1 : -1;
    bot.tacticalTurnRateMultiplier = 1 -
        config.botTacticTurnVariance / 2 +
        _random.nextDouble() * config.botTacticTurnVariance;
    return state.mode;
  }

  _BotTactic _selectBotTactic(SnakeState bot) {
    if (bot.retreating) return _BotTactic.disengage;
    if (!player.alive) return _BotTactic.weave;

    final playerDistance = bot.head.distanceTo(player.head);
    final nearDanger = playerDistance <= config.botEngagementRadius * 0.72;
    final engagementRank = _playerEngagementRank(bot);
    if (engagementRank == 0 &&
        playerDistance <= config.botEngagementRadius &&
        (bot.disposition == BotDisposition.aggressive ||
            bot.disposition == BotDisposition.opportunistic)) {
      return _BotTactic.cutoff;
    }
    if (engagementRank == 1 && playerDistance <= config.botEngagementRadius) {
      return _BotTactic.flank;
    }
    final roll = _random.nextDouble();
    switch (bot.disposition) {
      case BotDisposition.defensive:
        return nearDanger && roll < 0.65
            ? _BotTactic.disengage
            : roll < 0.55
                ? _BotTactic.feint
                : _BotTactic.weave;
      case BotDisposition.aggressive:
        if (roll < 0.35) return _BotTactic.cutoff;
        if (roll < 0.65) return _BotTactic.flank;
        if (roll < 0.82) return _BotTactic.encircle;
        return _BotTactic.feint;
      case BotDisposition.opportunistic:
        if (_nearestFoodTarget(bot) != null && roll < 0.42) {
          return _BotTactic.bait;
        }
        if (roll < 0.7) return _BotTactic.flank;
        return _BotTactic.feint;
      case BotDisposition.wanderer:
        return roll < 0.5 ? _BotTactic.weave : _BotTactic.feint;
    }
  }

  void _applyTacticalMotion(SnakeState bot, _BotTactic tactic, double dt) {
    final state = _botTactics[bot.id];
    if (state == null) return;

    var targetMultiplier = 1.0;
    switch (tactic) {
      case _BotTactic.cutoff:
      case _BotTactic.flank:
      case _BotTactic.encircle:
        targetMultiplier = config.botTacticSpeedBoost;
      case _BotTactic.disengage:
        targetMultiplier = math.max(1, config.botTacticSpeedBoost);
      case _BotTactic.bait:
        final food = _nearestFoodTarget(bot);
        final nearFood = food != null && bot.head.distanceTo(food) < 90;
        targetMultiplier = nearFood ? config.botTacticBrakeMultiplier : 1.0;
      case _BotTactic.feint:
        targetMultiplier = 1 + math.sin(elapsed * 8 + bot.colorIndex) * 0.12;
      case _BotTactic.weave:
        targetMultiplier = 0.96;
    }

    final smoothing = (dt * 5).clamp(0.0, 1.0).toDouble();
    bot.tacticalSpeedMultiplier +=
        (targetMultiplier - bot.tacticalSpeedMultiplier) * smoothing;
  }

  Vec2 _tacticalIntent(SnakeState bot, _BotTactic tactic) {
    if (!player.alive) return Vec2.zero;
    final state = _botTactics[bot.id];
    final sign = state?.sign ?? 1;
    final playerLateral = Vec2(-player.heading.y, player.heading.x);
    final playerDistance = bot.head.distanceTo(player.head);
    final lead = player.heading * config.botCutoffLeadTime * player.speed;

    switch (tactic) {
      case _BotTactic.feint:
        final oscillation = math.sin(elapsed * 7.0 + bot.colorIndex * 1.9) *
            config.botTacticWeaveStrength;
        final target =
            player.head + lead + playerLateral * (oscillation + sign * 70);
        return target - bot.head;
      case _BotTactic.cutoff:
        return player.head +
            lead +
            playerLateral * (sign * config.botFlankDistance * 0.55) -
            bot.head;
      case _BotTactic.flank:
        final target = player.head +
            player.heading * (config.botCutoffLeadTime * player.speed * 0.55) +
            playerLateral * (sign * config.botFlankDistance);
        return target - bot.head;
      case _BotTactic.encircle:
        final index = math.min(
          player.body.length - 1,
          math.max(1, player.body.length ~/ 2),
        );
        final gap = player.body[index] +
            playerLateral * (sign * config.botEncircleGapDistance);
        return gap - bot.head;
      case _BotTactic.bait:
        final food = _nearestFoodTarget(bot);
        if (food == null) return player.head + lead - bot.head;
        final fromPlayer = food - player.head;
        final baitDirection =
            fromPlayer.length == 0 ? player.heading : fromPlayer.normalized();
        final trapPoint = food + baitDirection * config.botBaitDistance;
        return trapPoint - bot.head;
      case _BotTactic.disengage:
        final away = (bot.head - player.head).normalized();
        final tangent = Vec2(-away.y, away.x) * sign;
        return away * 2.0 +
            tangent * (playerDistance < 180 ? 1.4 : 0.7) +
            _nearbyThreat(bot);
      case _BotTactic.weave:
        final wave = math.sin(elapsed * 5.5 + bot.colorIndex) * sign;
        return bot.heading + Vec2(-bot.heading.y, bot.heading.x) * wave;
    }
  }

  void _advanceBotSprint(SnakeState bot, double dt) {
    if (bot.botSprintCooldownRemaining > 0) {
      bot.botSprintCooldownRemaining = math
          .max(
            0,
            bot.botSprintCooldownRemaining - dt,
          )
          .toDouble();
    }
    _advanceSprintTelegraph(bot, dt);
    if (!bot.sprinting) return;

    bot.botSprintRemaining -= dt;
    if (bot.botSprintRemaining <= 0) _stopBotSprint(bot);
  }

  void _decideBotSprint(SnakeState bot) {
    if (bot.sprinting ||
        bot.sprintRequested ||
        bot.botSprintCooldownRemaining > 0 ||
        bot.speed <= 0 ||
        bot.length <= config.botSprintMinimumLength) {
      return;
    }

    final playerDistance = bot.head.distanceTo(player.head);
    final droppedMassDistance = _nearestDroppedMassDistance(bot);
    final naturalFoodDistance = _nearestNaturalFoodDistance(bot);
    final distanceLimit = config.botSprintTriggerDistance;
    var shouldSprint = false;

    switch (bot.disposition) {
      case BotDisposition.defensive:
        shouldSprint = bot.retreating ||
            (player.alive &&
                playerDistance <= distanceLimit * 0.8 &&
                bot.length <= player.length * 1.2);
      case BotDisposition.aggressive:
        shouldSprint = player.alive &&
            playerDistance <= distanceLimit &&
            bot.length >= player.length * 0.75 &&
            bot.length <= player.length * 1.6;
      case BotDisposition.opportunistic:
        shouldSprint = droppedMassDistance <= distanceLimit;
      case BotDisposition.wanderer:
        shouldSprint = naturalFoodDistance <= distanceLimit * 0.7;
    }

    if (shouldSprint) {
      _requestSprint(bot);
      bot.botSprintRemaining = config.botSprintDuration;
      bot.sprintDrainAccumulator = 0;
      if (config.sprintAnticipationDuration <= 0) {
        _advanceSprintTelegraph(bot, 0);
      }
    }
  }

  void _stopBotSprint(SnakeState bot) {
    bot.sprintRequested = false;
    bot.sprinting = false;
    bot.botSprintRemaining = 0;
    bot.sprintAnticipationRemaining = 0;
    bot.sprintPulseRemaining = 0;
    bot.sprintDrainAccumulator = 0;
    bot.botSprintCooldownRemaining = config.botSprintCooldown;
    _recordTelegraphEvent(bot, TelegraphEventKind.sprintEnded);
  }

  void _turnBotToward(SnakeState bot, Vec2 intent, double dt) {
    final desired = intent.length == 0 ? bot.heading.angle : intent.angle;
    final current = bot.heading.angle;
    final delta = _shortestAngle(desired - current);
    final turnLimit = config.botTurnRate * bot.tacticalTurnRateMultiplier * dt;
    final turn = delta.clamp(-turnLimit, turnLimit).toDouble();
    bot.headingChange = turn.abs().clamp(0.0, math.pi).toDouble();
    bot.movementCommitment =
        (1 - bot.headingChange / math.pi).clamp(0.0, 1.0).toDouble();
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
        return 2.6;
      case BotDisposition.opportunistic:
        return 1.2;
      case BotDisposition.wanderer:
        return 0.65;
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

  double _nearestNaturalFoodDistance(SnakeState snake) {
    var nearestDistance = double.infinity;
    for (final pellet in pellets) {
      final distance = snake.head.distanceTo(pellet.position);
      if (distance < nearestDistance) nearestDistance = distance;
    }
    return nearestDistance;
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

  double _nearestDroppedMassDistance(SnakeState snake) {
    var nearestDistance = double.infinity;
    for (final pellet in droppedMass) {
      final distance = snake.head.distanceTo(pellet.position);
      if (distance < nearestDistance) nearestDistance = distance;
    }
    return nearestDistance;
  }

  Vec2 _playerPressure(SnakeState bot) {
    if (!player.alive) return Vec2.zero;

    final distance = bot.head.distanceTo(player.head);
    if (distance > config.botEngagementRadius) return Vec2.zero;

    final engagementRank = _playerEngagementRank(bot);
    final leadTime = config.botEngagementLeadTime *
        (1 + math.min(engagementRank, 2).toDouble() * 0.18);
    final projectedPlayer =
        player.head + player.heading * (player.speed * leadTime);
    final lateral = Vec2(-player.heading.y, player.heading.x);
    final laneOffset = engagementRank == 0
        ? 0.0
        : config.botFlankDistance *
            (1 + math.min(engagementRank - 1, 2).toDouble() * 0.55);
    final laneSign = bot.colorIndex.isEven ? 1.0 : -1.0;
    final target = projectedPlayer + lateral * laneSign * laneOffset;
    final direction = target - bot.head;
    if (direction.length == 0) return Vec2.zero;

    final proximity =
        ((config.botEngagementRadius - distance) / config.botEngagementRadius)
            .clamp(0.0, 1.0)
            .toDouble();
    final roleWeight = engagementRank == 0
        ? 1.0
        : engagementRank == 1
            ? 0.72
            : 0.42;
    final sizeFactor = bot.length >= player.length ? 1.25 : 0.9;
    return direction.normalized() *
        (config.botEngagementWeight *
            (0.7 + proximity * 0.3) *
            roleWeight *
            sizeFactor);
  }

  int _playerEngagementRank(SnakeState bot) {
    final target = player.head +
        player.heading * (player.speed * config.botEngagementLeadTime);
    final candidates = snakes
        .where(
          (candidate) =>
              candidate.kind == SnakeKind.bot &&
              candidate.alive &&
              !candidate.retreating &&
              candidate.head.distanceTo(player.head) <=
                  config.botEngagementRadius,
        )
        .toList()
      ..sort((left, right) {
        final leftArrival =
            left.head.distanceTo(target) / math.max(1.0, _effectiveSpeed(left));
        final rightArrival = right.head.distanceTo(target) /
            math.max(1.0, _effectiveSpeed(right));
        final arrivalOrder = leftArrival.compareTo(rightArrival);
        if (arrivalOrder != 0) return arrivalOrder;
        return left.id.compareTo(right.id);
      });
    final rank = candidates.indexWhere((candidate) => candidate.id == bot.id);
    return rank < 0 ? candidates.length : rank;
  }

  Vec2 _predictiveCollisionAvoidance(SnakeState snake) {
    var avoidance = Vec2.zero;
    final speed = _effectiveSpeed(snake);
    final samples = math.max(1, config.botCollisionSampleCount).toInt();
    if (speed <= 0 || samples <= 0) return avoidance;

    for (final other in snakes.where(
      (candidate) => candidate.id != snake.id && candidate.alive,
    )) {
      for (var sample = 1; sample <= samples; sample++) {
        final progress = sample / samples;
        final future = snake.head +
            snake.heading * (speed * config.botCollisionLookahead * progress);
        for (final segment in other.body.skip(1)) {
          final offset = future - segment;
          final distance = offset.length;
          if (distance <= 0 || distance >= config.botCollisionAvoidanceRadius) {
            continue;
          }

          final urgency = (config.botCollisionAvoidanceRadius - distance) /
              config.botCollisionAvoidanceRadius;
          var escape = offset.normalized();
          if (_alignment(snake.heading, segment - future) > 0.15) {
            final side = Vec2(-snake.heading.y, snake.heading.x) *
                (snake.id.compareTo(other.id) <= 0 ? 1.0 : -1.0);
            escape = (escape * 0.35 + side * 0.9).normalized();
          }
          avoidance += escape * (urgency * urgency);
        }
      }
    }
    return avoidance.normalized();
  }

  Vec2 _peerSeparation(SnakeState bot) {
    var separation = Vec2.zero;
    for (final other in snakes.where(
      (candidate) =>
          candidate.kind == SnakeKind.bot &&
          candidate.id != bot.id &&
          candidate.alive,
    )) {
      final offset = bot.head - other.head;
      final distance = offset.length;
      if (distance <= 0 || distance >= config.botPeerSeparationRadius) {
        continue;
      }

      final urgency = (config.botPeerSeparationRadius - distance) /
          config.botPeerSeparationRadius;
      separation += offset.normalized() * (urgency * urgency);
    }
    return separation.normalized();
  }

  ActorTelegraph _telegraphFor(SnakeState actor) => ActorTelegraph(
        actorId: actor.id,
        position: actor.head,
        heading: actor.heading,
        length: actor.length,
        speed: _effectiveSpeed(actor),
        intent: actor.publicIntent,
        sprintAnticipating: actor.sprintAnticipating,
        sprinting: actor.sprinting,
        movementCommitment: actor.movementCommitment,
      );

  void _refreshPublicTelegraphs() {
    for (final actor in snakes.where((snake) => snake.alive)) {
      actor.publicIntent = _classifyPublicIntent(actor);
    }
  }

  ActorIntent _classifyPublicIntent(SnakeState actor) {
    if (actor.sprinting || actor.sprintAnticipating) {
      return ActorIntent.sprinting;
    }

    final food = _nearestFoodTarget(actor);
    if (food != null &&
        actor.head.distanceTo(food) <= config.botSenseRadius &&
        _alignment(actor.heading, food - actor.head) >= 0.55) {
      return ActorIntent.contestingFood;
    }

    final other = _nearestOtherActor(actor);
    if (other != null) {
      final toOther = other.head - actor.head;
      final alignment = _alignment(actor.heading, toOther);
      if (alignment >= 0.55) return ActorIntent.pursuing;
      if (alignment <= -0.55 &&
          actor.head.distanceTo(other.head) <= config.botPressureRadius) {
        return ActorIntent.retreating;
      }
    }

    if (actor.headingChange >= config.threatCommitmentThreshold) {
      return ActorIntent.repositioning;
    }
    return ActorIntent.wandering;
  }

  Vec2? _nearestFoodTarget(SnakeState actor) {
    FoodPellet? nearest;
    var nearestDistance = double.infinity;
    for (final source in [droppedMass, pellets]) {
      for (final pellet in source) {
        final distance = actor.head.distanceTo(pellet.position);
        if (distance < nearestDistance) {
          nearest = pellet;
          nearestDistance = distance;
        }
      }
    }
    return nearest?.position;
  }

  SnakeState? _nearestOtherActor(SnakeState actor) {
    SnakeState? nearest;
    var nearestDistance = double.infinity;
    for (final candidate in snakes.where(
      (snake) => snake.alive && snake.id != actor.id,
    )) {
      final distance = actor.head.distanceTo(candidate.head);
      if (distance < nearestDistance) {
        nearest = candidate;
        nearestDistance = distance;
      }
    }
    return nearest;
  }

  double _effectiveSpeed(SnakeState actor) {
    var speed = actor.speed;
    if (actor.kind == SnakeKind.bot) {
      final excessLength = math.max(0, actor.length - actor.spawnLength);
      final mobilityPenalty = (excessLength * config.botSizeSpeedPenalty)
          .clamp(0.0, 0.28)
          .toDouble();
      speed *= 1 - mobilityPenalty;
    }
    if (actor.sprinting) {
      speed *= actor.kind == SnakeKind.player
          ? config.sprintMultiplier
          : config.botSprintMultiplier;
    }
    if (actor.kind == SnakeKind.bot) {
      speed *= actor.tacticalSpeedMultiplier;
    }
    return speed;
  }

  double _alignment(Vec2 first, Vec2 second) {
    if (first.length == 0 || second.length == 0) return 0;
    return (first.x * second.x + first.y * second.y) /
        (first.length * second.length);
  }

  void _recordTelegraphEvent(SnakeState actor, TelegraphEventKind kind) {
    telegraphEvents.insert(
      0,
      TelegraphEvent(
        actorId: actor.id,
        kind: kind,
        position: actor.head,
        heading: actor.heading,
        durationSeconds: config.telegraphEventDuration,
      ),
    );
    if (telegraphEvents.length > config.telegraphEventLimit) {
      telegraphEvents.removeRange(
        config.telegraphEventLimit,
        telegraphEvents.length,
      );
    }
  }

  void _advanceTelegraphEvents(double dt) {
    for (final event in telegraphEvents) {
      event.remainingSeconds -= dt;
    }
    telegraphEvents.removeWhere((event) => event.remainingSeconds <= 0);
  }

  void _moveSnake(SnakeState snake, double dt) {
    final currentHead = snake.head;
    final nextHead = snake.head + snake.heading * (_effectiveSpeed(snake) * dt);
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

    if (snake.sprinting) {
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
    final minimumLength = snake.kind == SnakeKind.bot
        ? config.botSprintMinimumLength
        : config.minimumSprintLength;
    snake.sprintDrainAccumulator += dt;
    while (snake.sprintDrainAccumulator + 1e-9 >= config.sprintDrainInterval) {
      snake.sprintDrainAccumulator -= config.sprintDrainInterval;
      final position = snake.shedMass(
        minimumLength: minimumLength,
      );
      if (position == null) {
        if (snake.kind == SnakeKind.bot) {
          _stopBotSprint(snake);
        } else {
          _stopPlayerSprint(snake);
        }
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
      if (snake.length <= minimumLength) {
        if (snake.kind == SnakeKind.bot) {
          _stopBotSprint(snake);
        } else {
          _stopPlayerSprint(snake);
        }
        return;
      }
    }
  }

  void _stopPlayerSprint(SnakeState player) {
    player.sprintRequested = false;
    player.sprinting = false;
    player.sprintAnticipationRemaining = 0;
    player.sprintPulseRemaining = 0;
    player.sprintDrainAccumulator = 0;
    _recordTelegraphEvent(player, TelegraphEventKind.sprintEnded);
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
        final requestedGrowth = snake.kind == SnakeKind.bot
            ? (pellet.value * config.botGrowthMultiplier)
                .round()
                .clamp(1, double.infinity)
                .toInt()
            : pellet.value;
        final growth = snake.kind == SnakeKind.bot
            ? math
                .min(
                  requestedGrowth,
                  math.max(0, config.botMaximumLength - snake.length),
                )
                .toInt()
            : requestedGrowth;
        if (growth > 0) snake.grow(growth);
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
        _botTactics.remove(id);
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
