import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:slither/training/domain/controller_contract.dart';
import 'package:slither/training/domain/recording_contract.dart';

void main() {
  group('versioned recording DTOs', () {
    test('RunHeaderDto round trips through JSON', () {
      final value = RunHeaderDto(
        runId: 'run-1',
        mode: 'training',
        seed: 42,
        tickRateHz: 60,
        createdAtMs: 1000,
      );
      expect(
        RunHeaderDto.fromJson(_jsonRoundTrip(value.toJson())).toJson(),
        value.toJson(),
      );
    });

    test('ControlSampleDto round trips through JSON', () {
      const value = ControlSampleDto(
        tick: 12,
        headingX: 0.25,
        headingY: -0.5,
        sprinting: true,
      );
      expect(
        ControlSampleDto.fromJson(_jsonRoundTrip(value.toJson())).toJson(),
        value.toJson(),
      );
    });

    test('ObservationSampleDto round trips through JSON', () {
      const value = ObservationSampleDto(
        tick: 14,
        nearestThreatDistance: 85.5,
        nearbyThreatCount: 2,
        nearbyPelletCount: 9,
        bodyLength: 25,
      );
      expect(
        ObservationSampleDto.fromJson(_jsonRoundTrip(value.toJson())).toJson(),
        value.toJson(),
      );
    });

    test('SimulationEventDto round trips through JSON', () {
      const value = SimulationEventDto(
        tick: 15,
        kind: 'pelletCollected',
        actorId: 'player',
        targetId: 'pellet-1',
        value: 3,
      );
      expect(
        SimulationEventDto.fromJson(_jsonRoundTrip(value.toJson())).toJson(),
        value.toJson(),
      );
    });

    test('SoulRevisionDto round trips through JSON', () {
      final value = SoulRevisionDto(
        soulId: 'soul-1',
        revisionId: 'rev-2',
        parentRevisionId: 'rev-1',
        trainerVersion: 'trainer-1',
        featureVersion: 'features-1',
        weights: const <String, double>{'collect': 0.7, 'evade': 0.3},
        sourceRunIds: const <String>['run-1', 'run-2'],
      );
      expect(
        SoulRevisionDto.fromJson(_jsonRoundTrip(value.toJson())).toJson(),
        value.toJson(),
      );
    });

    test('MatchParticipantDto keeps role independent from controller source',
        () {
      final value = MatchParticipantDto(
        actorId: 'bot-1',
        role: ActorRole.opponent,
        controller: ControllerSource.soul,
        snekProfileId: 'snek-1',
        soulRevisionIds: const <String>['rev-2'],
      );
      expect(
        MatchParticipantDto.fromJson(_jsonRoundTrip(value.toJson())).toJson(),
        value.toJson(),
      );
    });

    test('all DTOs reject an unsupported schema version', () {
      final values = <Map<String, Object?> Function()>[
        () => RunHeaderDto(
              runId: 'run-1',
              mode: 'training',
              seed: 1,
              tickRateHz: 60,
              createdAtMs: 1000,
            ).toJson(),
        () => const ControlSampleDto(
              tick: 1,
              headingX: 1,
              headingY: 0,
              sprinting: false,
            ).toJson(),
        () => const ObservationSampleDto(
              tick: 1,
              nearestThreatDistance: null,
              nearbyThreatCount: 0,
              nearbyPelletCount: 2,
              bodyLength: 5,
            ).toJson(),
        () => const SimulationEventDto(
              tick: 1,
              kind: 'runStarted',
              actorId: 'player',
            ).toJson(),
        () => SoulRevisionDto(
              soulId: 'soul-1',
              revisionId: 'rev-1',
              trainerVersion: 'trainer-1',
              featureVersion: 'features-1',
              weights: const <String, double>{},
              sourceRunIds: const <String>[],
            ).toJson(),
        () => MatchParticipantDto(
              actorId: 'player',
              role: ActorRole.player,
              controller: ControllerSource.human,
              soulRevisionIds: const <String>[],
            ).toJson(),
      ];
      final decoders = <Object Function(Object?)>[
        RunHeaderDto.fromJson,
        ControlSampleDto.fromJson,
        ObservationSampleDto.fromJson,
        SimulationEventDto.fromJson,
        SoulRevisionDto.fromJson,
        MatchParticipantDto.fromJson,
      ];

      for (var index = 0; index < values.length; index++) {
        final json = values[index]()..['schemaVersion'] = 99;
        expect(
          () => decoders[index](json),
          throwsUnsupportedError,
          reason: 'DTO index $index must reject an unknown schema version',
        );
      }
    });

    test('invalid JSON types are rejected as format errors', () {
      expect(
        () => ControlSampleDto.fromJson(<String, Object?>{
          'schemaVersion': currentTrainingRecordSchemaVersion,
          'tick': 'not-an-integer',
          'headingX': 1,
          'headingY': 0,
          'sprinting': false,
        }),
        throwsFormatException,
      );
    });
  });

  group('controller contract', () {
    test('a fake controller consumes an immutable observation', () {
      final observation = ActorObservation(
        tick: 20,
        headingX: 1,
        headingY: 0,
        nearestThreatDistance: 75,
        nearbyThreatCount: 1,
        nearbyPelletCount: 3,
        bodyLength: 19,
        pressured: true,
      );
      const command = ActorCommand(steeringX: 0, steeringY: 1, sprinting: true);
      final controller = _FakeController(command);

      expect(controller.decide(observation), command);
      expect(controller.lastObservationTick, 20);
      expect(controller.lastPressureState, isTrue);
      expect(observation.headingX, 1);
      expect(observation.pressured, isTrue);
    });
  });
}

Object? _jsonRoundTrip(Map<String, Object?> value) =>
    jsonDecode(jsonEncode(value));

class _FakeController implements SnekController {
  _FakeController(this.command);

  final ActorCommand command;
  int? lastObservationTick;
  bool? lastPressureState;

  @override
  ActorCommand decide(ActorObservation observation) {
    lastObservationTick = observation.tick;
    lastPressureState = observation.pressured;
    return command;
  }
}
