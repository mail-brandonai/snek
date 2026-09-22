enum ActorRole { player, opponent }

enum ControllerSource { human, builtin, soul }

class ActorObservation {
  const ActorObservation({
    required this.tick,
    required this.headingX,
    required this.headingY,
    required this.nearestThreatDistance,
    required this.nearbyThreatCount,
    required this.nearbyPelletCount,
    required this.bodyLength,
    required this.pressured,
    this.nearestThreatDirectionX = 0,
    this.nearestThreatDirectionY = 0,
    this.nearestPelletDirectionX = 0,
    this.nearestPelletDirectionY = 0,
  });

  final int tick;
  final double headingX;
  final double headingY;
  final double? nearestThreatDistance;
  final int nearbyThreatCount;
  final int nearbyPelletCount;
  final int bodyLength;
  final bool pressured;

  /// Direction toward the nearest public threat, when one is available.
  final double nearestThreatDirectionX;
  final double nearestThreatDirectionY;

  /// Direction toward the nearest public pellet, when one is available.
  final double nearestPelletDirectionX;
  final double nearestPelletDirectionY;
}

class ActorCommand {
  const ActorCommand({
    required this.steeringX,
    required this.steeringY,
    required this.sprinting,
  });

  final double steeringX;
  final double steeringY;
  final bool sprinting;
}

abstract interface class SnekController {
  ActorCommand decide(ActorObservation observation);
}
