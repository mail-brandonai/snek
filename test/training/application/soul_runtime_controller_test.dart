import 'package:flutter_test/flutter_test.dart';

import 'package:slither/game/domain/game_state.dart';
import 'package:slither/game/domain/simulation.dart';
import 'package:slither/training/application/soul_player_observations.dart';
import 'package:slither/game/domain/vec2.dart';

void main() {
  test('GameSimulation exposes public player food observations', () {
    final simulation = GameSimulation(
      config: const SimulationConfig(initialPellets: 0, botCount: 0),
    );
    simulation.pellets.add(
      const FoodPellet(position: Vec2(80, 0)),
    );
    simulation.droppedMass.add(
      const FoodPellet(
        position: Vec2(0, 120),
        kind: FoodPelletKind.sprintDrop,
      ),
    );

    simulation.update(1 / 60, Vec2.zero);

    expect(simulation.nearbyPlayerNaturalFoodCount, 1);
    expect(simulation.nearbyPlayerDroppedMassCount, 1);
    expect(simulation.nearestPlayerFoodDirection.x, closeTo(1, 0.000001));
    expect(simulation.nearestPlayerFoodDirection.y, closeTo(0, 0.000001));
  });
}
