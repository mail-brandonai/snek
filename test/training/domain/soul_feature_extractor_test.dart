import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:slither/training/domain/soul_feature_extractor.dart';

void main() {
  test(
    'resource collection evidence distinguishes forage from dropped mass',
    () {
    final observations = List<Map<String, Object?>>.generate(
      8,
      (index) => _observation(index + 1),
    );
    final forageEvents = List<Map<String, Object?>>.generate(
      6,
      (index) => _event(
        'foodCollected',
        index + 1,
        targetId: index < 5 ? 'natural' : 'sprintDrop',
      ),
    );
    final massEvents = List<Map<String, Object?>>.generate(
      6,
      (index) => _event(
        'foodCollected',
        index + 1,
        targetId: index < 5 ? 'defeatDrop' : 'natural',
      ),
    );

    final forage = _trait(
      _extract(observations: observations, events: forageEvents),
      'resourcePriority',
    );
    final massSeeking = _trait(
      _extract(observations: observations, events: massEvents),
      'resourcePriority',
    );

    final forageCounts = forage.observedEvidence['pickupsByKind'] as Map;
    final massCounts = massSeeking.observedEvidence['pickupsByKind'] as Map;
    expect(forageCounts['natural'], 5);
    expect(massCounts['defeatDrop'], 5);
    expect(forage.inferredInterpretation, contains('Natural-food pickups'));
    expect(
      massSeeking.inferredInterpretation,
      contains('Dropped-mass pickups'),
    );
    expect(forage.confidence, FeatureConfidence.low);
    expect(massSeeking.confidence, FeatureConfidence.low);
    expect(
      () => forageCounts['natural'] = 0,
      throwsUnsupportedError,
    );
  });

  test('sprint-heavy samples include lean size and turning evidence', () {
    final controls = List<Map<String, Object?>>.generate(
      8,
      (index) => _control(index, sprintRequested: index < 6),
    );
    final observations = List<Map<String, Object?>>.generate(
      8,
      (index) => _observation(
        index,
        length: 4,
        sprinting: index < 6,
        positionX: index.toDouble(),
        headingX: index.isEven ? 1 : 0,
        headingY: index.isEven ? 0 : 1,
      ),
    );
    final signature = _extract(
      controls: controls,
      observations: observations,
    );

    final sprint = _trait(signature, 'sprintBehavior');
    final sizeAgility = _trait(signature, 'sizeAgility');
    expect(sprint.observedEvidence['sprintRequestedSamples'], 6);
    expect(sprint.observedEvidence['requestShare'], 0.75);
    expect(sizeAgility.observedEvidence['meanObservedLength'], 4.0);
    expect(
      sizeAgility.observedEvidence['meanTurnDegreesPerObservation'],
      closeTo(90, 0.001),
    );
    expect(sprint.confidence, FeatureConfidence.moderate);
  });

  test('pressure episodes summarize response to captured bot maneuvers', () {
    const maneuvers = <String>[
      'leadInterceptor',
      'counterCut',
      'resourceDenial',
      'constrictor',
    ];
    final controls = <Map<String, Object?>>[];
    final observations = <Map<String, Object?>>[];
    final events = <Map<String, Object?>>[];

    for (var index = 0; index < maneuvers.length; index++) {
      final onset = 5 + index * 10;
      final botId = 'bot-$index';
      controls.add(_control(onset - 1));
      controls.add(_control(onset + 1, steeringX: 0, steeringY: 1));
      observations.add(
        _observation(
          onset,
          actorId: botId,
          maneuver: maneuvers[index],
          length: 10,
        ),
      );
      observations.add(
        _observation(
          onset + 4,
          actorId: botId,
          maneuver: maneuvers[index],
          length: 11,
        ),
      );
      events.add(_event(
        'botPressureStarted',
        onset,
        targetId: botId,
        value: 0.4,
      ));
      events.add(_event(
        'collision',
        onset + 2,
        targetId: botId,
      ));
      events.add(_event('botPressureEnded', onset + 4, targetId: botId));
    }

    final signature = _extract(
      controls: controls,
      observations: observations,
      events: events,
      lastTick: 50,
    );
    final repeated = _extract(
      controls: controls,
      observations: observations,
      events: events,
      lastTick: 50,
    );

    expect(signature.pressureEpisodes, hasLength(4));
    for (var index = 0; index < maneuvers.length; index++) {
      final episode = signature.pressureEpisodes[index];
      expect(episode.actorManeuver, maneuvers[index]);
      expect(episode.responseAction, 'steering change');
      expect(episode.responseLatencyTicks, 1);
      expect(episode.durationSeconds, closeTo(4 / 60, 0.000001));
      expect(episode.playerCollisionCount, 1);
      expect(episode.playerLengthChange, 1);
    }
    expect(
      jsonEncode(signature.toJson()),
      jsonEncode(repeated.toJson()),
    );
  });

  test(
    'no pressure and an abandoned run produce insufficient response evidence',
    () {
    final signature = _extract(
      observations: List<Map<String, Object?>>.generate(
        8,
        (index) => _observation(index),
      ),
      events: <Map<String, Object?>>[
        _event('abandoned', 10, detail: 'userExit'),
      ],
    );
    final response = _trait(signature, 'threatResponse');
    final risk = _trait(signature, 'riskPosture');

    expect(signature.pressureEpisodes, isEmpty);
    expect(response.confidence, FeatureConfidence.insufficient);
    expect(
      response.inferredInterpretation,
      contains('No pressure episode was observed'),
    );
    expect(risk.observedEvidence['playerDefeatEvents'], 0);
    expect(signature.eventCount, 1);
  });

  test('unsupported schemas are returned as typed compatibility results', () {
    final extractor = const SoulFeatureExtractor();
    final unsupportedRecord = extractor.extract(
      runId: 'run-1',
      recordSchemaVersion: 99,
      tickRateHz: 60,
      chunkPayloads: <Uint8List>[],
    );
    final unsupportedChunk = extractor.extract(
      runId: 'run-1',
      recordSchemaVersion: 1,
      tickRateHz: 60,
      chunkPayloads: <Uint8List>[
        _chunk(schemaVersion: 99),
      ],
    );

    expect(
      unsupportedRecord.status,
      SoulFeatureStatus.unsupportedRecordSchema,
    );
    expect(
      unsupportedChunk.status,
      SoulFeatureStatus.unsupportedRecordSchema,
    );
    expect(unsupportedRecord.message, contains('99'));
  });
}

