import 'dart:math' as math;

import '../domain/controller_contract.dart';

/// Applies a Soul revision's normalized trait weights to public observations.
///
/// This policy is deliberately pure: it does not read hidden bot state, mutate
/// the simulation, or decide anything for unbound actors. The Auto-mode gate
/// will provide the observation stream and choose when to invoke it.
class SoulController implements SnekController {
  const SoulController({required this.weights});

  final Map<String, double> weights;

  @override
  ActorCommand decide(ActorObservation observation) {
    final resourceBias = _weight('resourcePriority');
    final threatBias = _weight('riskPosture') + _weight('threatResponse');
    final movementBias = 0.5 + _weight('movementShape');

    var steeringX = observation.headingX * movementBias;
    var steeringY = observation.headingY * movementBias;

    if (observation.nearbyPelletCount > 0) {
      steeringX += observation.nearestPelletDirectionX * resourceBias;
      steeringY += observation.nearestPelletDirectionY * resourceBias;
    }
    if (observation.pressured) {
      steeringX -= observation.nearestThreatDirectionX * threatBias;
      steeringY -= observation.nearestThreatDirectionY * threatBias;
    }

    final magnitude = _length(steeringX, steeringY);
    if (magnitude <= 0) {
      steeringX = observation.headingX;
      steeringY = observation.headingY;
    } else {
      steeringX /= magnitude;
      steeringY /= magnitude;
    }

    final sprinting =
        !observation.pressured &&
        observation.bodyLength > 4 &&
        observation.nearbyPelletCount > 0 &&
        _weight('sprintBehavior') >= 0.35;

    return ActorCommand(
      steeringX: steeringX,
      steeringY: steeringY,
      sprinting: sprinting,
    );
  }

  double _weight(String traitId) =>
      (weights[traitId] ?? 0).clamp(0.0, 1.0).toDouble();

  double _length(double x, double y) => math.sqrt(x * x + y * y);
}
