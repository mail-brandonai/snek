import 'package:flutter_test/flutter_test.dart';

import 'package:slither/game/domain/game_state.dart';
import 'package:slither/game/domain/simulation.dart';
import 'package:slither/game/domain/vec2.dart';

void main() {
  group('Vec2', () {
    test('supports basic vector arithmetic', () {
      expect(const Vec2(2, 3) + const Vec2(4, -1), const Vec2(6, 2));
      expect((const Vec2(3, 4)).length, 5);
      expect(const Vec2(0, 0).normalized(), Vec2.zero);
    });
  });

  group('GameSimulation', () {
    test('reset creates a player, configured bots, and pellets', () {
      final simulation = GameSimulation(
        config: const SimulationConfig(botCount: 2, initialPellets: 10),
      );

      expect(simulation.snakes.length, 3);
      expect(simulation.player.kind, SnakeKind.player);
      expect(simulation.pellets.length, 10);
      expect(simulation.gameOver, isFalse);
    });

    test('collecting a pellet increases score and length', () {
      final simulation = GameSimulation(
        config: const SimulationConfig(
          botCount: 0,
          initialPellets: 0,
          playerSpeed: 0,
        ),
      );
      final initialLength = simulation.player.length;
      simulation.pellets.add(
        FoodPellet(position: simulation.player.head, value: 3),
      );

      simulation.update(1 / 60, Vec2.zero);

      expect(simulation.score, 3);
      expect(simulation.player.length, initialLength + 3);
      expect(simulation.pellets, isEmpty);
    });

    test('leaving the arena ends the player run', () {
      final simulation = GameSimulation(
        config: const SimulationConfig(
          arenaRadius: 20,
          botCount: 0,
          initialPellets: 0,
          playerSpeed: 1000,
        ),
      );

      simulation.update(1, Vec2(1, 0));

      expect(simulation.gameOver, isTrue);
      expect(simulation.player.alive, isFalse);
    });

    test('hitting another snake body ends the player run and drops mass', () {
      final simulation = GameSimulation(
        config: const SimulationConfig(
          botCount: 1,
          initialPellets: 0,
          playerSpeed: 0,
          botSpeed: 0,
        ),
      );
      final bot = simulation.snakes[1];
      bot.body[1] = simulation.player.head;

      simulation.update(1 / 60, Vec2.zero);

      expect(simulation.gameOver, isTrue);
      expect(simulation.droppedMass, isNotEmpty);
    });

    test('a bot hitting the player body is defeated without ending the run', () {
      final simulation = GameSimulation(
        config: const SimulationConfig(
          botCount: 1,
          initialPellets: 0,
          playerSpeed: 0,
          botSpeed: 0,
        ),
      );
      final bot = simulation.snakes[1];
      simulation.player.body[8] = bot.head;

      simulation.update(1 / 60, Vec2.zero);

      expect(bot.alive, isFalse);
      expect(simulation.player.alive, isTrue);
      expect(simulation.gameOver, isFalse);
      expect(simulation.droppedMass, isNotEmpty);
    });

    test('the player can collect dropped mass', () {
      final simulation = GameSimulation(
        config: const SimulationConfig(
          botCount: 0,
          initialPellets: 0,
          playerSpeed: 0,
        ),
      );
      final initialLength = simulation.player.length;
      simulation.droppedMass.add(
        FoodPellet(position: simulation.player.head, value: 2),
      );

      simulation.update(1 / 60, Vec2.zero);

      expect(simulation.score, 2);
      expect(simulation.player.length, initialLength + 2);
      expect(simulation.droppedMass, isEmpty);
    });

    test('restart reproduces the seeded opening state', () {
      final simulation = GameSimulation(
        config: const SimulationConfig(botCount: 1, initialPellets: 4),
        seed: 42,
      );
      final initialBotPosition = simulation.snakes[1].head;
      final initialPelletPositions = simulation.pellets.toList();

      simulation.update(1, Vec2(1, 0));
      simulation.restart();

      expect(simulation.snakes[1].head, initialBotPosition);
      expect(simulation.pellets.length, initialPelletPositions.length);
      for (var index = 0; index < simulation.pellets.length; index++) {
        expect(
          simulation.pellets[index].position,
          initialPelletPositions[index].position,
        );
      }
    });

    test('restart restores a playable state', () {
      final simulation = GameSimulation(
        config: const SimulationConfig(
          botCount: 0,
          initialPellets: 0,
          arenaRadius: 20,
          playerSpeed: 1000,
        ),
      );
      simulation.update(1, Vec2(1, 0));
      simulation.restart();

      expect(simulation.gameOver, isFalse);
      expect(simulation.player.alive, isTrue);
      expect(simulation.score, 0);
    });
  });
}
