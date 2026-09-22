enum SimulationEventKind {
  runStarted,
  foodCollected,
  growth,
  sprintRequested,
  sprintAnticipation,
  sprintStarted,
  sprintEnded,
  botPressureStarted,
  botPressureEscalated,
  botPressureEnded,
  botRoleChanged,
  botManeuverChanged,
  collision,
  defeat,
  runEnded,
  abandoned,
  elapsedTimeDiscarded,
}

class SimulationControlSample {
  const SimulationControlSample({
    required this.tick,
    required this.steeringX,
    required this.steeringY,
    required this.sprintRequested,
  });

  final int tick;
  final double steeringX;
  final double steeringY;
  final bool sprintRequested;

  Map<String, Object?> toJson() => <String, Object?>{
        'tick': tick,
        'steeringX': steeringX,
        'steeringY': steeringY,
        'sprintRequested': sprintRequested,
      };
}

class SimulationActorSnapshot {
  const SimulationActorSnapshot({
    required this.actorId,
    required this.role,
    required this.positionX,
    required this.positionY,
    required this.headingX,
    required this.headingY,
    required this.length,
    required this.sprintRequested,
    required this.sprinting,
    required this.intent,
    this.maneuver,
    this.maneuverPhase,
  });

  final String actorId;
  final String role;
  final double positionX;
  final double positionY;
  final double headingX;
  final double headingY;
  final int length;
  final bool sprintRequested;
  final bool sprinting;
  final String intent;
  final String? maneuver;
  final String? maneuverPhase;

  Map<String, Object?> toJson() => <String, Object?>{
        'actorId': actorId,
        'role': role,
        'positionX': positionX,
        'positionY': positionY,
        'headingX': headingX,
        'headingY': headingY,
        'length': length,
        'sprintRequested': sprintRequested,
        'sprinting': sprinting,
        'intent': intent,
        'maneuver': maneuver,
        'maneuverPhase': maneuverPhase,
      };
}

class SimulationObservationSnapshot {
  SimulationObservationSnapshot({
    required this.tick,
    required this.elapsedSeconds,
    required this.playerPositionX,
    required this.playerPositionY,
    required this.playerHeadingX,
    required this.playerHeadingY,
    required this.playerLength,
    required this.playerSprinting,
    required this.nearestThreatDistance,
    required this.nearbyThreatCount,
    required this.nearbyNaturalFoodCount,
    required this.nearbyDroppedMassCount,
    required this.boundaryRisk,
    required List<SimulationActorSnapshot> actors,
  }) : actors = List<SimulationActorSnapshot>.unmodifiable(actors);

  final int tick;
  final double elapsedSeconds;
  final double playerPositionX;
  final double playerPositionY;
  final double playerHeadingX;
  final double playerHeadingY;
  final int playerLength;
  final bool playerSprinting;
  final double? nearestThreatDistance;
  final int nearbyThreatCount;
  final int nearbyNaturalFoodCount;
  final int nearbyDroppedMassCount;
  final double boundaryRisk;
  final List<SimulationActorSnapshot> actors;

  Map<String, Object?> toJson() => <String, Object?>{
        'tick': tick,
        'elapsedSeconds': elapsedSeconds,
        'playerPositionX': playerPositionX,
        'playerPositionY': playerPositionY,
        'playerHeadingX': playerHeadingX,
        'playerHeadingY': playerHeadingY,
        'playerLength': playerLength,
        'playerSprinting': playerSprinting,
        'nearestThreatDistance': nearestThreatDistance,
        'nearbyThreatCount': nearbyThreatCount,
        'nearbyNaturalFoodCount': nearbyNaturalFoodCount,
        'nearbyDroppedMassCount': nearbyDroppedMassCount,
        'boundaryRisk': boundaryRisk,
        'actors': actors.map((actor) => actor.toJson()).toList(growable: false),
      };
}

class SimulationEventSnapshot {
  const SimulationEventSnapshot({
    required this.tick,
    required this.kind,
    required this.actorId,
    this.targetId,
    this.value,
    this.detail,
    this.metadata,
  });

  final int tick;
  final SimulationEventKind kind;
  final String actorId;
  final String? targetId;
  final double? value;
  final String? detail;
  final Map<String, Object?>? metadata;

  Map<String, Object?> toJson() => <String, Object?>{
        'tick': tick,
        'kind': kind.name,
        'actorId': actorId,
        'targetId': targetId,
        'value': value,
        'detail': detail,
        'metadata': metadata,
      };
}

/// Optional capability used to keep tactical interpretation out of the
/// gameplay recorder. Live runs record inputs and replayable observations;
/// review workers opt back in when reconstructing tactical events.
abstract interface class TacticalAnalysisCaptureSink {
  bool get captureTacticalAnalysis;
}

abstract interface class SimulationCaptureSink {
  void recordControl(SimulationControlSample sample);
  void recordObservation(SimulationObservationSnapshot observation);
  void completeStep(int tick);
  void recordEvent(SimulationEventSnapshot event);
}
