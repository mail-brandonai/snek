import 'package:flutter_test/flutter_test.dart';

import 'package:slither/game/domain/game_state.dart';
import 'package:slither/game/domain/minimap.dart';
import 'package:slither/game/domain/simulation.dart';
import 'package:slither/game/domain/vec2.dart';

void advanceSimulation(
  GameSimulation simulation,
  double duration,
  Vec2 steering, {
  bool sprinting = false,
}) {
  var remaining = duration;
  while (remaining > 1e-9) {
    final frame = remaining > 1 / 60 ? 1 / 60 : remaining;
    simulation.update(frame, steering, sprinting: sprinting);
    remaining -= frame;
  }
}

void resetSnakeAlongHeading(
  SnakeState snake,
  Vec2 position,
  Vec2 heading,
) {
  snake.resetAt(position);
  final direction = heading.normalized();
  snake.heading = direction;
  for (var index = 0; index < snake.body.length; index++) {
    snake.body[index] = position - direction * (index * snake.segmentSpacing);
  }
  snake.movementTrail
    ..clear()
    ..addAll(snake.body.reversed);
  snake.rebuildBodyChunks();
}

void main() {
  group('Vec2', () {
    test('supports basic vector arithmetic', () {
      expect(const Vec2(2, 3) + const Vec2(4, -1), const Vec2(6, 2));
      expect((const Vec2(3, 4)).length, 5);
      expect(const Vec2(0, 0).normalized(), Vec2.zero);
    });
  });

  group('GameSimulation', () {
    test('default food and sprint balance favours predation', () {
      const config = SimulationConfig();

      expect(config.naturalPelletValue, 1);
      expect(config.sprintDropValue, config.naturalPelletValue);
      expect(config.defeatDropValue, greaterThan(config.sprintDropValue));
      expect(config.sprintDrainInterval, 0.35);
    });

    test('default bots share the player movement capability envelope', () {
      const config = SimulationConfig();

      expect(config.botSpeed, config.playerSpeed);
      expect(config.botTurnRate, 6);
      expect(config.botSprintMultiplier, config.sprintMultiplier);
      expect(config.botSizeSpeedPenalty, 0);

      final simulation = GameSimulation(
        config: const SimulationConfig(botCount: 10, initialPellets: 0),
      );
      expect(
        simulation.snakes
            .where((snake) => snake.kind == SnakeKind.bot)
            .every((bot) => bot.speed == config.playerSpeed),
        isTrue,
      );
    });

    test('bots grow modestly faster from collected food', () {
      const config = SimulationConfig(
        botCount: 1,
        initialPellets: 0,
        playerSpeed: 0,
        botSpeed: 0,
        botGrowthMultiplier: 1.5,
      );
      final simulation = GameSimulation(config: config);
      final bot = simulation.snakes[1];
      final initialLength = bot.length;
      simulation.pellets.add(FoodPellet(position: bot.head, value: 2));

      simulation.update(1 / 60, Vec2.zero);

      expect(bot.length, initialLength + 3);
      expect(simulation.pellets, isEmpty);
    });

    test('reset creates a player, configured bots, and pellets', () {
      final simulation = GameSimulation(
        config: const SimulationConfig(botCount: 2, initialPellets: 10),
      );

      expect(simulation.snakes.length, 3);
      expect(simulation.player.kind, SnakeKind.player);
      expect(simulation.player.length, simulation.config.minimumSprintLength);
      expect(
        simulation.player.body.length,
        simulation.config.minimumSprintLength,
      );
      expect(simulation.pellets.length, 10);
      expect(
        simulation.pellets.every(
          (pellet) => pellet.value == simulation.config.naturalPelletValue,
        ),
        isTrue,
      );
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
        config: const SimulationConfig(botCount: 1, initialPellets: 0),
      );
      final bot = simulation.snakes[1];
      bot.grow(10);

      expect(simulation.playerRank, 2);

      bot.alive = false;
      expect(simulation.playerRank, 1);
    });

    test(
      'leaderboard returns the five longest living snakes in rank order',
      () {
        final simulation = GameSimulation(
          config: const SimulationConfig(botCount: 6, initialPellets: 0),
        );
        simulation.player.grow(88);
        for (var index = 0; index < 6; index++) {
          simulation.snakes[index + 1].grow(index * 3);
        }

        final leaderboard = simulation.leaderboard;

        expect(leaderboard, hasLength(5));
        expect(leaderboard.map((entry) => entry.rank), [1, 2, 3, 4, 5]);
        expect(
          leaderboard.map((entry) => entry.length.toDouble()).toList(),
          <double>[92, 63, 42, 42, 25],
        );
        expect(leaderboard.first.isPlayer, isTrue);
        expect(leaderboard.where((entry) => entry.isPlayer), hasLength(1));
      },
    );

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

      advanceSimulation(simulation, 0.1, Vec2.zero);
      expect(bot.alive, isFalse);

      advanceSimulation(simulation, 0.11, Vec2.zero);
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
      advanceSimulation(simulation, 0.21, Vec2.zero);

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

      advanceSimulation(simulation, 0.49, Vec2.zero);
      expect(simulation.totalBotCount, 1);

      advanceSimulation(simulation, 0.03, Vec2.zero);
      expect(simulation.totalBotCount, 2);
      expect(simulation.livingBotCount, 2);

      advanceSimulation(simulation, 1, Vec2.zero);
      expect(simulation.totalBotCount, 3);
      expect(simulation.livingBotCount, 3);

      advanceSimulation(simulation, 2, Vec2.zero);
      expect(simulation.totalBotCount, 3);
    });

    test('default bot roster varies size and disposition', () {
      final simulation = GameSimulation(
        config: const SimulationConfig(botCount: 6, initialPellets: 0),
      );
      final bots = simulation.snakes.skip(1).toList();

      expect(bots.map((bot) => bot.length).toSet().length, greaterThan(3));
      expect(
        bots.map((bot) => bot.disposition).toSet(),
        containsAll(<BotDisposition>[
          BotDisposition.defensive,
          BotDisposition.aggressive,
          BotDisposition.opportunistic,
          BotDisposition.wanderer,
        ]),
      );
      expect(bots[2].length, greaterThan(bots[0].length));
      expect(bots[5].length, greaterThan(bots[1].length));
    });

    test('bot roster opens with distinct strategic maneuver portfolios', () {
      final simulation = GameSimulation(
        config: const SimulationConfig(
          arenaRadius: 2000,
          botCount: 4,
          initialPellets: 0,
          playerSpeed: 0,
          botSpeed: 0,
          botTurnRate: 20,
        ),
      );

      simulation.update(1 / 60, Vec2.zero);

      final maneuvers = simulation.snakes
          .where((snake) => snake.kind == SnakeKind.bot)
          .map((bot) => simulation.botManeuverName(bot.id))
          .whereType<String>()
          .toSet();
      expect(maneuvers.length, greaterThanOrEqualTo(3));
      expect(maneuvers, contains('constrictor'));
      expect(maneuvers, contains('resourceDenial'));
    });

    test('maneuver phases expire on simulation time between replans', () {
      final simulation = GameSimulation(
        config: const SimulationConfig(
          arenaRadius: 2000,
          botCount: 1,
          initialPellets: 0,
          playerSpeed: 0,
          botSpeed: 0,
          botTurnRate: 20,
          botTacticalDecisionInterval: 0.18,
          botManeuverStageDuration: 0.12,
          botManeuverCommitDuration: 0.16,
          botManeuverRecoveryDuration: 0.1,
        ),
      );
      final bot = simulation.snakes[1];
      final observedPhases = <String>{};
      final observedManeuvers = <String>{};

      for (var frame = 0; frame < 90; frame++) {
        simulation.update(1 / 60, Vec2.zero);
        final phase = simulation.botManeuverPhase(bot.id);
        final maneuver = simulation.botManeuverName(bot.id);
        if (phase != null) observedPhases.add(phase);
        if (maneuver != null) observedManeuvers.add(maneuver);
      }

      expect(observedPhases.length, greaterThanOrEqualTo(3));
      expect(observedManeuvers.length, greaterThanOrEqualTo(2));
    });

    test('bots switch attack side after observing a repeated escape bias', () {
      final simulation = GameSimulation(
        config: const SimulationConfig(
          arenaRadius: 3000,
          botCount: 1,
          initialPellets: 0,
          playerSpeed: 0,
          botSpeed: 0,
          botTurnRate: 20,
          botTacticalDecisionInterval: 0.08,
          botManeuverStageDuration: 0.08,
          botManeuverCommitDuration: 0.1,
          botManeuverRecoveryDuration: 0.08,
        ),
      );
      final bot = simulation.snakes[1];
      simulation.update(1 / 60, Vec2.zero);
      final initialSide = simulation.botManeuverSide(bot.id);
      final observedSides = <double>{if (initialSide != null) initialSide};

      var angle = 0.0;
      for (var frame = 0; frame < 90; frame++) {
        angle += 0.08;
        simulation.player.heading = Vec2.fromAngle(angle);
        simulation.update(1 / 60, Vec2.zero);
        final side = simulation.botManeuverSide(bot.id);
        if (side != null) observedSides.add(side);
      }

      expect(initialSide, isNotNull);
      expect(simulation.observedPlayerEscapeSideBias, greaterThan(0.2));
      expect(observedSides, contains(-1));
      expect(observedSides.length, greaterThanOrEqualTo(2));
    });

    test('large bots enter a one-way retreat state', () {
      final simulation = GameSimulation(
        config: const SimulationConfig(
          arenaRadius: 1000,
          botCount: 1,
          botRetreatLength: 10,
          botSpeed: 0,
          initialPellets: 0,
        ),
      );
      final bot = simulation.snakes[1];

      simulation.update(1 / 60, Vec2.zero);

      expect(bot.retreating, isTrue);
    });

    test('large bots can re-engage while safely inside the arena', () {
      const config = SimulationConfig(
        arenaRadius: 2000,
        botCount: 1,
        initialPellets: 0,
        playerSpeed: 0,
        botSpeed: 100,
        botTurnRate: 20,
        botRetreatLength: 10,
        botEngagementRadius: 1000,
        botEngagementWeight: 8,
      );
      final simulation = GameSimulation(config: config);
      final bot = simulation.snakes[1];
      bot.body[0] = const Vec2(0, 300);
      bot.heading = const Vec2(0, -1);

      simulation.update(0.1, Vec2.zero);

      expect(bot.retreating, isTrue);
      expect(simulation.botPlanMode(bot.id), isNot('retreat'));
      expect(simulation.botManeuverName(bot.id), isNotNull);
    });

    test('bot sprinting follows each disposition objective', () {
      final simulation = GameSimulation(
        config: const SimulationConfig(
          arenaRadius: 2000,
          botCount: 4,
          initialPellets: 0,
          playerSpeed: 0,
          botSpeed: 100,
          botTurnRate: 20,
          botRetreatLength: 200,
          botRetreatBoundaryBuffer: 600,
          botSprintTriggerDistance: 400,
          sprintAnticipationDuration: 0,
        ),
      );
      final defensive = simulation.snakes[1];
      final aggressive = simulation.snakes[2];
      final opportunistic = simulation.snakes[3];
      final wanderer = simulation.snakes[4];
      defensive.resetAt(const Vec2(0, 1500));
      aggressive.resetAt(const Vec2(1500, 0));
      opportunistic.resetAt(const Vec2(0, -1500));
      wanderer.resetAt(const Vec2(-1500, 0));
      for (final bot in <SnakeState>[
        defensive,
        aggressive,
        opportunistic,
        wanderer,
      ]) {
        bot.retreating = true;
      }

      simulation.update(1 / 60, Vec2.zero);

      expect(defensive.sprinting, isTrue);
      expect(aggressive.sprinting, isTrue);
      expect(opportunistic.sprinting, isTrue);
      expect(wanderer.sprinting, isTrue);
    });

    test('bot sprinting sheds mass and observes a cooldown', () {
      final simulation = GameSimulation(
        config: const SimulationConfig(
          arenaRadius: 2000,
          botCount: 1,
          initialPellets: 0,
          playerSpeed: 0,
          botSpeed: 100,
          botTurnRate: 20,
          botRetreatLength: 200,
          botRetreatBoundaryBuffer: 600,
          botSprintDuration: 0.5,
          botSprintCooldown: 2,
          botSprintTriggerDistance: 400,
          sprintDrainInterval: 0.1,
          sprintAnticipationDuration: 0,
        ),
      );
      final bot = simulation.snakes[1];
      bot.resetAt(const Vec2(0, 1500));
      bot.retreating = true;
      final initialLength = bot.length;

      simulation.update(1 / 60, Vec2.zero);
      expect(bot.sprinting, isTrue);

      advanceSimulation(simulation, 0.6, Vec2.zero);

      expect(bot.sprinting, isFalse);
      expect(bot.length, lessThan(initialLength));
      expect(bot.botSprintCooldownRemaining, greaterThan(0));
      expect(
        simulation.droppedMass.any(
          (pellet) => pellet.kind == FoodPelletKind.sprintDrop,
        ),
        isTrue,
      );
    });

    test('sprint anticipation is public before acceleration begins', () {
      const config = SimulationConfig(
        botCount: 1,
        initialPellets: 0,
        playerSpeed: 0,
        botSpeed: 100,
        botTurnRate: 20,
        botRetreatLength: 200,
        botRetreatBoundaryBuffer: 600,
        botSprintTriggerDistance: 400,
        sprintAnticipationDuration: 0.2,
      );
      final simulation = GameSimulation(config: config);
      final bot = simulation.snakes[1];
      bot.resetAt(const Vec2(0, 1500));
      bot.retreating = true;

      simulation.update(1 / 60, Vec2.zero);

      expect(bot.sprintAnticipating, isTrue);
      expect(bot.sprinting, isFalse);
      expect(
        simulation.telegraphs
            .firstWhere((telegraph) => telegraph.actorId == bot.id)
            .sprintAnticipating,
        isTrue,
      );
      expect(
        simulation.telegraphEvents.first.kind,
        TelegraphEventKind.sprintAnticipation,
      );

      advanceSimulation(simulation, 0.2, Vec2.zero);

      expect(bot.sprinting, isTrue);
      expect(
        simulation.telegraphs
            .firstWhere((telegraph) => telegraph.actorId == bot.id)
            .sprinting,
        isTrue,
      );
      expect(
        simulation.telegraphEvents.map((event) => event.kind),
        contains(TelegraphEventKind.sprintStarted),
      );
    });

    test('threat signals use projected public movement state', () {
      const config = SimulationConfig(
        arenaRadius: 2000,
        botCount: 1,
        initialPellets: 0,
        playerSpeed: 100,
        botSpeed: 100,
        botTurnRate: 20,
        botRetreatLength: 200,
        threatRadius: 280,
      );
      final simulation = GameSimulation(config: config);
      final bot = simulation.snakes[1];
      bot.body[0] = const Vec2(200, 0);
      bot.heading = const Vec2(-1, 0);
      simulation.player.heading = const Vec2(1, 0);

      simulation.update(1 / 60, const Vec2(1, 0));

      final threat = simulation.primaryPlayerThreat;
      expect(threat, isNotNull);
      expect(threat!.actorId, bot.id);
      expect(threat.projectedPath, isTrue);
      expect(threat.direction.x, greaterThan(0));
      expect(threat.urgency, greaterThan(0));
    });

    test('public intent is classified from observable movement', () {
      const config = SimulationConfig(
        arenaRadius: 2000,
        botCount: 1,
        initialPellets: 0,
        playerSpeed: 0,
        botSpeed: 100,
        botTurnRate: 20,
        botRetreatLength: 200,
      );
      final simulation = GameSimulation(config: config);
      final bot = simulation.snakes[1];
      bot.body[0] = const Vec2(100, 0);
      bot.heading = const Vec2(-1, 0);
      simulation.player.heading = const Vec2(1, 0);

      simulation.update(1 / 60, Vec2.zero);

      expect(bot.publicIntent, ActorIntent.pursuing);
      expect(
        simulation.telegraphs
            .firstWhere((telegraph) => telegraph.actorId == bot.id)
            .intent,
        ActorIntent.pursuing,
      );
    });

    test('bots bend away from a predicted occupied route', () {
      const config = SimulationConfig(
        arenaRadius: 2000,
        botCount: 1,
        initialPellets: 0,
        playerSpeed: 0,
        botSpeed: 120,
        botTurnRate: 20,
        botEngagementRadius: 0,
        botCollisionLookahead: 1.2,
        botCollisionSampleCount: 6,
        botCollisionAvoidanceRadius: 220,
        botCollisionAvoidanceWeight: 10,
        botTacticDecisionMin: 30,
        botTacticDecisionMax: 30,
      );
      final simulation = GameSimulation(config: config);
      final bot = simulation.snakes[1];
      bot.resetAt(const Vec2(-260, 0));
      bot.heading = const Vec2(1, 0);

      simulation.update(0.1, Vec2.zero);

      expect(bot.heading.y.abs(), greaterThan(0.01));
    });

    test('the closest eligible bot claims the projected player lane', () {
      const config = SimulationConfig(
        arenaRadius: 2000,
        botCount: 1,
        initialPellets: 0,
        playerSpeed: 100,
        botSpeed: 0,
        botTurnRate: 20,
        botEngagementRadius: 1000,
        botEngagementLeadTime: 2.75,
        botEngagementWeight: 8,
        botTacticDecisionMin: 30,
        botTacticDecisionMax: 30,
      );
      final simulation = GameSimulation(config: config);
      final bot = simulation.snakes[1];
      bot.body[0] = const Vec2(0, 300);
      bot.heading = const Vec2(0, 1);
      simulation.player.heading = const Vec2(1, 0);

      simulation.update(0.1, Vec2.zero);

      expect(bot.heading.x, greaterThan(0));
      expect(bot.heading.y, lessThan(1));
    });
    test('bot tactics vary turn commitment and movement speed over time', () {
      const config = SimulationConfig(
        arenaRadius: 4000,
        botCount: 1,
        initialPellets: 0,
        playerSpeed: 0,
        botSpeed: 100,
        botTurnRate: 5,
        botRetreatLength: 200,
        botTacticDecisionMin: 0.2,
        botTacticDecisionMax: 0.35,
        botTacticTurnVariance: 1.2,
        botTacticSpeedBoost: 1.25,
        botTacticBrakeMultiplier: 0.6,
      );
      final simulation = GameSimulation(config: config, seed: 91);
      final bot = simulation.snakes[1];
      bot.body[0] = const Vec2(0, 600);

      final headings = <Vec2>[];
      final speeds = <double>[];
      for (var index = 0; index < 24; index++) {
        simulation.update(0.1, Vec2.zero);
        headings.add(bot.heading);
        speeds.add(bot.tacticalSpeedMultiplier);
      }

      expect(headings.toSet().length, greaterThan(3));
      expect(speeds.any((speed) => (speed - 1).abs() > 0.01), isTrue);
      expect(
        speeds.every((speed) => speed >= config.botTacticBrakeMultiplier),
        isTrue,
      );
      expect(
        speeds.every((speed) => speed <= config.botTacticSpeedBoost),
        isTrue,
      );
    });

    test(
      'bot growth is bounded while the disposition multiplier remains active',
      () {
        const config = SimulationConfig(
          botCount: 1,
          initialPellets: 0,
          botSpeed: 0,
          botMaximumLength: 20,
        );
        final simulation = GameSimulation(config: config);
        final bot = simulation.snakes[1];
        simulation.pellets.add(FoodPellet(position: bot.head, value: 100));

        simulation.update(1 / 60, Vec2.zero);

        expect(bot.length, config.botMaximumLength);
      },
    );

    test(
      'pellet maintenance refills gradually below the density threshold',
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

        advanceSimulation(simulation, 0.52, Vec2.zero);
        expect(simulation.pellets.length, 2);
        expect(simulation.pellets.length, lessThan(config.initialPellets));

        advanceSimulation(simulation, 0.52, Vec2.zero);
        expect(simulation.pellets.length, 4);
        expect(simulation.pellets.length, lessThanOrEqualTo(7));
      },
    );

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
        simulation.finalStats!.length,
        simulation.config.minimumSprintLength,
      );
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

    test(
      'bots abandon an unsafe player intercept and sidestep the body lane',
      () {
        final simulation = GameSimulation(
          config: const SimulationConfig(
            arenaRadius: 2000,
            botCount: 1,
            initialPellets: 0,
            playerSpeed: 0,
            botSpeed: 120,
            botTurnRate: 20,
            botDefensiveAvoidanceWeight: 14,
          ),
        );
        final bot = simulation.snakes[1];
        bot.body[0] = const Vec2(0, 150);
        bot.heading = const Vec2(0, -1);
        bot.sprinting = true;
        bot.sprintRequested = true;
        bot.botSprintRemaining = 0.8;

        simulation.update(0.1, Vec2.zero);

        expect(bot.heading.x.abs(), greaterThan(0.01));
        expect(bot.sprinting, isFalse);
        expect(bot.botSprintCooldownRemaining, greaterThan(0));
      },
    );

    test('a sharp player evasion invalidates the bot tactical commitment', () {
      final simulation = GameSimulation(
        config: const SimulationConfig(
          arenaRadius: 2000,
          botCount: 1,
          initialPellets: 0,
          playerSpeed: 100,
          botSpeed: 100,
          botTurnRate: 20,
          botTacticDecisionMin: 2,
          botTacticDecisionMax: 2,
        ),
      );
      final bot = simulation.snakes[1];
      bot.body[0] = const Vec2(0, 260);
      bot.heading = const Vec2(0, -1);
      simulation.player.heading = const Vec2(1, 0);

      simulation.update(0.1, Vec2.zero);
      final firstHeading = bot.heading;

      simulation.player.heading = const Vec2(-1, 0);
      simulation.update(0.1, Vec2.zero);

      expect(bot.heading, isNot(firstHeading));
      expect(bot.movementCommitment, lessThan(1));
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

    test('bots react to large defeat fields beyond local food sense', () {
      final simulation = GameSimulation(
        config: const SimulationConfig(
          arenaRadius: 2000,
          botCount: 1,
          initialPellets: 0,
          playerSpeed: 0,
          botSpeed: 0,
          botTurnRate: 20,
          botDroppedMassControlWeight: 8,
        ),
      );
      final bot = simulation.snakes[1];
      bot.body[0] = const Vec2(0, 700);
      bot.heading = const Vec2(0, 1);
      for (var index = 0; index < 5; index++) {
        simulation.droppedMass.add(
          FoodPellet(
            position: Vec2(index * 18.0, 0),
            value: 3,
            kind: FoodPelletKind.defeatDrop,
          ),
        );
      }

      simulation.update(0.1, Vec2.zero);

      expect(bot.heading.y, lessThan(1));
      expect(bot.heading.y, greaterThan(-1));
    });

    test('bots predict moving peer routes before they converge', () {
      final simulation = GameSimulation(
        config: const SimulationConfig(
          arenaRadius: 2000,
          botCount: 2,
          initialPellets: 0,
          playerSpeed: 0,
          botSpeed: 120,
          botTurnRate: 20,
          botEngagementRadius: 0,
        ),
      );
      final first = simulation.snakes[1];
      final second = simulation.snakes[2];
      first.body[0] = const Vec2(0, -70);
      first.heading = const Vec2(0, 1);
      second.body[0] = const Vec2(0, 70);
      second.heading = const Vec2(0, -1);

      simulation.update(0.1, Vec2.zero);

      expect(first.heading.x.abs(), greaterThan(0.01));
      expect(second.heading.x.abs(), greaterThan(0.01));
      expect(first.heading.x * second.heading.x, lessThan(0));
    });

    test('peer collision risk cancels bot sprint commitments', () {
      const config = SimulationConfig(
        arenaRadius: 2000,
        botCount: 2,
        initialPellets: 0,
        playerSpeed: 0,
        botSpeed: 120,
        botTurnRate: 20,
        botEngagementRadius: 0,
        sprintAnticipationDuration: 0,
      );
      final simulation = GameSimulation(config: config);
      final first = simulation.snakes[1];
      final second = simulation.snakes[2];
      first.body[0] = const Vec2(0, -70);
      first.heading = const Vec2(0, 1);
      second.body[0] = const Vec2(0, 70);
      second.heading = const Vec2(0, -1);
      first.sprintRequested = true;
      first.sprinting = true;
      first.botSprintRemaining = 1;
      second.sprintRequested = true;
      second.sprinting = true;
      second.botSprintRemaining = 1;

      simulation.update(0.1, Vec2.zero);

      expect(first.alive, isTrue);
      expect(second.alive, isTrue);
      expect(first.sprinting, isFalse);
      expect(second.sprinting, isFalse);
      expect(first.heading.x * second.heading.x, lessThan(0));
    });

    test('bots survive a sustained head-on convergence without immunity', () {
      const config = SimulationConfig(
        arenaRadius: 3000,
        botCount: 2,
        initialPellets: 0,
        playerSpeed: 0,
        botSpeed: 175,
        botTurnRate: 6,
        botEngagementRadius: 0,
        botTacticalDecisionInterval: 0.08,
      );
      final simulation = GameSimulation(config: config);
      simulation.player.resetAt(const Vec2(0, 1500));
      final first = simulation.snakes[1];
      final second = simulation.snakes[2];
      first.resetAt(const Vec2(-300, 0));
      first.heading = const Vec2(1, 0);
      second.resetAt(const Vec2(300, 0));
      second.heading = const Vec2(-1, 0);

      advanceSimulation(simulation, 2.2, Vec2.zero);

      expect(first.alive, isTrue);
      expect(second.alive, isTrue);
      expect(simulation.botPeerCollisionDeaths, 0);
      expect(first.head.distanceTo(second.head), greaterThan(40));
    });

    test('final route safety vetoes simultaneous crossing sprints', () {
      const config = SimulationConfig(
        arenaRadius: 3000,
        botCount: 2,
        initialPellets: 0,
        playerSpeed: 0,
        botSpeed: 175,
        botTurnRate: 6,
        botEngagementRadius: 0,
        botTacticalDecisionInterval: 0.05,
        sprintAnticipationDuration: 0,
      );
      final simulation = GameSimulation(config: config);
      simulation.player.resetAt(const Vec2(0, 1500));
      final first = simulation.snakes[1];
      final second = simulation.snakes[2];
      resetSnakeAlongHeading(
        first,
        const Vec2(-120, -120),
        const Vec2(1, 1),
      );
      resetSnakeAlongHeading(
        second,
        const Vec2(120, -120),
        const Vec2(-1, 1),
      );
      first.sprintRequested = true;
      first.sprinting = true;
      first.botSprintRemaining = 1;
      second.sprintRequested = true;
      second.sprinting = true;
      second.botSprintRemaining = 1;

      advanceSimulation(simulation, 0.8, Vec2.zero);

      expect(first.alive, isTrue);
      expect(second.alive, isTrue);
      expect(simulation.botPeerCollisionDeaths, 0);
      expect(first.sprinting && second.sprinting, isFalse);
    });

    test('persistent formation gives engaged bots separate pressure lanes', () {
      const config = SimulationConfig(
        arenaRadius: 2000,
        botCount: 2,
        initialPellets: 0,
        playerSpeed: 0,
        botSpeed: 120,
        botTurnRate: 20,
        botEngagementRadius: 1000,
        botPressureWeight: 0,
        botClosedLoopWeight: 0,
        botGeometryPressureWeight: 0,
        botFormationPressureWeight: 16,
        botTacticDecisionMin: 30,
        botTacticDecisionMax: 30,
      );
      final simulation = GameSimulation(config: config);
      final first = simulation.snakes[1];
      final second = simulation.snakes[2];
      first.body[0] = const Vec2(0, 300);
      first.heading = const Vec2(0, -1);
      second.body[0] = const Vec2(0, -300);
      second.heading = const Vec2(0, 1);
      simulation.player.heading = const Vec2(1, 0);

      simulation.update(0.1, Vec2.zero);

      expect(first.heading.y * second.heading.y, lessThan(0));
      expect(first.alive, isTrue);
      expect(second.alive, isTrue);
    });

    test('player engagement assigns separated safe lanes', () {
      const config = SimulationConfig(
        arenaRadius: 2000,
        botCount: 2,
        initialPellets: 0,
        playerSpeed: 100,
        botSpeed: 100,
        botTurnRate: 20,
        botEngagementRadius: 1000,
        botEngagementWeight: 8,
      );
      final simulation = GameSimulation(config: config);
      final first = simulation.snakes[1];
      final second = simulation.snakes[2];
      first.body[0] = const Vec2(0, 300);
      first.heading = const Vec2(0, -1);
      second.body[0] = const Vec2(0, -300);
      second.heading = const Vec2(0, 1);
      simulation.player.heading = const Vec2(1, 0);

      simulation.update(0.1, Vec2.zero);

      expect(first.heading.x.abs(), greaterThan(0.01));
      expect(second.heading.x.abs(), greaterThan(0.01));
      expect(first.heading.y * second.heading.y, lessThan(0));
    });

    test('closed-loop pursuit replans after a player route change', () {
      const config = SimulationConfig(
        arenaRadius: 2000,
        botCount: 1,
        initialPellets: 0,
        playerSpeed: 120,
        botSpeed: 120,
        botTurnRate: 20,
        botEngagementRadius: 1000,
        botEngagementWeight: 0,
        botClosedLoopWeight: 12,
      );
      final simulation = GameSimulation(config: config);
      final bot = simulation.snakes[1];
      bot.body[0] = const Vec2(0, 360);
      bot.heading = const Vec2(0, -1);
      simulation.player.heading = const Vec2(1, 0);

      simulation.update(0.1, Vec2.zero);
      final firstHeading = bot.heading;

      simulation.player.heading = const Vec2(0, 1);
      simulation.update(0.1, Vec2.zero);

      expect(bot.heading.distanceTo(firstHeading), greaterThan(0.01));
    });

    test('closed-loop drop control separates harvest and denial lanes', () {
      const config = SimulationConfig(
        arenaRadius: 2000,
        botCount: 2,
        initialPellets: 0,
        playerSpeed: 100,
        botSpeed: 100,
        botTurnRate: 20,
        botEngagementRadius: 1000,
        botClosedLoopWeight: 12,
      );
      final simulation = GameSimulation(config: config);
      final first = simulation.snakes[1];
      final second = simulation.snakes[2];
      first.body[0] = const Vec2(-260, 0);
      second.body[0] = const Vec2(260, 0);
      first.heading = const Vec2(1, 0);
      second.heading = const Vec2(-1, 0);
      simulation.droppedMass.addAll([
        const FoodPellet(
          position: Vec2(0, 160),
          value: 3,
          kind: FoodPelletKind.defeatDrop,
        ),
        const FoodPellet(
          position: Vec2(24, 160),
          value: 3,
          kind: FoodPelletKind.defeatDrop,
        ),
      ]);

      simulation.update(0.1, Vec2.zero);

      final maneuvers = <String?>{
        simulation.botManeuverName(first.id),
        simulation.botManeuverName(second.id),
      };
      expect(maneuvers.length, 2);
      expect(maneuvers, contains('resourceDenial'));
      expect(simulation.botPeerCollisionDeaths, 0);
    });

    test('geometry pressure selects a body lane instead of a blind charge', () {
      const config = SimulationConfig(
        arenaRadius: 2000,
        botCount: 1,
        initialPellets: 0,
        playerSpeed: 0,
        botSpeed: 120,
        botTurnRate: 20,
        botEngagementRadius: 1000,
        botPressureWeight: 0,
        botClosedLoopWeight: 0,
        botGeometryPressureWeight: 16,
        botTacticDecisionMin: 30,
        botTacticDecisionMax: 30,
      );
      final simulation = GameSimulation(config: config);
      final bot = simulation.snakes[1];
      bot.body[0] = const Vec2(0, 420);
      bot.heading = const Vec2(0, -1);
      simulation.player.body
        ..[0] = const Vec2(0, 0)
        ..[1] = const Vec2(-12, 0)
        ..[2] = const Vec2(-24, 0)
        ..[3] = const Vec2(-36, 0);

      simulation.update(0.1, Vec2.zero);

      expect(simulation.botManeuverName(bot.id), 'constrictor');
      expect(simulation.botPlanMode(bot.id), isNot('wander'));
    });

    test('multi-phase attacks create credible player collision windows', () {
      const config = SimulationConfig(
        arenaRadius: 3000,
        botCount: 3,
        initialPellets: 0,
        playerSpeed: 120,
        botSpeed: 175,
        botTurnRate: 6,
        botEngagementRadius: 1200,
        botTacticalDecisionInterval: 0.06,
        botManeuverStageDuration: 0.12,
        botManeuverCommitDuration: 0.3,
        botManeuverRecoveryDuration: 0.16,
      );
      final simulation = GameSimulation(config: config);
      simulation.player.heading = const Vec2(1, 0);
      simulation.snakes[1].resetAt(const Vec2(-260, 220));
      simulation.snakes[2].resetAt(const Vec2(180, 320));
      simulation.snakes[3].resetAt(const Vec2(360, -260));
      var credibleWindows = 0;

      for (var frame = 0; frame < 180 && !simulation.gameOver; frame++) {
        simulation.update(1 / 60, const Vec2(1, 0));
        credibleWindows += simulation.lastCrediblePlayerKillWindowCount;
      }

      expect(credibleWindows, greaterThan(0));
      expect(
        simulation.snakes
            .where((snake) => snake.kind == SnakeKind.bot)
            .map((bot) => simulation.botManeuverName(bot.id))
            .whereType<String>()
            .toSet()
            .length,
        greaterThanOrEqualTo(2),
      );
    });

    test('sprint-drop fields participate in bot denial planning', () {
      const config = SimulationConfig(
        arenaRadius: 2000,
        botCount: 1,
        initialPellets: 0,
        playerSpeed: 0,
        botSpeed: 0,
        botTurnRate: 20,
        botDroppedMassControlWeight: 10,
      );
      final simulation = GameSimulation(config: config);
      final bot = simulation.snakes[1];
      bot.body[0] = const Vec2(0, 700);
      bot.heading = const Vec2(0, 1);
      simulation.droppedMass.addAll([
        const FoodPellet(
          position: Vec2(-24, 0),
          value: 1,
          kind: FoodPelletKind.sprintDrop,
        ),
        const FoodPellet(
          position: Vec2(0, 0),
          value: 1,
          kind: FoodPelletKind.sprintDrop,
        ),
        const FoodPellet(
          position: Vec2(24, 0),
          value: 1,
          kind: FoodPelletKind.sprintDrop,
        ),
      ]);

      simulation.update(0.1, Vec2.zero);

      expect(bot.heading.y, lessThan(1));
      expect(bot.heading.y, greaterThan(-1));
    });

    test('bots scale growth when the player creates a large size gap', () {
      const config = SimulationConfig(
        botCount: 1,
        initialPellets: 0,
        playerSpeed: 0,
        botSpeed: 0,
        botMaximumLength: 120,
        botAdaptiveMaximumLength: 260,
      );
      final simulation = GameSimulation(config: config);
      final bot = simulation.snakes[1];
      simulation.player.grow(400);
      simulation.pellets.add(FoodPellet(position: bot.head, value: 100));

      simulation.update(1 / 60, Vec2.zero);

      expect(bot.length, greaterThan(config.botMaximumLength));
      expect(bot.length, lessThanOrEqualTo(config.botAdaptiveMaximumLength));
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
      expect(simulation.player.length, greaterThanOrEqualTo(initialLength + 3));
      expect(simulation.pellets, isEmpty);
    });

    test(
      'growth keeps existing spacing and extends only the terminal tail',
      () {
        const config = SimulationConfig(
          botCount: 0,
          initialPellets: 0,
          playerSpeed: 120,
          growthExpressionRate: 0.05,
        );
        final simulation = GameSimulation(config: config);
        final pellet = FoodPellet(position: simulation.player.head, value: 1);
        simulation.pellets.add(pellet);

        simulation.update(1 / 60, const Vec2(1, 0));

        final player = simulation.player;
        final collectedTail = player.body.last;
        final tailAtCollection = Vec2(collectedTail.x, collectedTail.y);
        final lengthAtCollection = player.length;
        expect(player.growthExpressionRemaining, config.segmentSpacing);
        expect(player.body.length, lengthAtCollection - 1);

        simulation.update(0.05, const Vec2(1, 0));
        expect(player.length, lengthAtCollection);
        expect(player.body.length, lengthAtCollection);
        expect(player.body.last.x, greaterThan(tailAtCollection.x));
        expect(player.body.last.x, lessThan(tailAtCollection.x + 6));
        for (var index = 1; index < player.body.length - 1; index++) {
          expect(
            player.body[index - 1].distanceTo(player.body[index]),
            closeTo(config.segmentSpacing, 0.0001),
          );
        }
        expect(
          player.body[player.body.length - 2].distanceTo(player.body.last),
          lessThan(config.segmentSpacing),
        );
        expect(
          player.body.last.distanceTo(player.body[player.body.length - 2]),
          greaterThan(0),
        );

        advanceSimulation(simulation, 2.2, const Vec2(1, 0));
        expect(player.growthExpressionRemaining, closeTo(0, 0.0001));
        expect(player.body.length, player.length);
        for (var index = 1; index < player.body.length; index++) {
          expect(
            player.body[index - 1].distanceTo(player.body[index]),
            closeTo(config.segmentSpacing, 0.0001),
          );
        }
      },
    );

    test(
      'multiple queued growth events do not create hidden collision segments',
      () {
        const config = SimulationConfig(
          botCount: 0,
          initialPellets: 0,
          playerSpeed: 120,
          growthExpressionRate: 0.05,
        );
        final simulation = GameSimulation(config: config);
        final player = simulation.player;
        player.grow(3);

        expect(player.length, config.minimumSprintLength + 3);
        expect(player.body.length, config.minimumSprintLength);

        simulation.update(0.05, const Vec2(1, 0));

        expect(player.body.length, lessThan(player.length));
        expect(player.pendingGrowthSegments, 3);
        expect(player.body.length, player.fullyExpressedLength + 1);

        advanceSimulation(simulation, 8, const Vec2(1, 0));

        expect(player.growthExpressionRemaining, closeTo(0, 0.0001));
        expect(player.body.length, player.length);
        expect(player.pendingGrowthSegments, 0);
      },
    );

    test('growth follows a turn without deforming established segments', () {
      const config = SimulationConfig(
        botCount: 0,
        initialPellets: 0,
        playerSpeed: 120,
        growthExpressionRate: 0.05,
      );
      final simulation = GameSimulation(config: config);
      final player = simulation.player;
      player.grow();

      simulation.update(0.25, const Vec2(1, 0));
      simulation.update(0.25, const Vec2(0, 1));

      expect(player.growthExpressionRemaining, greaterThan(0));
      for (var index = 1; index < player.body.length - 1; index++) {
        expect(
          player.body[index - 1].distanceTo(player.body[index]),
          lessThanOrEqualTo(config.segmentSpacing + 0.0001),
        );
      }
      expect(
        player.body.last.distanceTo(player.body[player.body.length - 2]),
        lessThan(config.segmentSpacing),
      );
    });

    test('restart clears any unexpressed growth distance', () {
      final simulation = GameSimulation(
        config: const SimulationConfig(
          botCount: 0,
          initialPellets: 0,
          playerSpeed: 0,
        ),
      );
      simulation.player.grow(3);

      expect(simulation.player.growthExpressionRemaining, greaterThan(0));
      simulation.restart();

      expect(simulation.player.growthExpressionRemaining, 0);
      expect(simulation.player.length, simulation.config.minimumSprintLength);
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
      expect(simulation.droppedMass, isEmpty);
    });

    test('a bot leaving the arena is removed without dropping mass', () {
      final simulation = GameSimulation(
        config: const SimulationConfig(
          arenaRadius: 100,
          botCount: 1,
          initialPellets: 0,
          playerSpeed: 0,
          botSpeed: 1000,
        ),
      );
      final bot = simulation.snakes[1];
      bot.body[0] = const Vec2(99, 0);
      bot.heading = const Vec2(1, 0);

      simulation.update(1 / 60, Vec2.zero);

      expect(bot.alive, isFalse);
      expect(simulation.droppedMass, isEmpty);
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
      expect(
        simulation.droppedMass.every(
          (pellet) => pellet.kind == FoodPelletKind.defeatDrop,
        ),
        isTrue,
      );
      expect(
        simulation.droppedMass.every(
          (pellet) => pellet.value == simulation.config.defeatDropValue,
        ),
        isTrue,
      );
      expect(
        simulation.droppedMass.every(
          (pellet) => pellet.sourceColorIndex == simulation.player.colorIndex,
        ),
        isTrue,
      );
      expect(simulation.collisionPings, hasLength(1));
      expect(simulation.collisionPings.single.position, simulation.player.head);

      simulation.update(0.45, Vec2.zero);
      expect(simulation.collisionPings, hasLength(1));
      simulation.update(0.45, Vec2.zero);
      expect(simulation.collisionPings, isEmpty);
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
        expect(
          simulation.droppedMass.every(
            (pellet) => pellet.kind == FoodPelletKind.defeatDrop,
          ),
          isTrue,
        );
        expect(
          simulation.droppedMass.every(
            (pellet) => pellet.value == simulation.config.defeatDropValue,
          ),
          isTrue,
        );
        expect(
          simulation.droppedMass.every(
            (pellet) => pellet.sourceColorIndex == bot.colorIndex,
          ),
          isTrue,
        );
        expect(simulation.collisionPings, hasLength(1));
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
      final previousPoint = simulation.player.body[3];
      final beforeTurn = Vec2(previousPoint.x, previousPoint.y);
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
        sprintAnticipationDuration: 0,
      );
      final normal = GameSimulation(config: config);
      final sprinting = GameSimulation(config: config);
      normal.player.grow(4);
      sprinting.player.grow(4);
      final normalLength = normal.player.length;
      final sprintLength = sprinting.player.length;

      advanceSimulation(normal, 0.5, const Vec2(1, 0));
      advanceSimulation(
        sprinting,
        0.5,
        const Vec2(1, 0),
        sprinting: true,
      );

      expect(sprinting.player.head.x, greaterThan(normal.player.head.x));
      expect(sprinting.player.length, lessThan(sprintLength));
      expect(
        sprinting.player.length,
        greaterThanOrEqualTo(config.minimumSprintLength),
      );
      expect(sprinting.droppedMass, isNotEmpty);
      expect(
        sprinting.droppedMass.every(
          (pellet) => pellet.kind == FoodPelletKind.sprintDrop,
        ),
        isTrue,
      );
      expect(
        sprinting.droppedMass.every(
          (pellet) => pellet.value == config.naturalPelletValue,
        ),
        isTrue,
      );
      expect(
        sprinting.droppedMass.every(
          (pellet) => pellet.sourceColorIndex == sprinting.player.colorIndex,
        ),
        isTrue,
      );
      expect(config.defeatDropValue, greaterThan(config.sprintDropValue));
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

      advanceSimulation(
        simulation,
        0.1,
        const Vec2(1, 0),
        sprinting: true,
      );

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
        sprintAnticipationDuration: 0,
      );
      final simulation = GameSimulation(config: config);
      simulation.player.grow(1);

      advanceSimulation(
        simulation,
        0.2,
        const Vec2(1, 0),
        sprinting: true,
      );

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
      expect(simulation.player.length, greaterThanOrEqualTo(initialLength + 2));
      expect(simulation.droppedMass, isEmpty);
    });

    test('dropped mass is bounded and expires after its lifetime', () {
      const config = SimulationConfig(
        botCount: 0,
        initialPellets: 0,
        playerSpeed: 0,
        maxDroppedMass: 3,
        droppedMassLifetime: 0.5,
      );
      final simulation = GameSimulation(config: config);
      for (var index = 0; index < 5; index++) {
        simulation.droppedMass.add(
          FoodPellet(position: Vec2(100 + index * 20, 100), value: 1),
        );
      }

      simulation.update(1 / 60, Vec2.zero);
      expect(simulation.droppedMass, hasLength(3));

      simulation.update(0.5, Vec2.zero);
      expect(simulation.droppedMass, isEmpty);
    });

    test('nearby food remains collectible with a populated world index', () {
      const config = SimulationConfig(
        botCount: 0,
        initialPellets: 0,
        playerSpeed: 0,
        arenaRadius: 2000,
      );
      final simulation = GameSimulation(config: config);
      for (var index = 0; index < 400; index++) {
        simulation.pellets.add(
          FoodPellet(position: Vec2(1000 + index * 2.0, 1000)),
        );
      }
      simulation.pellets.add(
        FoodPellet(position: simulation.player.head, value: 2),
      );

      simulation.update(1 / 60, Vec2.zero);

      expect(simulation.score, 2);
      expect(simulation.pellets, hasLength(400));
    });

    test('spatial collision lookup still defeats a head entering a body', () {
      const config = SimulationConfig(
        botCount: 1,
        initialPellets: 0,
        playerSpeed: 0,
        botSpeed: 0,
        arenaRadius: 2000,
      );
      final simulation = GameSimulation(config: config);
      final bot = simulation.snakes[1];
      bot.body[0] = const Vec2(0, 0);
      simulation.player.body[3] = const Vec2(0, 0);

      simulation.update(1 / 60, Vec2.zero);

      expect(bot.alive, isFalse);
      expect(simulation.droppedMass, isNotEmpty);
    });

    test('dropped mass merging preserves value instead of deleting dots', () {
      const config = SimulationConfig(
        botCount: 0,
        initialPellets: 0,
        playerSpeed: 0,
        maxDroppedMass: 3,
      );
      final simulation = GameSimulation(config: config);
      simulation.droppedMass.addAll([
        const FoodPellet(position: Vec2(300, 0), value: 2),
        const FoodPellet(position: Vec2(308, 0), value: 3),
        const FoodPellet(position: Vec2(316, 0), value: 4),
        const FoodPellet(position: Vec2(324, 0), value: 5),
      ]);

      simulation.update(1 / 60, Vec2.zero);

      expect(simulation.droppedMass, hasLength(3));
      expect(
        simulation.droppedMass.fold<int>(
          0,
          (total, pellet) => total + pellet.value,
        ),
        14,
      );
    });

    test(
      'long updates cap authoritative work and discard excess backlog',
      () {
        const config = SimulationConfig(
          botCount: 0,
          initialPellets: 0,
          playerSpeed: 100,
          arenaRadius: 2000,
        );
        final simulation = GameSimulation(config: config);

        simulation.update(2, const Vec2(1, 0));

        expect(simulation.elapsed, closeTo(2, 0.0001));
        expect(simulation.lastFixedStepCount, 2);
        expect(simulation.player.head.x, closeTo(100 * 2 / 60, 0.0001));

        simulation.update(1 / 60, const Vec2(1, 0));
        expect(simulation.lastFixedStepCount, lessThanOrEqualTo(2));
      },
    );

    test('sustained turning triggers one immediate tactical replan', () {
      const config = SimulationConfig(
        arenaRadius: 2000,
        botCount: 3,
        initialPellets: 0,
        playerSpeed: 100,
        botSpeed: 100,
        botTacticalDecisionInterval: 1,
      );
      final simulation = GameSimulation(config: config);

      simulation.update(1 / 60, const Vec2(1, 0));
      simulation.update(0.2, const Vec2(0, 1));

      expect(simulation.lastFixedStepCount, 2);
      expect(simulation.lastTacticalReplanCount, 1);
      expect(simulation.lastSpatialIndexBuildCount, lessThanOrEqualTo(3));
    });

    test('formidable planning preserves the V1.23 busy-frame budget', () {
      const config = SimulationConfig(
        arenaRadius: 5000,
        botCount: 10,
        maxBotCount: 10,
        initialPellets: 0,
        playerSpeed: 175,
        botSpeed: 175,
        busyPlanningLoadThreshold: 1,
        botTacticalDecisionInterval: 0.08,
      );
      final simulation = GameSimulation(config: config);
      simulation.player.grow(1500);
      for (final bot in simulation.snakes.where(
        (snake) => snake.kind == SnakeKind.bot,
      )) {
        bot.grow(220);
      }
      for (var index = 0; index < config.maxDroppedMass; index++) {
        simulation.droppedMass.add(
          FoodPellet(
            position: Vec2(
              900 + index % 24 * 12.0,
              900 + index ~/ 24 * 12.0,
            ),
            kind: FoodPelletKind.defeatDrop,
          ),
        );
      }

      simulation.update(1 / 30, const Vec2(0, 1), sprinting: true);

      expect(simulation.lastFixedStepCount, 2);
      expect(simulation.lastTacticalReplanCount, lessThanOrEqualTo(1));
      expect(simulation.lastSpatialIndexBuildCount, lessThanOrEqualTo(3));
      expect(simulation.droppedMass.length, lessThanOrEqualTo(480));
    });

    test('body reconstruction reuses established segment storage', () {
      const config = SimulationConfig(
        botCount: 0,
        initialPellets: 0,
        playerSpeed: 120,
      );
      final simulation = GameSimulation(config: config);

      simulation.update(1 / 60, const Vec2(1, 0));
      final firstSegment = simulation.player.body[1];
      simulation.update(1 / 60, const Vec2(1, 0));

      expect(identical(simulation.player.body[1], firstSegment), isTrue);
      expect(simulation.player.bodyChunks, isNotEmpty);
    });

    test('drop-cap consolidation batches a busy field into one merge pass', () {
      const config = SimulationConfig(
        arenaRadius: 4000,
        botCount: 0,
        initialPellets: 0,
        playerSpeed: 0,
        maxDroppedMass: 50,
      );
      final simulation = GameSimulation(config: config);
      for (var index = 0; index < 600; index++) {
        simulation.droppedMass.add(
          FoodPellet(
            position: Vec2(
              1000.0 + index % 30 * 3,
              1000.0 + index ~/ 30 * 3,
            ),
            kind: FoodPelletKind.defeatDrop,
          ),
        );
      }

      simulation.update(1 / 60, Vec2.zero);

      expect(simulation.droppedMass, hasLength(config.maxDroppedMass));
      expect(simulation.lastDroppedMassMergeCount, 1);
      expect(
        simulation.droppedMass.fold<int>(
          0,
          (total, pellet) => total + pellet.value,
        ),
        600,
      );
    });

    test(
      'bots receive bounded catch-up growth when the player pulls ahead',
      () {
        const config = SimulationConfig(
          botCount: 1,
          initialPellets: 0,
          playerSpeed: 0,
          botSpeed: 0,
          botCatchUpDelay: 0,
          botCatchUpRate: 10,
          botCatchUpTargetFraction: 0.5,
        );
        final simulation = GameSimulation(config: config);
        final bot = simulation.snakes[1];
        final initialLength = bot.length;
        simulation.player.grow(100);

        advanceSimulation(simulation, 1, Vec2.zero);

        expect(bot.length, greaterThan(initialLength));
        expect(bot.length, lessThanOrEqualTo(config.botAdaptiveMaximumLength));
      },
    );

    test(
      'movement trail appends in time order without losing the live head',
      () {
        const config = SimulationConfig(
          botCount: 0,
          initialPellets: 0,
          playerSpeed: 180,
          movementTrailTrimSlackSegments: 8,
        );
        final simulation = GameSimulation(config: config);

        simulation.update(2, const Vec2(1, 0));

        expect(simulation.player.movementTrail.last, simulation.player.head);
        expect(simulation.player.body.first, simulation.player.head);
        expect(
          simulation.player.movementTrail.first.distanceTo(
            simulation.player.movementTrail.last,
          ),
          greaterThan(simulation.player.segmentSpacing),
        );
      },
    );

    test('urgent player turns invalidate a cached bot plan immediately', () {
      const config = SimulationConfig(
        arenaRadius: 2000,
        botCount: 1,
        initialPellets: 0,
        playerSpeed: 100,
        botSpeed: 100,
        botTurnRate: 20,
        botTacticalDecisionInterval: 1.0,
        botTacticDecisionMin: 2,
        botTacticDecisionMax: 2,
      );
      final simulation = GameSimulation(config: config);
      final bot = simulation.snakes[1];
      bot.body[0] = const Vec2(0, 260);
      bot.heading = const Vec2(0, -1);
      simulation.player.heading = const Vec2(1, 0);

      simulation.update(0.1, Vec2.zero);
      final firstHeading = bot.heading;

      simulation.player.heading = const Vec2(-1, 0);
      simulation.update(0.1, Vec2.zero);

      expect(bot.heading, isNot(firstHeading));
      expect(bot.movementCommitment, lessThan(1));
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
      expect(MinimapModel.project(const Vec2(0, 0), 100), const Vec2(0.5, 0.5));
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

    test('projects collision pings and exposes their animation progress', () {
      final ping = CollisionPing(
        position: const Vec2(250, -250),
        durationSeconds: 1,
      );
      ping.remainingSeconds = 0.5;

      final pings = MinimapModel.pings(
        collisionPings: [ping],
        arenaRadius: 100,
      );

      expect(pings, hasLength(1));
      expect(pings.single.x, 1);
      expect(pings.single.y, 0);
      expect(pings.single.progress, 0.5);
    });
  });
}