SoulBehaviorSignature _extract({
  List<Map<String, Object?>> controls = const <Map<String, Object?>>[],
  List<Map<String, Object?>> observations =
      const <Map<String, Object?>>[],
  List<Map<String, Object?>> events = const <Map<String, Object?>>[],
  int lastTick = 100,
}) {
  final result = const SoulFeatureExtractor().extract(
    runId: 'run-1',
    recordSchemaVersion: 1,
    tickRateHz: 60,
    chunkPayloads: <Uint8List>[
      _chunk(
        controls: controls,
        observations: observations,
        events: events,
        lastTick: lastTick,
      ),
    ],
  );
  expect(result.status, SoulFeatureStatus.ready);
  return result.signature!;
}

BehaviorTraitSummary _trait(SoulBehaviorSignature signature, String id) =>
    signature.traits.singleWhere((trait) => trait.id == id);

Uint8List _chunk({
  int schemaVersion = 1,
  List<Map<String, Object?>> controls = const <Map<String, Object?>>[],
  List<Map<String, Object?>> observations =
      const <Map<String, Object?>>[],
  List<Map<String, Object?>> events = const <Map<String, Object?>>[],
  int lastTick = 100,
}) =>
    Uint8List.fromList(
      utf8.encode(
        jsonEncode(<String, Object?>{
          'format': 'snek-run-chunk',
          'schemaVersion': schemaVersion,
          'runId': 'run-1',
          'sequence': 0,
          'firstTick': 0,
          'lastTick': lastTick,
          'controls': controls,
          'observations': observations,
          'events': events,
        }),
      ),
    );

Map<String, Object?> _control(
  int tick, {
  double steeringX = 1,
  double steeringY = 0,
  bool sprintRequested = false,
}) =>
    <String, Object?>{
      'tick': tick,
      'steeringX': steeringX,
      'steeringY': steeringY,
      'sprintRequested': sprintRequested,
    };

Map<String, Object?> _observation(
  int tick, {
  int length = 10,
  bool sprinting = false,
  int naturalFood = 2,
  int droppedMass = 2,
  double boundaryRisk = 0.1,
  int nearbyThreats = 0,
  double positionX = 0,
  double positionY = 0,
  double headingX = 1,
  double headingY = 0,
  String? actorId,
  String? maneuver,
}) =>
    <String, Object?>{
      'tick': tick,
      'playerPositionX': positionX,
      'playerPositionY': positionY,
      'playerHeadingX': headingX,
      'playerHeadingY': headingY,
      'playerLength': length,
      'playerSprinting': sprinting,
      'nearestThreatDistance': nearbyThreats == 0 ? null : 12.0,
      'nearbyThreatCount': nearbyThreats,
      'nearbyNaturalFoodCount': naturalFood,
      'nearbyDroppedMassCount': droppedMass,
      'boundaryRisk': boundaryRisk,
      'actors': actorId == null
          ? <Object?>[]
          : <Object?>[
              <String, Object?>{
                'actorId': actorId,
                'role': 'bot',
                'intent': 'pressurePlayer',
                'maneuver': maneuver,
                'maneuverPhase': 'commit',
              },
            ],
    };

Map<String, Object?> _event(
  String kind,
  int tick, {
  String actorId = 'player',
  String? targetId,
  double? value,
  String? detail,
}) =>
    <String, Object?>{
      'tick': tick,
      'kind': kind,
      'actorId': actorId,
      'targetId': targetId,
      'value': value,
      'detail': detail,
    };
