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
    this.botEngagementWeight = 4.2,
    this.botEngagementLaneDistance = 240,
    this.botEngagementSafetyRadius = 170,
    this.botCollisionLookahead = 1.2,
    this.botCollisionSampleCount = 6,
    this.botCollisionAvoidanceRadius = 150,
    this.botCollisionAvoidanceWeight = 4.8,
    this.botPeerSeparationRadius = 260,
    this.botPeerSeparationWeight = 2.4,
    this.botDroppedMassSenseRadius = 1400,
    this.botDroppedMassClusterRadius = 150,
    this.botDroppedMassControlWeight = 5.8,
    this.botDroppedMassGuardDistance = 190,
    this.botDroppedMassGuardRadius = 720,
    this.botRouteAvoidanceRadius = 210,
    this.botRouteAvoidanceWeight = 6.4,
    this.botDefensiveAvoidanceRadius = 190,
    this.botDefensiveAvoidanceWeight = 11.0,
    this.botAdaptiveLeadTime = 1.2,
    this.botClosedLoopWeight = 8.0,
    this.botCurvedRouteLeadTime = 2.8,
    this.botEvasionReplanDistance = 120,
    this.botScreenDistance = 220,
    this.botDenyDistance = 170,
    this.botGeometryPressureWeight = 9.2,
    this.botAttackAbortDistance = 230,
    this.botAttackAbortSafety = 0.34,
    this.botFormationCommitmentDuration = 1.35,
    this.botFormationReplanDistance = 210,
    this.botFormationSeparationDistance = 210,
    this.botFormationPressureWeight = 5.4,
    this.botPeerHardAvoidanceRadius = 210,
    this.botPeerHardAvoidanceThreshold = 0.28,
    this.botPeerAbortThreshold = 0.32,
    this.botAdaptiveMaximumLength = 420,
    this.botAdaptiveGrowthGap = 180,
    this.maxDroppedMass = 480,
    this.droppedMassLifetime = 24,
    this.botCatchUpDelay = 18,
    this.botCatchUpRate = 1.4,
    this.botCatchUpTargetFraction = 0.58,
    this.botTacticalDecisionInterval = 0.12,
    this.botPlannerLookahead = 0.9,
    this.botRouteReservationDistance = 170,
    this.movementTrailTrimSlackSegments = 8,
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
  final double botEngagementLaneDistance;
  final double botEngagementSafetyRadius;
  final double botCollisionLookahead;
  final int botCollisionSampleCount;
  final double botCollisionAvoidanceRadius;
  final double botCollisionAvoidanceWeight;
  final double botPeerSeparationRadius;
  final double botPeerSeparationWeight;
  final double botDroppedMassSenseRadius;
  final double botDroppedMassClusterRadius;
  final double botDroppedMassControlWeight;
  final double botDroppedMassGuardDistance;
  final double botDroppedMassGuardRadius;
  final double botRouteAvoidanceRadius;
  final double botRouteAvoidanceWeight;
  final double botDefensiveAvoidanceRadius;
  final double botDefensiveAvoidanceWeight;
  final double botAdaptiveLeadTime;
  final double botClosedLoopWeight;
  final double botCurvedRouteLeadTime;
  final double botEvasionReplanDistance;
  final double botScreenDistance;
  final double botDenyDistance;
  final double botGeometryPressureWeight;
  final double botAttackAbortDistance;
  final double botAttackAbortSafety;
  final double botFormationCommitmentDuration;
  final double botFormationReplanDistance;
  final double botFormationSeparationDistance;
  final double botFormationPressureWeight;
  final double botPeerHardAvoidanceRadius;
  final double botPeerHardAvoidanceThreshold;
  final double botPeerAbortThreshold;
  final int botAdaptiveMaximumLength;
  final double botAdaptiveGrowthGap;
  final int maxDroppedMass;
  final double droppedMassLifetime;
  final double botCatchUpDelay;
  final double botCatchUpRate;
  final double botCatchUpTargetFraction;
  final double botTacticalDecisionInterval;
  final double botPlannerLookahead;
  final double botRouteReservationDistance;
  final int movementTrailTrimSlackSegments;
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

enum _BotEngagementMode {
  observe,
  intercept,
  screen,
  deny,
  harvest,
  abort,
  replan,
}

class _BotTacticState {
  _BotTactic mode = _BotTactic.weave;
  double remaining = 0;
  double sign = 1;
  Vec2? plannedPlayerHeading;
  Vec2? plannedPlayerPosition;
}

enum _BotPlanMode { retreat, evadePeer, evadePlayer, attack, contest, wander }

class _BotPlan {
  const _BotPlan({required this.intent, required this.mode});

  final Vec2 intent;
  final _BotPlanMode mode;
}

class _BotClosedLoopState {
  _BotEngagementMode mode = _BotEngagementMode.observe;
  double remaining = 0;
  double evasionCooldown = 0;
  int lane = 0;
  Vec2? expectedPlayerPosition;
}

enum _BotFormationRole {
  leadCutoff,
  leftScreen,
  rightScreen,
  resourceGuard,
  reserve,
}

class _BotFormationState {
  double remaining = 0;
  Vec2? playerAnchor;
}

class _BotRouteRisk {
  const _BotRouteRisk({required this.escape, required this.urgency});

  final Vec2 escape;
  final double urgency;
}

class _BotPeerRisk {
  const _BotPeerRisk({required this.escape, required this.urgency});

  final Vec2 escape;
  final double urgency;
}

class _BotEngagementPlan {
  const _BotEngagementPlan({
    required this.target,
    required this.rank,
    required this.safety,
  });

  final Vec2 target;
  final int rank;
  final double safety;
}

class _BotGeometryPlan {
  const _BotGeometryPlan({
    required this.target,
    required this.safety,
    required this.abortRoute,
  });

  final Vec2 target;
  final double safety;
  final Vec2 abortRoute;

  bool get attack => safety >= 0.34 && abortRoute.length >= 0.34;
}

class _DroppedMassCluster {
  const _DroppedMassCluster({
    required this.center,
    required this.value,
    required this.radius,
    required this.memberCount,
  });

  final Vec2 center;
  final int value;
  final double radius;
  final int memberCount;
}

class _DroppedMassBucket {
  int value = 0;
  int count = 0;
  double weightedX = 0;
  double weightedY = 0;
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
  final Map<String, double> _botCatchUpCredits = {};
  final Map<FoodPellet, double> _droppedMassAges = {};
  final List<_DroppedMassCluster> _droppedMassClusters = [];
  final Map<String, _BotTacticState> _botTactics = {};
  final Map<String, _BotClosedLoopState> _botEngagementStates = {};
  final Map<String, _BotFormationRole> _botFormationRoles = {};
  final Map<String, _BotPlan> _botPlans = {};
  final List<Vec2> _botRouteReservations = [];
  final _BotFormationState _botFormation = _BotFormationState();
  Vec2 _observedPlayerHeading = const Vec2(1, 0);
  double _observedPlayerTurnRate = 0;
  double elapsed = 0;
  double _pelletRefillAccumulator = 0;
  double _botPopulationAccumulator = 0;
  double _botTacticalDecisionRemaining = 0;
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
    _botCatchUpCredits.clear();
    _droppedMassAges.clear();
    _droppedMassClusters.clear();
    _botTactics.clear();
    _botEngagementStates.clear();
    _botFormationRoles.clear();
    _botPlans.clear();
    _botRouteReservations.clear();
    _botFormation.remaining = 0;
    _botFormation.playerAnchor = null;
    _observedPlayerHeading = const Vec2(1, 0);
    _observedPlayerTurnRate = 0;
    elapsed = 0;
    _pelletRefillAccumulator = 0;
    _botPopulationAccumulator = 0;
    _botTacticalDecisionRemaining = 0;
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
      _advanceDroppedMass(step);
      _advancePlayerSprint(step);
      _steerPlayer(steering, step);
      _observePlayerRoute(step);
      _steerBots(step);

