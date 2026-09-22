import '../../game/domain/game_state.dart';
import '../../game/domain/simulation.dart';
import '../../game/domain/vec2.dart';

extension SoulPlayerObservations on GameSimulation {
  int get nearbyPlayerNaturalFoodCount =>
      _countNearbyFood(pellets, player.head);

  int get nearbyPlayerDroppedMassCount =>
      _countNearbyFood(droppedMass, player.head);

  Vec2 get nearestPlayerFoodDirection {
    final origin = player.head;
    final radius = config.botSenseRadius;
    FoodPellet? nearest;
    var nearestDistance = radius;

    for (final pellet in droppedMass) {
      final distance = origin.distanceTo(pellet.position);
      if (distance < nearestDistance) {
        nearest = pellet;
        nearestDistance = distance;
      }
    }
    for (final pellet in pellets) {
      final distance = origin.distanceTo(pellet.position);
      if (distance < nearestDistance) {
        nearest = pellet;
        nearestDistance = distance;
      }
    }

    return nearest == null
        ? Vec2.zero
        : (nearest.position - origin).normalized();
  }
}

int _countNearbyFood(List<FoodPellet> source, Vec2 origin) {
  const radius = 320.0;
  var count = 0;
  for (final pellet in source) {
    if (origin.distanceTo(pellet.position) <= radius) count++;
  }
  return count;
}
