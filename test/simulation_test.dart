import 'package:flutter_test/flutter_test.dart';

import 'package:slither/game/domain/game_state.dart';
import 'package:slither/game/domain/minimap.dart';
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
      expect(
        simulation.player.length,
        simulation.config.minimumSprintLength,
      );
      expect(
        simulation.player.body.length,
        simulation.config.minimumSprintLength,
      );
      expect(simulation.pellets.length, 10);
      expect(simulation.gameOver, isFalse);
      for (final bot in simulation.snakes.skip(1)) {
        expect(
          bot.head.length,
          lessThanOrEqualTo(simulation.config.botSpawnRadius),
        );
      }
    });

    test('player rank reflects longer living snakes', () {
      final simulation = GameSimulation(
        config: const SimulationConfig(
          botCount: 1,
          initialPellets: 0,
        ),
      );
      final bot = simulation.snakes[1];
      bot.grow(10);

      expect(simulation.playerRank, 2);

      bot.alive = false;
      expect(simulation.playerRank, 1);
    });

    test('leaderboard returns the five longest living snakes in rank order',
        () {
      final simulation = GameSimulation(
        config: const SimulationConfig(
          botCount: 6,
          initialPellets: 0,
        ),
      );
      simulation.player.grow(40);
      for (var index = 0; index < 6; index++) {
        simulation.snakes[index + 1].grow(index * 3);
      }

      final leaderboard = simulation.leaderboard;

      expect(leaderboard, hasLength(5));
      expect(leaderboard.map((entry) => entry.rank), [1, 2, 3, 4, 5]);
      expect(
        leaderboard.map((entry) => entry.length.toDouble()).toList(),
        <double>[44, 37, 32, 27, 22],
      );
      expect(leaderboard.first.isPlayer, isTrue);
      expect(leaderboard.where((entry) => entry.isPlayer), hasLength(1));
    });

    test('defeated bots respawn after a delay at a safe position', () {
      const config = SimulationConfig(
        arenaRadius: 1000,
        botBoundaryBuffer: 100,
        botCount: 1,
        initialPellets: 0,
        playerSpeed: 0,
        botSpeed: 0,
        botRespawnDelay: 0.2,
        botRespawnSafeDistance: 180,
      );
      final simulation = GameSimulation(config: config, seed: 19);
      final bot = simulation.snakes[1];
      simulation.player.body[3] = bot.head;

      simulation.update(1 / 60, Vec2.zero);
      expect(bot.alive, isFalse);

      simulation.update(0.1, Vec2.zero);
      expect(bot.alive, isFalse);

      simulation.update(0.11, Vec2.zero);
      expect(bot.alive, isTrue);
      final firstRespawnPosition = bot.head;
      for (final playerSegment in simulation.player.body) {
        for (final botSegment in bot.body) {
          expect(
            botSegment.distanceTo(playerSegment),
            greaterThanOrEqualTo(config.botRespawnSafeDistance),
          );
        }
      }

      simulation.restart();
      final restartedBot = simulation.snakes[1];
      simulation.player.body[3] = restartedBot.head;
      simulation.update(1 / 60, Vec2.zero);
      simulation.update(0.21, Vec2.zero);

      expect(restartedBot.alive, isTrue);
      expect(restartedBot.head, firstRespawnPosition);
    });

    test('bot population grows one snake at a time and stops at its cap', () {
      const config = SimulationConfig(
        arenaRadius: 2000,
        botCount: 1,
        maxBotCount: 3,
        botPopulationInterval: 0.5,
        initialPellets: 0,
        playerSpeed: 0,
        botSpeed: 0,
      );
      final simulation = GameSimulation(config: config, seed: 31);

      expect(simulation.totalBotCount, 1);
      expect(simulation.livingBotCount, 1);

      simulation.update(0.49, Vec2.zero);
      expect(simulation.totalBotCount, 1);

      simulation.update(0.02, Vec2.zero);
      expect(simulation.totalBotCount, 2);
      expect(simulation.livingBotCount, 2);

      simulation.update(1.0, Vec2.zero);
      expect(simulation.totalBotCount, 3);
      expect(simulation.livingBotCount, 3);

      simulation.update(2.0, Vec2.zero);
      expect(simulation.totalBotCount, 3);
    });

    test('pellet maintenance refills gradually below the density threshold',
        () {
      const config = SimulationConfig(
        botCount: 0,
        initialPellets: 10,
        pelletRefillThreshold: 0.7,
        pelletRefillRate: 4,
        playerSpeed: 0,
      );
      final simulation = GameSimulation(config: config);
      simulation.pellets.clear();

      simulation.update(0.5, Vec2.zero);
      expect(simulation.pellets.length, 2);
      expect(simulation.pellets.length, lessThan(config.initialPellets));

      simulation.update(0.5, Vec2.zero);
      expect(simulation.pellets.length, 4);
      expect(simulation.pellets.length, lessThanOrEqualTo(7));
    });

    test('defeat captures final run statistics', () {
      final simulation = GameSimulation(
        config: const SimulationConfig(
          arenaRadius: 20,
          botCount: 0,
          initialPellets: 0,
          playerSpeed: 1000,
        ),
      );

      simulation.update(0.2, const Vec2(1, 0));

      expect(simulation.finalStats, isNotNull);
      expect(simulation.finalStats!.score, simulation.score);
      expect(
          simulation.finalStats!.length, simulation.config.minimumSprintLength);
      expect(simulation.finalStats!.survivalSeconds, greaterThan(0));
      expect(simulation.finalStats!.rank, 1);
    });

    test('bots turn away from the arena boundary', () {
      final simulation = GameSimulation(
        config: const SimulationConfig(
          arenaRadius: 500,
          botCount: 1,
          initialPellets: 0,
          botSpeed: 0,
        ),
      );
      final bot = simulation.snakes[1];
      bot.body[0] = const Vec2(480, 0);
      bot.heading = const Vec2(1, 0);

      simulation.update(1 / 60, Vec2.zero);

      expect(bot.heading.x, lessThan(1));
    });

    test('nearby bots steer toward an intercept point ahead of the player', () {
      final simulation = GameSimulation(
        config: const SimulationConfig(
          arenaRadius: 2000,
          botCount: 1,
          initialPellets: 0,
          playerSpeed: 100,
          botSpeed: 0,
          botTurnRate: 20,
          botPressureRadius: 800,
          botPressureWeight: 4,
        ),
      );
      final bot = simulation.snakes[1];
      bot.body[0] = const Vec2(0, 300);
      bot.heading = const Vec2(0, 1);
      simulation.player.heading = const Vec2(1, 0);

      simulation.update(0.1, Vec2.zero);

      expect(bot.heading.x, greaterThan(0));
      expect(bot.heading.y, lessThan(1));
    });

    test('bots prioritize nearby dropped mass as a reaction opportunity', () {
      final simulation = GameSimulation(
        config: const SimulationConfig(
          arenaRadius: 2000,
          botCount: 1,
          initialPellets: 0,
          botSpeed: 0,
          botTurnRate: 20,
          botDroppedMassWeight: 6,
        ),
      );
      final bot = simulation.snakes[1];
      bot.body[0] = const Vec2(0, 300);
      bot.heading = const Vec2(0, 1);
      simulation.droppedMass.add(
        const FoodPellet(position: Vec2(0, 0), value: 2),
      );

      simulation.update(0.1, Vec2.zero);

      expect(bot.heading.y, lessThan(1));
      expect(bot.heading.y, greaterThan(-1));
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
      expect(
        simulation.player.length,
        greaterThanOrEqualTo(initialLength + 3),
      );
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

      simulation.update(1, const Vec2(1, 0));

      expect(simulation.gameOver, isTrue);
      expect(simulation.player.alive, isFalse);
      expect(simulation.gameOverReason, GameOverReason.boundary);
      expect(simulation.droppedMass, isNotEmpty);
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
      bot.body[2] = simulation.player.head;

      simulation.update(1 / 60, Vec2.zero);

      expect(simulation.gameOver, isTrue);
      expect(simulation.gameOverReason, GameOverReason.bodyCollision);
      expect(simulation.droppedMass, isNotEmpty);
    });

    test(
      'a bot hitting the player body is defeated without ending the run',
      () {
        final simulation = GameSimulation(
          config: const SimulationConfig(
            botCount: 1,
            initialPellets: 0,
            playerSpeed: 0,
            botSpeed: 0,
          ),
        );
        final bot = simulation.snakes[1];
        simulation.player.body[3] = bot.head;

        simulation.update(1 / 60, Vec2.zero);

        expect(bot.alive, isFalse);
        expect(simulation.player.alive, isTrue);
        expect(simulation.gameOver, isFalse);
        expect(simulation.gameOverReason, isNull);
        expect(simulation.droppedMass, isNotEmpty);
      },
    );

    test('the player can overlap its own body without ending the run', () {
      final simulation = GameSimulation(
        config: const SimulationConfig(
          botCount: 0,
          initialPellets: 0,
          playerSpeed: 0,
        ),
      );
      simulation.player.body[3] = simulation.player.head;

      simulation.update(1 / 60, Vec2.zero);

      expect(simulation.gameOver, isFalse);
      expect(simulation.gameOverReason, isNull);
      expect(simulation.player.alive, isTrue);
    });

    test('body segments follow the head at stable spacing', () {
      final simulation = GameSimulation(
        config: const SimulationConfig(
          botCount: 0,
          initialPellets: 0,
          playerSpeed: 180,
        ),
      );
      final initialTail = simulation.player.body.last;

      simulation.update(1 / 30, const Vec2(1, 0));

      expect(simulation.player.body.last, isNot(initialTail));
      for (var index = 1; index < simulation.player.body.length; index++) {
        expect(
          simulation.player.body[index - 1].distanceTo(
            simulation.player.body[index],
          ),
          closeTo(simulation.config.segmentSpacing, 0.0001),
        );
      }
    });

    test('body follows the travelled head path through a turn', () {
      final simulation = GameSimulation(
        config: const SimulationConfig(
          botCount: 0,
          initialPellets: 0,
          playerSpeed: 180,
        ),
      );

      simulation.update(1 / 30, const Vec2(1, 0));
      final beforeTurn = simulation.player.body[3];
      simulation.update(1 / 30, const Vec2(0, 1));
      final afterTurn = simulation.player.body[3];

      expect(afterTurn, isNot(beforeTurn));
      for (var index = 1; index < simulation.player.body.length; index++) {
        expect(
          simulation.player.body[index - 1].distanceTo(
            simulation.player.body[index],
          ),
          lessThanOrEqualTo(simulation.config.segmentSpacing + 0.0001),
        );
      }
    });

    test('sprint increases speed and sheds mass while held', () {
      const config = SimulationConfig(
        botCount: 0,
        initialPellets: 0,
        playerSpeed: 100,
        sprintMultiplier: 2,
        sprintDrainInterval: 0.2,
      );
      final normal = GameSimulation(config: config);
      final sprinting = GameSimulation(config: config);
      normal.player.grow(4);
      sprinting.player.grow(4);
      final normalLength = normal.player.length;
      final sprintLength = sprinting.player.length;

      normal.update(0.5, const Vec2(1, 0));
      sprinting.update(0.5, const Vec2(1, 0), sprinting: true);

      expect(sprinting.player.head.x, greaterThan(normal.player.head.x));
      expect(sprinting.player.length, lessThan(sprintLength));
      expect(
        sprinting.player.length,
        greaterThanOrEqualTo(config.minimumSprintLength),
      );
      expect(sprinting.droppedMass, isNotEmpty);
      expect(normal.player.length, normalLength);
    });

    test('sprint cannot activate when the player has no mass to shed', () {
      const config = SimulationConfig(
        botCount: 0,
        initialPellets: 0,
        playerSpeed: 100,
        sprintMultiplier: 2,
      );
      final simulation = GameSimulation(config: config);

      simulation.update(0.1, const Vec2(1, 0), sprinting: true);

      expect(simulation.player.length, config.minimumSprintLength);
      expect(simulation.player.sprinting, isFalse);
      expect(simulation.player.head.x, closeTo(10, 0.0001));
      expect(simulation.droppedMass, isEmpty);
    });

    test('sprint disengages immediately after reaching minimum length', () {
      const config = SimulationConfig(
        botCount: 0,
        initialPellets: 0,
        playerSpeed: 100,
        sprintMultiplier: 2,
        sprintDrainInterval: 0.2,
      );
      final simulation = GameSimulation(config: config);
      simulation.player.grow(1);

      simulation.update(0.2, const Vec2(1, 0), sprinting: true);

      expect(simulation.player.length, config.minimumSprintLength);
      expect(simulation.player.sprinting, isFalse);
      expect(simulation.droppedMass, hasLength(1));
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
      expect(
        simulation.player.length,
        greaterThanOrEqualTo(initialLength + 2),
      );
      expect(simulation.droppedMass, isEmpty);
    });

    test('restart reproduces the seeded opening state', () {
      final simulation = GameSimulation(
        config: const SimulationConfig(botCount: 1, initialPellets: 4),
        seed: 42,
      );
      final initialBotPosition = simulation.snakes[1].head;
      final initialPelletPositions = simulation.pellets.toList();

      simulation.update(1, const Vec2(1, 0));
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
      simulation.update(1, const Vec2(1, 0));
      simulation.restart();

      expect(simulation.gameOver, isFalse);
      expect(simulation.gameOverReason, isNull);
      expect(simulation.player.alive, isTrue);
      expect(simulation.score, 0);
    });
  });

  group('MinimapModel', () {
    test('projects arena coordinates into clamped unit coordinates', () {
      expect(
        MinimapModel.project(const Vec2(0, 0), 100),
        const Vec2(0.5, 0.5),
      );
      expect(
        MinimapModel.project(const Vec2(250, -250), 100),
        const Vec2(1, 0),
      );
    });

    test('includes living snakes and excludes defeated snakes', () {
      final simulation = GameSimulation(
        config: const SimulationConfig(botCount: 1, initialPellets: 0),
      );
      simulation.snakes[1].alive = false;

      final markers = MinimapModel.markers(
        snakes: simulation.snakes,
        arenaRadius: simulation.config.arenaRadius,
      );

      expect(markers.map((marker) => marker.id), ['player']);
      expect(markers.single.isPlayer, isTrue);
    });
  });
}