      for (final snake in snakes.where((item) => item.alive)) {
        _moveSnake(snake, step);
        if (!snake.alive) continue;
        _collectPellets(snake);
        _collectDroppedMass(snake);
      }
      _resolveCollisions();
      _refreshPublicTelegraphs();
      _advanceBotCatchUp(step);
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

  void _observePlayerRoute(double dt) {
    final previousHeading = _observedPlayerHeading;
    final currentHeading = player.heading;
    final turn = _shortestAngle(
      currentHeading.angle - previousHeading.angle,
    );
    final instantaneousTurnRate = dt <= 0 ? 0.0 : turn / dt;
    _observedPlayerTurnRate = (_observedPlayerTurnRate * 0.65 +
            instantaneousTurnRate.clamp(-8.0, 8.0).toDouble() * 0.35)
        .clamp(-8.0, 8.0)
        .toDouble();
    _observedPlayerHeading = currentHeading;
  }

  void _steerBots(double dt) {
    for (final bot in snakes.where(
      (snake) => snake.kind == SnakeKind.bot && snake.alive,
    )) {
      _advanceBotSprint(bot, dt);
      final tactic = _botTactics[bot.id]?.mode ?? _BotTactic.weave;
      _applyTacticalMotion(bot, tactic, dt);
    }

    _botTacticalDecisionRemaining -= dt;
    if (_observedPlayerTurnRate.abs() >= 1.2) {
      _botTacticalDecisionRemaining = 0;
    }
    if (_botTacticalDecisionRemaining <= 0) {
      _botTacticalDecisionRemaining = math
          .max(
            0.04,
            config.botTacticalDecisionInterval,
          )
          .toDouble();
      _replanBotPlans(dt);
    }

    for (final bot in snakes.where(
      (snake) => snake.kind == SnakeKind.bot && snake.alive,
    )) {
      final plan = _botPlans[bot.id];
      if (plan == null) continue;
      if ((plan.mode == _BotPlanMode.evadePeer ||
              plan.mode == _BotPlanMode.evadePlayer) &&
          (bot.sprinting || bot.sprintRequested)) {
        _interruptBotPursuit(bot);
      }
      _turnBotToward(bot, plan.intent, dt);
    }
  }

