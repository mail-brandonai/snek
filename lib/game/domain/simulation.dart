import 'dart:math' as math;

import 'game_state.dart';
import 'simulation_capture.dart';
import 'vec2.dart';

class SimulationConfig {
  const SimulationConfig({
    this.arenaRadius = 1800,
    this.arenaBoundaryWarningBuffer = 260,
    this.playerSpeed = 175,
    this.botSpeed = 175,
    this.botTurnRate = 6,
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
    this.botSizeSpeedPenalty = 0,
    this.botSprintMultiplier = 2.4,
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
    // Dropped mass is persistent by default. A finite lifetime remains
    // available to constrained test or server configurations, but ordinary
    // gameplay must not silently erase a recoverable reward.
    this.droppedMassLifetime = 0,
    this.droppedMassMergeRadius = 72,
    this.botCatchUpDelay = 18,
    this.botCatchUpRate = 1.4,
    this.botCatchUpTargetFraction = 0.58,
    this.botTacticalDecisionInterval = 0.12,
    this.botPlannerLookahead = 0.9,
    this.botRouteReservationDistance = 170,
    this.movementTrailTrimSlackSegments = 8,
    this.spatialBucketSize = 180,
    this.busyPlanningLoadThreshold = 1800,
    this.busyPlanningIntervalMultiplier = 2.25,
    this.simulationStep = 1 / 60,
    this.maxSimulationStepsPerUpdate = 2,
    this.bodyIndexStrideThreshold = 320,
    this.botManeuverStageDuration = 0.42,
    this.botManeuverCommitDuration = 0.62,
    this.botManeuverRecoveryDuration = 0.38,
    this.botPlayerMemoryDecay = 0.72,
    this.botReservationHorizon = 1.05,
    this.botYieldSpeedMultiplier = 0.58,
    this.botHunterInitialCount = 1,
    this.botHunterMaximumCount = 2,
    this.botHunterSecondPopulation = 7,
    this.botHunterReentryDistance = 320,
    this.collisionCoreScale = 0.84,
    this.collisionTailTaper = 0.72,
    this.botParallelAlignmentThreshold = 0.82,
    this.botParallelClosingThreshold = 0.1,
    this.botOpportunitySenseRadius = 1500,
    this.botOpportunityResponderLimit = 2,
    this.botOpportunityCommitmentDuration = 1.8,
    this.botEnclosureGraceDuration = 0.55,
    this.botEnclosureSampleLimit = 24,
    this.botEnclosureMinimumSweep = 4.1,
    this.botHookMinimumSweepRatio = 0.72,
    this.botHookClosureRadiusMultiplier = 1.8,
    this.botTacticalPrecisionSafetyRadius = 48,
    this.botResourceFieldRadius = 160,
    this.botResourceFieldMinimumValue = 4,
    this.botPlayerSprintRecoveryDuration = 0.9,
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
  final double droppedMassMergeRadius;
  final double botCatchUpDelay;
  final double botCatchUpRate;
  final double botCatchUpTargetFraction;
  final double botTacticalDecisionInterval;
  final double botPlannerLookahead;
  final double botRouteReservationDistance;
  final int movementTrailTrimSlackSegments;
  final double spatialBucketSize;
  final int busyPlanningLoadThreshold;
  final double busyPlanningIntervalMultiplier;
  final double simulationStep;
  final int maxSimulationStepsPerUpdate;
  final int bodyIndexStrideThreshold;
  final double botManeuverStageDuration;
  final double botManeuverCommitDuration;
  final double botManeuverRecoveryDuration;
  final double botPlayerMemoryDecay;
  final double botReservationHorizon;
  final double botYieldSpeedMultiplier;
  final int botHunterInitialCount;
  final int botHunterMaximumCount;
  final int botHunterSecondPopulation;
  final double botHunterReentryDistance;
  final double collisionCoreScale;
  final double collisionTailTaper;
  final double botParallelAlignmentThreshold;
  final double botParallelClosingThreshold;
  final double botOpportunitySenseRadius;
  final int botOpportunityResponderLimit;
  final double botOpportunityCommitmentDuration;
  final double botEnclosureGraceDuration;
  final int botEnclosureSampleLimit;
  final double botEnclosureMinimumSweep;
  final double botHookMinimumSweepRatio;
  final double botHookClosureRadiusMultiplier;
  final double botTacticalPrecisionSafetyRadius;
  final double botResourceFieldRadius;
  final int botResourceFieldMinimumValue;
  final double botPlayerSprintRecoveryDuration;

  Map<String, Object?> toJson() => <String, Object?>{
        'arenaRadius': arenaRadius,
        'arenaBoundaryWarningBuffer': arenaBoundaryWarningBuffer,
        'playerSpeed': playerSpeed,
        'botSpeed': botSpeed,
        'botTurnRate': botTurnRate,
        'botSenseRadius': botSenseRadius,
        'botBoundaryBuffer': botBoundaryBuffer,
        'botSpawnRadius': botSpawnRadius,
        'segmentSpacing': segmentSpacing,
        'growthExpressionRate': growthExpressionRate,
        'sprintMultiplier': sprintMultiplier,
        'sprintDrainInterval': sprintDrainInterval,
        'naturalPelletValue': naturalPelletValue,
        'sprintDropValue': sprintDropValue,
        'defeatDropValue': defeatDropValue,
        'minimumSprintLength': minimumSprintLength,
        'initialPellets': initialPellets,
        'pelletRefillThreshold': pelletRefillThreshold,
        'pelletRefillRate': pelletRefillRate,
        'botCount': botCount,
        'maxBotCount': maxBotCount,
        'initialLength': initialLength,
        'botRespawnDelay': botRespawnDelay,
        'botRespawnSafeDistance': botRespawnSafeDistance,
        'botRespawnAttempts': botRespawnAttempts,
        'botPopulationInterval': botPopulationInterval,
        'botPressureRadius': botPressureRadius,
        'botPressureWeight': botPressureWeight,
        'botInterceptLeadTime': botInterceptLeadTime,
        'botDroppedMassWeight': botDroppedMassWeight,
        'botGrowthMultiplier': botGrowthMultiplier,
        'botRetreatLength': botRetreatLength,
        'botRetreatBoundaryBuffer': botRetreatBoundaryBuffer,
        'botRetreatWeight': botRetreatWeight,
        'botSizeSpeedPenalty': botSizeSpeedPenalty,
        'botSprintMultiplier': botSprintMultiplier,
        'botSprintDuration': botSprintDuration,
        'botSprintCooldown': botSprintCooldown,
        'botSprintMinimumLength': botSprintMinimumLength,
        'botSprintTriggerDistance': botSprintTriggerDistance,
        'botMaximumLength': botMaximumLength,
        'collisionPingDuration': collisionPingDuration,
        'sprintAnticipationDuration': sprintAnticipationDuration,
        'sprintPulseDuration': sprintPulseDuration,
        'telegraphEventDuration': telegraphEventDuration,
        'telegraphEventLimit': telegraphEventLimit,
        'threatProjectionSeconds': threatProjectionSeconds,
        'threatRadius': threatRadius,
        'threatCommitmentThreshold': threatCommitmentThreshold,
        'botTacticDecisionMin': botTacticDecisionMin,
        'botTacticDecisionMax': botTacticDecisionMax,
        'botTacticTurnVariance': botTacticTurnVariance,
        'botTacticSpeedBoost': botTacticSpeedBoost,
        'botTacticBrakeMultiplier': botTacticBrakeMultiplier,
        'botTacticWeaveStrength': botTacticWeaveStrength,
        'botCutoffLeadTime': botCutoffLeadTime,
        'botFlankDistance': botFlankDistance,
        'botEncircleGapDistance': botEncircleGapDistance,
        'botBaitDistance': botBaitDistance,
        'botEngagementRadius': botEngagementRadius,
        'botEngagementLeadTime': botEngagementLeadTime,
        'botEngagementWeight': botEngagementWeight,
        'botEngagementLaneDistance': botEngagementLaneDistance,
        'botEngagementSafetyRadius': botEngagementSafetyRadius,
        'botCollisionLookahead': botCollisionLookahead,
        'botCollisionSampleCount': botCollisionSampleCount,
        'botCollisionAvoidanceRadius': botCollisionAvoidanceRadius,
        'botCollisionAvoidanceWeight': botCollisionAvoidanceWeight,
        'botPeerSeparationRadius': botPeerSeparationRadius,
        'botPeerSeparationWeight': botPeerSeparationWeight,
        'botDroppedMassSenseRadius': botDroppedMassSenseRadius,
        'botDroppedMassClusterRadius': botDroppedMassClusterRadius,
        'botDroppedMassControlWeight': botDroppedMassControlWeight,
        'botDroppedMassGuardDistance': botDroppedMassGuardDistance,
        'botDroppedMassGuardRadius': botDroppedMassGuardRadius,
        'botRouteAvoidanceRadius': botRouteAvoidanceRadius,
        'botRouteAvoidanceWeight': botRouteAvoidanceWeight,
        'botDefensiveAvoidanceRadius': botDefensiveAvoidanceRadius,
        'botDefensiveAvoidanceWeight': botDefensiveAvoidanceWeight,
        'botAdaptiveLeadTime': botAdaptiveLeadTime,
        'botClosedLoopWeight': botClosedLoopWeight,
        'botCurvedRouteLeadTime': botCurvedRouteLeadTime,
        'botEvasionReplanDistance': botEvasionReplanDistance,
        'botScreenDistance': botScreenDistance,
        'botDenyDistance': botDenyDistance,
        'botGeometryPressureWeight': botGeometryPressureWeight,
        'botAttackAbortDistance': botAttackAbortDistance,
        'botAttackAbortSafety': botAttackAbortSafety,
        'botFormationCommitmentDuration': botFormationCommitmentDuration,
        'botFormationReplanDistance': botFormationReplanDistance,
        'botFormationSeparationDistance': botFormationSeparationDistance,
        'botFormationPressureWeight': botFormationPressureWeight,
        'botPeerHardAvoidanceRadius': botPeerHardAvoidanceRadius,
        'botPeerHardAvoidanceThreshold': botPeerHardAvoidanceThreshold,
        'botPeerAbortThreshold': botPeerAbortThreshold,
        'botAdaptiveMaximumLength': botAdaptiveMaximumLength,
        'botAdaptiveGrowthGap': botAdaptiveGrowthGap,
        'maxDroppedMass': maxDroppedMass,
        'droppedMassLifetime': droppedMassLifetime,
        'droppedMassMergeRadius': droppedMassMergeRadius,
        'botCatchUpDelay': botCatchUpDelay,
        'botCatchUpRate': botCatchUpRate,
        'botCatchUpTargetFraction': botCatchUpTargetFraction,
        'botTacticalDecisionInterval': botTacticalDecisionInterval,
        'botPlannerLookahead': botPlannerLookahead,
        'botRouteReservationDistance': botRouteReservationDistance,
        'movementTrailTrimSlackSegments': movementTrailTrimSlackSegments,
        'spatialBucketSize': spatialBucketSize,
        'busyPlanningLoadThreshold': busyPlanningLoadThreshold,
        'busyPlanningIntervalMultiplier': busyPlanningIntervalMultiplier,
        'simulationStep': simulationStep,
        'maxSimulationStepsPerUpdate': maxSimulationStepsPerUpdate,
        'bodyIndexStrideThreshold': bodyIndexStrideThreshold,
        'botManeuverStageDuration': botManeuverStageDuration,
        'botManeuverCommitDuration': botManeuverCommitDuration,
        'botManeuverRecoveryDuration': botManeuverRecoveryDuration,
        'botPlayerMemoryDecay': botPlayerMemoryDecay,
        'botReservationHorizon': botReservationHorizon,
        'botYieldSpeedMultiplier': botYieldSpeedMultiplier,
        'botHunterInitialCount': botHunterInitialCount,
        'botHunterMaximumCount': botHunterMaximumCount,
        'botHunterSecondPopulation': botHunterSecondPopulation,
        'botHunterReentryDistance': botHunterReentryDistance,
        'collisionCoreScale': collisionCoreScale,
        'collisionTailTaper': collisionTailTaper,
        'botParallelAlignmentThreshold': botParallelAlignmentThreshold,
        'botParallelClosingThreshold': botParallelClosingThreshold,
        'botOpportunitySenseRadius': botOpportunitySenseRadius,
        'botOpportunityResponderLimit': botOpportunityResponderLimit,
        'botOpportunityCommitmentDuration': botOpportunityCommitmentDuration,
        'botEnclosureGraceDuration': botEnclosureGraceDuration,
        'botEnclosureSampleLimit': botEnclosureSampleLimit,
        'botEnclosureMinimumSweep': botEnclosureMinimumSweep,
        'botHookMinimumSweepRatio': botHookMinimumSweepRatio,
        'botHookClosureRadiusMultiplier': botHookClosureRadiusMultiplier,
        'botTacticalPrecisionSafetyRadius': botTacticalPrecisionSafetyRadius,
        'botResourceFieldRadius': botResourceFieldRadius,
        'botResourceFieldMinimumValue': botResourceFieldMinimumValue,
        'botPlayerSprintRecoveryDuration': botPlayerSprintRecoveryDuration,
      };
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
  const _BotPlan({
    required this.intent,
    required this.mode,
    required this.allowSprint,
    required this.speedMultiplier,
    this.tacticalPrecision = false,
  });

  final Vec2 intent;
  final _BotPlanMode mode;
  final bool allowSprint;
  final double speedMultiplier;
  final bool tacticalPrecision;
}

class _BotRouteReservation {
  const _BotRouteReservation({
    required this.ownerId,
    required this.start,
    required this.startHeading,
    required this.intent,
    required this.speed,
    required this.turnRate,
    required this.radius,
    required this.duration,
    required this.sprinting,
  });

  final String ownerId;
  final Vec2 start;
  final Vec2 startHeading;
  final Vec2 intent;
  final double speed;
  final double turnRate;
  final double radius;
  final double duration;
  final bool sprinting;
}

enum _BotManeuverKind {
  laneExecution,
  counterCut,
  constrictor,
  baitAmbush,
  feintReversal,
  resourceDenial,
  roamingDuel,
}

enum _BotManeuverPhase { stage, wait, commit, execute, recover }

enum _BotHunterStyle {
  leadInterceptor,
  lateralHarrier,
  sprintBrakeTrap,
  patientConstrictor,
}

enum _TacticalOpportunityRole {
  outerConstrictor,
  gapStriker,
  exitCutter,
  innerSurvivor,
}

class _BotOpportunityCommitment {
  _BotOpportunityCommitment({
    required this.role,
    required this.subjectId,
    required this.remaining,
  });

  final _TacticalOpportunityRole role;
  final String subjectId;
  double remaining;
}

enum _ResourceControlRole { harvester, approachGuard, exitAmbusher }

class _ResourceField {
  _ResourceField({
    required this.center,
    required this.value,
    required this.radius,
    required this.memberCount,
    required this.droppedMemberCount,
  });

  Vec2 center;
  int value;
  double radius;
  int memberCount;
  int droppedMemberCount;

  void update({
    required Vec2 center,
    required int value,
    required double radius,
    required int memberCount,
    required int droppedMemberCount,
  }) {
    this.center = center;
    this.value = value;
    this.radius = radius;
    this.memberCount = memberCount;
    this.droppedMemberCount = droppedMemberCount;
  }
}

class _ResourceFieldBucket {
  _ResourceFieldBucket({required this.gridX, required this.gridY});

  final int gridX;
  final int gridY;
  int value = 0;
  int count = 0;
  int droppedCount = 0;
  double weightedX = 0;
  double weightedY = 0;

  void reset() {
    value = 0;
    count = 0;
    droppedCount = 0;
    weightedX = 0;
    weightedY = 0;
  }
}

class _TacticalOpportunitySnapshot {
  bool playerEnclosing = false;
  bool playerDevelopingHook = false;
  bool playerHarvesting = false;
  bool playerBoundaryPinned = false;
  bool playerSprintRecovering = false;
  bool playerInNarrowCorridor = false;
  Vec2 center = Vec2.zero;
  Vec2 gap = Vec2.zero;
  double radius = 0;
  double enclosureConfidence = 0;
  String? enclosedBotId;
  _ResourceField? resourceField;

  bool get active =>
      playerEnclosing ||
      playerDevelopingHook ||
      playerHarvesting ||
      playerBoundaryPinned ||
      playerSprintRecovering ||
      playerInNarrowCorridor;

  void reset() {
    playerEnclosing = false;
    playerDevelopingHook = false;
    playerHarvesting = false;
    playerBoundaryPinned = false;
    playerSprintRecovering = false;
    playerInNarrowCorridor = false;
    center = Vec2.zero;
    gap = Vec2.zero;
    radius = 0;
    enclosureConfidence = 0;
    enclosedBotId = null;
    resourceField = null;
  }
}

class _BotHunterState {
  _BotHunterState(this.style);

  final _BotHunterStyle style;
  double pressureSeconds = 0;
  int reacquisitionCount = 0;
}

class _BotManeuverState {
  _BotManeuverKind kind = _BotManeuverKind.roamingDuel;
  _BotManeuverPhase phase = _BotManeuverPhase.recover;
  double remaining = 0;
  double side = 1;
  int sequence = 0;
  int failedApproaches = 0;
  Vec2 anchor = Vec2.zero;
  Vec2 observedPlayerHeading = const Vec2(1, 0);
  Vec2 observedPlayerPosition = Vec2.zero;
}

class _BotManeuverPlan {
  const _BotManeuverPlan({
    required this.intent,
    required this.mode,
    required this.wantsSprint,
    required this.speedMultiplier,
  });

  final Vec2 intent;
  final _BotPlanMode mode;
  final bool wantsSprint;
  final double speedMultiplier;
}

class _PlayerBehaviorModel {
  double escapeSideBias = 0;
  double reversalTendency = 0;
  double sprintTendency = 0;
  double resourceAttraction = 0;
  double gapCamping = 0;
  double circularCommitment = 0;
  double sprintRecoveryRemaining = 0;
  double previousTurnSign = 0;
  bool previousSprinting = false;

  void reset() {
    escapeSideBias = 0;
    reversalTendency = 0;
    sprintTendency = 0;
    resourceAttraction = 0;
    gapCamping = 0;
    circularCommitment = 0;
    sprintRecoveryRemaining = 0;
    previousTurnSign = 0;
    previousSprinting = false;
  }
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
  const _BotPeerRisk({
    required this.escape,
    required this.urgency,
    this.rightOfWayOwnerId,
  });

  final Vec2 escape;
  final double urgency;
  final String? rightOfWayOwnerId;
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
  _DroppedMassCluster({
    required this.center,
    required this.value,
    required this.radius,
    required this.memberCount,
  });

  Vec2 center;
  int value;
  double radius;
  int memberCount;

  void update({
    required Vec2 center,
    required int value,
    required double radius,
    required int memberCount,
  }) {
    this.center = center;
    this.value = value;
    this.radius = radius;
    this.memberCount = memberCount;
  }
}

class _DroppedMassBucket {
  int value = 0;
  int count = 0;
  double weightedX = 0;
  double weightedY = 0;

  void reset() {
    value = 0;
    count = 0;
    weightedX = 0;
    weightedY = 0;
  }
}

class _BodySample {
  _BodySample({
    required this.owner,
    required this.index,
    required this.position,
  });

  SnakeState owner;
  int index;
  Vec2 position;

  void update(SnakeState owner, int index, Vec2 position) {
    this.owner = owner;
    this.index = index;
    this.position = position;
  }
}

class _MutableBodyPoint extends Vec2 {
  _MutableBodyPoint(double x, double y)
      : _x = x,
        _y = y,
        _previousX = x,
        _previousY = y,
        super(0, 0);

  double _x;
  double _y;
  double _previousX;
  double _previousY;
  bool _hasCoordinates = false;

  @override
  double get x => _x;

  @override
  double get y => _y;

  double get previousX => _previousX;

  double get previousY => _previousY;

  void setCoordinates(
    double x,
    double y, {
    bool preservePrevious = true,
  }) {
    if (preservePrevious && _hasCoordinates) {
      _previousX = _x;
      _previousY = _y;
    } else {
      _previousX = x;
      _previousY = y;
    }
    _x = x;
    _y = y;
    _hasCoordinates = true;
  }
}

class GameSimulation {
  GameSimulation({
    this.config = const SimulationConfig(),
    this.seed = 7,
    this.playerColorIndex = 0,
    this.captureSink,
  }) : _random = math.Random(seed) {
    reset();
  }

  final SimulationConfig config;
  final int seed;
  SimulationCaptureSink? captureSink;
  int playerColorIndex;
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
  final List<_DroppedMassCluster> _droppedMassClusterPool = [];
  final Map<int, _DroppedMassBucket> _droppedMassClusterBuckets = {};
  final List<_ResourceField> _resourceFields = [];
  final List<_ResourceField> _resourceFieldPool = [];
  final Map<int, _ResourceFieldBucket> _resourceFieldBuckets = {};
  final Map<int, List<int>> _droppedMassMergeBuckets = {};
  final List<FoodPellet> _droppedMassMergeOutput = [];
  final List<bool> _droppedMassMergeUsed = [];
  final Map<int, List<_BodySample>> _bodyBuckets = {};
  final Map<int, List<FoodPellet>> _pelletBuckets = {};
  final Map<int, List<FoodPellet>> _droppedMassBuckets = {};
  final List<_BodySample> _bodySamplePool = [];
  final List<_BodySample> _bodyQueryScratch = [];
  final List<FoodPellet> _foodQueryScratch = [];
  final Map<String, List<_MutableBodyPoint>> _bodyPointPools = {};
  final Map<String, _BotTacticState> _botTactics = {};
  final Map<String, _BotClosedLoopState> _botEngagementStates = {};
  final Map<String, _BotFormationRole> _botFormationRoles = {};
  final Map<String, _BotManeuverState> _botManeuvers = {};
  final Map<String, _BotHunterState> _botHunters = {};
  final Map<String, _TacticalOpportunityRole> _botOpportunityRoles = {};
  final Map<String, _BotOpportunityCommitment> _botOpportunityCommitments = {};
  final Map<String, _ResourceControlRole> _botResourceRoles = {};
  final Map<String, String> _botTacticalRejections = {};
  final Map<String, _BotPlan> _botPlans = {};
  final Map<String, double> _botSafetyHolds = {};
  final Map<String, Vec2> _botSafetyEscapes = {};
  final Map<String, String> _botYieldingTo = {};
  final List<_BotRouteReservation> _botRouteReservations = [];
  final _BotFormationState _botFormation = _BotFormationState();
  final _PlayerBehaviorModel _playerBehavior = _PlayerBehaviorModel();
  final _TacticalOpportunitySnapshot _opportunity =
      _TacticalOpportunitySnapshot();
  Vec2 _observedPlayerHeading = const Vec2(1, 0);
  double _observedPlayerTurnRate = 0;
  double elapsed = 0;
  double _pelletRefillAccumulator = 0;
  double _botPopulationAccumulator = 0;
  double _botTacticalDecisionRemaining = 0;
  double _enclosureGraceRemaining = 0;
  Vec2 _lastEnclosureCenter = Vec2.zero;
  Vec2 _lastEnclosureGap = Vec2.zero;
  double _lastEnclosureRadius = 0;
  double _lastEnclosureConfidence = 0;
  String? _lastEnclosedBotId;
  double _simulationAccumulator = 0;
  int _currentSimulationTick = 0;
  int simulationTick = 0;
  bool _isProcessingFixedStep = false;
  final Map<String, double> _capturedThreatUrgencies = {};
  final Map<String, ThreatSignal> _currentCaptureThreats = {};
  final Map<String, String> _capturedBotRoles = {};
  final Map<String, String> _capturedBotManeuvers = {};
  double _playerTurnCommitmentRemaining = 0;
  bool _playerTurnWasSharp = false;
  bool _playerTurnReplanPending = false;
  bool _droppedMassLimitDirty = false;
  int _bodySampleCount = 0;
  int lastFixedStepCount = 0;
  int lastSpatialIndexBuildCount = 0;
  int lastTacticalReplanCount = 0;
  int lastDroppedMassMergeCount = 0;
  int lastCrediblePlayerKillWindowCount = 0;
  int lastOpportunityAssessmentCount = 0;
  int botPeerCollisionDeaths = 0;
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

      final actorTowardPlayer = _alignment(
        actor.heading,
        player.head - actor.head,
      );
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

  String? botManeuverName(String botId) => _botManeuvers[botId]?.kind.name;

  String? botManeuverPhase(String botId) => _botManeuvers[botId]?.phase.name;

  double? botManeuverSide(String botId) => _botManeuvers[botId]?.side;

  bool botIsHunter(String botId) => _botHunters.containsKey(botId);

  String? botHunterStyle(String botId) => _botHunters[botId]?.style.name;

  double botHunterPressureSeconds(String botId) =>
      _botHunters[botId]?.pressureSeconds ?? 0;

  int botHunterReacquisitionCount(String botId) =>
      _botHunters[botId]?.reacquisitionCount ?? 0;

  int get activeHunterCount => snakes.where((snake) {
        return snake.kind == SnakeKind.bot &&
            snake.alive &&
            _botHunters.containsKey(snake.id);
      }).length;

  bool botPlanAllowsSprint(String botId) =>
      _botPlans[botId]?.allowSprint ?? false;

  String? botPlanMode(String botId) => _botPlans[botId]?.mode.name;

  String? botOpportunityRole(String botId) => _botOpportunityRoles[botId]?.name;

  double botOpportunityCommitmentRemaining(String botId) =>
      _botOpportunityCommitments[botId]?.remaining ?? 0;

  String? botResourceRole(String botId) => _botResourceRoles[botId]?.name;

  String? botYieldingTo(String botId) => _botYieldingTo[botId];

  String? botTacticalRejectionReason(String botId) =>
      _botTacticalRejections[botId];

  Vec2? botPlanIntent(String botId) => _botPlans[botId]?.intent;

  bool botPlanUsesTacticalPrecision(String botId) =>
      _botPlans[botId]?.tacticalPrecision ?? false;

  int get activeOpportunityResponderCount => _botOpportunityRoles.entries
      .where((entry) => entry.value != _TacticalOpportunityRole.innerSurvivor)
      .length;

  bool get playerEnclosureOpportunity => _opportunity.playerEnclosing;

  bool get playerDevelopingHookOpportunity => _opportunity.playerDevelopingHook;

  bool get playerResourceOpportunity => _opportunity.playerHarvesting;

  double get playerEnclosureConfidence => _opportunity.enclosureConfidence;

  String? get enclosedBotId => _opportunity.enclosedBotId;

  int get contestedResourceValue => _opportunity.resourceField?.value ?? 0;

  String get tacticalDiagnostics {
    final parts = <String>[];
    if (_opportunity.playerEnclosing) {
      parts.add(
        _opportunity.playerDevelopingHook
            ? 'HOOK DETECTED'
            : 'ENCLOSURE DETECTED',
      );
      parts.add('$activeOpportunityResponderCount COMMITTED');
    } else if (_opportunity.playerHarvesting && contestedResourceValue > 0) {
      parts.add('MASS $contestedResourceValue CONTESTED');
    }
    if (_botTacticalRejections.isNotEmpty) {
      parts.add('${_botTacticalRejections.length} ROUTE BLOCKED');
    }
    return parts.join('  ·  ');
  }

  double get observedPlayerEscapeSideBias => _playerBehavior.escapeSideBias;

  /// Blend between the last two fixed simulation states for smooth rendering.
  double get renderInterpolationAlpha {
    if (gameOver) return 1;
    return (_simulationAccumulator / math.max(0.001, config.simulationStep))
        .clamp(0.0, 1.0)
        .toDouble();
  }

  double renderBodyX(SnakeState snake, int index, double alpha) {
    if (index == 0) {
      return _interpolate(snake.previousHead.x, snake.head.x, alpha);
    }
    final point = snake.body[index];
    if (point is! _MutableBodyPoint) return point.x;
    return _interpolate(point.previousX, point.x, alpha);
  }

  double renderBodyY(SnakeState snake, int index, double alpha) {
    if (index == 0) {
      return _interpolate(snake.previousHead.y, snake.head.y, alpha);
    }
    final point = snake.body[index];
    if (point is! _MutableBodyPoint) return point.y;
    return _interpolate(point.previousY, point.y, alpha);
  }

  double _interpolate(double previous, double current, double alpha) =>
      previous + (current - previous) * alpha;

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
    for (final bucket in _droppedMassClusterBuckets.values) {
      bucket.reset();
    }
    _resourceFields.clear();
    for (final bucket in _resourceFieldBuckets.values) {
      bucket.reset();
    }
    for (final bucket in _droppedMassMergeBuckets.values) {
      bucket.clear();
    }
    for (final bucket in _bodyBuckets.values) {
      bucket.clear();
    }
    for (final bucket in _pelletBuckets.values) {
      bucket.clear();
    }
    for (final bucket in _droppedMassBuckets.values) {
      bucket.clear();
    }
    _botTactics.clear();
    _botEngagementStates.clear();
    _botFormationRoles.clear();
    _botManeuvers.clear();
    _botHunters.clear();
    _botOpportunityRoles.clear();
    _botOpportunityCommitments.clear();
    _botResourceRoles.clear();
    _botTacticalRejections.clear();
    _botPlans.clear();
    _botSafetyHolds.clear();
    _botSafetyEscapes.clear();
    _botYieldingTo.clear();
    _botRouteReservations.clear();
    _botFormation.remaining = 0;
    _botFormation.playerAnchor = null;
    _playerBehavior.reset();
    _opportunity.reset();
    _observedPlayerHeading = const Vec2(1, 0);
    _observedPlayerTurnRate = 0;
    elapsed = 0;
    _pelletRefillAccumulator = 0;
    _botPopulationAccumulator = 0;
    _botTacticalDecisionRemaining = 0;
    _enclosureGraceRemaining = 0;
    _lastEnclosureCenter = Vec2.zero;
    _lastEnclosureGap = Vec2.zero;
    _lastEnclosureRadius = 0;
    _lastEnclosureConfidence = 0;
    _lastEnclosedBotId = null;
    _simulationAccumulator = 0;
    _currentSimulationTick = 0;
    simulationTick = 0;
    _isProcessingFixedStep = false;
    _capturedThreatUrgencies.clear();
    _currentCaptureThreats.clear();
    _capturedBotRoles.clear();
    _capturedBotManeuvers.clear();
    _playerTurnCommitmentRemaining = 0;
    _playerTurnWasSharp = false;
    _playerTurnReplanPending = false;
    _droppedMassLimitDirty = false;
    _bodySampleCount = 0;
    lastFixedStepCount = 0;
    lastSpatialIndexBuildCount = 0;
    lastTacticalReplanCount = 0;
    lastDroppedMassMergeCount = 0;
    lastCrediblePlayerKillWindowCount = 0;
    lastOpportunityAssessmentCount = 0;
    botPeerCollisionDeaths = 0;
    score = 0;
    gameOver = false;
    gameOverReason = null;
    finalStats = null;

    snakes.add(
      SnakeState(
        id: 'player',
        kind: SnakeKind.player,
        position: Vec2.zero,
        colorIndex: playerColorIndex,
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
    lastFixedStepCount = 0;
    lastSpatialIndexBuildCount = 0;
    lastTacticalReplanCount = 0;
    lastDroppedMassMergeCount = 0;
    lastCrediblePlayerKillWindowCount = 0;
    lastOpportunityAssessmentCount = 0;
    if (gameOver) {
      _advanceCollisionPings(dt);
      _advanceTelegraphEvents(dt);
      return;
    }

    // Never replay an arbitrarily large delayed frame. The previous loop
    // consumed all accumulated wall time, so one bad frame caused a catch-up
    // spiral in which every following frame inherited the backlog. Movement
    // now runs on a bounded fixed-step budget; excess time is intentionally
    // discarded while short-lived presentation state still ages in real time.
    final boundedDt = dt.clamp(0.0, 0.5).toDouble();
    if (captureSink != null && dt > boundedDt) {
      _emitCaptureEvent(
        SimulationEventKind.elapsedTimeDiscarded,
        actorId: 'simulation',
        value: dt - boundedDt,
        detail: 'frameDeltaCap',
      );
    }
    final stepSize = math.max(0.001, config.simulationStep).toDouble();
    final maximumSteps =
        math.max(1, config.maxSimulationStepsPerUpdate).toInt();
    _simulationAccumulator += boundedDt;
    _advanceCollisionPings(dt);
    _advanceTelegraphEvents(dt);
    _advanceDroppedMass(dt);
    elapsed += dt;

    if (sprinting && canSprint) {
      _requestSprint(player);
    } else {
      _cancelSprintRequest(player);
    }

    var processedSteps = 0;
    while (_simulationAccumulator >= stepSize - 1e-9 &&
        processedSteps < maximumSteps &&
        !gameOver) {
      final step = stepSize;
      processedSteps++;
      lastFixedStepCount++;
      _simulationAccumulator -= step;
      simulationTick++;
      _currentSimulationTick = simulationTick;
      _isProcessingFixedStep = true;
      final normalizedSteering = steering.normalized();
      captureSink?.recordControl(
        SimulationControlSample(
          tick: simulationTick,
          steeringX: normalizedSteering.x,
          steeringY: normalizedSteering.y,
          sprintRequested: player.sprintRequested,
        ),
      );
      _advancePlayerSprint(step);
      _steerPlayer(steering, step);
      _observePlayerRoute(step);
      if (_botTacticalDecisionRemaining <= 0) {
        // Tests and debug tooling may reposition public body points directly;
        // refresh before a new plan so those edits cannot use stale buckets.
        _rebuildSpatialIndexes();
      }
      _steerBots(step);

      for (final snake in snakes.where((item) => item.alive)) {
        _moveSnake(snake, step);
      }
      _rebuildSpatialIndexes();
      for (final snake in snakes.where((item) => item.alive)) {
        _collectPellets(snake);
        _collectDroppedMass(snake);
      }
      _resolveCollisions();
      _refreshPublicTelegraphs();
      _advanceBotCatchUp(step);
      _advanceBotRespawns(step);
      _advanceBotPopulation(step);
      _maintainPelletDensity(step);
      if (captureSink != null) {
        _recordTacticalCaptureEvents();
        if (simulationTick % 6 == 0) _recordObservationCapture();
        captureSink?.completeStep(simulationTick);
      }
      _isProcessingFixedStep = false;
    }

    // Keep at most one fractional step. This is the anti-spiral boundary: a
    // stalled frame may lose simulation time, but it cannot turn into a long
    // burst of expensive work on the next frame.
    if (processedSteps >= maximumSteps &&
        _simulationAccumulator >= stepSize - 1e-9) {
      final discardedSeconds =
          _simulationAccumulator - (_simulationAccumulator % stepSize);
      if (captureSink != null && discardedSeconds > 0) {
        _emitCaptureEvent(
          SimulationEventKind.elapsedTimeDiscarded,
          actorId: 'simulation',
          value: discardedSeconds,
          detail: 'fixedStepBudget',
        );
      }
      _simulationAccumulator %= stepSize;
    }

    // No full-world remainder pass is allowed here. A late browser frame may
    // advance less authoritative simulation time than wall time, but it can
    // never turn one missed deadline into another multi-pass frame spike.
    _enforceDroppedMassLimit();
  }

  void abandon() {
    _emitCaptureEvent(
      SimulationEventKind.abandoned,
      actorId: player.id,
    );
  }

  void _emitCaptureEvent(
    SimulationEventKind kind, {
    required String actorId,
    String? targetId,
    double? value,
    String? detail,
    Map<String, Object?>? metadata,
  }) {
    captureSink?.recordEvent(
      SimulationEventSnapshot(
        tick: _isProcessingFixedStep
            ? _currentSimulationTick
            : _currentSimulationTick + 1,
        kind: kind,
        actorId: actorId,
        targetId: targetId,
        value: value,
        detail: detail,
        metadata: metadata,
      ),
    );
  }

  void _recordTacticalCaptureEvents() {
    final signals = player.alive ? playerThreats : const <ThreatSignal>[];
    _currentCaptureThreats
      ..clear()
      ..addEntries(signals.map((signal) => MapEntry(signal.actorId, signal)));
    final currentUrgencies = <String, double>{};
    for (final signal in signals) {
      currentUrgencies[signal.actorId] = signal.urgency;
      final previous = _capturedThreatUrgencies[signal.actorId];
      if (previous == null) {
        _emitCaptureEvent(
          SimulationEventKind.botPressureStarted,
          actorId: player.id,
          targetId: signal.actorId,
          value: signal.urgency,
        );
      } else if ((signal.urgency - previous).abs() >= 0.2) {
        _emitCaptureEvent(
          SimulationEventKind.botPressureEscalated,
          actorId: player.id,
          targetId: signal.actorId,
          value: signal.urgency,
          detail: signal.urgency > previous ? 'increased' : 'decreased',
        );
      }
    }
    for (final actorId in _capturedThreatUrgencies.keys.toList()) {
      if (!currentUrgencies.containsKey(actorId)) {
        _emitCaptureEvent(
          SimulationEventKind.botPressureEnded,
          actorId: player.id,
          targetId: actorId,
        );
      }
    }
    _capturedThreatUrgencies
      ..clear()
      ..addAll(currentUrgencies);

    for (final actor in snakes) {
      if (actor.kind != SnakeKind.bot) continue;
      final role = actor.publicIntent.name;
      final previousRole = _capturedBotRoles[actor.id];
      if (previousRole != null && previousRole != role) {
        _emitCaptureEvent(
          SimulationEventKind.botRoleChanged,
          actorId: actor.id,
          detail: role,
        );
      }
      _capturedBotRoles[actor.id] = role;

      final maneuver = _botManeuvers[actor.id];
      final maneuverState = maneuver == null
          ? 'none'
          : maneuver.kind.name + ':' + maneuver.phase.name;
      final previousManeuver = _capturedBotManeuvers[actor.id];
      if (previousManeuver != null && previousManeuver != maneuverState) {
        _emitCaptureEvent(
          SimulationEventKind.botManeuverChanged,
          actorId: actor.id,
          detail: maneuverState,
        );
      }
      _capturedBotManeuvers[actor.id] = maneuverState;
    }
  }

  void _recordObservationCapture() {
    final sink = captureSink;
    if (sink == null) return;
    final actorSnapshots = <SimulationActorSnapshot>[];
    for (final actor in snakes) {
      if (!actor.alive) continue;
      final maneuver = actor.kind == SnakeKind.bot ? _botManeuvers[actor.id] : null;
      actorSnapshots.add(
        SimulationActorSnapshot(
          actorId: actor.id,
          role: actor.kind.name,
          positionX: actor.head.x,
          positionY: actor.head.y,
          headingX: actor.heading.x,
          headingY: actor.heading.y,
          length: actor.length,
          sprintRequested: actor.sprintRequested,
          sprinting: actor.sprinting,
          intent: actor.publicIntent.name,
          maneuver: maneuver?.kind.name,
          maneuverPhase: maneuver?.phase.name,
        ),
      );
    }
    final nearbyNaturalFood = _nearbyFood(
      player.head,
      config.threatRadius,
      _pelletBuckets,
    ).length;
    final nearbyDroppedMass = _nearbyFood(
      player.head,
      config.threatRadius,
      _droppedMassBuckets,
    ).length;
    final warningBuffer = config.arenaBoundaryWarningBuffer;
    final boundaryRisk = warningBuffer <= 0
        ? 0.0
        : ((player.head.length -
                    (config.arenaRadius - warningBuffer) +
                    player.radius) /
                warningBuffer)
            .clamp(0.0, 1.0)
            .toDouble();
    final threatSignals = _currentCaptureThreats.values.toList()
      ..sort((left, right) => right.urgency.compareTo(left.urgency));
    sink.recordObservation(
      SimulationObservationSnapshot(
        tick: simulationTick,
        elapsedSeconds: simulationTick * config.simulationStep,
        playerPositionX: player.head.x,
        playerPositionY: player.head.y,
        playerHeadingX: player.heading.x,
        playerHeadingY: player.heading.y,
        playerLength: player.length,
        playerSprinting: player.sprinting,
        nearestThreatDistance:
            threatSignals.isEmpty ? null : threatSignals.first.distance,
        nearbyThreatCount: threatSignals.length,
        nearbyNaturalFoodCount: nearbyNaturalFood,
        nearbyDroppedMassCount: nearbyDroppedMass,
        boundaryRisk: boundaryRisk,
        actors: actorSnapshots,
      ),
    );
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
    _emitCaptureEvent(
      SimulationEventKind.sprintRequested,
      actorId: actor.id,
    );
    _recordTelegraphEvent(actor, TelegraphEventKind.sprintAnticipation);
  }

  void _cancelSprintRequest(SnakeState actor) {
    final wasAnticipating =
        actor.sprintRequested || actor.sprintAnticipationRemaining > 0;
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
      if (wasAnticipating) {
        _emitCaptureEvent(
          SimulationEventKind.sprintEnded,
          actorId: actor.id,
          detail: 'cancelledBeforeStart',
        );
      }
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
    if (actor.sprintAnticipationRemaining > 1e-9) return;
    actor.sprintAnticipationRemaining = 0;

    actor.sprinting = true;
    actor.sprintPulseRemaining = config.sprintPulseDuration;
    _recordTelegraphEvent(actor, TelegraphEventKind.sprintStarted);
  }

  void _observePlayerRoute(double dt) {
    final previousHeading = _observedPlayerHeading;
    final currentHeading = player.heading;
    final turn = _shortestAngle(currentHeading.angle - previousHeading.angle);
    final instantaneousTurnRate = dt <= 0 ? 0.0 : turn / dt;
    _observedPlayerTurnRate = (_observedPlayerTurnRate * 0.65 +
            instantaneousTurnRate.clamp(-8.0, 8.0).toDouble() * 0.35)
        .clamp(-8.0, 8.0)
        .toDouble();
    _playerTurnCommitmentRemaining =
        math.max(0, _playerTurnCommitmentRemaining - dt).toDouble();
    final sharpTurn = instantaneousTurnRate.abs() >= 1.2;
    if (sharpTurn && !_playerTurnWasSharp) {
      _playerTurnCommitmentRemaining = 0.18;
      _playerTurnReplanPending = true;
      for (final bot in snakes.where(
        (snake) => snake.kind == SnakeKind.bot && snake.alive,
      )) {
        if (botIsHunter(bot.id)) {
          _reacquireHunter(bot);
        } else {
          _interruptBotPursuit(bot);
        }
        final side = Vec2(-currentHeading.y, currentHeading.x) *
            (bot.id.hashCode.isEven ? 1.0 : -1.0);
        bot.heading = (bot.heading * 0.82 + side * 0.18).normalized();
      }
    }
    _playerTurnWasSharp = sharpTurn;
    _observedPlayerHeading = currentHeading;
  }

  int _spatialKey(int x, int y) => x * 1000003 + y;

  int _spatialCoordinate(double value) =>
      (value / math.max(1.0, config.spatialBucketSize)).floor();

  void _rebuildSpatialIndexes() {
    lastSpatialIndexBuildCount++;
    _bodySampleCount = 0;
    for (final bucket in _bodyBuckets.values) {
      bucket.clear();
    }
    for (final bucket in _pelletBuckets.values) {
      bucket.clear();
    }
    for (final bucket in _droppedMassBuckets.values) {
      bucket.clear();
    }

    for (final snake in snakes.where((item) => item.alive)) {
      final stride =
          snake.body.length > config.bodyIndexStrideThreshold ? 2 : 1;
      for (var index = 0; index < snake.body.length; index += stride) {
        final position = snake.body[index];
        final key = _spatialKey(
          _spatialCoordinate(position.x),
          _spatialCoordinate(position.y),
        );
        final bucket = _bodyBuckets[key] ??= <_BodySample>[];
        bucket.add(_claimBodySample(snake, index, position));
      }
      final lastIndex = snake.body.length - 1;
      if (stride > 1 && lastIndex >= 0 && lastIndex.isOdd) {
        final position = snake.body[lastIndex];
        final key = _spatialKey(
          _spatialCoordinate(position.x),
          _spatialCoordinate(position.y),
        );
        final bucket = _bodyBuckets[key] ??= <_BodySample>[];
        bucket.add(_claimBodySample(snake, lastIndex, position));
      }
    }

    _indexFood(pellets, _pelletBuckets);
    _indexFood(droppedMass, _droppedMassBuckets);
  }

  _BodySample _claimBodySample(
    SnakeState owner,
    int index,
    Vec2 position,
  ) {
    if (_bodySampleCount == _bodySamplePool.length) {
      _bodySamplePool.add(
        _BodySample(owner: owner, index: index, position: position),
      );
    } else {
      _bodySamplePool[_bodySampleCount].update(owner, index, position);
    }
    return _bodySamplePool[_bodySampleCount++];
  }

  void _indexFood(List<FoodPellet> source, Map<int, List<FoodPellet>> index) {
    for (final pellet in source) {
      final key = _spatialKey(
        _spatialCoordinate(pellet.position.x),
        _spatialCoordinate(pellet.position.y),
      );
      final bucket = index[key] ??= <FoodPellet>[];
      bucket.add(pellet);
    }
  }

  List<FoodPellet> _nearbyFood(
    Vec2 position,
    double radius,
    Map<int, List<FoodPellet>> index,
  ) {
    if (index.isEmpty) return const <FoodPellet>[];
    final bucketSize = math.max(1.0, config.spatialBucketSize);
    final minimumX = ((position.x - radius) / bucketSize).floor();
    final maximumX = ((position.x + radius) / bucketSize).floor();
    final minimumY = ((position.y - radius) / bucketSize).floor();
    final maximumY = ((position.y + radius) / bucketSize).floor();
    final result = _foodQueryScratch..clear();
    for (var x = minimumX; x <= maximumX; x++) {
      for (var y = minimumY; y <= maximumY; y++) {
        final bucket = index[_spatialKey(x, y)];
        if (bucket != null) result.addAll(bucket);
      }
    }
    return result;
  }

  List<_BodySample> _nearbyBodySamples(Vec2 position, double radius) {
    if (_bodyBuckets.isEmpty) return const <_BodySample>[];
    // Long-body indexes sample every second segment. Expanding the bucket
    // query by one spacing preserves the collision safety margin around the
    // omitted midpoint while keeping the index itself bounded.
    radius += config.segmentSpacing;
    final bucketSize = math.max(1.0, config.spatialBucketSize);
    final minimumX = ((position.x - radius) / bucketSize).floor();
    final maximumX = ((position.x + radius) / bucketSize).floor();
    final minimumY = ((position.y - radius) / bucketSize).floor();
    final maximumY = ((position.y + radius) / bucketSize).floor();
    final result = _bodyQueryScratch..clear();
    for (var x = minimumX; x <= maximumX; x++) {
      for (var y = minimumY; y <= maximumY; y++) {
        final bucket = _bodyBuckets[_spatialKey(x, y)];
        if (bucket != null) result.addAll(bucket);
      }
    }
    return result;
  }

  void _steerBots(double dt) {
    _advanceBotDecisionClocks(dt);
    for (final bot in snakes.where(
      (snake) => snake.kind == SnakeKind.bot && snake.alive,
    )) {
      _advanceBotSprint(bot, dt);
    }

    _botTacticalDecisionRemaining -= dt;
    if (_playerTurnReplanPending) {
      _botTacticalDecisionRemaining = 0;
    }
    if (_botTacticalDecisionRemaining <= 0) {
      _botTacticalDecisionRemaining = _botPlanningInterval();
      _replanBotPlans(dt);
      _playerTurnReplanPending = false;
    }

    for (final bot in snakes.where(
      (snake) => snake.kind == SnakeKind.bot && snake.alive,
    )) {
      final plan = _botPlans[bot.id];
      if (plan == null) continue;
      final emergencyAvoidance = _immediateBotAvoidance(bot);
      if ((plan.mode == _BotPlanMode.evadePeer ||
              plan.mode == _BotPlanMode.evadePlayer) &&
          (bot.sprinting || bot.sprintRequested)) {
        _interruptBotPursuit(bot);
      }
      final speedTarget = emergencyAvoidance.length > 0
          ? config.botYieldSpeedMultiplier
          : plan.speedMultiplier;
      final speedSmoothing = (dt * 8).clamp(0.0, 1.0).toDouble();
      bot.tacticalSpeedMultiplier +=
          (speedTarget - bot.tacticalSpeedMultiplier) * speedSmoothing;
      bot.tacticalSpeedMultiplier = bot.tacticalSpeedMultiplier
          .clamp(config.botYieldSpeedMultiplier, 1.0)
          .toDouble();
      if (emergencyAvoidance.length > 0) {
        _holdBotSafety(bot, emergencyAvoidance);
        if (bot.sprinting || bot.sprintRequested) {
          _interruptBotPursuit(bot);
        }
        _turnBotToward(bot, emergencyAvoidance, dt);
      } else {
        _turnBotToward(bot, plan.intent, dt);
      }
    }
  }

  void _advanceBotDecisionClocks(double dt) {
    _botFormation.remaining =
        math.max(0, _botFormation.remaining - dt).toDouble();
    _enclosureGraceRemaining =
        math.max(0, _enclosureGraceRemaining - dt).toDouble();
    for (final commitment in _botOpportunityCommitments.values) {
      commitment.remaining = math.max(0, commitment.remaining - dt).toDouble();
    }
    for (final state in _botTactics.values) {
      state.remaining = math.max(0, state.remaining - dt).toDouble();
    }
    for (final state in _botEngagementStates.values) {
      state.remaining = math.max(0, state.remaining - dt).toDouble();
      state.evasionCooldown =
          math.max(0, state.evasionCooldown - dt).toDouble();
    }
    for (final state in _botManeuvers.values) {
      state.remaining = math.max(0, state.remaining - dt).toDouble();
    }
    if (player.alive) {
      for (final entry in _botHunters.entries) {
        final plan = _botPlans[entry.key];
        if (plan?.mode == _BotPlanMode.attack) {
          entry.value.pressureSeconds += dt;
        }
      }
    }
    for (final id in _botSafetyHolds.keys.toList()) {
      if (_botYieldingTo.containsKey(id)) continue;
      final remaining = (_botSafetyHolds[id] ?? 0) - dt;
      if (remaining <= 0) {
        _botSafetyHolds.remove(id);
        _botSafetyEscapes.remove(id);
      } else {
        _botSafetyHolds[id] = remaining;
      }
    }
    _updatePlayerBehavior(dt);
  }

  void _reacquireHunter(SnakeState bot) {
    if (bot.sprinting || bot.sprintRequested) {
      _cancelSprintRequest(bot);
    }
    final hunter = _botHunters[bot.id];
    if (hunter == null) return;
    hunter.reacquisitionCount++;
    final maneuver = _botManeuvers.putIfAbsent(
      bot.id,
      _BotManeuverState.new,
    );
    maneuver.failedApproaches++;
    maneuver.side *= -1;
    maneuver.phase = _BotManeuverPhase.stage;
    maneuver.remaining = math
        .min(config.botManeuverStageDuration, 0.2)
        .clamp(0.0, double.infinity)
        .toDouble();
    maneuver.anchor = _playerRoutePoint(0.55);
    maneuver.observedPlayerHeading = player.heading;
    maneuver.observedPlayerPosition = player.head;
    final engagement = _botEngagementStates.putIfAbsent(
      bot.id,
      _BotClosedLoopState.new,
    );
    engagement.mode = _BotEngagementMode.replan;
    engagement.remaining = 0;
    engagement.expectedPlayerPosition = _playerRoutePoint(0.45);
    final tactic = _botTactics.putIfAbsent(bot.id, _BotTacticState.new);
    tactic.mode = _BotTactic.cutoff;
    tactic.remaining = 0;
    bot.movementCommitment = math.min(bot.movementCommitment, 0.55).toDouble();
  }

  void _updatePlayerBehavior(double dt) {
    final decayBase = config.botPlayerMemoryDecay.clamp(0.05, 0.999);
    final decay = math.pow(decayBase, dt).toDouble();
    _playerBehavior.escapeSideBias *= decay;
    _playerBehavior.reversalTendency *= decay;
    _playerBehavior.sprintTendency *= decay;
    _playerBehavior.resourceAttraction *= decay;
    _playerBehavior.gapCamping *= decay;
    _playerBehavior.circularCommitment *= decay;
    _playerBehavior.sprintRecoveryRemaining =
        math.max(0, _playerBehavior.sprintRecoveryRemaining - dt).toDouble();

    final turnSign = _observedPlayerTurnRate.abs() < 0.35
        ? 0.0
        : _observedPlayerTurnRate.sign;
    if (turnSign != 0) {
      _playerBehavior.escapeSideBias =
          (_playerBehavior.escapeSideBias + turnSign * dt * 1.8)
              .clamp(-1.0, 1.0)
              .toDouble();
      if (_playerBehavior.previousTurnSign != 0 &&
          turnSign != _playerBehavior.previousTurnSign) {
        _playerBehavior.reversalTendency =
            (_playerBehavior.reversalTendency + 0.16)
                .clamp(0.0, 1.0)
                .toDouble();
      }
      _playerBehavior.previousTurnSign = turnSign;
    }

    final playerSprintActive = player.sprinting || player.sprintRequested;
    if (playerSprintActive) {
      _playerBehavior.sprintTendency =
          (_playerBehavior.sprintTendency + dt * 1.4)
              .clamp(0.0, 1.0)
              .toDouble();
    }
    if (!playerSprintActive && _playerBehavior.previousSprinting) {
      _playerBehavior.sprintRecoveryRemaining =
          config.botPlayerSprintRecoveryDuration;
    }
    _playerBehavior.previousSprinting = playerSprintActive;

    for (final cluster in _droppedMassClusters) {
      final toCluster = cluster.center - player.head;
      if (toCluster.length <= config.botDroppedMassGuardRadius &&
          _alignment(player.heading, toCluster) >= 0.25) {
        _playerBehavior.resourceAttraction =
            (_playerBehavior.resourceAttraction + dt * 1.6)
                .clamp(0.0, 1.0)
                .toDouble();
        break;
      }
    }

    for (final bot in snakes.where(
      (snake) => snake.kind == SnakeKind.bot && snake.alive,
    )) {
      if (bot.body.length < 3 ||
          bot.head.distanceTo(player.head) > config.botEngagementRadius) {
        continue;
      }
      final tail = bot.body.last;
      final gapMidpoint = (bot.head + tail) * 0.5;
      final gapRadius =
          math.max(90.0, bot.head.distanceTo(tail) * 0.38).toDouble();
      if (player.head.distanceTo(gapMidpoint) <= gapRadius) {
        _playerBehavior.gapCamping =
            (_playerBehavior.gapCamping + dt * 1.8).clamp(0.0, 1.0).toDouble();
        break;
      }
    }
  }

  Vec2 _immediateBotAvoidance(SnakeState bot) {
    final speed = _effectiveSpeed(bot);
    if (speed <= 0 || _bodyBuckets.isEmpty) return Vec2.zero;
    final lookahead = math.min(0.28, config.botCollisionLookahead).toDouble();
    final future = bot.head + bot.heading * (speed * lookahead);
    final radius = math
        .max(
          bot.radius * 2 + config.segmentSpacing,
          config.botPeerHardAvoidanceRadius * 0.42,
        )
        .toDouble();
    var escape = Vec2.zero;
    var maximumUrgency = 0.0;
    for (final sample in _nearbyBodySamples(future, radius)) {
      if (sample.owner.id == bot.id ||
          !sample.owner.alive ||
          sample.index < 1) {
        continue;
      }
      final projectedSegment = _projectBodySample(sample, lookahead);
      final offset = future - projectedSegment;
      final distance = offset.length;
      if (distance >= radius) continue;
      final motionThreat = _relativeMotionThreat(
        bot,
        sample.owner,
        actorPosition: future,
        otherPosition: projectedSegment,
        separation: distance,
      );
      if (motionThreat <= 0) continue;
      final urgency = (((radius - distance) / radius) * motionThreat)
          .clamp(0.0, 1.0)
          .toDouble();
      if (urgency <= maximumUrgency) continue;
      maximumUrgency = urgency;
      final side = Vec2(-bot.heading.y, bot.heading.x) *
          (bot.id.compareTo(sample.owner.id) <= 0 ? 1.0 : -1.0);
      final away = distance == 0 ? side : offset.normalized();
      escape = (away * 0.35 + side * 0.95).normalized();
    }
    final responseThreshold =
        (0.2 / _threatWeight(bot)).clamp(0.1, 0.24).toDouble();
    return maximumUrgency >= responseThreshold ? escape : Vec2.zero;
  }

  double _botPlanningInterval() {
    final bodyLoad = snakes.fold<int>(
      0,
      (total, snake) => total + (snake.alive ? snake.body.length : 0),
    );
    final worldLoad = bodyLoad + pellets.length + droppedMass.length;
    final busyMultiplier = worldLoad <= config.busyPlanningLoadThreshold
        ? 1.0
        : config.busyPlanningIntervalMultiplier.clamp(1.0, 4.0).toDouble();
    return math
        .max(0.04, config.botTacticalDecisionInterval * busyMultiplier)
        .toDouble();
  }

  void _replanBotPlans(double dt) {
    lastTacticalReplanCount++;
    _rebuildDroppedMassClusters();
    _rebuildResourceFields();
    _assessTacticalOpportunities();
    _refreshBotFormation();
    _botPlans.clear();
    _botRouteReservations.clear();
    _botTacticalRejections.clear();
    final planningBots = snakes
        .where((snake) => snake.kind == SnakeKind.bot && snake.alive)
        .toList()
      ..sort((left, right) {
        final leftPriority = _botPlanningPriority(left);
        final rightPriority = _botPlanningPriority(right);
        final order = rightPriority.compareTo(leftPriority);
        return order == 0 ? left.id.compareTo(right.id) : order;
      });

    for (final bot in planningBots) {
      _advanceBotTactic(bot);
      if (!bot.retreating && bot.length >= config.botRetreatLength) {
        bot.retreating = true;
      }
      final trappedCounterplay = _botOpportunityRoles[bot.id] ==
          _TacticalOpportunityRole.innerSurvivor;
      if (_shouldPrioritizeRetreat(bot) && !trappedCounterplay) {
        if (_botOpportunityRoles.containsKey(bot.id) ||
            _botResourceRoles.containsKey(bot.id)) {
          _botTacticalRejections[bot.id] = 'retreating';
        }
        final plan = _commitBotPlan(
          bot,
          _retreatDirection(bot),
          _BotPlanMode.retreat,
          wantsSprint: true,
          speedMultiplier: 1,
        );
        _decideBotSprint(bot, plan: plan, maneuverRequestsSprint: true);
        _recheckCommittedBotPlan(bot);
        continue;
      }

      final priorityManeuver = _priorityOpportunityPlan(bot);
      if (priorityManeuver != null) {
        final requestedMode = priorityManeuver.mode;
        final tacticalPrecision = _botOpportunityRoles.containsKey(bot.id);
        final plan = _commitBotPlan(
          bot,
          priorityManeuver.intent,
          requestedMode,
          wantsSprint: priorityManeuver.wantsSprint,
          speedMultiplier: priorityManeuver.speedMultiplier,
          tacticalPrecision: tacticalPrecision,
        );
        if (plan.mode == requestedMode) {
          _botYieldingTo.remove(bot.id);
          _botSafetyHolds.remove(bot.id);
          _botSafetyEscapes.remove(bot.id);
        } else {
          _botTacticalRejections[bot.id] = 'unsafe route';
        }
        _decideBotSprint(
          bot,
          plan: plan,
          maneuverRequestsSprint: priorityManeuver.wantsSprint,
        );
        _recheckCommittedBotPlan(bot);
        final finalPlan = _botPlans[bot.id] ?? plan;
        if (finalPlan.mode != requestedMode) {
          _botTacticalRejections[bot.id] = 'route changed';
        } else if (finalPlan.mode == _BotPlanMode.attack &&
            _createsCrediblePlayerKillWindow(bot, finalPlan)) {
          lastCrediblePlayerKillWindowCount++;
        }
        continue;
      }

      final boundary = _boundaryAvoidance(bot);
      final peerRisk = _botPeerRouteRisk(bot);
      final routeRisk = _playerRouteRisk(bot);
      final routeAbortThreshold =
          (config.botAttackAbortSafety + 0.14).clamp(0.42, 0.58).toDouble();
      final rightOfWayOwner = _botYieldingTo[bot.id];
      if (rightOfWayOwner != null) {
        if (_yieldCorridorStillBlocked(bot, rightOfWayOwner)) {
          final escape = peerRisk.escape.length == 0
              ? _botSafetyEscapes[bot.id] ?? _peerYieldFallback(bot)
              : peerRisk.escape;
          _holdBotSafety(
            bot,
            escape,
            yieldingTo: rightOfWayOwner,
          );
          _interruptBotPursuit(bot);
          _commitBotPlan(
            bot,
            escape,
            _BotPlanMode.evadePeer,
            wantsSprint: false,
            speedMultiplier: config.botYieldSpeedMultiplier,
          );
          continue;
        }
        _botYieldingTo.remove(bot.id);
        _botSafetyHolds.remove(bot.id);
        _botSafetyEscapes.remove(bot.id);
      }
      final safetyHold = _botSafetyHolds[bot.id] ?? 0;
      if (safetyHold > 0) {
        final escape = peerRisk.urgency >= 0.1
            ? peerRisk.escape
            : routeRisk.urgency >= 0.1
                ? routeRisk.escape
                : _botSafetyEscapes[bot.id] ?? bot.heading;
        _interruptBotPursuit(bot);
        _commitBotPlan(
          bot,
          escape,
          peerRisk.urgency >= routeRisk.urgency
              ? _BotPlanMode.evadePeer
              : _BotPlanMode.evadePlayer,
          wantsSprint: false,
          speedMultiplier: config.botYieldSpeedMultiplier,
        );
        continue;
      }
      if (peerRisk.urgency >= config.botPeerHardAvoidanceThreshold) {
        _holdBotSafety(
          bot,
          peerRisk.escape,
          yieldingTo: peerRisk.rightOfWayOwnerId,
        );
        _interruptBotPursuit(bot);
        _commitBotPlan(
          bot,
          peerRisk.escape,
          _BotPlanMode.evadePeer,
          wantsSprint: false,
          speedMultiplier: config.botYieldSpeedMultiplier,
        );
        continue;
      }
      if (routeRisk.urgency >= routeAbortThreshold) {
        _holdBotSafety(bot, routeRisk.escape);
        _interruptBotPursuit(bot);
        _commitBotPlan(
          bot,
          routeRisk.escape,
          _BotPlanMode.evadePlayer,
          wantsSprint: false,
          speedMultiplier: config.botYieldSpeedMultiplier,
        );
        continue;
      }
      final boundaryThreshold =
          (0.9 / _boundaryWeight(bot)).clamp(0.55, 0.95).toDouble();
      if (boundary.length >= boundaryThreshold) {
        _commitBotPlan(
          bot,
          boundary,
          _BotPlanMode.evadePlayer,
          wantsSprint: false,
          speedMultiplier: config.botYieldSpeedMultiplier,
        );
        continue;
      }

      final maneuver = _maneuverPlan(bot);
      final plan = _commitBotPlan(
        bot,
        maneuver.intent,
        maneuver.mode,
        wantsSprint: maneuver.wantsSprint,
        speedMultiplier: maneuver.speedMultiplier,
      );
      _decideBotSprint(
        bot,
        plan: plan,
        maneuverRequestsSprint: maneuver.wantsSprint,
      );
      _recheckCommittedBotPlan(bot);
      final finalPlan = _botPlans[bot.id] ?? plan;
      if (finalPlan.mode == _BotPlanMode.attack &&
          _createsCrediblePlayerKillWindow(bot, finalPlan)) {
        lastCrediblePlayerKillWindowCount++;
      }
    }
  }

  _BotManeuverPlan? _priorityOpportunityPlan(SnakeState bot) {
    final state = _ensureBotManeuver(bot);
    return _tacticalOpportunityPlan(bot, state) ??
        _resourceControlPlan(bot, state) ??
        _hunterHookGuardPlan(bot, state);
  }

  void _holdBotSafety(
    SnakeState bot,
    Vec2 escape, {
    String? yieldingTo,
  }) {
    _botSafetyHolds[bot.id] = 0.55;
    if (yieldingTo != null) {
      _botYieldingTo[bot.id] = yieldingTo;
    }
    bot.tacticalSpeedMultiplier = math
        .min(bot.tacticalSpeedMultiplier, config.botYieldSpeedMultiplier)
        .toDouble();
    if (escape.length > 0) {
      _botSafetyEscapes[bot.id] = escape.normalized();
    }
  }

  Vec2 _peerYieldFallback(SnakeState bot) {
    final side = Vec2(-bot.heading.y, bot.heading.x) *
        (bot.id.hashCode.isEven ? 1.0 : -1.0);
    return (bot.heading * 0.25 + side).normalized();
  }

  bool _yieldCorridorStillBlocked(SnakeState bot, String ownerId) {
    SnakeState? owner;
    for (final candidate in snakes) {
      if (candidate.id == ownerId && candidate.alive) {
        owner = candidate;
        break;
      }
    }
    if (owner == null) return false;
    final ownerPlan = _botPlans[owner.id];
    final ownerIntent = ownerPlan?.intent ?? owner.heading;
    final botSpeed =
        math.max(_effectiveSpeed(bot), bot.speed * 0.55).toDouble();
    final ownerSpeed =
        math.max(_effectiveSpeed(owner), owner.speed * 0.55).toDouble();
    final horizon = math.max(0.4, config.botReservationHorizon).toDouble();
    final samples = math.max(3, config.botCollisionSampleCount).toInt();
    final clearance = math.max(
      config.botPeerHardAvoidanceRadius * 0.72,
      bot.radius + owner.radius + 30,
    );
    for (var index = 1; index <= samples; index++) {
      final time = horizon * index / samples;
      final botPoint = _projectBotRoutePoint(
        bot,
        bot.heading,
        time,
        speed: botSpeed,
      );
      final ownerPoint = _projectBotRoutePoint(
        owner,
        ownerIntent,
        time,
        speed: ownerSpeed,
      );
      if (botPoint.distanceTo(ownerPoint) < clearance) return true;
      for (final sample in _nearbyBodySamples(
        botPoint,
        clearance + ownerSpeed * time,
      )) {
        if (sample.owner.id != owner.id || sample.index < 2) continue;
        if (botPoint.distanceTo(_projectBodySample(sample, time)) < clearance) {
          return true;
        }
      }
    }
    return false;
  }

  bool _createsCrediblePlayerKillWindow(SnakeState bot, _BotPlan plan) {
    if (!player.alive || plan.intent.length == 0) return false;
    const horizon = 0.72;
    const samples = 5;
    final botSpeed = bot.speed *
        plan.speedMultiplier *
        (plan.allowSprint ? config.botSprintMultiplier : 1.0);
    final collisionWindow = bot.radius + player.radius + 46;
    for (var index = 1; index <= samples; index++) {
      final time = horizon * index / samples;
      final botPoint = _projectBotRoutePoint(
        bot,
        plan.intent,
        time,
        speed: botSpeed,
      );
      final playerPoint = _playerRoutePoint(time);
      if (botPoint.distanceTo(playerPoint) <= collisionWindow) return true;
    }
    return false;
  }

  double _botPlanningPriority(SnakeState bot) {
    final distance = player.alive ? bot.head.distanceTo(player.head) : 10000;
    final sizePressure = bot.length >= player.length ? 1.5 : 1.0;
    final disposition =
        bot.disposition == BotDisposition.aggressive ? 1.4 : 1.0;
    final hunter = botIsHunter(bot.id) ? 2.5 : 1.0;
    final opportunity = _botOpportunityRoles.containsKey(bot.id)
        ? 2.2
        : _playerBehavior.circularCommitment >= 0.45
            ? 1.12
            : 1.0;
    return sizePressure *
        disposition *
        hunter *
        opportunity *
        (1 + config.botEngagementRadius / math.max(1.0, distance));
  }

  _BotPlan _commitBotPlan(
    SnakeState bot,
    Vec2 intent,
    _BotPlanMode mode, {
    required bool wantsSprint,
    required double speedMultiplier,
    bool tacticalPrecision = false,
  }) {
    final requested = intent.length == 0 ? bot.heading : intent.normalized();
    final deconflicted = _deconflictBotIntent(bot, requested);
    final sprintViable = wantsSprint &&
        bot.botSprintCooldownRemaining <= 0 &&
        bot.length > config.botSprintMinimumLength;
    final safety = _finalRouteSafety(
      bot,
      deconflicted,
      speedMultiplier: speedMultiplier,
      sprinting: sprintViable,
      tacticalPrecision: tacticalPrecision,
    );
    final unsafe = safety.risk >= 0.62;
    final finalIntent = unsafe ? safety.escape : deconflicted;
    final finalMode =
        unsafe && mode != _BotPlanMode.retreat ? _BotPlanMode.evadePeer : mode;
    final allowSprint = wantsSprint && !unsafe;
    final finalSpeedMultiplier = unsafe
        ? config.botYieldSpeedMultiplier
        : speedMultiplier.clamp(config.botYieldSpeedMultiplier, 1.0).toDouble();
    final plan = _BotPlan(
      intent: finalIntent,
      mode: finalMode,
      allowSprint: allowSprint,
      speedMultiplier: finalSpeedMultiplier,
      tacticalPrecision: tacticalPrecision && !unsafe,
    );
    _botPlans[bot.id] = plan;
    _reserveBotPlan(bot, plan);
    return plan;
  }

  void _reserveBotPlan(SnakeState bot, _BotPlan plan) {
    _botRouteReservations.removeWhere(
      (reservation) => reservation.ownerId == bot.id,
    );
    final finalIntent = plan.intent;
    if (finalIntent.length > 0) {
      final projectedSpeed = math.max(1.0, bot.speed * plan.speedMultiplier) *
          (plan.allowSprint ? config.botSprintMultiplier : 1.0);
      final duration = math.max(0.2, config.botReservationHorizon).toDouble();
      _botRouteReservations.add(
        _BotRouteReservation(
          ownerId: bot.id,
          start: bot.head,
          startHeading: bot.heading,
          intent: finalIntent.normalized(),
          speed: projectedSpeed,
          turnRate: config.botTurnRate * bot.tacticalTurnRateMultiplier,
          radius: config.botRouteReservationDistance,
          duration: duration,
          sprinting: plan.allowSprint,
        ),
      );
    }
  }

  void _recheckCommittedBotPlan(SnakeState bot) {
    final plan = _botPlans[bot.id];
    if (plan == null) return;
    final sprinting = bot.sprinting || bot.sprintRequested || plan.allowSprint;
    final routeSpeed = math.max(1.0, bot.speed * plan.speedMultiplier) *
        (sprinting ? config.botSprintMultiplier : 1.0);
    final horizon = math.max(0.2, config.botReservationHorizon).toDouble();
    final committedTarget = _projectBotRoutePoint(
      bot,
      plan.intent,
      horizon,
      speed: routeSpeed,
    );
    final committedRisk = _engagementLaneRisk(
      bot,
      committedTarget,
      intendedDirection: plan.intent,
      speedOverride: routeSpeed,
      includePeerBodies: true,
      tacticalPrecision: plan.tacticalPrecision,
    );
    if (committedRisk < 0.62) {
      _reserveBotPlan(bot, plan);
      return;
    }
    final safety = _finalRouteSafety(
      bot,
      plan.intent,
      speedMultiplier: plan.speedMultiplier,
      sprinting: sprinting,
      tacticalPrecision: plan.tacticalPrecision,
    );
    if (bot.sprinting || bot.sprintRequested) {
      _cancelSprintRequest(bot);
    }
    final safePlan = _BotPlan(
      intent: safety.escape,
      mode: _BotPlanMode.evadePeer,
      allowSprint: false,
      speedMultiplier: config.botYieldSpeedMultiplier,
    );
    _botPlans[bot.id] = safePlan;
    _reserveBotPlan(bot, safePlan);
  }

  ({double risk, Vec2 escape}) _finalRouteSafety(
    SnakeState bot,
    Vec2 intended, {
    required double speedMultiplier,
    required bool sprinting,
    bool tacticalPrecision = false,
  }) {
    if (intended.length == 0) return (risk: 1.0, escape: bot.heading);
    final direction = intended.normalized();
    final horizon = math.max(0.2, config.botReservationHorizon).toDouble();
    final routeSpeed = math.max(1.0, bot.speed * speedMultiplier) *
        (sprinting ? config.botSprintMultiplier : 1.0);
    final target = _projectBotRoutePoint(
      bot,
      direction,
      horizon,
      speed: routeSpeed,
    );
    var bestIntent = direction;
    var bestRisk = _engagementLaneRisk(
      bot,
      target,
      intendedDirection: direction,
      speedOverride: routeSpeed,
      includePeerBodies: true,
      tacticalPrecision: tacticalPrecision,
    );
    final side = Vec2(-direction.y, direction.x);
    final predictive = _predictiveCollisionAvoidance(bot);
    final peerSeparation = _peerSeparation(bot);
    final candidates = <Vec2>[
      (direction * 0.72 + side * 0.7).normalized(),
      (direction * 0.72 - side * 0.7).normalized(),
      if (predictive.length > 0) predictive,
      if (peerSeparation.length > 0) peerSeparation,
      side,
      side * -1,
      direction * -1,
    ];
    for (var index = 0; index < candidates.length; index++) {
      final candidate = candidates[index];
      final risk = _engagementLaneRisk(
        bot,
        _projectBotRoutePoint(
          bot,
          candidate,
          horizon * (index < 2 ? 1.0 : 0.72),
          speed: routeSpeed,
        ),
        intendedDirection: candidate,
        speedOverride: routeSpeed,
        tacticalPrecision: tacticalPrecision,
      );
      final preferencePenalty = index < 2 ? 0.03 : 0.1 + index * 0.025;
      if (risk + preferencePenalty < bestRisk) {
        bestRisk = risk;
        bestIntent = candidate;
      }
    }
    return (risk: bestRisk, escape: bestIntent);
  }

  Vec2 _deconflictBotIntent(SnakeState bot, Vec2 intent) {
    if (intent.length == 0 || _botRouteReservations.isEmpty) {
      return intent;
    }
    var result = intent.normalized();
    for (final reservation in _botRouteReservations) {
      final projectedEnd = _projectBotRoutePoint(
        bot,
        result,
        config.botPlannerLookahead,
      );
      if (!_routeCorridorsConflict(bot, result, reservation)) {
        continue;
      }
      final reservationEnd = _projectTurningPoint(
        start: reservation.start,
        heading: reservation.startHeading,
        intended: reservation.intent,
        speed: reservation.speed,
        turnRate: reservation.turnRate,
        time: math.min(config.botPlannerLookahead, reservation.duration),
      );
      final axis = projectedEnd - reservationEnd;
      SnakeState? owner;
      for (final candidate in snakes) {
        if (candidate.kind == SnakeKind.bot &&
            candidate.alive &&
            candidate.id == reservation.ownerId) {
          owner = candidate;
          break;
        }
      }
      final separation = axis.length == 0
          ? owner == null
              ? Vec2(-result.y, result.x)
              : _peerYieldSide(bot, owner)
          : axis.normalized();
      result = (result * 0.35 + separation * 1.15).normalized();
      if (_routeCorridorsConflict(bot, result, reservation)) {
        _botYieldingTo[bot.id] = reservation.ownerId;
      } else if (_botYieldingTo[bot.id] == reservation.ownerId) {
        _botYieldingTo.remove(bot.id);
      }
    }
    return result;
  }

  bool _routeCorridorsConflict(
    SnakeState bot,
    Vec2 intended,
    _BotRouteReservation reservation,
  ) {
    const samples = 6;
    final minimum = math
            .max(config.botRouteReservationDistance, reservation.radius)
            .toDouble() *
        (reservation.sprinting ? 1.12 : 1.0);
    final sharedHorizon = math
        .min(config.botReservationHorizon, reservation.duration)
        .clamp(0.01, double.infinity)
        .toDouble();
    final ownDirection = intended.normalized();
    final otherDirection = reservation.intent.normalized();
    final ownRouteEnd = _projectBotRoutePoint(
      bot,
      ownDirection,
      sharedHorizon,
    );
    final otherRouteEnd = _projectTurningPoint(
      start: reservation.start,
      heading: reservation.startHeading,
      intended: reservation.intent,
      speed: reservation.speed,
      turnRate: reservation.turnRate,
      time: sharedHorizon,
    );
    final ownTravel = ownRouteEnd - bot.head;
    final otherTravel = otherRouteEnd - reservation.start;
    final ownRouteDirection =
        ownTravel.length == 0 ? ownDirection : ownTravel.normalized();
    final otherRouteDirection =
        otherTravel.length == 0 ? otherDirection : otherTravel.normalized();
    final startOffset = reservation.start - bot.head;
    final ownSpeed =
        math.max(_effectiveSpeed(bot), bot.speed * 0.55).toDouble();
    final otherSpeed = reservation.speed;
    final relativeVelocity =
        ownRouteDirection * ownSpeed - otherRouteDirection * otherSpeed;
    final closingRatio = startOffset.length == 0
        ? 1.0
        : ((relativeVelocity.x * startOffset.normalized().x +
                    relativeVelocity.y * startOffset.normalized().y) /
                math.max(1.0, ownSpeed + otherSpeed))
            .clamp(0.0, 1.0)
            .toDouble();
    final parallel = _alignment(ownRouteDirection, otherRouteDirection) >=
        config.botParallelAlignmentThreshold;
    final lethalCore =
        20 * config.collisionCoreScale.clamp(0.0, 1.0).toDouble();
    final tightParallel = _alignment(ownRouteDirection, otherRouteDirection) >=
        math.max(config.botParallelAlignmentThreshold, 0.96);
    if (tightParallel) {
      final lateralSeparation = (startOffset.x * ownRouteDirection.y -
              startOffset.y * ownRouteDirection.x)
          .abs();
      if (lateralSeparation >= lethalCore) return false;
    }
    if (parallel &&
        closingRatio <= config.botParallelClosingThreshold &&
        startOffset.length >= lethalCore) {
      return false;
    }
    for (var index = 0; index <= samples; index++) {
      final time = sharedHorizon * index / samples;
      final point = _projectBotRoutePoint(
        bot,
        ownDirection,
        time,
        speed: ownSpeed,
      );
      final otherPoint = _projectTurningPoint(
        start: reservation.start,
        heading: reservation.startHeading,
        intended: reservation.intent,
        speed: reservation.speed,
        turnRate: reservation.turnRate,
        time: time,
      );
      if (point.distanceTo(otherPoint) < minimum) return true;
    }
    return false;
  }

  Vec2 _projectBotRoutePoint(
    SnakeState bot,
    Vec2 intended,
    double time, {
    double? speed,
  }) {
    return _projectTurningPoint(
      start: bot.head,
      heading: bot.heading,
      intended: intended,
      speed: speed ?? _effectiveSpeed(bot),
      turnRate: config.botTurnRate * bot.tacticalTurnRateMultiplier,
      time: time,
    );
  }

  Vec2 _projectTurningPoint({
    required Vec2 start,
    required Vec2 heading,
    required Vec2 intended,
    required double speed,
    required double turnRate,
    required double time,
  }) {
    if (time <= 0 || speed <= 0) return start;
    final desired = intended.length == 0 ? heading : intended.normalized();
    final startAngle = heading.angle;
    final turn = _shortestAngle(desired.angle - startAngle);
    final boundedRate = math.max(0.001, turnRate.abs()).toDouble();
    if (turn.abs() <= 0.001 || turnRate <= 0) {
      return start + heading.normalized() * (speed * time);
    }
    final turnDuration = turn.abs() / boundedRate;
    final arcTime = math.min(time, turnDuration).toDouble();
    final angularVelocity = turn.sign * boundedRate;
    final arcEndAngle = startAngle + angularVelocity * arcTime;
    final arc = Vec2(
      speed * (math.sin(arcEndAngle) - math.sin(startAngle)) / angularVelocity,
      speed * (-math.cos(arcEndAngle) + math.cos(startAngle)) / angularVelocity,
    );
    if (time <= turnDuration) return start + arc;
    return start + arc + desired * (speed * (time - turnDuration));
  }

  Vec2 _projectTurningDirection({
    required Vec2 heading,
    required Vec2 intended,
    required double turnRate,
    required double time,
  }) {
    final start = heading.length == 0 ? const Vec2(1, 0) : heading.normalized();
    final desired = intended.length == 0 ? start : intended.normalized();
    if (time <= 0 || turnRate <= 0) return start;
    final turn = _shortestAngle(desired.angle - start.angle);
    if (turn.abs() <= 0.001) return desired;
    final applied = math.min(turn.abs(), turnRate.abs() * time) * turn.sign;
    final angle = start.angle + applied;
    return Vec2(math.cos(angle), math.sin(angle));
  }

  Vec2 _projectBodySample(_BodySample sample, double time) {
    final owner = sample.owner;
    if (time <= 0 || owner.body.isEmpty) return sample.position;
    final speed = _effectiveSpeed(owner);
    if (speed <= 0) return sample.position;
    final spacing = math.max(1.0, owner.segmentSpacing).toDouble();
    final sourceIndex = sample.index - speed * time / spacing;
    if (sourceIndex <= 0) {
      final headLead =
          math.max(0.0, time - sample.index * spacing / speed).toDouble();
      if (owner.kind == SnakeKind.player) return _playerRoutePoint(headLead);
      final plan = _botPlans[owner.id];
      final intent = plan?.intent ?? owner.heading;
      final projectedSpeed = owner.speed *
          (plan?.speedMultiplier ?? owner.tacticalSpeedMultiplier) *
          ((owner.sprinting || owner.sprintRequested)
              ? config.botSprintMultiplier
              : 1.0);
      return _projectBotRoutePoint(
        owner,
        intent,
        headLead,
        speed: projectedSpeed,
      );
    }
    final lower = sourceIndex.floor().clamp(0, owner.body.length - 1).toInt();
    final upper = math.min(lower + 1, owner.body.length - 1).toInt();
    final fraction = (sourceIndex - lower).clamp(0.0, 1.0).toDouble();
    return owner.body[lower] * (1 - fraction) + owner.body[upper] * fraction;
  }

  void _rebuildResourceFields() {
    _resourceFields.clear();
    for (final bucket in _resourceFieldBuckets.values) {
      bucket.reset();
    }
    final bucketSize = math.max(40.0, config.botResourceFieldRadius);

    void addFood(FoodPellet pellet, bool dropped) {
      final x = (pellet.position.x / bucketSize).floor();
      final y = (pellet.position.y / bucketSize).floor();
      final bucket = _resourceFieldBuckets[_spatialKey(x, y)] ??=
          _ResourceFieldBucket(gridX: x, gridY: y);
      final value = math.max(1, pellet.value).toInt();
      bucket.value += value;
      bucket.count++;
      if (dropped) bucket.droppedCount++;
      bucket.weightedX += pellet.position.x * value;
      bucket.weightedY += pellet.position.y * value;
    }

    for (final pellet in pellets) {
      addFood(pellet, false);
    }
    for (final pellet in droppedMass) {
      addFood(pellet, true);
    }

    for (final seed in _resourceFieldBuckets.values) {
      if (seed.count == 0) continue;
      final seedCenter = Vec2(
        seed.weightedX / seed.value,
        seed.weightedY / seed.value,
      );
      var value = 0;
      var count = 0;
      var droppedCount = 0;
      var weightedX = 0.0;
      var weightedY = 0.0;
      var localMaximum = true;
      for (var offsetX = -1; offsetX <= 1; offsetX++) {
        for (var offsetY = -1; offsetY <= 1; offsetY++) {
          final neighbor = _resourceFieldBuckets[
              _spatialKey(seed.gridX + offsetX, seed.gridY + offsetY)];
          if (neighbor == null || neighbor.count == 0) continue;
          final neighborCenter = Vec2(
            neighbor.weightedX / neighbor.value,
            neighbor.weightedY / neighbor.value,
          );
          if (seedCenter.distanceTo(neighborCenter) > bucketSize) continue;
          localMaximum = localMaximum && neighbor.value <= seed.value;
          value += neighbor.value;
          count += neighbor.count;
          droppedCount += neighbor.droppedCount;
          weightedX += neighbor.weightedX;
          weightedY += neighbor.weightedY;
        }
      }
      if (!localMaximum ||
          value < config.botResourceFieldMinimumValue ||
          count < 2) {
        continue;
      }
      final center = Vec2(
        weightedX / value,
        weightedY / value,
      );
      final radius = (42 + math.sqrt(count) * 18)
          .clamp(42.0, config.botResourceFieldRadius)
          .toDouble();
      final index = _resourceFields.length;
      if (index < _resourceFieldPool.length) {
        final field = _resourceFieldPool[index];
        field.update(
          center: center,
          value: value,
          radius: radius,
          memberCount: count,
          droppedMemberCount: droppedCount,
        );
        _resourceFields.add(field);
      } else {
        final field = _ResourceField(
          center: center,
          value: value,
          radius: radius,
          memberCount: count,
          droppedMemberCount: droppedCount,
        );
        _resourceFieldPool.add(field);
        _resourceFields.add(field);
      }
    }
  }

  void _assessTacticalOpportunities() {
    lastOpportunityAssessmentCount++;
    _opportunity.reset();
    if (!player.alive) return;

    _assessPlayerEnclosure();
    if (_opportunity.playerEnclosing) {
      _enclosureGraceRemaining = config.botEnclosureGraceDuration;
      _lastEnclosureCenter = _opportunity.center;
      _lastEnclosureGap = _opportunity.gap;
      _lastEnclosureRadius = _opportunity.radius;
      _lastEnclosureConfidence = _opportunity.enclosureConfidence;
      _lastEnclosedBotId = _opportunity.enclosedBotId;
    } else if (_enclosureGraceRemaining > 0 &&
        _lastEnclosedBotId != null &&
        snakes.any((snake) => snake.id == _lastEnclosedBotId && snake.alive)) {
      _opportunity.playerEnclosing = true;
      _opportunity.playerDevelopingHook = true;
      _opportunity.center = _lastEnclosureCenter;
      _opportunity.gap = player.body.isEmpty
          ? _lastEnclosureGap
          : (player.body.first + player.body.last) * 0.5;
      _opportunity.radius = _lastEnclosureRadius;
      _opportunity.enclosureConfidence =
          (_lastEnclosureConfidence * 0.92).clamp(0.0, 1.0).toDouble();
      _opportunity.enclosedBotId = _lastEnclosedBotId;
    }
    final resource = _bestContestedResourceField();
    if (resource != null) {
      _opportunity.resourceField = resource;
      _opportunity.playerHarvesting = true;
      if (!_opportunity.playerEnclosing) {
        _opportunity.center = resource.center;
        _opportunity.radius = resource.radius;
      }
    }

    final boundaryDistance = player.head.length;
    final boundaryThreshold =
        config.arenaRadius - config.arenaBoundaryWarningBuffer * 0.72;
    if (boundaryDistance >= boundaryThreshold && boundaryDistance > 0) {
      final outward = player.head.normalized();
      _opportunity.playerBoundaryPinned =
          _alignment(player.heading, outward) >= -0.1;
    }
    _opportunity.playerSprintRecovering =
        _playerBehavior.sprintRecoveryRemaining > 0;
    _opportunity.playerInNarrowCorridor = _playerInNarrowBodyCorridor();
    if (!_opportunity.playerEnclosing && resource == null) {
      _opportunity.center = player.head;
      _opportunity.radius = player.radius + 80;
      _opportunity.gap = _playerRoutePoint(0.35);
    }
  }

  void _assessPlayerEnclosure() {
    final body = player.body;
    final sampleLimit = math.max(8, config.botEnclosureSampleLimit).toInt();
    if (body.length < 10 || sampleLimit <= 0) return;
    final stride = math.max(1, (body.length / sampleLimit).ceil()).toInt();
    var centerX = 0.0;
    var centerY = 0.0;
    var count = 0;
    for (var index = 0; index < body.length; index += stride) {
      centerX += body[index].x;
      centerY += body[index].y;
      count++;
    }
    if ((body.length - 1) % stride != 0) {
      centerX += body.last.x;
      centerY += body.last.y;
      count++;
    }
    if (count < 4) return;
    final center = Vec2(centerX / count, centerY / count);

    var radiusTotal = 0.0;
    var radiusMaximum = 0.0;
    var sweep = 0.0;
    double? previousAngle;
    for (var index = 0; index < body.length; index += stride) {
      final offset = body[index] - center;
      final radius = offset.length;
      radiusTotal += radius;
      radiusMaximum = math.max(radiusMaximum, radius).toDouble();
      final angle = offset.angle;
      if (previousAngle != null) {
        sweep += _shortestAngle(angle - previousAngle).abs();
      }
      previousAngle = angle;
    }
    final averageRadius = radiusTotal / math.max(1, count);
    if (averageRadius < 48 || radiusMaximum < 60) return;
    final closureGap = body.first.distanceTo(body.last);
    final committedClosureLimit =
        math.max(120.0, averageRadius * 1.05).toDouble();
    final hookClosureLimit = math
        .max(
          150.0,
          averageRadius *
              config.botHookClosureRadiusMultiplier.clamp(1.05, 2.4),
        )
        .toDouble();
    final hookMinimumSweep = config.botEnclosureMinimumSweep *
        config.botHookMinimumSweepRatio.clamp(0.55, 1.0);
    final sweepScore = (sweep / math.max(0.1, config.botEnclosureMinimumSweep))
        .clamp(0.0, 1.0)
        .toDouble();
    final closureScore =
        (1 - closureGap / hookClosureLimit).clamp(0.0, 1.0).toDouble();
    final confidence = sweepScore * 0.62 + closureScore * 0.38;
    _playerBehavior.circularCommitment = math
        .max(_playerBehavior.circularCommitment, confidence)
        .clamp(0.0, 1.0)
        .toDouble();
    if (sweep < hookMinimumSweep ||
        closureGap > hookClosureLimit ||
        confidence < 0.5) {
      return;
    }

    SnakeState? enclosed;
    var enclosedDistance = double.infinity;
    final innerRadius = averageRadius * 0.82;
    for (final bot in snakes.where(
      (snake) => snake.kind == SnakeKind.bot && snake.alive,
    )) {
      final distance = bot.head.distanceTo(center);
      if (distance <= innerRadius && distance < enclosedDistance) {
        enclosed = bot;
        enclosedDistance = distance;
      }
    }
    if (enclosed == null) return;

    _opportunity.playerEnclosing = true;
    _opportunity.playerDevelopingHook =
        sweep < config.botEnclosureMinimumSweep ||
            closureGap > committedClosureLimit ||
            confidence < 0.58;
    _opportunity.center = center;
    _opportunity.gap = (body.first + body.last) * 0.5;
    _opportunity.radius = radiusMaximum + player.radius;
    _opportunity.enclosureConfidence = confidence;
    _opportunity.enclosedBotId = enclosed.id;
  }

  _ResourceField? _bestContestedResourceField() {
    _ResourceField? best;
    var bestScore = 0.0;
    for (final field in _resourceFields) {
      final distance = player.head.distanceTo(field.center);
      if (distance > config.botOpportunitySenseRadius) continue;
      final direction = field.center - player.head;
      final approaching = direction.length == 0 ||
          _alignment(player.heading, direction) >= 0.08;
      final occupying = distance <= field.radius + 90;
      if (!approaching && !occupying) continue;
      final density = field.memberCount / math.max(1.0, field.radius / 40);
      final droppedBonus = field.droppedMemberCount > 0 ? 1.35 : 1.0;
      final score = (field.value + density * 1.8) *
          droppedBonus /
          math.max(90.0, distance);
      if (score > bestScore) {
        bestScore = score;
        best = field;
      }
    }
    return best;
  }

  bool _playerInNarrowBodyCorridor() {
    final radius = math.min(240.0, config.botOpportunitySenseRadius).toDouble();
    var leftDistance = double.infinity;
    var rightDistance = double.infinity;
    for (final sample in _nearbyBodySamples(player.head, radius)) {
      if (!sample.owner.alive ||
          sample.owner.id == player.id ||
          sample.index < 2) {
        continue;
      }
      final offset = sample.position - player.head;
      final distance = offset.length;
      if (distance <= 0 || distance > radius) continue;
      final cross = player.heading.x * offset.y - player.heading.y * offset.x;
      if (cross >= 0) {
        leftDistance = math.min(leftDistance, distance).toDouble();
      } else {
        rightDistance = math.min(rightDistance, distance).toDouble();
      }
    }
    return leftDistance < 175 && rightDistance < 175;
  }

  void _assignTacticalOpportunityRoles(List<SnakeState> active) {
    _botOpportunityRoles.clear();
    _botResourceRoles.clear();
    final livingIds = snakes
        .where((snake) => snake.kind == SnakeKind.bot && snake.alive)
        .map((snake) => snake.id)
        .toSet();
    final enclosedId = _opportunity.enclosedBotId;
    _botOpportunityCommitments.removeWhere(
      (id, commitment) =>
          !livingIds.contains(id) ||
          commitment.remaining <= 0 ||
          !_opportunity.playerEnclosing ||
          enclosedId == null ||
          commitment.subjectId != enclosedId,
    );
    if (!_opportunity.active) return;

    if (_opportunity.playerEnclosing && enclosedId != null) {
      _botOpportunityCommitments[enclosedId] = _BotOpportunityCommitment(
        role: _TacticalOpportunityRole.innerSurvivor,
        subjectId: enclosedId,
        remaining: config.botOpportunityCommitmentDuration,
      );
      for (final commitment in _botOpportunityCommitments.values) {
        if (commitment.subjectId == enclosedId) {
          commitment.remaining = math
              .max(
                commitment.remaining,
                config.botOpportunityCommitmentDuration,
              )
              .toDouble();
        }
      }
      _botOpportunityRoles.addEntries(
        _botOpportunityCommitments.entries.map(
          (entry) => MapEntry(entry.key, entry.value.role),
        ),
      );
    }
    final field = _opportunity.resourceField;
    final highValueResource = field != null &&
        field.value >= math.max(8, config.botResourceFieldMinimumValue * 2);
    final recruitTacticalResponders = _opportunity.playerEnclosing ||
        (!highValueResource &&
            (_opportunity.playerBoundaryPinned ||
                _opportunity.playerSprintRecovering ||
                _opportunity.playerInNarrowCorridor));
    final candidates = active
        .where(
          (bot) =>
              bot.id != enclosedId &&
              !_botOpportunityRoles.containsKey(bot.id) &&
              bot.head.distanceTo(_opportunity.center) <=
                  config.botOpportunitySenseRadius,
        )
        .toList()
      ..sort((left, right) {
        final dispositionOrder = _opportunityDispositionPriority(left)
            .compareTo(_opportunityDispositionPriority(right));
        if (dispositionOrder != 0) return dispositionOrder;
        final leftArrival = left.head.distanceTo(_opportunity.center) /
            math.max(1.0, _effectiveSpeed(left));
        final rightArrival = right.head.distanceTo(_opportunity.center) /
            math.max(1.0, _effectiveSpeed(right));
        final arrivalOrder = leftArrival.compareTo(rightArrival);
        return arrivalOrder == 0 ? left.id.compareTo(right.id) : arrivalOrder;
      });
    final externalCommitments = _botOpportunityRoles.entries
        .where((entry) => entry.value != _TacticalOpportunityRole.innerSurvivor)
        .length;
    final availableResponderSlots = recruitTacticalResponders
        ? math.max(0, config.botOpportunityResponderLimit - externalCommitments)
        : 0;
    final responderCount =
        math.min(availableResponderSlots, candidates.length).toInt();
    for (var index = 0; index < responderCount; index++) {
      final bot = candidates[index];
      final _TacticalOpportunityRole role;
      if (_opportunity.playerEnclosing) {
        final hasOuterConstrictor = _botOpportunityRoles.containsValue(
          _TacticalOpportunityRole.outerConstrictor,
        );
        role = !hasOuterConstrictor
            ? _TacticalOpportunityRole.outerConstrictor
            : bot.disposition == BotDisposition.aggressive
                ? _TacticalOpportunityRole.exitCutter
                : _TacticalOpportunityRole.gapStriker;
        _botOpportunityCommitments[bot.id] = _BotOpportunityCommitment(
          role: role,
          subjectId: enclosedId!,
          remaining: config.botOpportunityCommitmentDuration,
        );
      } else {
        role = index == 0
            ? _TacticalOpportunityRole.exitCutter
            : _TacticalOpportunityRole.gapStriker;
      }
      _botOpportunityRoles[bot.id] = role;
    }

    if (field == null) return;
    final resourceCandidates = active
        .where(
          (bot) =>
              !_botOpportunityRoles.containsKey(bot.id) &&
              bot.head.distanceTo(field.center) <=
                  config.botOpportunitySenseRadius,
        )
        .toList()
      ..sort((left, right) {
        final leftArrival = left.head.distanceTo(field.center) /
            math.max(1.0, _effectiveSpeed(left));
        final rightArrival = right.head.distanceTo(field.center) /
            math.max(1.0, _effectiveSpeed(right));
        final order = leftArrival.compareTo(rightArrival);
        return order == 0 ? left.id.compareTo(right.id) : order;
      });
    const roles = <_ResourceControlRole>[
      _ResourceControlRole.harvester,
      _ResourceControlRole.approachGuard,
      _ResourceControlRole.exitAmbusher,
    ];
    for (var index = 0;
        index < math.min(roles.length, resourceCandidates.length);
        index++) {
      _botResourceRoles[resourceCandidates[index].id] = roles[index];
    }
  }

  int _opportunityDispositionPriority(SnakeState bot) {
    return switch (bot.disposition) {
      BotDisposition.aggressive => 0,
      BotDisposition.opportunistic => 1,
      BotDisposition.defensive => 2,
      BotDisposition.wanderer => 3,
    };
  }

  void _refreshBotFormation() {
    final active = snakes
        .where(
          (snake) =>
              snake.kind == SnakeKind.bot &&
              snake.alive &&
              !_shouldPrioritizeRetreat(snake),
        )
        .toList();
    if (!player.alive) {
      _botFormationRoles.clear();
      _botHunters.clear();
      _botOpportunityRoles.clear();
      _botOpportunityCommitments.clear();
      _botResourceRoles.clear();
      _botTacticalRejections.clear();
      _botFormation.playerAnchor = null;
      _botFormation.remaining = 0;
      return;
    }
    if (active.isEmpty) {
      _botFormationRoles.clear();
      _botHunters.clear();
      _assignTacticalOpportunityRoles(active);
      _botFormation.playerAnchor = player.head;
      _botFormation.remaining = 0;
      return;
    }
    _refreshHunterAssignments(active);
    _assignTacticalOpportunityRoles(active);

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
        final hunterOrder = (botIsHunter(left.id) ? 0 : 1)
            .compareTo(botIsHunter(right.id) ? 0 : 1);
        if (hunterOrder != 0) return hunterOrder;
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
        active.map((bot) => MapEntry(bot.id, _BotFormationRole.reserve)),
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

  void _refreshHunterAssignments(List<SnakeState> active) {
    final maximum = math.max(0, config.botHunterMaximumCount).toInt();
    var desired = math.max(0, config.botHunterInitialCount).toInt();
    if (active.length >= config.botHunterSecondPopulation) {
      desired = math.max(desired, 2).toInt();
    }
    desired = math.min(active.length, math.min(maximum, desired)).toInt();
    if (desired <= 0) {
      _botHunters.clear();
      return;
    }

    final candidates = active.toList()
      ..sort((left, right) {
        final persistenceOrder = (_botHunters.containsKey(left.id) ? 0 : 1)
            .compareTo(_botHunters.containsKey(right.id) ? 0 : 1);
        if (persistenceOrder != 0) return persistenceOrder;
        final dispositionOrder = _hunterDispositionPriority(left)
            .compareTo(_hunterDispositionPriority(right));
        if (dispositionOrder != 0) return dispositionOrder;
        final distanceOrder = left.head
            .distanceTo(player.head)
            .compareTo(right.head.distanceTo(player.head));
        return distanceOrder == 0 ? left.id.compareTo(right.id) : distanceOrder;
      });
    final selected = <String>{
      for (var index = 0; index < desired; index++) candidates[index].id,
    };
    _botHunters.removeWhere((id, _) => !selected.contains(id));
    for (var index = 0; index < desired; index++) {
      final bot = candidates[index];
      _botHunters.putIfAbsent(
        bot.id,
        () => _BotHunterState(_hunterStyleFor(bot, index)),
      );
    }
  }

  int _hunterDispositionPriority(SnakeState bot) {
    return switch (bot.disposition) {
      BotDisposition.aggressive => 0,
      BotDisposition.opportunistic => 1,
      BotDisposition.wanderer => 2,
      BotDisposition.defensive => 3,
    };
  }

  _BotHunterStyle _hunterStyleFor(SnakeState bot, int slot) {
    const styles = <_BotHunterStyle>[
      _BotHunterStyle.leadInterceptor,
      _BotHunterStyle.lateralHarrier,
      _BotHunterStyle.sprintBrakeTrap,
      _BotHunterStyle.patientConstrictor,
    ];
    final index = (bot.colorIndex + slot - 2).abs() % styles.length;
    return styles[index];
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

  _BotEngagementMode _closedLoopEngagement(SnakeState bot) {
    final state = _botEngagementStates.putIfAbsent(
      bot.id,
      _BotClosedLoopState.new,
    );
    final previousTarget = state.expectedPlayerPosition;
    final playerTurned = _observedPlayerTurnRate.abs() >= 0.75;
    final departedLane = previousTarget != null &&
        _alignment(player.heading, previousTarget - player.head) < 0.2 &&
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
        (botIsHunter(bot.id) ||
            bot.head.distanceTo(player.head) <= config.botEngagementRadius)) {
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

  Vec2 _closedLoopIntent(SnakeState bot, _BotEngagementMode mode) {
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

  _BotManeuverState _ensureBotManeuver(SnakeState bot) {
    final state = _botManeuvers.putIfAbsent(bot.id, _BotManeuverState.new);
    final committed = state.phase == _BotManeuverPhase.commit ||
        state.phase == _BotManeuverPhase.execute;
    final playerEscaped = committed &&
        (_alignment(state.observedPlayerHeading, player.heading) < 0.45 ||
            (player.head.distanceTo(state.observedPlayerPosition) >=
                    config.botEvasionReplanDistance &&
                _alignment(
                      player.heading,
                      player.head - state.observedPlayerPosition,
                    ) <
                    0.1));
    if (playerEscaped) {
      state.failedApproaches++;
      state.side *= -1;
      final hunter = _botHunters[bot.id];
      if (hunter == null) {
        state.phase = _BotManeuverPhase.recover;
        state.remaining = math
            .min(
              state.remaining,
              config.botManeuverRecoveryDuration,
            )
            .toDouble();
      } else {
        hunter.reacquisitionCount++;
        state.phase = _BotManeuverPhase.stage;
        state.remaining = math
            .min(config.botManeuverStageDuration, 0.2)
            .clamp(0.0, double.infinity)
            .toDouble();
        state.anchor = _playerRoutePoint(0.55);
      }
    }

    final stageTarget = _maneuverStageTarget(bot, state);
    final arrivedAtStage = state.phase == _BotManeuverPhase.stage &&
        bot.head.distanceTo(stageTarget) <= 105;
    final playerCommitted = state.phase == _BotManeuverPhase.wait &&
        _playerCommittedToManeuver(state);
    if (state.remaining > 0 && !arrivedAtStage && !playerCommitted) {
      return state;
    }

    switch (state.phase) {
      case _BotManeuverPhase.stage:
        state.phase = state.kind == _BotManeuverKind.baitAmbush ||
                state.kind == _BotManeuverKind.counterCut ||
                (_botHunters[bot.id]?.style ==
                        _BotHunterStyle.patientConstrictor &&
                    state.kind == _BotManeuverKind.constrictor)
            ? _BotManeuverPhase.wait
            : _BotManeuverPhase.commit;
        state.remaining = state.phase == _BotManeuverPhase.wait
            ? config.botManeuverStageDuration * 0.8
            : config.botManeuverCommitDuration;
      case _BotManeuverPhase.wait:
        state.phase = _BotManeuverPhase.commit;
        state.remaining = config.botManeuverCommitDuration;
      case _BotManeuverPhase.commit:
        state.phase = _BotManeuverPhase.execute;
        state.remaining = config.botManeuverCommitDuration * 0.72;
      case _BotManeuverPhase.execute:
        state.phase = _BotManeuverPhase.recover;
        state.remaining = config.botManeuverRecoveryDuration;
      case _BotManeuverPhase.recover:
        state.sequence++;
        state.kind = _selectManeuver(bot, state);
        state.phase = _BotManeuverPhase.stage;
        state.remaining = config.botManeuverStageDuration;
        state.side = _adaptiveAttackSide(bot, state);
        state.anchor = _maneuverAnchor(bot, state.kind);
    }
    state.observedPlayerHeading = player.heading;
    state.observedPlayerPosition = player.head;
    return state;
  }

  _BotManeuverKind _selectManeuver(
    SnakeState bot,
    _BotManeuverState state,
  ) {
    final opportunityRole = _botOpportunityRoles[bot.id];
    if (opportunityRole != null) {
      return switch (opportunityRole) {
        _TacticalOpportunityRole.outerConstrictor =>
          _BotManeuverKind.constrictor,
        _TacticalOpportunityRole.gapStriker => _BotManeuverKind.counterCut,
        _TacticalOpportunityRole.exitCutter => _BotManeuverKind.laneExecution,
        _TacticalOpportunityRole.innerSurvivor => _BotManeuverKind.counterCut,
      };
    }
    if (_botResourceRoles.containsKey(bot.id)) {
      return _BotManeuverKind.resourceDenial;
    }
    final hunter = _botHunters[bot.id];
    if (hunter != null) {
      return _selectHunterManeuver(hunter.style, state);
    }
    final role = _botFormationRoles[bot.id];
    if (role == _BotFormationRole.resourceGuard) {
      return _BotManeuverKind.resourceDenial;
    }
    if (role == _BotFormationRole.leadCutoff) {
      return state.sequence.isEven
          ? _BotManeuverKind.laneExecution
          : _BotManeuverKind.constrictor;
    }
    if (role == _BotFormationRole.leftScreen ||
        role == _BotFormationRole.rightScreen) {
      return state.sequence.isEven
          ? _BotManeuverKind.counterCut
          : _BotManeuverKind.feintReversal;
    }

    switch (bot.disposition) {
      case BotDisposition.aggressive:
        const portfolio = <_BotManeuverKind>[
          _BotManeuverKind.laneExecution,
          _BotManeuverKind.constrictor,
          _BotManeuverKind.feintReversal,
        ];
        return portfolio[
            (state.sequence + state.failedApproaches) % portfolio.length];
      case BotDisposition.opportunistic:
        if (_bestDroppedMassCluster(bot) != null ||
            _playerBehavior.resourceAttraction >= 0.25) {
          return state.sequence.isEven
              ? _BotManeuverKind.baitAmbush
              : _BotManeuverKind.resourceDenial;
        }
        return state.sequence.isEven
            ? _BotManeuverKind.baitAmbush
            : _BotManeuverKind.laneExecution;
      case BotDisposition.defensive:
        return state.sequence.isEven
            ? _BotManeuverKind.counterCut
            : _BotManeuverKind.resourceDenial;
      case BotDisposition.wanderer:
        const portfolio = <_BotManeuverKind>[
          _BotManeuverKind.feintReversal,
          _BotManeuverKind.roamingDuel,
          _BotManeuverKind.counterCut,
        ];
        return portfolio[(state.sequence + bot.colorIndex) % portfolio.length];
    }
  }

  _BotManeuverKind _selectHunterManeuver(
    _BotHunterStyle style,
    _BotManeuverState state,
  ) {
    return switch (style) {
      _BotHunterStyle.leadInterceptor => state.sequence.isEven
          ? _BotManeuverKind.laneExecution
          : _BotManeuverKind.constrictor,
      _BotHunterStyle.lateralHarrier => state.sequence.isEven
          ? _BotManeuverKind.feintReversal
          : _BotManeuverKind.counterCut,
      _BotHunterStyle.sprintBrakeTrap => state.sequence.isEven
          ? _BotManeuverKind.feintReversal
          : _BotManeuverKind.laneExecution,
      _BotHunterStyle.patientConstrictor => _BotManeuverKind.constrictor,
    };
  }

  double _adaptiveAttackSide(SnakeState bot, _BotManeuverState state) {
    if (_playerBehavior.escapeSideBias.abs() >= 0.12) {
      final learned = -_playerBehavior.escapeSideBias.sign;
      return state.failedApproaches.isOdd ? -learned : learned;
    }
    final parity = (bot.colorIndex + state.sequence).isEven ? 1.0 : -1.0;
    return state.failedApproaches.isOdd ? -parity : parity;
  }

  Vec2 _maneuverAnchor(SnakeState bot, _BotManeuverKind kind) {
    if (kind == _BotManeuverKind.baitAmbush ||
        kind == _BotManeuverKind.resourceDenial) {
      final cluster = _bestDroppedMassCluster(bot);
      if (cluster != null) return cluster.center;
      final food = _nearestFoodTarget(bot);
      if (food != null) return food;
    }
    return _playerRoutePoint(0.8);
  }

  bool _playerCommittedToManeuver(_BotManeuverState state) {
    final toAnchor = state.anchor - player.head;
    if (toAnchor.length == 0) return true;
    final approaching = _alignment(player.heading, toAnchor) >= 0.42;
    final close = toAnchor.length <= config.botDroppedMassGuardRadius * 0.75;
    final stableRoute = player.movementCommitment >= 0.55;
    return close && approaching && stableRoute;
  }

  Vec2 _maneuverStageTarget(SnakeState bot, _BotManeuverState state) {
    if (!player.alive) return bot.head + bot.heading * 120;
    final hunter = _botHunters[bot.id];
    if (hunter != null &&
        bot.head.distanceTo(player.head) > config.botEngagementRadius * 0.7) {
      return _hunterApproachTarget(bot, state, hunter.style);
    }
    final lateral = Vec2(-player.heading.y, player.heading.x);
    final formation = _formationIntent(bot);
    if (formation.length > 0 && state.phase == _BotManeuverPhase.stage) {
      return bot.head + formation * config.botFormationSeparationDistance;
    }
    switch (state.kind) {
      case _BotManeuverKind.laneExecution:
        final pressure = _playerPressure(bot);
        final pressureTarget = pressure.length == 0
            ? _playerRoutePoint(0.95)
            : bot.head + pressure.normalized() * 260;
        return pressureTarget + lateral * state.side * 245;
      case _BotManeuverKind.counterCut:
        return player.head + player.heading * 105 + lateral * state.side * 205;
      case _BotManeuverKind.constrictor:
        final geometry = _geometryAttackPlan(bot);
        if (geometry.attack) return geometry.target;
        final midpoint = player.body[math.min(
          player.body.length - 1,
          math.max(1, player.body.length ~/ 2),
        )];
        final widen = _playerBehavior.gapCamping >= 0.22 ? 1.65 : 1.0;
        return midpoint +
            lateral * state.side * config.botEncircleGapDistance * widen;
      case _BotManeuverKind.baitAmbush:
        final fromPlayer = state.anchor - player.head;
        final approach =
            fromPlayer.length == 0 ? player.heading : fromPlayer.normalized();
        final anchorLateral = Vec2(-approach.y, approach.x);
        return state.anchor +
            approach * config.botBaitDistance +
            anchorLateral * state.side * 145;
      case _BotManeuverKind.feintReversal:
        return _playerRoutePoint(0.72) + lateral * state.side * 220;
      case _BotManeuverKind.resourceDenial:
        final control = _droppedMassControl(bot);
        if (control.length > 0) {
          return bot.head + control.normalized() * config.botScreenDistance;
        }
        final droppedMass = _nearestDroppedMass(bot);
        if (droppedMass.length > 0) {
          return bot.head + droppedMass.normalized() * config.botScreenDistance;
        }
        final approach = (state.anchor - player.head).normalized();
        final anchorLateral = Vec2(-approach.y, approach.x);
        return player.head +
            approach * config.botDroppedMassGuardDistance +
            anchorLateral * state.side * config.botScreenDistance;
      case _BotManeuverKind.roamingDuel:
        final food = _nearestFood(bot);
        if (bot.head.distanceTo(player.head) > config.botEngagementRadius &&
            food.length > 0) {
          return bot.head + food.normalized() * 170;
        }
        final phase = elapsed * (1.9 + bot.colorIndex % 3 * 0.27);
        final irregular = math.sin(phase) + math.sin(phase * 1.73) * 0.48;
        final tactical = _tacticalIntent(bot, _BotTactic.feint);
        final tacticalDirection =
            tactical.length == 0 ? bot.heading : tactical.normalized();
        return bot.head +
            tacticalDirection * 70 +
            bot.heading * 170 +
            Vec2(-bot.heading.y, bot.heading.x) * irregular * 145;
    }
  }

  Vec2 _hunterApproachTarget(
    SnakeState bot,
    _BotManeuverState maneuver,
    _BotHunterStyle style,
  ) {
    final distance = bot.head.distanceTo(player.head);
    final arrival = (distance / math.max(1.0, _effectiveSpeed(bot)) * 0.52)
        .clamp(0.65, 2.8)
        .toDouble();
    final route = _playerRoutePoint(arrival);
    final lateral = Vec2(-player.heading.y, player.heading.x);
    final approachWidth = math
        .min(config.botHunterReentryDistance, math.max(95.0, distance * 0.2))
        .toDouble();
    return switch (style) {
      _BotHunterStyle.leadInterceptor =>
        route + lateral * maneuver.side * approachWidth * 0.38,
      _BotHunterStyle.lateralHarrier =>
        route + lateral * maneuver.side * approachWidth,
      _BotHunterStyle.sprintBrakeTrap => route -
          player.heading * 70 +
          lateral * maneuver.side * approachWidth * 0.52,
      _BotHunterStyle.patientConstrictor => _playerRoutePoint(arrival * 0.72) +
          lateral * maneuver.side * approachWidth * 0.82,
    };
  }

  Vec2 _hunterReentryTarget(_BotManeuverState maneuver) {
    final lateral = Vec2(-player.heading.y, player.heading.x);
    final route = _playerRoutePoint(1.05);
    return route +
        lateral * maneuver.side * config.botHunterReentryDistance -
        player.heading * 80;
  }

  _BotManeuverPlan _maneuverPlan(SnakeState bot) {
    final state = _ensureBotManeuver(bot);
    final opportunityPlan = _tacticalOpportunityPlan(bot, state);
    if (opportunityPlan != null) return opportunityPlan;
    final resourcePlan = _resourceControlPlan(bot, state);
    if (resourcePlan != null) return resourcePlan;
    final hookGuardPlan = _hunterHookGuardPlan(bot, state);
    if (hookGuardPlan != null) return hookGuardPlan;
    final closedLoopMode = _closedLoopEngagement(bot);
    final closedLoop = _closedLoopIntent(bot, closedLoopMode);
    final lateral = Vec2(-player.heading.y, player.heading.x);
    final stageTarget = _maneuverStageTarget(bot, state);
    Vec2 target = stageTarget;
    var wantsSprint = false;
    var mode = _BotPlanMode.attack;
    var speedMultiplier = 0.84;

    switch (state.phase) {
      case _BotManeuverPhase.stage:
        speedMultiplier = _botHunters.containsKey(bot.id) ? 1 : 0.86;
      case _BotManeuverPhase.wait:
        speedMultiplier = config.botYieldSpeedMultiplier;
        if (state.kind == _BotManeuverKind.counterCut) {
          target = bot.head - player.heading * 60 + lateral * state.side * 35;
        }
      case _BotManeuverPhase.commit:
        speedMultiplier = 1;
        wantsSprint = state.kind == _BotManeuverKind.laneExecution ||
            state.kind == _BotManeuverKind.counterCut ||
            state.kind == _BotManeuverKind.feintReversal ||
            state.kind == _BotManeuverKind.baitAmbush;
        switch (state.kind) {
          case _BotManeuverKind.laneExecution:
            target = _playerRoutePoint(0.5) - lateral * state.side * 190;
          case _BotManeuverKind.counterCut:
            target = _playerRoutePoint(0.38) - lateral * state.side * 125;
          case _BotManeuverKind.constrictor:
            target = _playerRoutePoint(0.3) +
                lateral *
                    state.side *
                    (_playerBehavior.gapCamping >= 0.22 ? 175 : 75);
            final geometry = _geometryPressure(bot, _geometryAttackPlan(bot));
            if (geometry.length > 0) {
              target = target + geometry * 90;
            }
            wantsSprint = _playerBehavior.gapCamping < 0.22;
          case _BotManeuverKind.baitAmbush:
            target =
                player.head + player.heading * 135 - lateral * state.side * 110;
          case _BotManeuverKind.feintReversal:
            target = _playerRoutePoint(0.42) - lateral * state.side * 215;
          case _BotManeuverKind.resourceDenial:
            target = player.head +
                (state.anchor - player.head).normalized() *
                    config.botDenyDistance;
            mode = _BotPlanMode.contest;
            wantsSprint = _playerBehavior.resourceAttraction >= 0.2 ||
                bot.head.distanceTo(state.anchor) <=
                    config.botSprintTriggerDistance * 1.25;
          case _BotManeuverKind.roamingDuel:
            target = _playerRoutePoint(0.5) - lateral * state.side * 140;
            wantsSprint = _playerBehavior.reversalTendency < 0.5;
        }
      case _BotManeuverPhase.execute:
        speedMultiplier =
            state.kind == _BotManeuverKind.constrictor ? 0.72 : 0.9;
        if (_botHunters[bot.id]?.style == _BotHunterStyle.sprintBrakeTrap) {
          if (bot.sprinting) {
            _stopBotSprint(bot);
          } else if (bot.sprintRequested) {
            _cancelSprintRequest(bot);
          }
          speedMultiplier = config.botTacticBrakeMultiplier;
          wantsSprint = false;
        }
        switch (state.kind) {
          case _BotManeuverKind.constrictor:
            final midpoint = player.body[math.min(
              player.body.length - 1,
              math.max(1, player.body.length ~/ 2),
            )];
            final radial = (bot.head - midpoint).normalized();
            final tangent = Vec2(-radial.y, radial.x) * state.side;
            target = bot.head +
                tangent * 190 +
                radial * (_playerBehavior.gapCamping >= 0.22 ? 120 : -55);
          case _BotManeuverKind.baitAmbush:
          case _BotManeuverKind.resourceDenial:
            target = _playerRoutePoint(0.32) - lateral * state.side * 80;
            mode = _BotPlanMode.contest;
          case _BotManeuverKind.laneExecution:
          case _BotManeuverKind.counterCut:
          case _BotManeuverKind.feintReversal:
          case _BotManeuverKind.roamingDuel:
            target = _playerRoutePoint(0.28) - lateral * state.side * 120;
        }
      case _BotManeuverPhase.recover:
        if (_botHunters.containsKey(bot.id)) {
          speedMultiplier = 0.9;
          mode = _BotPlanMode.attack;
          target = _hunterReentryTarget(state);
        } else {
          speedMultiplier = 0.76;
          mode = _BotPlanMode.wander;
          final away = (bot.head - player.head).normalized();
          target =
              bot.head + away * 210 + Vec2(-away.y, away.x) * state.side * 130;
        }
    }

    if (state.kind == _BotManeuverKind.resourceDenial) {
      mode = _BotPlanMode.contest;
      speedMultiplier = (speedMultiplier *
              (0.82 + math.min(0.18, _droppedMassWeight(bot) * 0.06)))
          .clamp(config.botYieldSpeedMultiplier, 1.0)
          .toDouble();
      if (closedLoop.length > 0 &&
          (closedLoopMode == _BotEngagementMode.deny ||
              closedLoopMode == _BotEngagementMode.screen ||
              closedLoopMode == _BotEngagementMode.harvest)) {
        target = bot.head + closedLoop * config.botScreenDistance;
      }
    } else if (state.kind == _BotManeuverKind.roamingDuel &&
        bot.head.distanceTo(player.head) > config.botEngagementRadius) {
      mode = _BotPlanMode.wander;
      speedMultiplier = (speedMultiplier *
              (0.72 +
                  math.min(
                    0.28,
                    (_wanderWeight(bot) + _foodWeight(bot)) * 0.1,
                  )))
          .clamp(config.botYieldSpeedMultiplier, 1.0)
          .toDouble();
    } else if (mode == _BotPlanMode.attack) {
      speedMultiplier = (speedMultiplier *
              (0.84 + math.min(0.16, _pressureWeight(bot) * 0.05)))
          .clamp(config.botYieldSpeedMultiplier, 1.0)
          .toDouble();
    }
    final direction = target - bot.head;
    return _BotManeuverPlan(
      intent: direction.length == 0 ? bot.heading : direction.normalized(),
      mode: mode,
      wantsSprint: wantsSprint,
      speedMultiplier: speedMultiplier,
    );
  }

  _BotManeuverPlan? _tacticalOpportunityPlan(
    SnakeState bot,
    _BotManeuverState state,
  ) {
    final role = _botOpportunityRoles[bot.id];
    if (role == null || !_opportunity.active || !player.alive) return null;
    final lateral = Vec2(-player.heading.y, player.heading.x);
    Vec2 target;
    var wantsSprint = false;
    var speedMultiplier = 0.92;
    switch (role) {
      case _TacticalOpportunityRole.outerConstrictor:
        state.kind = _BotManeuverKind.constrictor;
        final fromCenter = bot.head - _opportunity.center;
        final radial = fromCenter.length == 0
            ? lateral * state.side
            : fromCenter.normalized();
        final tangent = Vec2(-radial.y, radial.x) * state.side;
        final ringRadius = _opportunity.radius + bot.radius + 68;
        final ringPoint = _opportunity.center + radial * ringRadius;
        final ringError = bot.head.distanceTo(ringPoint);
        target = ringError > 120
            ? ringPoint + tangent * 90
            : bot.head +
                tangent * 210 +
                radial * (ringRadius - fromCenter.length);
        wantsSprint = ringError > 260;
        speedMultiplier = ringError > 120 ? 1 : 0.78;
      case _TacticalOpportunityRole.gapStriker:
        state.kind = _BotManeuverKind.counterCut;
        target =
            _opportunity.gap + player.heading * 62 - lateral * state.side * 82;
        wantsSprint = bot.head.distanceTo(target) <=
            config.botSprintTriggerDistance * 1.45;
        speedMultiplier = 1;
      case _TacticalOpportunityRole.exitCutter:
        state.kind = _BotManeuverKind.laneExecution;
        final exit = _opportunity.playerEnclosing
            ? _opportunity.gap + player.heading * 220
            : _playerRoutePoint(0.72);
        target = exit + lateral * state.side * 95;
        wantsSprint = bot.head.distanceTo(target) <=
            config.botSprintTriggerDistance * 1.7;
        speedMultiplier = 1;
      case _TacticalOpportunityRole.innerSurvivor:
        state.kind = _BotManeuverKind.counterCut;
        final pressure = _opportunity.gap - bot.head;
        final seam = player.body.isEmpty
            ? player.heading
            : (player.body.first - player.body.last).normalized();
        final seamDirection = seam.length == 0 ? player.heading : seam;
        final seamLateral = Vec2(-seamDirection.y, seamDirection.x);
        final distanceToSeam = pressure.length;
        target = distanceToSeam > 105
            ? _opportunity.gap +
                seamDirection * 24 +
                seamLateral * state.side * 38
            : _opportunity.gap + seamLateral * state.side * 72;
        wantsSprint = distanceToSeam > 170 &&
            distanceToSeam <= config.botSprintTriggerDistance * 1.6;
        speedMultiplier =
            distanceToSeam > 105 ? 1 : config.botYieldSpeedMultiplier * 1.08;
    }
    final direction = target - bot.head;
    return _BotManeuverPlan(
      intent: direction.length == 0 ? bot.heading : direction.normalized(),
      mode: _BotPlanMode.attack,
      wantsSprint: wantsSprint,
      speedMultiplier: speedMultiplier,
    );
  }

  _BotManeuverPlan? _hunterHookGuardPlan(
    SnakeState bot,
    _BotManeuverState state,
  ) {
    if (!_opportunity.playerDevelopingHook ||
        !_botHunters.containsKey(bot.id) ||
        _botOpportunityRoles.containsKey(bot.id) ||
        !player.alive) {
      return null;
    }
    final fromCenter = bot.head - _opportunity.center;
    final radial = fromCenter.length == 0
        ? Vec2(-player.heading.y, player.heading.x) * state.side
        : fromCenter.normalized();
    final guardRadius = _opportunity.radius + bot.radius + 110;
    final disengageRadius =
        math.max(guardRadius, fromCenter.length + 160).toDouble();
    final outsideRing = _opportunity.center + radial * disengageRadius;
    final lateral = Vec2(-player.heading.y, player.heading.x);
    final cutoff =
        _opportunity.gap + player.heading * 165 + lateral * state.side * 125;
    final insideClosingHook = fromCenter.length < guardRadius + 35 &&
        _alignment(bot.heading, _opportunity.center - bot.head) > -0.15;
    final inward = (_opportunity.center - bot.head).normalized();
    var tangent = Vec2(-inward.y, inward.x);
    if (_alignment(tangent, cutoff - bot.head) < 0) tangent = tangent * -1;
    final radialError = math.max(0.0, fromCenter.length - guardRadius);
    final guardedCutoff = bot.head +
        tangent * 240 +
        inward * math.min(90.0, radialError).toDouble();
    final target = insideClosingHook ? outsideRing : guardedCutoff;
    state.kind = insideClosingHook
        ? _BotManeuverKind.feintReversal
        : _BotManeuverKind.laneExecution;
    final direction = target - bot.head;
    return _BotManeuverPlan(
      intent: direction.length == 0 ? bot.heading : direction.normalized(),
      mode: _BotPlanMode.attack,
      wantsSprint: !insideClosingHook &&
          bot.head.distanceTo(target) <= config.botSprintTriggerDistance * 1.4,
      speedMultiplier: insideClosingHook ? 0.82 : 0.96,
    );
  }

  _BotManeuverPlan? _resourceControlPlan(
    SnakeState bot,
    _BotManeuverState state,
  ) {
    final role = _botResourceRoles[bot.id];
    final field = _opportunity.resourceField;
    if (role == null || field == null || !player.alive) return null;
    state.kind = _BotManeuverKind.resourceDenial;
    final playerApproach = field.center - player.head;
    final approach = playerApproach.length == 0
        ? player.heading
        : playerApproach.normalized();
    final lateral = Vec2(-approach.y, approach.x);
    final side = state.side;
    Vec2 target;
    var wantsSprint = false;
    var speedMultiplier = 0.9;
    switch (role) {
      case _ResourceControlRole.harvester:
        target = field.center + lateral * side * field.radius * 0.24;
        wantsSprint = field.value >=
                math.max(8, config.botResourceFieldMinimumValue * 2) ||
            bot.head.distanceTo(target) <=
                config.botSprintTriggerDistance * 1.4;
        speedMultiplier = 1;
      case _ResourceControlRole.approachGuard:
        target = player.head +
            approach * config.botDroppedMassGuardDistance +
            lateral * side * 74;
        wantsSprint = player.head.distanceTo(field.center) <=
            config.botDroppedMassGuardRadius * 0.8;
        speedMultiplier = 0.92;
      case _ResourceControlRole.exitAmbusher:
        target = field.center +
            approach * (field.radius + config.botDenyDistance) +
            lateral * side * 96;
        wantsSprint = player.head.distanceTo(field.center) <=
            config.botDroppedMassGuardRadius * 0.62;
        speedMultiplier = 0.88;
    }
    final direction = target - bot.head;
    return _BotManeuverPlan(
      intent: direction.length == 0 ? bot.heading : direction.normalized(),
      mode: _BotPlanMode.contest,
      wantsSprint: wantsSprint,
      speedMultiplier: speedMultiplier,
    );
  }

  _BotTactic _advanceBotTactic(SnakeState bot) {
    final maneuver = _ensureBotManeuver(bot);
    final state = _botTactics.putIfAbsent(bot.id, _BotTacticState.new);
    if (!player.alive) {
      state.mode = _selectBotTactic(bot);
      return state.mode;
    }
    state.mode = switch (maneuver.kind) {
      _BotManeuverKind.laneExecution => _BotTactic.cutoff,
      _BotManeuverKind.counterCut => _BotTactic.flank,
      _BotManeuverKind.constrictor => _BotTactic.encircle,
      _BotManeuverKind.baitAmbush => _BotTactic.bait,
      _BotManeuverKind.feintReversal => _BotTactic.feint,
      _BotManeuverKind.resourceDenial => _BotTactic.flank,
      _BotManeuverKind.roamingDuel => _BotTactic.weave,
    };
    state.remaining = maneuver.remaining;
    state.sign = maneuver.side;
    state.plannedPlayerHeading = player.heading;
    state.plannedPlayerPosition = player.head;
    final phaseTurn = maneuver.phase == _BotManeuverPhase.commit ||
            maneuver.phase == _BotManeuverPhase.execute
        ? 1.0
        : 0.82;
    final variation = ((bot.colorIndex + maneuver.sequence) % 4) * 0.035;
    bot.tacticalTurnRateMultiplier =
        (phaseTurn - variation).clamp(0.72, 1.0).toDouble();
    _applyTacticalMotion(bot, state.mode, 0);
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
      bot.botSprintCooldownRemaining =
          math.max(0, bot.botSprintCooldownRemaining - dt).toDouble();
    }
    _advanceSprintTelegraph(bot, dt);
    if (!bot.sprinting) return;

    bot.botSprintRemaining -= dt;
    if (bot.botSprintRemaining <= 0) _stopBotSprint(bot);
  }

  void _decideBotSprint(
    SnakeState bot, {
    required _BotPlan plan,
    required bool maneuverRequestsSprint,
  }) {
    if (bot.sprinting ||
        bot.sprintRequested ||
        bot.botSprintCooldownRemaining > 0 ||
        bot.speed <= 0 ||
        bot.length <= config.botSprintMinimumLength) {
      return;
    }
    if (!plan.allowSprint ||
        plan.mode == _BotPlanMode.evadePeer ||
        plan.mode == _BotPlanMode.evadePlayer) {
      return;
    }

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
    var shouldSprint = maneuverRequestsSprint;
    final playerNearCluster = droppedMassCluster != null &&
        player.alive &&
        player.head.distanceTo(droppedMassCluster.center) <=
            config.botDroppedMassGuardRadius;

    switch (bot.disposition) {
      case BotDisposition.defensive:
        shouldSprint = shouldSprint ||
            bot.retreating ||
            (player.alive &&
                playerDistance <= distanceLimit * 0.8 &&
                bot.length <= player.length * 1.2);
      case BotDisposition.aggressive:
        shouldSprint = shouldSprint ||
            (player.alive &&
                playerDistance <= distanceLimit &&
                bot.length >= player.length * 0.75 &&
                bot.length <= player.length * 1.6) ||
            (playerNearCluster && droppedMassDistance <= distanceLimit * 1.5);
      case BotDisposition.opportunistic:
        shouldSprint = shouldSprint ||
            droppedMassDistance <= distanceLimit ||
            (playerNearCluster && droppedMassDistance <= distanceLimit * 1.5);
      case BotDisposition.wanderer:
        shouldSprint =
            shouldSprint || naturalFoodDistance <= distanceLimit * 0.7;
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
    state.remaining = math.max(state.remaining, 0.35).toDouble();
    state.sign = bot.id.hashCode.isEven ? 1 : -1;
    final maneuver = _botManeuvers[bot.id];
    if (maneuver != null) {
      maneuver.phase = _BotManeuverPhase.recover;
      maneuver.remaining = math
          .min(
            math.max(maneuver.remaining, 0.12),
            config.botManeuverRecoveryDuration,
          )
          .toDouble();
    }
    bot.movementCommitment = math.min(bot.movementCommitment, 0.45).toDouble();
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
    if (_botTactics[bot.id]?.mode == _BotTactic.disengage ||
        _playerTurnCommitmentRemaining > 0) {
      bot.movementCommitment =
          math.min(bot.movementCommitment, 0.45).toDouble();
    }
    bot.heading = Vec2.fromAngle(current + turn);
  }

  Vec2 _retreatDirection(SnakeState bot) {
    final direction =
        bot.head.length == 0 ? bot.heading : bot.head.normalized();
    final target = direction *
        math.max(0.0, config.arenaRadius - config.botRetreatBoundaryBuffer);
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
    for (final sample in _nearbyBodySamples(
      snake.head,
      config.botSenseRadius,
    )) {
      if (sample.owner.id == snake.id || sample.index == 0) continue;
      final offset = snake.head - sample.position;
      final distance = offset.length;
      if (distance == 0 || distance > config.botSenseRadius) continue;
      final double urgency =
          (config.botSenseRadius - distance) / config.botSenseRadius;
      avoidance += offset.normalized() * (urgency * urgency * 4);
    }
    return avoidance;
  }

  Vec2 _nearestFood(SnakeState snake) {
    FoodPellet? nearest;
    var nearestDistance = config.botSenseRadius;
    for (final pellet in _nearbyFood(
      snake.head,
      config.botSenseRadius,
      _droppedMassBuckets,
    )) {
      final distance = snake.head.distanceTo(pellet.position);
      if (distance < nearestDistance) {
        nearest = pellet;
        nearestDistance = distance;
      }
    }
    for (final pellet in _nearbyFood(
      snake.head,
      config.botSenseRadius,
      _pelletBuckets,
    )) {
      final distance = snake.head.distanceTo(pellet.position);
      if (distance < nearestDistance) {
        nearest = pellet;
        nearestDistance = distance;
      }
    }
    if (nearest == null) return Vec2.zero;
    return (nearest.position - snake.head).normalized() * 1.5;
  }

  double _nearestNaturalFoodDistance(SnakeState snake) {
    var nearestDistance = double.infinity;
    for (final pellet in _nearbyFood(
      snake.head,
      config.botSenseRadius,
      _pelletBuckets,
    )) {
      final distance = snake.head.distanceTo(pellet.position);
      if (distance < nearestDistance) nearestDistance = distance;
    }
    return nearestDistance;
  }

  Vec2 _nearestDroppedMass(SnakeState snake) {
    FoodPellet? nearest;
    var nearestDistance = config.botSenseRadius;
    for (final pellet in _nearbyFood(
      snake.head,
      config.botSenseRadius,
      _droppedMassBuckets,
    )) {
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
    for (final pellet in _nearbyFood(
      snake.head,
      config.botDroppedMassSenseRadius,
      _droppedMassBuckets,
    )) {
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

  int _droppedMassClaimRank(SnakeState bot, _DroppedMassCluster cluster) {
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
      return _BotEngagementPlan(target: bot.head, rank: 100, safety: 0);
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
        : <double>[preferredOffset, -preferredOffset, side * lane * 0.55];
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
    return _BotEngagementPlan(target: bestTarget, rank: rank, safety: safety);
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
    final midpoint = player.body[math.min(
      player.body.length - 1,
      math.max(1, player.body.length ~/ 2),
    )];
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

  double _engagementLaneRisk(
    SnakeState bot,
    Vec2 target, {
    Vec2? intendedDirection,
    double? speedOverride,
    bool includePeerBodies = false,
    bool tacticalPrecision = false,
  }) {
    final toTarget = target - bot.head;
    if (toTarget.length == 0) return 1;

    final direction = intendedDirection?.normalized() ?? toTarget.normalized();
    final speed = speedOverride ?? _effectiveSpeed(bot);
    final lookahead = math.max(config.botAdaptiveLeadTime, 1.0).toDouble();
    final samples = math.max(2, config.botCollisionSampleCount).toInt();
    var maximumRisk = 0.0;
    final bodyRadius = tacticalPrecision
        ? math
            .max(
              config.botTacticalPrecisionSafetyRadius,
              bot.radius + player.radius + 18,
            )
            .toDouble()
        : math
            .max(
              config.botEngagementSafetyRadius,
              bot.radius + player.radius + 24,
            )
            .toDouble();

    for (var sample = 1; sample <= samples; sample++) {
      final progress = sample / samples;
      final time = lookahead * progress;
      final future = _projectBotRoutePoint(
        bot,
        direction,
        time,
        speed: speed,
      );
      final routeDirection = _projectTurningDirection(
        heading: bot.heading,
        intended: direction,
        turnRate: config.botTurnRate * bot.tacticalTurnRateMultiplier,
        time: time,
      );
      if (player.alive) {
        final playerTravel = _effectiveSpeed(player) * time;
        for (final sample in _nearbyBodySamples(
          future,
          bodyRadius + playerTravel,
        )) {
          if (sample.owner.id != player.id || sample.index < 2) continue;
          final projectedSegment = _projectBodySample(sample, time);
          final distance = future.distanceTo(projectedSegment);
          if (distance >= bodyRadius) continue;
          final motionThreat = _relativeMotionThreat(
            bot,
            player,
            actorPosition: future,
            otherPosition: projectedSegment,
            separation: distance,
            actorDirection: routeDirection,
            actorSpeed: speed,
          );
          if (motionThreat <= 0) continue;
          maximumRisk = math
              .max(
                maximumRisk,
                (((bodyRadius - distance) / bodyRadius) * motionThreat)
                    .clamp(0.0, 1.0)
                    .toDouble(),
              )
              .toDouble();
        }
      }

      for (final other in snakes.where(
        (candidate) =>
            candidate.kind == SnakeKind.bot &&
            candidate.id != bot.id &&
            candidate.alive,
      )) {
        final otherPlan = _botPlans[other.id];
        final otherIntent = otherPlan?.intent ?? other.heading;
        final otherSpeed = other.speed *
            (otherPlan?.speedMultiplier ?? other.tacticalSpeedMultiplier) *
            ((other.sprinting ||
                    other.sprintRequested ||
                    (otherPlan?.allowSprint ?? false))
                ? config.botSprintMultiplier
                : 1.0);
        final otherFuture = _projectBotRoutePoint(
          other,
          otherIntent,
          time,
          speed: otherSpeed,
        );
        final otherRouteDirection = _projectTurningDirection(
          heading: other.heading,
          intended: otherIntent,
          turnRate: config.botTurnRate * other.tacticalTurnRateMultiplier,
          time: time,
        );
        final distance = future.distanceTo(otherFuture);
        final peerRadius = bot.radius + other.radius + 52;
        if (distance < peerRadius) {
          final motionThreat = _relativeMotionThreat(
            bot,
            other,
            actorPosition: future,
            otherPosition: otherFuture,
            separation: distance,
            actorDirection: routeDirection,
            actorSpeed: speed,
            otherDirection: otherRouteDirection,
            otherSpeed: otherSpeed,
          );
          if (motionThreat > 0) {
            maximumRisk = math
                .max(
                  maximumRisk,
                  (((peerRadius - distance) / peerRadius) * motionThreat)
                      .clamp(0.0, 1.0)
                      .toDouble(),
                )
                .toDouble();
          }
        }

        if (includePeerBodies) {
          for (final bodySample in _nearbyBodySamples(
            future,
            peerRadius + otherSpeed * time,
          )) {
            if (bodySample.owner.id != other.id || bodySample.index < 2) {
              continue;
            }
            final projectedSegment = _projectBodySample(bodySample, time);
            final bodyDistance = future.distanceTo(projectedSegment);
            if (bodyDistance >= peerRadius) continue;
            final bodyThreat = _relativeMotionThreat(
              bot,
              other,
              actorPosition: future,
              otherPosition: projectedSegment,
              separation: bodyDistance,
              actorDirection: routeDirection,
              actorSpeed: speed,
              otherDirection: otherRouteDirection,
              otherSpeed: otherSpeed,
            );
            if (bodyThreat <= 0) continue;
            maximumRisk = math
                .max(
                  maximumRisk,
                  (((peerRadius - bodyDistance) / peerRadius) * bodyThreat)
                      .clamp(0.0, 1.0)
                      .toDouble(),
                )
                .toDouble();
          }
        }
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

    final avoidanceRadius = math
        .max(config.botCollisionAvoidanceRadius, config.botRouteAvoidanceRadius)
        .toDouble();
    for (var sample = 1; sample <= samples; sample++) {
      final progress = sample / samples;
      final time = lookahead * progress;
      final future = _projectBotRoutePoint(
        snake,
        snake.heading,
        time,
        speed: speed,
      );
      final projectedTravel = speed * lookahead * progress;
      for (final bodySample in _nearbyBodySamples(
        future,
        avoidanceRadius + projectedTravel,
      )) {
        final other = bodySample.owner;
        if (other.id == snake.id || !other.alive || bodySample.index == 0) {
          continue;
        }
        // Body samples advance along their existing curved trail. This keeps
        // the predictor aligned with the geometry the snake will actually
        // occupy instead of translating every segment as a rigid line.
        final projectedSegment = _projectBodySample(bodySample, time);
        final offset = future - projectedSegment;
        final distance = offset.length;
        if (distance <= 0 || distance >= avoidanceRadius) continue;

        final motionThreat = _relativeMotionThreat(
          snake,
          other,
          actorPosition: future,
          otherPosition: projectedSegment,
          separation: distance,
        );
        if (motionThreat <= 0) continue;
        final urgency =
            (avoidanceRadius - distance) / avoidanceRadius * motionThreat;
        var escape = offset.normalized();
        if (_alignment(snake.heading, projectedSegment - future) > 0.15) {
          final side = Vec2(-snake.heading.y, snake.heading.x) *
              (snake.id.compareTo(other.id) <= 0 ? 1.0 : -1.0);
          escape = (escape * 0.35 + side * 0.9).normalized();
        }
        avoidance += escape * (urgency * urgency);
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
      final time = lookahead * progress;
      final future = _projectBotRoutePoint(
        bot,
        bot.heading,
        time,
        speed: speed,
      );
      final playerTravel = _effectiveSpeed(player) * time;
      for (final samplePoint in _nearbyBodySamples(
        future,
        radius + playerTravel,
      )) {
        if (samplePoint.owner.id != player.id || samplePoint.index < 1) {
          continue;
        }
        final projectedSegment = _projectBodySample(samplePoint, time);
        final offset = future - projectedSegment;
        final distance = offset.length;
        if (distance >= radius) continue;

        final motionThreat = _relativeMotionThreat(
          bot,
          player,
          actorPosition: future,
          otherPosition: projectedSegment,
          separation: distance,
        );
        if (motionThreat <= 0) continue;
        final urgency =
            (((radius - distance) / radius) * motionThreat).clamp(0.0, 1.0);
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

    return _BotRouteRisk(escape: escape.normalized(), urgency: maximumUrgency);
  }

  _BotPeerRisk _botPeerRouteRisk(SnakeState bot) {
    if (bot.speed <= 0) {
      return const _BotPeerRisk(escape: Vec2.zero, urgency: 0);
    }
    // A stopped bot must evaluate the route it would occupy after yielding,
    // not conclude that the lane is clear merely because its current velocity
    // is zero. The bounded restart probe prevents both peers from releasing a
    // safety hold into the same crossing on the same planning tick.
    final speed = math.max(_effectiveSpeed(bot), bot.speed * 0.55).toDouble();

    final lookahead = math.max(
      config.botCollisionLookahead,
      config.botAdaptiveLeadTime,
    );
    final samples = math.max(2, config.botCollisionSampleCount).toInt();
    var escape = Vec2.zero;
    var maximumUrgency = 0.0;
    String? rightOfWayOwnerId;
    for (final other in snakes.where(
      (candidate) =>
          candidate.kind == SnakeKind.bot &&
          candidate.id != bot.id &&
          candidate.alive,
    )) {
      final otherOwnsRightOfWay = !_botHasRightOfWay(bot, other);
      for (var sample = 1; sample <= samples; sample++) {
        final progress = sample / samples;
        final time = lookahead * progress;
        final future = _projectBotRoutePoint(
          bot,
          bot.heading,
          time,
          speed: speed,
        );
        final otherProbeSpeed =
            math.max(_effectiveSpeed(other), other.speed * 0.55).toDouble();
        final otherPlan = _botPlans[other.id];
        final otherIntent = otherPlan?.intent ?? other.heading;
        final peerHead = _projectBotRoutePoint(
          other,
          otherIntent,
          time,
          speed: otherProbeSpeed,
        );
        final peerRadius = math.max(
          config.botPeerHardAvoidanceRadius,
          bot.radius + other.radius + 42,
        );
        final headOffset = future - peerHead;
        final headDistance = headOffset.length;
        if (headDistance < peerRadius) {
          final motionThreat = _relativeMotionThreat(
            bot,
            other,
            actorPosition: future,
            otherPosition: peerHead,
            separation: headDistance,
          );
          final rawUrgency =
              (((peerRadius - headDistance) / peerRadius) * motionThreat)
                  .clamp(0.0, 1.0)
                  .toDouble();
          final urgency = rawUrgency *
              (otherOwnsRightOfWay || rawUrgency >= 0.78 ? 1.0 : 0.42);
          if (urgency > maximumUrgency) {
            maximumUrgency = urgency;
            rightOfWayOwnerId = otherOwnsRightOfWay ? other.id : null;
          }
          final side = _peerYieldSide(bot, other);
          final away = headDistance == 0 ? side : headOffset.normalized();
          escape +=
              (away * 0.35 + side * 0.95).normalized() * (urgency * urgency);
        }

        final bodyRadius = bot.radius + other.radius + 24;
        for (final samplePoint in _nearbyBodySamples(
          future,
          bodyRadius + otherProbeSpeed * time,
        )) {
          if (samplePoint.owner.id != other.id || samplePoint.index < 1) {
            continue;
          }
          final projectedSegment = _projectBodySample(samplePoint, time);
          final offset = future - projectedSegment;
          final distance = offset.length;
          if (distance >= bodyRadius) continue;

          final motionThreat = _relativeMotionThreat(
            bot,
            other,
            actorPosition: future,
            otherPosition: projectedSegment,
            separation: distance,
          );
          final rawUrgency =
              (((bodyRadius - distance) / bodyRadius) * motionThreat)
                  .clamp(0.0, 1.0)
                  .toDouble();
          final urgency = rawUrgency *
              (otherOwnsRightOfWay || rawUrgency >= 0.78 ? 1.0 : 0.42);
          if (urgency > maximumUrgency) {
            maximumUrgency = urgency;
            rightOfWayOwnerId = otherOwnsRightOfWay ? other.id : null;
          }
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
      rightOfWayOwnerId: rightOfWayOwnerId,
    );
  }

  bool _botHasRightOfWay(SnakeState bot, SnakeState other) {
    final botPriority = _botPlanningPriority(bot);
    final otherPriority = _botPlanningPriority(other);
    if ((botPriority - otherPriority).abs() > 1e-6) {
      return botPriority > otherPriority;
    }
    return bot.id.compareTo(other.id) < 0;
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
    var nearestDistance = config.botSenseRadius;
    for (final pellet in _nearbyFood(
      actor.head,
      config.botSenseRadius,
      _droppedMassBuckets,
    )) {
      final distance = actor.head.distanceTo(pellet.position);
      if (distance < nearestDistance) {
        nearest = pellet;
        nearestDistance = distance;
      }
    }
    for (final pellet in _nearbyFood(
      actor.head,
      config.botSenseRadius,
      _pelletBuckets,
    )) {
      final distance = actor.head.distanceTo(pellet.position);
      if (distance < nearestDistance) {
        nearest = pellet;
        nearestDistance = distance;
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

  double _relativeMotionThreat(
    SnakeState actor,
    SnakeState other, {
    required Vec2 actorPosition,
    required Vec2 otherPosition,
    required double separation,
    Vec2? actorDirection,
    double? actorSpeed,
    Vec2? otherDirection,
    double? otherSpeed,
  }) {
    final direction = actorDirection ?? actor.heading;
    final peerDirection = otherDirection ?? other.heading;
    final speed = actorSpeed ?? _effectiveSpeed(actor);
    final peerSpeed = otherSpeed ?? _effectiveSpeed(other);
    if (direction.length == 0 || separation <= 0) return 1;

    final offsetX = otherPosition.x - actorPosition.x;
    final offsetY = otherPosition.y - actorPosition.y;
    final relativeVelocityX = direction.x * speed - peerDirection.x * peerSpeed;
    final relativeVelocityY = direction.y * speed - peerDirection.y * peerSpeed;
    final closingRatio =
        ((relativeVelocityX * offsetX + relativeVelocityY * offsetY) /
                (separation * math.max(1.0, speed + peerSpeed)))
            .clamp(0.0, 1.0)
            .toDouble();
    final headingAlignment = _alignment(direction, peerDirection);
    final tightParallelAlignment =
        math.max(config.botParallelAlignmentThreshold, 0.96).toDouble();
    if (headingAlignment >= tightParallelAlignment) {
      final routeDirection = direction.normalized();
      final lateralSeparation =
          (offsetX * routeDirection.y - offsetY * routeDirection.x).abs();
      final lethalClearance = (actor.radius + other.radius) *
          config.collisionCoreScale.clamp(0.0, 1.0).toDouble();
      if (lateralSeparation >= lethalClearance) return 0;
    }
    if (headingAlignment >= config.botParallelAlignmentThreshold &&
        closingRatio <= config.botParallelClosingThreshold) {
      return 0;
    }
    final crossingThreat =
        ((1 - headingAlignment) * 0.5).clamp(0.0, 1.0).toDouble();
    return math.max(closingRatio, crossingThreat * 0.82).toDouble();
  }

  void _recordTelegraphEvent(SnakeState actor, TelegraphEventKind kind) {
    final captureKind = switch (kind) {
      TelegraphEventKind.sprintAnticipation =>
        SimulationEventKind.sprintAnticipation,
      TelegraphEventKind.sprintStarted => SimulationEventKind.sprintStarted,
      TelegraphEventKind.sprintEnded => SimulationEventKind.sprintEnded,
    };
    _emitCaptureEvent(captureKind, actorId: actor.id);
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
    snake.previousHead = currentHead;
    final distance = _effectiveSpeed(snake) * dt;
    final nextHead = Vec2(
      currentHead.x + snake.heading.x * distance,
      currentHead.y + snake.heading.y * distance,
    );
    final hasMoved = distance > 0;
    if (hasMoved) {
      final travelled = distance.abs();
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
    final previousBodyLength = snake.body.length;
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

    final trail = snake.movementTrail;
    var trailIndex = trail.length - 1;
    var travelled = 0.0;
    final pointPool =
        _bodyPointPools.putIfAbsent(snake.id, () => <_MutableBodyPoint>[]);

    void sampleInto(
      double distance,
      _MutableBodyPoint target, {
      required bool snapPrevious,
    }) {
      while (trailIndex > 0) {
        final start = trail[trailIndex];
        final end = trail[trailIndex - 1];
        final deltaX = end.x - start.x;
        final deltaY = end.y - start.y;
        final segmentLength = math.sqrt(deltaX * deltaX + deltaY * deltaY);
        if (segmentLength == 0) {
          trailIndex--;
          continue;
        }
        if (travelled + segmentLength >= distance) {
          final fraction = (distance - travelled) / segmentLength;
          target.setCoordinates(
            start.x + deltaX * fraction,
            start.y + deltaY * fraction,
            preservePrevious: !snapPrevious,
          );
          return;
        }
        travelled += segmentLength;
        trailIndex--;
      }

      final last = trail.first;
      if (trail.length < 2) {
        target.setCoordinates(
          last.x,
          last.y,
          preservePrevious: !snapPrevious,
        );
        return;
      }
      final directionX = last.x - trail[1].x;
      final directionY = last.y - trail[1].y;
      final directionLength =
          math.sqrt(directionX * directionX + directionY * directionY);
      final remaining = distance - travelled;
      if (directionLength == 0) {
        target.setCoordinates(
          last.x - snake.heading.x * remaining,
          last.y - snake.heading.y * remaining,
          preservePrevious: !snapPrevious,
        );
      } else {
        target.setCoordinates(
          last.x + directionX / directionLength * remaining,
          last.y + directionY / directionLength * remaining,
          preservePrevious: !snapPrevious,
        );
      }
    }

    final targetLength =
        fullLength + (extension > 0.0001 && fullLength > 0 ? 1 : 0);
    if (snake.body.length > targetLength) {
      snake.body.removeRange(targetLength, snake.body.length);
    }
    if (targetLength == 0) {
      snake.body.clear();
      snake.rebuildBodyChunks();
      return;
    }
    snake.body[0] = trail.last;
    for (var index = 1; index < targetLength; index++) {
      final poolIndex = index - 1;
      if (poolIndex == pointPool.length) {
        pointPool.add(_MutableBodyPoint(0, 0));
      }
      final target = pointPool[poolIndex];
      final distance = index < fullLength
          ? index * snake.segmentSpacing
          : (fullLength - 1) * snake.segmentSpacing + extension;
      sampleInto(
        distance,
        target,
        snapPrevious: index >= previousBodyLength,
      );
      if (index < snake.body.length) {
        snake.body[index] = target;
      } else {
        snake.body.add(target);
      }
    }
    snake.rebuildBodyChunks();
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
      final position = snake.shedMass(minimumLength: minimumLength);
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
    final index = source == droppedMass ? _droppedMassBuckets : _pelletBuckets;
    final candidates = _nearbyFood(snake.head, snake.radius + 6, index);
    for (final pellet in candidates) {
      if (snake.head.distanceTo(pellet.position) <= snake.radius + 6) {
        if (!source.remove(pellet)) continue;
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
        _emitCaptureEvent(
          SimulationEventKind.foodCollected,
          actorId: snake.id,
          targetId: pellet.kind.name,
          value: pellet.value.toDouble(),
        );
        if (growth > 0) {
          _emitCaptureEvent(
            SimulationEventKind.growth,
            actorId: snake.id,
            value: growth.toDouble(),
            detail: pellet.kind.name,
          );
        }
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
    final coreScale = config.collisionCoreScale.clamp(0.0, 1.0).toDouble();
    final minimumTaper = config.collisionTailTaper.clamp(0.0, 1.0).toDouble();
    for (final snake in snakes.where((item) => item.alive)) {
      final headRadius = snake.radius * coreScale;
      final searchRadius = snake.radius +
          snakes.fold<double>(
            0,
            (maximum, other) => math.max(maximum, other.radius).toDouble(),
          );
      for (final sample in _nearbyBodySamples(snake.head, searchRadius)) {
        final other = sample.owner;
        if (other.id == snake.id || !other.alive || sample.index < 2) {
          continue;
        }
        final bodyTaper = (1 - sample.index / (other.body.length * 1.5))
            .clamp(minimumTaper, 1.0)
            .toDouble();
        final lethalDistance =
            headRadius + other.radius * coreScale * bodyTaper;
        if (snake.head.distanceTo(sample.position) < lethalDistance) {
          if (snake.kind == SnakeKind.bot && other.kind == SnakeKind.bot) {
            botPeerCollisionDeaths++;
          }
          _defeat(
            snake,
            GameOverReason.bodyCollision,
            targetId: other.id,
          );
          break;
        }
      }
    }
  }

  void _defeat(
    SnakeState snake,
    GameOverReason reason, {
    String? targetId,
  }) {
    if (!snake.alive) return;
    if (reason == GameOverReason.bodyCollision) {
      _emitCaptureEvent(
        SimulationEventKind.collision,
        actorId: snake.id,
        targetId: targetId,
        detail: reason.name,
      );
    }
    _emitCaptureEvent(
      SimulationEventKind.defeat,
      actorId: snake.id,
      targetId: targetId,
      detail: reason.name,
    );
    if (snake.kind == SnakeKind.player) {
      _emitCaptureEvent(
        SimulationEventKind.runEnded,
        actorId: snake.id,
        targetId: targetId,
        value: score.toDouble(),
        detail: reason.name,
        metadata: <String, Object?>{
          'score': score,
          'length': snake.length,
          'survivalSeconds': elapsed,
          'simulationElapsedSeconds':
              _currentSimulationTick * config.simulationStep,
          'rank': _rankForLength(snake.length),
        },
      );
    }
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
      _botHunters.remove(snake.id);
      _botOpportunityRoles.remove(snake.id);
      _botResourceRoles.remove(snake.id);
      _botYieldingTo.remove(snake.id);
      _botYieldingTo.removeWhere((_, ownerId) => ownerId == snake.id);
      _botRespawnTimers[snake.id] = config.botRespawnDelay;
    }
    if (reason == GameOverReason.bodyCollision) {
      for (var index = 0; index < snake.body.length; index += 3) {
        final position = snake.body[index];
        _addDroppedMass(
          FoodPellet(
            position: Vec2(position.x, position.y),
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
    _droppedMassLimitDirty = true;
  }

  void _advanceDroppedMass(double dt) {
    if (droppedMass.isEmpty) return;
    if (config.maxDroppedMass <= 0) {
      droppedMass.clear();
      _droppedMassAges.clear();
      _droppedMassClusters.clear();
      _droppedMassLimitDirty = false;
      return;
    }

    if (config.droppedMassLifetime > 0) {
      for (final pellet in droppedMass) {
        _droppedMassAges[pellet] = (_droppedMassAges[pellet] ?? 0) + dt;
      }
      droppedMass.removeWhere((pellet) {
        final expired =
            (_droppedMassAges[pellet] ?? 0) >= config.droppedMassLifetime;
        if (expired) _droppedMassAges.remove(pellet);
        return expired;
      });
    }
    if (droppedMass.length > config.maxDroppedMass) {
      _droppedMassLimitDirty = true;
    }
  }

  void _enforceDroppedMassLimit() {
    if (!_droppedMassLimitDirty &&
        droppedMass.length <= config.maxDroppedMass) {
      return;
    }
    _droppedMassLimitDirty = false;
    if (droppedMass.length <= config.maxDroppedMass ||
        config.maxDroppedMass <= 0) {
      return;
    }
    lastDroppedMassMergeCount++;
    final radius = math.max(1.0, config.droppedMassMergeRadius);
    for (final bucket in _droppedMassMergeBuckets.values) {
      bucket.clear();
    }
    for (var index = 0; index < droppedMass.length; index++) {
      final pellet = droppedMass[index];
      final bucketX = (pellet.position.x / radius).floor();
      final bucketY = (pellet.position.y / radius).floor();
      final key = _spatialKey(bucketX, bucketY);
      final bucket = _droppedMassMergeBuckets[key] ??= <int>[];
      bucket.add(index);
    }

    while (_droppedMassMergeUsed.length < droppedMass.length) {
      _droppedMassMergeUsed.add(false);
    }
    for (var index = 0; index < droppedMass.length; index++) {
      _droppedMassMergeUsed[index] = false;
    }
    _droppedMassMergeOutput.clear();
    var mergesRemaining = droppedMass.length - config.maxDroppedMass;
    for (var index = 0; index < droppedMass.length; index++) {
      if (_droppedMassMergeUsed[index]) continue;
      final pellet = droppedMass[index];
      int? bestIndex;
      var bestDistanceSquared = double.infinity;
      final bucketX = (pellet.position.x / radius).floor();
      final bucketY = (pellet.position.y / radius).floor();
      for (var offsetX = -1; offsetX <= 1; offsetX++) {
        for (var offsetY = -1; offsetY <= 1; offsetY++) {
          final candidates = _droppedMassMergeBuckets[
              _spatialKey(bucketX + offsetX, bucketY + offsetY)];
          if (candidates == null) continue;
          for (final candidateIndex in candidates) {
            if (candidateIndex <= index ||
                _droppedMassMergeUsed[candidateIndex]) {
              continue;
            }
            final candidate = droppedMass[candidateIndex];
            final deltaX = pellet.position.x - candidate.position.x;
            final deltaY = pellet.position.y - candidate.position.y;
            final distanceSquared = deltaX * deltaX + deltaY * deltaY;
            if (distanceSquared < bestDistanceSquared) {
              bestDistanceSquared = distanceSquared;
              bestIndex = candidateIndex;
            }
          }
        }
      }
      if (mergesRemaining > 0 && bestIndex != null) {
        _droppedMassMergeUsed[index] = true;
        _droppedMassMergeUsed[bestIndex] = true;
        _droppedMassMergeOutput.add(
          _mergeDroppedMass(pellet, droppedMass[bestIndex]),
        );
        mergesRemaining--;
      } else {
        _droppedMassMergeUsed[index] = true;
        _droppedMassMergeOutput.add(pellet);
      }
    }

    // Extremely sparse fields may not contain enough neighbouring pairs.
    // Preserve the existing fallback semantics without repeating an O(n)
    // nearest-pair search for every single excess dot.
    while (_droppedMassMergeOutput.length > config.maxDroppedMass) {
      final right = _droppedMassMergeOutput.removeLast();
      final left = _droppedMassMergeOutput.removeLast();
      _droppedMassMergeOutput.add(_mergeDroppedMass(left, right));
    }
    droppedMass
      ..clear()
      ..addAll(_droppedMassMergeOutput);
  }

  FoodPellet _mergeDroppedMass(FoodPellet left, FoodPellet right) {
    final combinedValue = left.value + right.value;
    final weight = math.max(1, combinedValue).toDouble();
    final merged = FoodPellet(
      position: Vec2(
        (left.position.x * left.value + right.position.x * right.value) /
            weight,
        (left.position.y * left.value + right.position.y * right.value) /
            weight,
      ),
      value: combinedValue,
      kind: left.kind == FoodPelletKind.defeatDrop ||
              right.kind == FoodPelletKind.defeatDrop
          ? FoodPelletKind.defeatDrop
          : FoodPelletKind.sprintDrop,
      sourceColorIndex: left.sourceColorIndex ?? right.sourceColorIndex,
    );
    final mergedAge = math
        .max(
          _droppedMassAges[left] ?? 0,
          _droppedMassAges[right] ?? 0,
        )
        .toDouble();
    _droppedMassAges.remove(left);
    _droppedMassAges.remove(right);
    _droppedMassAges[merged] = mergedAge;
    return merged;
  }

  void _rebuildDroppedMassClusters() {
    _droppedMassClusters.clear();
    if (droppedMass.isEmpty) return;

    final bucketSize = math.max(1.0, config.botDroppedMassClusterRadius);
    for (final bucket in _droppedMassClusterBuckets.values) {
      bucket.reset();
    }
    for (final pellet in droppedMass) {
      final bucketX = (pellet.position.x / bucketSize).floor();
      final bucketY = (pellet.position.y / bucketSize).floor();
      final key = _spatialKey(bucketX, bucketY);
      final bucket = _droppedMassClusterBuckets[key] ??= _DroppedMassBucket();
      bucket.value += pellet.value;
      bucket.count++;
      bucket.weightedX += pellet.position.x * pellet.value;
      bucket.weightedY += pellet.position.y * pellet.value;
    }

    for (final bucket in _droppedMassClusterBuckets.values) {
      if (bucket.count == 0) continue;
      final value = math.max(1, bucket.value);
      final center = Vec2(bucket.weightedX / value, bucket.weightedY / value);
      final clusterIndex = _droppedMassClusters.length;
      if (clusterIndex < _droppedMassClusterPool.length) {
        final cluster = _droppedMassClusterPool[clusterIndex];
        cluster.update(
          center: center,
          value: bucket.value,
          radius: config.botDroppedMassClusterRadius,
          memberCount: bucket.count,
        );
        _droppedMassClusters.add(cluster);
      } else {
        final cluster = _DroppedMassCluster(
          center: Vec2(bucket.weightedX / value, bucket.weightedY / value),
          value: bucket.value,
          radius: config.botDroppedMassClusterRadius,
          memberCount: bucket.count,
        );
        _droppedMassClusterPool.add(cluster);
        _droppedMassClusters.add(cluster);
      }
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
        _botEngagementStates.remove(id);
        _botManeuvers.remove(id);
        _botFormationRoles.remove(id);
        _botPlans.remove(id);
        _botSafetyHolds.remove(id);
        _botSafetyEscapes.remove(id);
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
        speedMultiplier: 1.0,
      ),
      _BotProfile(
        disposition: BotDisposition.wanderer,
        lengthBonus: 4,
        speedMultiplier: 1.0,
      ),
      _BotProfile(
        disposition: BotDisposition.defensive,
        lengthBonus: 18,
        speedMultiplier: 1.0,
      ),
      _BotProfile(
        disposition: BotDisposition.aggressive,
        lengthBonus: 36,
        speedMultiplier: 1.0,
      ),
      _BotProfile(
        disposition: BotDisposition.opportunistic,
        lengthBonus: 12,
        speedMultiplier: 1.0,
      ),
      _BotProfile(
        disposition: BotDisposition.defensive,
        lengthBonus: 58,
        speedMultiplier: 1.0,
      ),
      _BotProfile(
        disposition: BotDisposition.aggressive,
        lengthBonus: 2,
        speedMultiplier: 1.0,
      ),
      _BotProfile(
        disposition: BotDisposition.opportunistic,
        lengthBonus: 44,
        speedMultiplier: 1.0,
      ),
    ];
    return profiles[index % profiles.length];
  }

  Vec2 _findBotSpawnPosition(SnakeState bot) {
    final spawnRadius =
        math.max(0.0, config.arenaRadius - config.botBoundaryBuffer).toDouble();
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
          clearance = math.min(clearance, candidateSegment.distanceTo(segment));
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
        .min(config.arenaRadius, maxRadius ?? config.arenaRadius)
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