  void _replanBotPlans(double dt) {
    _rebuildDroppedMassClusters();
    _refreshBotFormation(dt);
    _botPlans.clear();
    _botRouteReservations.clear();
    final planningBots = snakes
        .where(
          (snake) => snake.kind == SnakeKind.bot && snake.alive,
        )
        .toList()
      ..sort((left, right) {
        final leftPriority = _botPlanningPriority(left);
        final rightPriority = _botPlanningPriority(right);
        final order = rightPriority.compareTo(leftPriority);
        return order == 0 ? left.id.compareTo(right.id) : order;
      });

    for (final bot in planningBots) {
      final tactic = _advanceBotTactic(bot, dt);
      if (!bot.retreating && bot.length >= config.botRetreatLength) {
        bot.retreating = true;
      }
      if (_shouldPrioritizeRetreat(bot)) {
        _decideBotSprint(bot);
        _commitBotPlan(
          bot,
          _retreatDirection(bot),
          _BotPlanMode.retreat,
        );
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
      final peerRisk = _botPeerRouteRisk(bot);
      final droppedMassControl = _droppedMassControl(bot);
      final routeRisk = _playerRouteRisk(bot);
      final closedLoop = _closedLoopEngagement(bot, dt);
      final closedLoopIntent = _closedLoopIntent(bot, closedLoop);
      final geometryPlan = _geometryAttackPlan(bot);
      final geometryPressure = _geometryPressure(bot, geometryPlan);
      final formationIntent = _formationIntent(bot);
      final safeAttack = geometryPlan.attack &&
          geometryPlan.safety >= config.botAttackAbortSafety;
      if (peerRisk.urgency >= config.botPeerHardAvoidanceThreshold) {
        _interruptBotPursuit(bot);
      }
      if (routeRisk.urgency >= 0.58 &&
          (!safeAttack || routeRisk.urgency >= 0.86)) {
        _interruptBotPursuit(bot);
      }
      final baseIntent = wander * _wanderWeight(bot) +
          boundary * _boundaryWeight(bot) +
          threat * _threatWeight(bot) +
          interest * _foodWeight(bot) +
          droppedMassInterest * _droppedMassWeight(bot) +
          pressure * _pressureWeight(bot) +
          tactical * 1.55 +
          predictiveAvoidance *
              math.max(
                config.botCollisionAvoidanceWeight,
                config.botRouteAvoidanceWeight,
              ) +
          peerSeparation * config.botPeerSeparationWeight +
          droppedMassControl * config.botDroppedMassControlWeight +
          closedLoopIntent * config.botClosedLoopWeight +
          geometryPressure * config.botGeometryPressureWeight +
          formationIntent * config.botFormationPressureWeight;
      final intent = peerRisk.urgency >= config.botPeerAbortThreshold
          ? (peerRisk.escape * (1.4 + peerRisk.urgency * 2) +
                  boundary * _boundaryWeight(bot))
              .normalized()
          : routeRisk.urgency >= 0.58
              ? (routeRisk.escape *
                          (config.botDefensiveAvoidanceWeight +
                              routeRisk.urgency * 5) +
                      baseIntent * (safeAttack ? 0.72 : 0.3) +
                      (safeAttack ? geometryPressure * 2.0 : Vec2.zero))
                  .normalized()
              : (baseIntent +
                      peerRisk.escape *
                          (peerRisk.urgency *
                              config.botPeerSeparationWeight *
                              2.6) +
                      routeRisk.escape *
                          (routeRisk.urgency *
                              config.botDefensiveAvoidanceWeight *
                              (safeAttack ? 0.45 : 1.0)))
                  .normalized();
      final mode = peerRisk.urgency >= config.botPeerAbortThreshold
          ? _BotPlanMode.evadePeer
          : routeRisk.urgency >= 0.58 && !safeAttack
              ? _BotPlanMode.evadePlayer
              : safeAttack
                  ? _BotPlanMode.attack
                  : closedLoop == _BotEngagementMode.harvest ||
                          closedLoop == _BotEngagementMode.deny ||
                          closedLoop == _BotEngagementMode.screen
                      ? _BotPlanMode.contest
                      : _BotPlanMode.wander;
      _decideBotSprint(bot);
      _commitBotPlan(bot, intent, mode);
    }
  }

  double _botPlanningPriority(SnakeState bot) {
    final distance = player.alive ? bot.head.distanceTo(player.head) : 10000;
    final sizePressure = bot.length >= player.length ? 1.5 : 1.0;
    final disposition =
        bot.disposition == BotDisposition.aggressive ? 1.4 : 1.0;
    return sizePressure *
        disposition *
        (1 + config.botEngagementRadius / math.max(1.0, distance));
  }

  void _commitBotPlan(
    SnakeState bot,
    Vec2 intent,
    _BotPlanMode mode,
  ) {
    final deconflicted = _deconflictBotIntent(bot, intent);
    _botPlans[bot.id] = _BotPlan(
      intent: deconflicted,
      mode: mode,
    );
    if (deconflicted.length > 0) {
      _botRouteReservations.add(
        bot.head +
            deconflicted * (_effectiveSpeed(bot) * config.botPlannerLookahead),
      );
    }
  }

  Vec2 _deconflictBotIntent(SnakeState bot, Vec2 intent) {
    if (intent.length == 0 || _botRouteReservations.isEmpty) {
      return intent;
    }
    var result = intent.normalized();
    final projected =
        bot.head + result * (_effectiveSpeed(bot) * config.botPlannerLookahead);
    for (final reservation in _botRouteReservations) {
      if (projected.distanceTo(reservation) >=
          config.botRouteReservationDistance) {
        continue;
      }
      final axis = projected - reservation;
      final separation = axis.length == 0
          ? _peerYieldSide(
              bot,
              snakes.firstWhere(
                (candidate) =>
                    candidate.kind == SnakeKind.bot &&
                    candidate.alive &&
                    candidate.id != bot.id,
              ))
          : axis.normalized();
      result = (result * 0.35 + separation * 1.15).normalized();
    }
    return result;
  }

  void _refreshBotFormation(double dt) {
    _botFormation.remaining =
        math.max(0, _botFormation.remaining - dt).toDouble();
    final active = snakes
        .where(
          (snake) =>
              snake.kind == SnakeKind.bot &&
              snake.alive &&
              !_shouldPrioritizeRetreat(snake),
        )
        .toList();
    if (!player.alive || active.isEmpty) {
      _botFormationRoles.clear();
      _botFormation.playerAnchor = null;
      _botFormation.remaining = 0;
      return;
    }

    final anchor = player.head;
    if (_botFormation.playerAnchor != null &&
        _botFormation.playerAnchor!.distanceTo(anchor) >=
            config.botFormationReplanDistance) {
      _botFormation.remaining = 0;
    }
    if (_botFormation.remaining > 0) return;

    final engaged = active
        .where(
          (bot) =>
              bot.head.distanceTo(player.head) <= config.botEngagementRadius,
        )
        .toList()
      ..sort((left, right) {
        final leftArrival =
            left.head.distanceTo(anchor) / math.max(1.0, _effectiveSpeed(left));
        final rightArrival = right.head.distanceTo(anchor) /
            math.max(1.0, _effectiveSpeed(right));
        final order = leftArrival.compareTo(rightArrival);
        return order == 0 ? left.id.compareTo(right.id) : order;
      });

    _botFormationRoles
      ..clear()
      ..addEntries(
        active.map(
          (bot) => MapEntry(bot.id, _BotFormationRole.reserve),
        ),
      );
    if (engaged.isEmpty) {
      _botFormation.playerAnchor = anchor;
      _botFormation.remaining = config.botFormationCommitmentDuration;
      return;
    }

    final cluster = _bestDroppedMassCluster(engaged.first);
    final contestedField = cluster != null &&
        player.head.distanceTo(cluster.center) <=
            config.botDroppedMassGuardRadius;
    final roles = contestedField
        ? <_BotFormationRole>[
            _BotFormationRole.leadCutoff,
            _BotFormationRole.resourceGuard,
            _BotFormationRole.leftScreen,
            _BotFormationRole.rightScreen,
            _BotFormationRole.reserve,
          ]
        : <_BotFormationRole>[
            _BotFormationRole.leadCutoff,
            _BotFormationRole.leftScreen,
            _BotFormationRole.rightScreen,
            _BotFormationRole.resourceGuard,
            _BotFormationRole.reserve,
          ];
    for (var index = 0; index < engaged.length; index++) {
      _botFormationRoles[engaged[index].id] =
          roles[math.min(index, roles.length - 1)];
    }
    _botFormation.playerAnchor = anchor;
    _botFormation.remaining = config.botFormationCommitmentDuration;
  }

  Vec2 _formationIntent(SnakeState bot) {
    final role = _botFormationRoles[bot.id];
    if (!player.alive || role == null || role == _BotFormationRole.reserve) {
      return Vec2.zero;
    }

    final lateral = Vec2(-player.heading.y, player.heading.x);
    final side = bot.colorIndex.isEven ? 1.0 : -1.0;
    final route = _playerRoutePoint(
      role == _BotFormationRole.leadCutoff ? 2.1 : 1.55,
    );
    Vec2 target;
    switch (role) {
      case _BotFormationRole.leadCutoff:
        target = route +
            lateral * side * config.botFormationSeparationDistance * 0.28;
      case _BotFormationRole.leftScreen:
        target = route + lateral * config.botFormationSeparationDistance;
      case _BotFormationRole.rightScreen:
        target = route - lateral * config.botFormationSeparationDistance;
      case _BotFormationRole.resourceGuard:
        final cluster = _bestDroppedMassCluster(bot);
        if (cluster != null &&
            player.head.distanceTo(cluster.center) <=
                config.botDroppedMassGuardRadius) {
          final approach = (cluster.center - player.head).normalized();
          final fieldLateral = Vec2(-approach.y, approach.x);
          target = player.head +
              approach * config.botDroppedMassGuardDistance +
              fieldLateral * side * config.botFormationSeparationDistance;
        } else {
          target = route +
              lateral * side * config.botFormationSeparationDistance * 1.25;
        }
      case _BotFormationRole.reserve:
        return Vec2.zero;
    }
    final direction = target - bot.head;
    return direction.length == 0 ? Vec2.zero : direction.normalized();
  }

  _BotEngagementMode _closedLoopEngagement(SnakeState bot, double dt) {
    final state = _botEngagementStates.putIfAbsent(
      bot.id,
      _BotClosedLoopState.new,
    );
    state.remaining = math.max(0, state.remaining - dt).toDouble();
    state.evasionCooldown = math.max(0, state.evasionCooldown - dt).toDouble();

    final previousTarget = state.expectedPlayerPosition;
    final playerTurned = _observedPlayerTurnRate.abs() >= 0.75;
    final departedLane = previousTarget != null &&
        _alignment(
              player.heading,
              previousTarget - player.head,
            ) <
            0.2 &&
        player.head.distanceTo(previousTarget) >=
            config.botEvasionReplanDistance;
    final evaded = state.evasionCooldown <= 0 && (playerTurned || departedLane);
    if (evaded) {
      state.lane = (state.lane + 1) % 3;
      state.evasionCooldown = 0.7;
      state.mode = _BotEngagementMode.replan;
      state.remaining = 0.35;
    }

    final routeRisk = _playerRouteRisk(bot);
    if (routeRisk.urgency >= 0.72) {
      state.mode = _BotEngagementMode.abort;
      state.remaining = math.min(state.remaining, 0.35).toDouble();
      state.expectedPlayerPosition = _playerRoutePoint(0.45);
      return state.mode;
    }

    if (state.remaining > 0 && state.mode != _BotEngagementMode.replan) {
      state.expectedPlayerPosition = _playerRoutePoint(0.45);
      return state.mode;
    }

    final cluster = _bestDroppedMassCluster(bot);
    final clusterContested = cluster != null &&
        player.alive &&
        player.head.distanceTo(cluster.center) <=
            config.botDroppedMassGuardRadius;
    if (clusterContested) {
      final claimRank = _droppedMassClaimRank(bot, cluster);
      state.mode = claimRank == 0
          ? _BotEngagementMode.harvest
          : claimRank == 1
              ? _BotEngagementMode.deny
              : _BotEngagementMode.screen;
      state.remaining = state.mode == _BotEngagementMode.harvest ? 0.85 : 0.65;
    } else if (player.alive &&
        bot.head.distanceTo(player.head) <= config.botEngagementRadius) {
      final rank = _playerEngagementRank(bot);
      state.mode = rank == 0
          ? _BotEngagementMode.intercept
          : rank == 1
              ? _BotEngagementMode.screen
              : _BotEngagementMode.deny;
      state.remaining = state.mode == _BotEngagementMode.intercept ? 0.75 : 0.6;
    } else {
      state.mode = _BotEngagementMode.observe;
      state.remaining = 0.45;
    }

    state.expectedPlayerPosition = _playerRoutePoint(0.45);
    return state.mode;
  }

  Vec2 _closedLoopIntent(
    SnakeState bot,
    _BotEngagementMode mode,
  ) {
    if (!player.alive) return Vec2.zero;
    final state = _botEngagementStates[bot.id];
    final side = bot.colorIndex.isEven ? 1.0 : -1.0;
    final lateral = Vec2(-player.heading.y, player.heading.x);
    final lead = math.max(config.botCurvedRouteLeadTime, 0.8).toDouble();

    Vec2 target;
    switch (mode) {
      case _BotEngagementMode.observe:
        return Vec2.zero;
      case _BotEngagementMode.replan:
      case _BotEngagementMode.intercept:
        final lane = state?.lane ?? 0;
        final offsets = <double>[
          side * config.botEngagementLaneDistance * 0.35,
          side * config.botEngagementLaneDistance,
          -side * config.botEngagementLaneDistance * 0.7,
        ];
        target = _bestClosedLoopTarget(
          bot,
          lead,
          offsets[(lane + 1) % offsets.length],
          offsets,
        );
      case _BotEngagementMode.screen:
        final lane = state?.lane ?? 0;
        final offsets = <double>[
          side * config.botScreenDistance,
          -side * config.botScreenDistance,
          side * config.botScreenDistance * 0.45,
        ];
        target = _bestClosedLoopTarget(
          bot,
          lead * 0.78,
          offsets[lane % offsets.length],
          offsets,
        );
      case _BotEngagementMode.deny:
        final cluster = _bestDroppedMassCluster(bot);
        if (cluster != null &&
            player.head.distanceTo(cluster.center) <=
                config.botDroppedMassGuardRadius) {
          final approach = (cluster.center - player.head).normalized();
          target = player.head +
              approach * config.botDenyDistance +
              lateral * side * config.botScreenDistance * 0.45;
        } else {
          target = _bestClosedLoopTarget(
            bot,
            lead * 0.9,
            -side * config.botDenyDistance,
            <double>[
              -side * config.botDenyDistance,
              side * config.botDenyDistance,
            ],
          );
        }
      case _BotEngagementMode.harvest:
        final cluster = _bestDroppedMassCluster(bot);
        if (cluster == null) return Vec2.zero;
        target = cluster.center +
            lateral * side * config.botEngagementLaneDistance * 0.3;
      case _BotEngagementMode.abort:
        final risk = _playerRouteRisk(bot);
        final escape = risk.escape.length == 0
            ? (bot.head - player.head).normalized()
            : risk.escape;
        target = bot.head + escape * config.botScreenDistance * 1.8;
    }

    final direction = target - bot.head;
    return direction.length == 0 ? Vec2.zero : direction.normalized();
  }

  Vec2 _bestClosedLoopTarget(
    SnakeState bot,
    double lead,
    double preferredOffset,
    List<double> offsets,
  ) {
    var bestTarget = _playerRoutePoint(lead) +
        Vec2(-player.heading.y, player.heading.x) * preferredOffset;
    var bestScore = double.infinity;
    for (final offset in offsets) {
      final candidate = _playerRoutePoint(lead) +
          Vec2(-player.heading.y, player.heading.x) * offset;
      final risk = _engagementLaneRisk(bot, candidate);
      final preferencePenalty = (offset - preferredOffset).abs() /
          math.max(config.botEngagementLaneDistance, 1.0);
      final score = risk * 8 + preferencePenalty * 0.16;
      if (score < bestScore) {
        bestScore = score;
        bestTarget = candidate;
      }
    }
    return bestTarget;
  }

  Vec2 _playerRoutePoint(double seconds) {
    final speed = _effectiveSpeed(player);
    final lateral = Vec2(-player.heading.y, player.heading.x);
    final curveOffset =
        speed * _observedPlayerTurnRate * seconds * seconds * 0.5;
    return player.head +
        player.heading * (speed * seconds) +
        lateral * curveOffset;
  }

  _BotTactic _advanceBotTactic(SnakeState bot, double dt) {
    final state = _botTactics.putIfAbsent(bot.id, _BotTacticState.new);
    final headingChanged = state.plannedPlayerHeading != null &&
        _alignment(state.plannedPlayerHeading!, player.heading) < 0.58;
    final lateralReplan = state.plannedPlayerPosition != null &&
        player.head.distanceTo(state.plannedPlayerPosition!) > 120 &&
        _alignment(
              player.heading,
              player.head - state.plannedPlayerPosition!,
            ) <
            0.35;
    if (headingChanged || lateralReplan) {
      // A tactic is a short commitment, not a locked target. A sharp player
      // turn or lateral escape invalidates the old intercept lane immediately.
      state.remaining = 0;
    }
    state.remaining -= dt;
    if (state.remaining > 0) return state.mode;

    state.mode = _selectBotTactic(bot);
    final minimum = math.max(0.1, config.botTacticDecisionMin);
    final maximum = math.max(minimum, config.botTacticDecisionMax);
    state.remaining = minimum + _random.nextDouble() * (maximum - minimum);
    state.sign = _random.nextBool() ? 1 : -1;
    state.plannedPlayerHeading = player.heading;
    state.plannedPlayerPosition = player.head;
    bot.tacticalTurnRateMultiplier = 1 -
        config.botTacticTurnVariance / 2 +
        _random.nextDouble() * config.botTacticTurnVariance;
    return state.mode;
  }

  _BotTactic _selectBotTactic(SnakeState bot) {
    if (_shouldPrioritizeRetreat(bot)) return _BotTactic.disengage;
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
        targetMultiplier = config.botTacticSpeedBoost;
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
    final plan = _playerEngagementPlan(bot);

    switch (tactic) {
      case _BotTactic.feint:
        final oscillation = math.sin(elapsed * 7.0 + bot.colorIndex * 1.9) *
            config.botTacticWeaveStrength;
        final target =
            player.head + lead + playerLateral * (oscillation + sign * 70);
        return target - bot.head;
      case _BotTactic.cutoff:
        final target = plan.rank < 100
            ? plan.target
            : player.head +
                lead +
                playerLateral * (sign * config.botFlankDistance * 0.55);
        return target - bot.head;
      case _BotTactic.flank:
        final target = plan.rank < 100
            ? plan.target
            : player.head +
                player.heading *
                    (config.botCutoffLeadTime * player.speed * 0.55) +
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

    final routeRisk = _playerRouteRisk(bot);
    final geometryPlan = _geometryAttackPlan(bot);
    final canSprintThroughLane = geometryPlan.attack &&
        geometryPlan.safety >= config.botAttackAbortSafety &&
        routeRisk.urgency < 0.8;
    if (routeRisk.urgency >= 0.48 && !canSprintThroughLane) return;

    final playerDistance = bot.head.distanceTo(player.head);
    final droppedMassCluster = _bestDroppedMassCluster(bot);
    final droppedMassDistance = math.min(
      _nearestDroppedMassDistance(bot),
      droppedMassCluster == null
          ? double.infinity
          : bot.head.distanceTo(droppedMassCluster.center),
    );
    final naturalFoodDistance = _nearestNaturalFoodDistance(bot);
    final distanceLimit = config.botSprintTriggerDistance;
    var shouldSprint = false;
    final playerNearCluster = droppedMassCluster != null &&
        player.alive &&
        player.head.distanceTo(droppedMassCluster.center) <=
            config.botDroppedMassGuardRadius;

    switch (bot.disposition) {
      case BotDisposition.defensive:
        shouldSprint = bot.retreating ||
            (player.alive &&
                playerDistance <= distanceLimit * 0.8 &&
                bot.length <= player.length * 1.2);
      case BotDisposition.aggressive:
        shouldSprint = (player.alive &&
                playerDistance <= distanceLimit &&
                bot.length >= player.length * 0.75 &&
                bot.length <= player.length * 1.6) ||
            (playerNearCluster && droppedMassDistance <= distanceLimit * 1.5);
      case BotDisposition.opportunistic:
        shouldSprint = droppedMassDistance <= distanceLimit ||
            (playerNearCluster && droppedMassDistance <= distanceLimit * 1.5);
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

  void _interruptBotPursuit(SnakeState bot) {
    if (bot.sprinting || bot.sprintRequested) {
      _cancelSprintRequest(bot);
    }
    final state = _botTactics.putIfAbsent(bot.id, _BotTacticState.new);
    state.mode = _BotTactic.disengage;
    state.remaining = math.min(state.remaining, 0.35).toDouble();
    state.sign = bot.id.hashCode.isEven ? 1 : -1;
  }

  bool _shouldPrioritizeRetreat(SnakeState bot) {
    if (!bot.retreating) return false;

    final boundaryStart = config.arenaRadius - config.botRetreatBoundaryBuffer;
    final atBoundary = bot.head.length >= boundaryStart;
    if (atBoundary) return true;

    final nearbyThreat = _nearbyThreat(bot).length;
    if (nearbyThreat >= 1.15) return true;

    return _playerRouteRisk(bot).urgency >= 0.72;
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

  Vec2 _droppedMassControl(SnakeState bot) {
    final cluster = _bestDroppedMassCluster(bot);
    if (cluster == null) return Vec2.zero;

    final claimRank = _droppedMassClaimRank(bot, cluster);
    final toCluster = cluster.center - bot.head;
    if (toCluster.length == 0) return Vec2.zero;

    final playerToCluster = cluster.center - player.head;
    final playerDistance = player.head.distanceTo(cluster.center);
    final playerApproaching = player.alive &&
        playerDistance <= config.botDroppedMassGuardRadius &&
        _alignment(player.heading, playerToCluster) >= 0.15;

    Vec2 target;
    if (playerApproaching && claimRank > 0) {
      // The first claimant harvests. The next claimant blocks the public
      // approach instead of joining the same pellet lane, giving the bots a
      // way to deny a player access to a fresh defeat field.
      final approach = playerToCluster.normalized();
      final lateral = Vec2(-approach.y, approach.x);
      final side = bot.colorIndex.isEven ? 1.0 : -1.0;
      target = player.head +
          approach * config.botDroppedMassGuardDistance +
          lateral * (side * math.min(claimRank, 2).toDouble() * 95.0);
    } else {
      final toTarget = toCluster.normalized();
      final lateral = Vec2(-toTarget.y, toTarget.x);
      final side = bot.colorIndex.isEven ? 1.0 : -1.0;
      final lane = claimRank == 0
          ? 0.0
          : side *
              math.min(claimRank, 3).toDouble() *
              config.botDroppedMassGuardDistance;
      target = cluster.center + lateral * lane;
    }

    final distance = bot.head.distanceTo(target);
    final proximity = (1 - distance / config.botDroppedMassSenseRadius)
        .clamp(0.0, 1.0)
        .toDouble();
    final clusterValue = math.min(cluster.value, 12).toDouble();
    return (target - bot.head).normalized() *
        (0.55 + proximity * 0.45) *
        (1 + clusterValue * 0.08);
  }

  _DroppedMassCluster? _bestDroppedMassCluster(SnakeState bot) {
    if (_droppedMassClusters.isEmpty) return null;

    _DroppedMassCluster? best;
    var bestScore = 0.0;
    for (final cluster in _droppedMassClusters) {
      final distance = bot.head.distanceTo(cluster.center);
      if (distance > config.botDroppedMassSenseRadius) continue;

      final playerDistance = player.head.distanceTo(cluster.center);
      final contested =
          player.alive && playerDistance <= config.botDroppedMassGuardRadius
              ? 1.9
              : 1.0;
      final score = (cluster.value *
              (1 + math.min(cluster.memberCount, 8) * 0.3) *
              contested) /
          math.max(140.0, distance).toDouble();
      if (score > bestScore) {
        bestScore = score;
        best = cluster;
      }
    }
    return best;
  }

  int _droppedMassClaimRank(
    SnakeState bot,
    _DroppedMassCluster cluster,
  ) {
    final candidates = snakes
        .where(
          (candidate) =>
              candidate.kind == SnakeKind.bot &&
              candidate.alive &&
              !_shouldPrioritizeRetreat(candidate) &&
              candidate.head.distanceTo(cluster.center) <=
                  config.botDroppedMassSenseRadius,
        )
        .toList()
      ..sort((left, right) {
        final leftArrival = left.head.distanceTo(cluster.center) /
            math.max(1.0, _effectiveSpeed(left));
        final rightArrival = right.head.distanceTo(cluster.center) /
            math.max(1.0, _effectiveSpeed(right));
        final arrivalOrder = leftArrival.compareTo(rightArrival);
        if (arrivalOrder != 0) return arrivalOrder;
        return left.id.compareTo(right.id);
      });
    final rank = candidates.indexWhere((candidate) => candidate.id == bot.id);
    return rank < 0 ? candidates.length : rank;
  }

  Vec2 _playerPressure(SnakeState bot) {
    if (!player.alive) return Vec2.zero;

    final distance = bot.head.distanceTo(player.head);
    if (distance > config.botEngagementRadius) return Vec2.zero;

    final plan = _playerEngagementPlan(bot);
    final direction = plan.target - bot.head;
    if (direction.length == 0) return Vec2.zero;

    final proximity =
        ((config.botEngagementRadius - distance) / config.botEngagementRadius)
            .clamp(0.0, 1.0)
            .toDouble();
    final roleWeight = plan.rank == 0
        ? 1.0
        : plan.rank == 1
            ? 0.72
            : 0.42;
    final sizeFactor = bot.length >= player.length ? 1.25 : 0.9;
    return direction.normalized() *
        (config.botEngagementWeight *
            (0.7 + proximity * 0.3) *
            roleWeight *
            sizeFactor *
            (0.72 + plan.safety * 0.28));
  }

  _BotEngagementPlan _playerEngagementPlan(SnakeState bot) {
    if (!player.alive ||
        bot.head.distanceTo(player.head) > config.botEngagementRadius) {
      return _BotEngagementPlan(
        target: bot.head,
        rank: 100,
        safety: 0,
      );
    }

    final rank = _playerEngagementRank(bot);
    final lateral = Vec2(-player.heading.y, player.heading.x);
    final lane = config.botEngagementLaneDistance;
    final side = bot.colorIndex.isEven ? 1.0 : -1.0;
    final leadTime = config.botEngagementLeadTime *
        (1 + math.min(rank, 2).toDouble() * 0.18);
    final preferredOffset =
        rank == 0 ? side * lane * 0.35 : side * lane * (rank == 1 ? 1.0 : 1.35);
    final offsets = rank == 0
        ? <double>[preferredOffset, 0, -preferredOffset]
        : <double>[
            preferredOffset,
            -preferredOffset,
            side * lane * 0.55,
          ];
    var bestTarget = player.head +
        player.heading * (player.speed * leadTime) +
        lateral * preferredOffset;
    var bestRisk = double.infinity;
    for (final offset in offsets) {
      final candidate = player.head +
          player.heading * (player.speed * leadTime) +
          lateral * offset;
      final risk = _engagementLaneRisk(bot, candidate);
      final preferencePenalty = (offset - preferredOffset).abs() / lane;
      final score = risk * 8 + preferencePenalty * 0.12;
      if (score < bestRisk) {
        bestRisk = score;
        bestTarget = candidate;
      }
    }

    final safety = (1 - bestRisk.clamp(0.0, 1.0)).toDouble();
    return _BotEngagementPlan(
      target: bestTarget,
      rank: rank,
      safety: safety,
    );
  }

  _BotGeometryPlan _geometryAttackPlan(SnakeState bot) {
    if (!player.alive ||
        bot.head.distanceTo(player.head) > config.botEngagementRadius) {
      return const _BotGeometryPlan(
        target: Vec2.zero,
        safety: 0,
        abortRoute: Vec2.zero,
      );
    }

    final lateral = Vec2(-player.heading.y, player.heading.x);
    final side = bot.colorIndex.isEven ? 1.0 : -1.0;
    final midpoint = player.body[
        math.min(player.body.length - 1, math.max(1, player.body.length ~/ 2))];
    final tail = player.body.last;
    final routeLead = _playerRoutePoint(config.botEngagementLeadTime);
    final gapDirection =
        (player.heading + (player.head - tail).normalized()).normalized();
    final candidates = <Vec2>[
      routeLead + lateral * side * config.botEngagementLaneDistance * 0.35,
      routeLead + lateral * -side * config.botEngagementLaneDistance * 0.8,
      player.head + lateral * side * (player.radius + bot.radius + 82),
      midpoint + lateral * side * config.botEncircleGapDistance,
      midpoint + lateral * -side * config.botEncircleGapDistance,
      tail +
          gapDirection * config.botFlankDistance +
          lateral * side * config.botFlankDistance * 0.45,
    ];

    var bestTarget = candidates.first;
    var bestScore = double.infinity;
    var bestLaneSafety = 0.0;
    var bestAbortSafety = 0.0;
    var bestAbort = Vec2.zero;
    for (var index = 0; index < candidates.length; index++) {
      final candidate = candidates[index];
      final laneRisk = _engagementLaneRisk(bot, candidate);
      final approach = (candidate - bot.head).normalized();
      if (approach.length == 0) continue;
      final approachLateral = Vec2(-approach.y, approach.x);
      final abortCandidates = <Vec2>[
        bot.head + approachLateral * side * config.botAttackAbortDistance,
        bot.head - approachLateral * side * config.botAttackAbortDistance,
        bot.head +
            (bot.head - player.head).normalized() *
                config.botAttackAbortDistance,
      ];
      var abortSafety = 0.0;
      var abortVector = Vec2.zero;
      for (final abortTarget in abortCandidates) {
        final safety =
            (1 - _engagementLaneRisk(bot, abortTarget).clamp(0.0, 1.0))
                .toDouble();
        if (safety > abortSafety) {
          abortSafety = safety;
          abortVector = (abortTarget - bot.head).normalized();
        }
      }
      final laneSafety = (1 - laneRisk.clamp(0.0, 1.0)).toDouble();
      final preferredPenalty = index == 0 ? 0.0 : 0.06;
      final geometryReward = index >= 2 ? 0.18 : 0.0;
      final score = laneRisk * 8 +
          (1 - abortSafety) * 2.4 +
          preferredPenalty -
          geometryReward *
              (bot.disposition == BotDisposition.aggressive ? 1.3 : 1.0);
      if (score < bestScore) {
        bestScore = score;
        bestTarget = candidate;
        bestLaneSafety = laneSafety;
        bestAbortSafety = abortSafety;
        bestAbort = abortVector * abortSafety;
      }
    }

    return _BotGeometryPlan(
      target: bestTarget,
      safety: bestLaneSafety * 0.7 + bestAbortSafety * 0.3,
      abortRoute: bestAbort,
    );
  }

  Vec2 _geometryPressure(SnakeState bot, _BotGeometryPlan plan) {
    if (!player.alive || !plan.attack || plan.target == bot.head) {
      return Vec2.zero;
    }
    final approach = (plan.target - bot.head).normalized();
    final routeBias = plan.abortRoute * (1 - plan.safety).clamp(0.0, 1.0);
    return (approach * (0.65 + plan.safety * 0.35) + routeBias * 0.22)
        .normalized();
  }

  double _engagementLaneRisk(SnakeState bot, Vec2 target) {
    final toTarget = target - bot.head;
    if (toTarget.length == 0) return 1;

    final direction = toTarget.normalized();
    final speed = _effectiveSpeed(bot);
    final lookahead = math.max(config.botAdaptiveLeadTime, 1.0).toDouble();
    final samples = math.max(2, config.botCollisionSampleCount).toInt();
    var maximumRisk = 0.0;
    final bodyRadius = math
        .max(
          config.botEngagementSafetyRadius,
          bot.radius + player.radius + 24,
        )
        .toDouble();

    for (var sample = 1; sample <= samples; sample++) {
      final progress = sample / samples;
      final travel = math
          .min(
            toTarget.length * progress,
            speed * lookahead * progress,
          )
          .toDouble();
      final future = bot.head + direction * travel;
      final playerTravel =
          _playerRoutePoint(lookahead * progress) - player.head;
      for (final segment in player.body.skip(2)) {
        final distance = future.distanceTo(segment + playerTravel);
        if (distance >= bodyRadius) continue;
        maximumRisk = math
            .max(
              maximumRisk,
              ((bodyRadius - distance) / bodyRadius).clamp(0.0, 1.0).toDouble(),
            )
            .toDouble();
      }

      for (final other in snakes.where(
        (candidate) =>
            candidate.kind == SnakeKind.bot &&
            candidate.id != bot.id &&
            candidate.alive,
      )) {
        final otherFuture = other.head +
            other.heading * (_effectiveSpeed(other) * lookahead * progress);
        final distance = future.distanceTo(otherFuture);
        final peerRadius = bot.radius + other.radius + 52;
        if (distance >= peerRadius) continue;
        maximumRisk = math
            .max(
              maximumRisk,
              ((peerRadius - distance) / peerRadius).clamp(0.0, 1.0).toDouble(),
            )
            .toDouble();
      }
    }

    final boundary =
        target.length >= config.arenaRadius - config.botBoundaryBuffer * 0.5;
    return boundary ? math.max(maximumRisk, 0.75).toDouble() : maximumRisk;
  }

  int _playerEngagementRank(SnakeState bot) {
    final target = _playerRoutePoint(config.botEngagementLeadTime);
    final candidates = snakes
        .where(
          (candidate) =>
              candidate.kind == SnakeKind.bot &&
              candidate.alive &&
              !_shouldPrioritizeRetreat(candidate) &&
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
    final lookahead = config.botCollisionLookahead;
    final samples = math.max(1, config.botCollisionSampleCount).toInt();
    if (speed <= 0 || samples <= 0) return avoidance;

    for (final other in snakes.where(
      (candidate) => candidate.id != snake.id && candidate.alive,
    )) {
      final otherSpeed = _effectiveSpeed(other);
      for (var sample = 1; sample <= samples; sample++) {
        final progress = sample / samples;
        final future =
            snake.head + snake.heading * (speed * lookahead * progress);
        final otherTravel = other.heading * (otherSpeed * lookahead * progress);
        for (final segment in other.body.skip(1)) {
          // Treat the other body as moving with its current public heading.
          // A static-body test reacts after two snakes have already selected
          // the same lane; this projected body test creates room before the
          // crossing occurs.
          final projectedSegment = segment + otherTravel;
          final offset = future - projectedSegment;
          final distance = offset.length;
          final avoidanceRadius = math
              .max(
                config.botCollisionAvoidanceRadius,
                config.botRouteAvoidanceRadius,
              )
              .toDouble();
          if (distance <= 0 || distance >= avoidanceRadius) {
            continue;
          }

          final urgency = (avoidanceRadius - distance) / avoidanceRadius;
          var escape = offset.normalized();
          if (_alignment(snake.heading, projectedSegment - future) > 0.15) {
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

  _BotRouteRisk _playerRouteRisk(SnakeState bot) {
    if (!player.alive || _effectiveSpeed(bot) <= 0) {
      return const _BotRouteRisk(escape: Vec2.zero, urgency: 0);
    }

    final speed = _effectiveSpeed(bot);
    final lookahead = math.max(
      config.botCollisionLookahead,
      config.botAdaptiveLeadTime,
    );
    final samples = math.max(2, config.botCollisionSampleCount).toInt();
    final radius = math
        .max(
          config.botDefensiveAvoidanceRadius,
          bot.radius + player.radius + 26,
        )
        .toDouble();
    var escape = Vec2.zero;
    var maximumUrgency = 0.0;

    for (var sample = 1; sample <= samples; sample++) {
      final progress = sample / samples;
      final future = bot.head + bot.heading * (speed * lookahead * progress);
      final playerTravel =
          _playerRoutePoint(lookahead * progress) - player.head;
      for (final segment in player.body.skip(1)) {
        final projectedSegment = segment + playerTravel;
        final offset = future - projectedSegment;
        final distance = offset.length;
        if (distance >= radius) continue;

        final urgency = ((radius - distance) / radius).clamp(0.0, 1.0);
        maximumUrgency = math.max(maximumUrgency, urgency).toDouble();
        final away = distance == 0
            ? Vec2(-bot.heading.y, bot.heading.x) *
                (bot.id.compareTo(player.id) <= 0 ? 1.0 : -1.0)
            : offset.normalized();
        final lateral = Vec2(-bot.heading.y, bot.heading.x) *
            (bot.id.compareTo(player.id) <= 0 ? 1.0 : -1.0);
        // Side-step first, then open distance. This avoids the common failure
        // where a bot brakes toward the same player body it was pursuing.
        escape +=
            (away * 0.35 + lateral * 0.95).normalized() * (urgency * urgency);
      }
    }

    return _BotRouteRisk(
      escape: escape.normalized(),
      urgency: maximumUrgency,
    );
  }

  _BotPeerRisk _botPeerRouteRisk(SnakeState bot) {
    final speed = _effectiveSpeed(bot);
    if (speed <= 0) {
      return const _BotPeerRisk(escape: Vec2.zero, urgency: 0);
    }

    final lookahead = math.max(
      config.botCollisionLookahead,
      config.botAdaptiveLeadTime,
    );
    final samples = math.max(2, config.botCollisionSampleCount).toInt();
    var escape = Vec2.zero;
    var maximumUrgency = 0.0;
    for (final other in snakes.where(
      (candidate) =>
          candidate.kind == SnakeKind.bot &&
          candidate.id != bot.id &&
          candidate.alive,
    )) {
      for (var sample = 1; sample <= samples; sample++) {
        final progress = sample / samples;
        final future = bot.head + bot.heading * (speed * lookahead * progress);
        final otherTravel =
            other.heading * (_effectiveSpeed(other) * lookahead * progress);
        final peerRadius = math.max(
          config.botPeerHardAvoidanceRadius,
          bot.radius + other.radius + 42,
        );
        final peerHead = other.head + otherTravel;
        final headOffset = future - peerHead;
        final headDistance = headOffset.length;
        if (headDistance < peerRadius) {
          final urgency = ((peerRadius - headDistance) / peerRadius)
              .clamp(0.0, 1.0)
              .toDouble();
          maximumUrgency = math.max(maximumUrgency, urgency).toDouble();
          final side = _peerYieldSide(bot, other);
          final away = headDistance == 0 ? side : headOffset.normalized();
          escape +=
              (away * 0.35 + side * 0.95).normalized() * (urgency * urgency);
        }

        for (final segment in other.body.skip(1)) {
          final projectedSegment = segment + otherTravel;
          final offset = future - projectedSegment;
          final distance = offset.length;
          final bodyRadius = bot.radius + other.radius + 24;
          if (distance >= bodyRadius) continue;

          final urgency =
              ((bodyRadius - distance) / bodyRadius).clamp(0.0, 1.0).toDouble();
          maximumUrgency = math.max(maximumUrgency, urgency).toDouble();
          final side = _peerYieldSide(bot, other);
          final away = distance == 0 ? side : offset.normalized();
          escape +=
              (away * 0.45 + side * 0.85).normalized() * (urgency * urgency);
        }
      }
    }
    return _BotPeerRisk(
      escape: escape.normalized(),
      urgency: maximumUrgency,
    );
  }

  Vec2 _peerYieldSide(SnakeState bot, SnakeState other) {
    final lowerId = bot.id.compareTo(other.id) <= 0;
    final lowerHead = lowerId ? bot.head : other.head;
    final higherHead = lowerId ? other.head : bot.head;
    final axis = higherHead - lowerHead;
    final basis = axis.length == 0
        ? const Vec2(0, 1)
        : Vec2(-axis.y, axis.x).normalized();
    return basis * (lowerId ? 1.0 : -1.0);
  }

  Vec2 _peerSeparation(SnakeState bot) {
    var separation = Vec2.zero;
    final samples = math.max(1, config.botCollisionSampleCount).toInt();
    final lookahead = config.botCollisionLookahead;
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

      final botSpeed = _effectiveSpeed(bot);
      final otherSpeed = _effectiveSpeed(other);
      for (var sample = 1; sample <= samples; sample++) {
        final progress = sample / samples;
        final future =
            bot.head + bot.heading * (botSpeed * lookahead * progress);
        final otherFuture =
            other.head + other.heading * (otherSpeed * lookahead * progress);
        final routeOffset = future - otherFuture;
        final routeDistance = routeOffset.length;
        if (routeDistance <= 0 ||
            routeDistance >= config.botPeerSeparationRadius) {
          continue;
        }
        final routeUrgency = (config.botPeerSeparationRadius - routeDistance) /
            config.botPeerSeparationRadius;
        var escape = routeOffset.normalized();
        final side = Vec2(-bot.heading.y, bot.heading.x) *
            (bot.id.compareTo(other.id) <= 0 ? 1.0 : -1.0);
        escape = (escape * 0.4 + side * 0.8).normalized();
        separation += escape * (routeUrgency * routeUrgency);
      }
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
      if (snake.movementTrail.isEmpty ||
          snake.movementTrail.last != currentHead) {
        snake.movementTrail.add(currentHead);
      }
      snake.movementTrail.add(nextHead);
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
      maximumDistance +
          snake.segmentSpacing *
              math.max(2, config.movementTrailTrimSlackSegments),
    );

    final visibleBody = <Vec2>[];
    final trail = snake.movementTrail;
    var trailIndex = trail.length - 1;
    var travelled = 0.0;

    Vec2 sampleAt(double distance) {
      while (trailIndex > 0) {
        final start = trail[trailIndex];
        final end = trail[trailIndex - 1];
        final segmentLength = start.distanceTo(end);
        if (segmentLength == 0) {
          trailIndex--;
          continue;
        }
        if (travelled + segmentLength >= distance) {
          final fraction = (distance - travelled) / segmentLength;
          return start + (end - start) * fraction;
        }
        travelled += segmentLength;
        trailIndex--;
      }

      final last = trail.first;
      if (trail.length < 2) return last;
      final tailDirection = last - trail[1];
      final normalized = tailDirection.length == 0
          ? snake.heading * -1
          : tailDirection.normalized();
      return last + normalized * (distance - travelled);
    }

    for (var index = 0; index < fullLength; index++) {
      visibleBody.add(sampleAt(index * snake.segmentSpacing));
    }
    if (extension > 0.0001 && visibleBody.isNotEmpty) {
      visibleBody
          .add(sampleAt((fullLength - 1) * snake.segmentSpacing + extension));
    }
    snake.body
      ..clear()
      ..addAll(visibleBody);
  }

  void _trimMovementTrail(SnakeState snake, double maximumDistance) {
    if (snake.movementTrail.length < 3) return;

    var distance = 0.0;
    for (var index = snake.movementTrail.length - 1; index > 0; index--) {
      distance += snake.movementTrail[index].distanceTo(
        snake.movementTrail[index - 1],
      );
      if (distance > maximumDistance) {
        final removeThrough = index - 1;
        if (removeThrough > 0) {
          snake.movementTrail.removeRange(0, removeThrough);
        }
        return;
      }
    }
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
      _addDroppedMass(
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
        _droppedMassAges.remove(pellet);
        final requestedGrowth = snake.kind == SnakeKind.bot
            ? (pellet.value *
                    config.botGrowthMultiplier *
                    _botAdaptiveGrowthMultiplier(snake))
                .round()
                .clamp(1, double.infinity)
                .toInt()
            : pellet.value;
        final adaptiveMaximum = snake.kind == SnakeKind.bot
            ? _botAdaptiveMaximumLength(snake)
            : double.infinity;
        final growth = snake.kind == SnakeKind.bot
            ? math
                .min(
                  requestedGrowth,
                  math.max(0, adaptiveMaximum - snake.length),
                )
                .toInt()
            : requestedGrowth;
        if (growth > 0) snake.grow(growth);
        if (snake.kind == SnakeKind.player) score += pellet.value;
      }
    }
  }

  double _botAdaptiveGrowthMultiplier(SnakeState bot) {
    if (!player.alive || config.botAdaptiveGrowthGap <= 0) return 1;
    final gap = math.max(0, player.length - bot.length).toDouble();
    final catchUp =
        (gap / config.botAdaptiveGrowthGap).clamp(0.0, 1.0).toDouble();
    return 1 + catchUp * 1.25;
  }

  double _botAdaptiveMaximumLength(SnakeState bot) {
    if (!player.alive || config.botAdaptiveMaximumLength <= 0) {
      return config.botMaximumLength.toDouble();
    }
    final gap = math.max(0, player.length - bot.length).toDouble();
    final scaledMaximum = config.botMaximumLength + (gap * 0.5).round();
    return math.min(config.botAdaptiveMaximumLength, scaledMaximum).toDouble();
  }

  void _advanceBotCatchUp(double dt) {
    if (!player.alive || elapsed < config.botCatchUpDelay) return;
    for (final bot in snakes.where(
      (snake) => snake.kind == SnakeKind.bot && snake.alive,
    )) {
      final target = math
          .min(
            _botAdaptiveMaximumLength(bot),
            math.max(
              bot.spawnLength,
              (player.length * config.botCatchUpTargetFraction).round(),
            ),
          )
          .toInt();
      final gap = target - bot.length;
      final credit = _botCatchUpCredits[bot.id] ?? 0;
      if (gap <= 0) {
        _botCatchUpCredits[bot.id] = math.max(0, credit - dt).toDouble();
        continue;
      }

      final pressure = (gap / math.max(1, config.botAdaptiveGrowthGap))
          .clamp(0.0, 1.0)
          .toDouble();
      final nextCredit =
          credit + dt * config.botCatchUpRate * (0.55 + pressure * 0.9);
      final growth = math.min(gap, nextCredit.floor()).toInt();
      if (growth > 0) {
        bot.grow(growth);
        _botCatchUpCredits[bot.id] = nextCredit - growth;
      } else {
        _botCatchUpCredits[bot.id] = nextCredit;
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
        _addDroppedMass(
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

  void _addDroppedMass(FoodPellet pellet) {
    if (config.maxDroppedMass <= 0) return;
    droppedMass.add(pellet);
    _droppedMassAges[pellet] = 0;
    _enforceDroppedMassLimit();
  }

  void _advanceDroppedMass(double dt) {
    if (droppedMass.isEmpty) return;
    if (config.droppedMassLifetime <= 0 || config.maxDroppedMass <= 0) {
      droppedMass.clear();
      _droppedMassAges.clear();
      _droppedMassClusters.clear();
      return;
    }

    for (final pellet in droppedMass) {
      _droppedMassAges[pellet] = (_droppedMassAges[pellet] ?? 0) + dt;
    }
    droppedMass.removeWhere((pellet) {
      final expired =
          (_droppedMassAges[pellet] ?? 0) >= config.droppedMassLifetime;
      if (expired) _droppedMassAges.remove(pellet);
      return expired;
    });
    _enforceDroppedMassLimit();
  }

  void _enforceDroppedMassLimit() {
    while (droppedMass.length > config.maxDroppedMass) {
      FoodPellet? oldest;
      var oldestAge = -1.0;
      for (final pellet in droppedMass) {
        final age = _droppedMassAges[pellet] ?? 0;
        if (age > oldestAge) {
          oldest = pellet;
          oldestAge = age;
        }
      }
      if (oldest == null) break;
      droppedMass.remove(oldest);
      _droppedMassAges.remove(oldest);
    }
  }

  void _rebuildDroppedMassClusters() {
    _droppedMassClusters.clear();
    if (droppedMass.isEmpty) return;

    final bucketSize = math.max(1.0, config.botDroppedMassClusterRadius);
    final buckets = <String, _DroppedMassBucket>{};
    for (final pellet in droppedMass) {
      final bucketX = (pellet.position.x / bucketSize).floor();
      final bucketY = (pellet.position.y / bucketSize).floor();
      final key = '$bucketX:$bucketY';
      final bucket = buckets.putIfAbsent(key, _DroppedMassBucket.new);
      bucket.value += pellet.value;
      bucket.count++;
      bucket.weightedX += pellet.position.x * pellet.value;
      bucket.weightedY += pellet.position.y * pellet.value;
    }

    for (final bucket in buckets.values) {
      final value = math.max(1, bucket.value);
      _droppedMassClusters.add(
        _DroppedMassCluster(
          center: Vec2(
            bucket.weightedX / value,
            bucket.weightedY / value,
          ),
          value: bucket.value,
          radius: config.botDroppedMassClusterRadius,
          memberCount: bucket.count,
        ),
      );
    }
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
        _botPlans.remove(id);
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
