import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'recording_contract.dart' show currentTrainingRecordSchemaVersion;

const currentSoulFeatureVersion = 'snek-features-v1';

enum FeatureConfidence { insufficient, low, moderate, high }

enum SoulFeatureStatus { ready, unsupportedRecordSchema, invalidTrace }

class SoulFeatureExtractionResult {
  const SoulFeatureExtractionResult._({
    required this.status,
    this.signature,
    this.message,
  });

  const SoulFeatureExtractionResult.ready(SoulBehaviorSignature signature)
      : this._(status: SoulFeatureStatus.ready, signature: signature);

  SoulFeatureExtractionResult.unsupportedSchema(int version)
      : this._(
          status: SoulFeatureStatus.unsupportedRecordSchema,
          message: 'Run record schema version $version is not supported by '
              '$currentSoulFeatureVersion',
        );

  const SoulFeatureExtractionResult.invalidTrace(String message)
      : this._(status: SoulFeatureStatus.invalidTrace, message: message);

  final SoulFeatureStatus status;
  final SoulBehaviorSignature? signature;
  final String? message;

  bool get isReady => status == SoulFeatureStatus.ready;
}

class BehaviorTraitSummary {
  BehaviorTraitSummary({
    required this.id,
    required this.label,
    required this.sampleCount,
    required this.opportunityCount,
    required this.coverage,
    required this.confidence,
    required Map<String, Object?> observedEvidence,
    this.inferredInterpretation,
  }) : observedEvidence = _freezeEvidence(observedEvidence) {
    if (sampleCount < 0 ||
        opportunityCount < 0 ||
        !coverage.isFinite ||
        coverage < 0 ||
        coverage > 1) {
      throw ArgumentError('Invalid trait evidence coverage');
    }
  }

  final String id;
  final String label;
  final int sampleCount;
  final int opportunityCount;
  final double coverage;
  final FeatureConfidence confidence;
  final Map<String, Object?> observedEvidence;

  /// A cautious, deterministic interpretation derived from recorded samples.
  /// The recorded facts remain available separately in [observedEvidence].
  final String? inferredInterpretation;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'label': label,
        'sampleCount': sampleCount,
        'opportunityCount': opportunityCount,
        'coverage': coverage,
        'confidence': confidence.name,
        'observedEvidence': observedEvidence,
        'inferredInterpretation': inferredInterpretation,
      };
}

Map<String, Object?> _freezeEvidence(Map<String, Object?> evidence) =>
    Map<String, Object?>.unmodifiable(
      evidence.map(
        (key, value) => MapEntry<String, Object?>(key, _freezeJsonValue(value)),
      ),
    );

Object? _freezeJsonValue(Object? value) {
  if (value is Map) {
    return Map<String, Object?>.unmodifiable(
      <String, Object?>{
        for (final entry in value.entries)
          if (entry.key is String)
            entry.key as String: _freezeJsonValue(entry.value),
      },
    );
  }
  if (value is List) {
    return List<Object?>.unmodifiable(value.map(_freezeJsonValue));
  }
  return value;
}

class PressureEpisodeSummary {
  const PressureEpisodeSummary({
    required this.onsetTick,
    required this.durationSeconds,
    required this.actorId,
    required this.urgencyAtOnset,
    required this.peakUrgency,
    required this.responseAction,
    required this.outcome,
    required this.playerCollisionCount,
    required this.sprintRequestedDuringEpisode,
    this.endTick,
    this.actorManeuver,
    this.responseLatencyTicks,
    this.playerLengthAtOnset,
    this.playerLengthAtEnd,
    this.playerLengthChange,
  });

  final int onsetTick;
  final double? durationSeconds;
  final int? endTick;
  final String actorId;
  final String? actorManeuver;
  final double? urgencyAtOnset;
  final double? peakUrgency;
  final String responseAction;
  final int? responseLatencyTicks;
  final String outcome;
  final int playerCollisionCount;
  final bool sprintRequestedDuringEpisode;
  final int? playerLengthAtOnset;
  final int? playerLengthAtEnd;

  /// End minus onset length. This is descriptive and does not assign causality.
  final int? playerLengthChange;

  Map<String, Object?> toJson() => <String, Object?>{
        'onsetTick': onsetTick,
        'durationSeconds': durationSeconds,
        'endTick': endTick,
        'actorId': actorId,
        'actorManeuver': actorManeuver,
        'urgencyAtOnset': urgencyAtOnset,
        'peakUrgency': peakUrgency,
        'responseAction': responseAction,
        'responseLatencyTicks': responseLatencyTicks,
        'outcome': outcome,
        'playerCollisionCount': playerCollisionCount,
        'sprintRequestedDuringEpisode': sprintRequestedDuringEpisode,
        'playerLengthAtOnset': playerLengthAtOnset,
        'playerLengthAtEnd': playerLengthAtEnd,
        'playerLengthChange': playerLengthChange,
      };
}

class SoulBehaviorSignature {
  SoulBehaviorSignature({
    required this.runId,
    required this.recordSchemaVersion,
    required this.featureVersion,
    required List<BehaviorTraitSummary> traits,
    required List<PressureEpisodeSummary> pressureEpisodes,
    required this.controlSampleCount,
    required this.observationSampleCount,
    required this.eventCount,
  })  : traits = List<BehaviorTraitSummary>.unmodifiable(traits),
        pressureEpisodes =
            List<PressureEpisodeSummary>.unmodifiable(pressureEpisodes);

  final String runId;
  final int recordSchemaVersion;
  final String featureVersion;
  final List<BehaviorTraitSummary> traits;
  final List<PressureEpisodeSummary> pressureEpisodes;
  final int controlSampleCount;
  final int observationSampleCount;
  final int eventCount;

  Map<String, Object?> toJson() => <String, Object?>{
        'runId': runId,
        'recordSchemaVersion': recordSchemaVersion,
        'featureVersion': featureVersion,
        'controlSampleCount': controlSampleCount,
        'observationSampleCount': observationSampleCount,
        'eventCount': eventCount,
        'traits': traits.map((trait) => trait.toJson()).toList(),
        'pressureEpisodes':
            pressureEpisodes.map((episode) => episode.toJson()).toList(),
      };
}

/// Extracts versioned descriptive evidence from immutable run chunks.
///
/// The extractor is pure Dart: it reads the supplied bytes and does not mutate
/// the run or create or update a Soul.
class SoulFeatureExtractor {
  const SoulFeatureExtractor();

  SoulFeatureExtractionResult extract({
    required String runId,
    required int recordSchemaVersion,
    required int tickRateHz,
    required List<Uint8List> chunkPayloads,
  }) {
    if (recordSchemaVersion != currentTrainingRecordSchemaVersion) {
      return SoulFeatureExtractionResult.unsupportedSchema(
        recordSchemaVersion,
      );
    }
    if (runId.trim().isEmpty || tickRateHz <= 0) {
      return const SoulFeatureExtractionResult.invalidTrace(
        'Run identity or tick rate is invalid.',
      );
    }

    try {
      final trace = _readTrace(runId, chunkPayloads);
      final episodes = _buildPressureEpisodes(trace, tickRateHz);
      final traits = _buildTraits(trace, episodes);
      return SoulFeatureExtractionResult.ready(
        SoulBehaviorSignature(
          runId: runId,
          recordSchemaVersion: recordSchemaVersion,
          featureVersion: currentSoulFeatureVersion,
          traits: traits,
          pressureEpisodes: episodes,
          controlSampleCount: trace.controls.length,
          observationSampleCount: trace.observations.length,
          eventCount: trace.events.length,
        ),
      );
    } on _UnsupportedSchema catch (error) {
      return SoulFeatureExtractionResult.unsupportedSchema(error.version);
    } on FormatException catch (error) {
      return SoulFeatureExtractionResult.invalidTrace(error.message);
    } on StateError catch (error) {
      return SoulFeatureExtractionResult.invalidTrace(error.message);
    }
  }
}

class _RecordedTrace {
  _RecordedTrace({
    required this.controls,
    required this.observations,
    required this.events,
  });

  final List<_ControlSample> controls;
  final List<_ObservationSample> observations;
  final List<_RunEvent> events;
}

class _ControlSample {
  const _ControlSample({
    required this.tick,
    required this.steeringX,
    required this.steeringY,
    required this.sprintRequested,
  });

  final int tick;
  final double steeringX;
  final double steeringY;
  final bool sprintRequested;
}

class _ActorObservation {
  const _ActorObservation({
    required this.actorId,
    this.role,
    this.intent,
    this.maneuver,
    this.maneuverPhase,
  });

  final String actorId;
  final String? role;
  final String? intent;
  final String? maneuver;
  final String? maneuverPhase;
}

class _ObservationSample {
  const _ObservationSample({
    required this.tick,
    this.positionX,
    this.positionY,
    this.headingX,
    this.headingY,
    this.length,
    this.sprinting,
    this.nearestThreatDistance,
    this.nearbyThreatCount,
    this.nearbyNaturalFoodCount,
    this.nearbyDroppedMassCount,
    this.boundaryRisk,
    this.actors = const <String, _ActorObservation>{},
  });

  final int tick;
  final double? positionX;
  final double? positionY;
  final double? headingX;
  final double? headingY;
  final int? length;
  final bool? sprinting;
  final double? nearestThreatDistance;
  final int? nearbyThreatCount;
  final int? nearbyNaturalFoodCount;
  final int? nearbyDroppedMassCount;
  final double? boundaryRisk;
  final Map<String, _ActorObservation> actors;
}

class _RunEvent {
  const _RunEvent({
    required this.order,
    required this.kind,
    required this.actorId,
    this.tick,
    this.targetId,
    this.value,
    this.detail,
  });

  final int order;
  final int? tick;
  final String kind;
  final String actorId;
  final String? targetId;
  final double? value;
  final String? detail;
}

class _UnsupportedSchema implements Exception {
  const _UnsupportedSchema(this.version);
  final int version;
}

_RecordedTrace _readTrace(String runId, List<Uint8List> payloads) {
  final controls = <_ControlSample>[];
  final observations = <_ObservationSample>[];
  final events = <_RunEvent>[];
  var expectedSequence = 0;
  int? previousLastTick;
  var eventOrder = 0;

  for (final payload in payloads) {
    final decoded = jsonDecode(utf8.decode(payload));
    final chunk = _object(decoded, 'run chunk');
    final schemaVersion = chunk['schemaVersion'];
    if (schemaVersion is! int) {
      throw const FormatException('Run chunk schema version is missing.');
    }
    if (schemaVersion != currentTrainingRecordSchemaVersion) {
      throw _UnsupportedSchema(schemaVersion);
    }
    if (chunk['format'] != 'snek-run-chunk' ||
        chunk['runId'] != runId ||
        chunk['sequence'] != expectedSequence) {
      throw const FormatException('Run chunk identity or sequence is invalid.');
    }

    final firstTick = _integer(chunk, 'firstTick');
    final lastTick = _integer(chunk, 'lastTick');
    if (firstTick < 0 ||
        lastTick < firstTick ||
        (previousLastTick != null && firstTick <= previousLastTick)) {
      throw const FormatException('Run chunk tick range is invalid.');
    }
    previousLastTick = lastTick;
    expectedSequence++;

    for (final value in _array(chunk, 'controls')) {
      final sample = _optionalObject(value);
      if (sample == null) continue;
      final tick = _optionalInt(sample['tick']);
      final x = _optionalNumber(sample['steeringX']);
      final y = _optionalNumber(sample['steeringY']);
      final sprint = sample['sprintRequested'];
      if (tick == null || x == null || y == null || sprint is! bool) continue;
      controls.add(
        _ControlSample(
          tick: tick,
          steeringX: x,
          steeringY: y,
          sprintRequested: sprint,
        ),
      );
    }

    for (final value in _array(chunk, 'observations')) {
      final sample = _optionalObject(value);
      if (sample == null) continue;
      final tick = _optionalInt(sample['tick']);
      if (tick == null) continue;
      final actorValues = sample['actors'];
      final actors = <String, _ActorObservation>{};
      if (actorValues is List) {
        for (final actorValue in actorValues) {
          final actor = _optionalObject(actorValue);
          final actorId = actor?['actorId'];
          if (actor == null || actorId is! String || actorId.isEmpty) continue;
          actors[actorId] = _ActorObservation(
            actorId: actorId,
            role: _optionalString(actor['role']),
            intent: _optionalString(actor['intent']),
            maneuver: _optionalString(actor['maneuver']),
            maneuverPhase: _optionalString(actor['maneuverPhase']),
          );
        }
      }
      observations.add(
        _ObservationSample(
          tick: tick,
          positionX: _optionalNumber(sample['playerPositionX']),
          positionY: _optionalNumber(sample['playerPositionY']),
          headingX: _optionalNumber(sample['playerHeadingX']),
          headingY: _optionalNumber(sample['playerHeadingY']),
          length: _optionalInt(sample['playerLength']),
          sprinting: sample['playerSprinting'] is bool
              ? sample['playerSprinting'] as bool
              : null,
          nearestThreatDistance:
              _optionalNumber(sample['nearestThreatDistance']),
          nearbyThreatCount: _optionalInt(sample['nearbyThreatCount']),
          nearbyNaturalFoodCount:
              _optionalInt(sample['nearbyNaturalFoodCount']),
          nearbyDroppedMassCount:
              _optionalInt(sample['nearbyDroppedMassCount']),
          boundaryRisk: _optionalNumber(sample['boundaryRisk']),
          actors: Map<String, _ActorObservation>.unmodifiable(actors),
        ),
      );
    }

    for (final value in _array(chunk, 'events')) {
      final event = _optionalObject(value);
      if (event == null) continue;
      final kind = event['kind'];
      final actorId = event['actorId'];
      if (kind is! String || actorId is! String) continue;
      events.add(
        _RunEvent(
          order: eventOrder++,
          tick: _optionalInt(event['tick']),
          kind: kind,
          actorId: actorId,
          targetId: _optionalString(event['targetId']),
          value: _optionalNumber(event['value']),
          detail: _optionalString(event['detail']),
        ),
      );
    }
  }

  controls.sort((a, b) => a.tick.compareTo(b.tick));
  observations.sort((a, b) => a.tick.compareTo(b.tick));
  events.sort((a, b) {
    final leftTick = a.tick ?? 0;
    final rightTick = b.tick ?? 0;
    final byTick = leftTick.compareTo(rightTick);
    return byTick != 0 ? byTick : a.order.compareTo(b.order);
  });

  return _RecordedTrace(
    controls: List<_ControlSample>.unmodifiable(controls),
    observations: List<_ObservationSample>.unmodifiable(observations),
    events: List<_RunEvent>.unmodifiable(events),
  );
}

List<BehaviorTraitSummary> _buildTraits(
  _RecordedTrace trace,
  List<PressureEpisodeSummary> episodes,
) {
  return <BehaviorTraitSummary>[
    _resourceTrait(trace),
    _sizeAndAgilityTrait(trace),
    _movementTrait(trace),
    _sprintTrait(trace),
    _riskTrait(trace),
    _threatResponseTrait(episodes),
    _botCounterStrategyTrait(trace),
  ];
}

BehaviorTraitSummary _resourceTrait(_RecordedTrace trace) {
  final pickups = <String, int>{
    'natural': 0,
    'sprintDrop': 0,
    'defeatDrop': 0,
    'other': 0,
  };
  for (final event in trace.events) {
    if (event.kind != 'foodCollected') continue;
    final kind = event.targetId;
    pickups[pickups.containsKey(kind) ? kind! : 'other'] =
        (pickups[pickups.containsKey(kind) ? kind! : 'other'] ?? 0) + 1;
  }

  final validExposureSamples = trace.observations
      .where((sample) =>
          sample.nearbyNaturalFoodCount != null &&
          sample.nearbyDroppedMassCount != null)
      .toList(growable: false);
  final naturalExposureSamples = validExposureSamples
      .where((sample) => sample.nearbyNaturalFoodCount! > 0)
      .length;
  final massExposureSamples = validExposureSamples
      .where((sample) => sample.nearbyDroppedMassCount! > 0)
      .length;
  final mixedExposureSamples = validExposureSamples
      .where((sample) =>
          sample.nearbyNaturalFoodCount! > 0 &&
          sample.nearbyDroppedMassCount! > 0)
      .length;
  final pickupCount = pickups.values.fold<int>(0, (sum, count) => sum + count);
  final totalSamples = trace.observations.length;
  final coverage = _ratio(validExposureSamples.length, totalSamples);
  final naturalRate = naturalExposureSamples == 0
      ? null
      : pickups['natural']! / naturalExposureSamples;
  final massPickups = pickups['sprintDrop']! + pickups['defeatDrop']!;
  final massRate =
      massExposureSamples == 0 ? null : massPickups / massExposureSamples;
  String? interpretation;
  if (mixedExposureSamples >= 3 && naturalRate != null && massRate != null) {
    if ((naturalRate - massRate).abs() < 0.000001) {
      interpretation = 'Natural-food and dropped-mass pickups occurred at '
          'similar rates per observed exposure sample.';
    } else if (naturalRate > massRate) {
      interpretation = 'Natural-food pickups were more frequent per observed '
          'exposure sample; nearby availability is only an '
          'approximation of choice.';
    } else {
      interpretation = 'Dropped-mass pickups were more frequent per observed '
          'exposure sample; nearby availability is only an '
          'approximation of choice.';
    }
  } else {
    interpretation = 'There are too few samples with both resource types '
        'nearby to compare collection rates.';
  }

  return BehaviorTraitSummary(
    id: 'resourcePriority',
    label: 'Resource collection pattern',
    sampleCount: pickupCount,
    opportunityCount: mixedExposureSamples,
    coverage: coverage,
    confidence: _confidence(pickupCount, coverage, minimumSamples: 3),
    observedEvidence: <String, Object?>{
      'pickupsByKind': pickups,
      'naturalExposureSamples': naturalExposureSamples,
      'droppedMassExposureSamples': massExposureSamples,
      'mixedExposureSamples': mixedExposureSamples,
      'naturalPickupsPerExposureSample': naturalRate,
      'droppedMassPickupsPerExposureSample': massRate,
    },
    inferredInterpretation: interpretation,
  );
}

BehaviorTraitSummary _sizeAndAgilityTrait(_RecordedTrace trace) {
  final lengths = trace.observations
      .map((sample) => sample.length)
      .whereType<int>()
      .where((length) => length > 0)
      .toList(growable: false);
  final turns = _turnAngles(trace.observations);
  final averageLength =
      _mean(lengths.map((value) => value.toDouble()).toList());
  final averageTurn = _mean(turns);
  final count = lengths.length < turns.length ? lengths.length : turns.length;
  final coverage = _ratio(count, trace.observations.length);
  return BehaviorTraitSummary(
    id: 'sizeAgility',
    label: 'Size and agility',
    sampleCount: count,
    opportunityCount: trace.observations.length,
    coverage: coverage,
    confidence: _confidence(count, coverage, minimumSamples: 3),
    observedEvidence: <String, Object?>{
      'lengthSampleCount': lengths.length,
      'minimumObservedLength':
          lengths.isEmpty ? null : lengths.reduce((a, b) => a < b ? a : b),
      'meanObservedLength': averageLength,
      'maximumObservedLength':
          lengths.isEmpty ? null : lengths.reduce((a, b) => a > b ? a : b),
      'turnSampleCount': turns.length,
      'meanTurnRadiansPerObservation': averageTurn,
      'meanTurnDegreesPerObservation':
          averageTurn == null ? null : averageTurn * 180 / math.pi,
    },
    inferredInterpretation: averageTurn == null
        ? 'Insufficient heading samples to describe turning behavior.'
        : 'Average sampled heading change was '
            '${(averageTurn * 180 / math.pi).toStringAsFixed(1)} '
            'degrees per observation interval.',
  );
}

BehaviorTraitSummary _movementTrait(_RecordedTrace trace) {
  final positions = trace.observations
      .where((sample) => sample.positionX != null && sample.positionY != null)
      .toList(growable: false);
  var pathLength = 0.0;
  for (var index = 1; index < positions.length; index++) {
    final dx = positions[index].positionX! - positions[index - 1].positionX!;
    final dy = positions[index].positionY! - positions[index - 1].positionY!;
    pathLength += math.sqrt(dx * dx + dy * dy);
  }
  double? efficiency;
  if (positions.length >= 2 && pathLength > 0) {
    final dx = positions.last.positionX! - positions.first.positionX!;
    final dy = positions.last.positionY! - positions.first.positionY!;
    efficiency =
        (math.sqrt(dx * dx + dy * dy) / pathLength).clamp(0.0, 1.0).toDouble();
  }
  final sampleCount = positions.length > 1 ? positions.length - 1 : 0;
  final coverage = _ratio(positions.length, trace.observations.length);
  return BehaviorTraitSummary(
    id: 'movementShape',
    label: 'Movement shape',
    sampleCount: sampleCount,
    opportunityCount:
        trace.observations.length > 1 ? trace.observations.length - 1 : 0,
    coverage: coverage,
    confidence: _confidence(sampleCount, coverage, minimumSamples: 3),
    observedEvidence: <String, Object?>{
      'positionSampleCount': positions.length,
      'sampledPathDistance': pathLength,
      'pathEfficiency': efficiency,
    },
    inferredInterpretation: efficiency == null
        ? 'Insufficient position samples to describe path shape.'
        : 'Recorded path efficiency was '
            '${(efficiency * 100).toStringAsFixed(1)}% '
            '(straight-line distance divided by sampled path distance).',
  );
}

BehaviorTraitSummary _sprintTrait(_RecordedTrace trace) {
  final controlCount = trace.controls.length;
  final requestedCount =
      trace.controls.where((sample) => sample.sprintRequested).length;
  var requestTransitions = 0;
  for (var index = 1; index < trace.controls.length; index++) {
    if (trace.controls[index].sprintRequested !=
        trace.controls[index - 1].sprintRequested) {
      requestTransitions++;
    }
  }
  final sprintingSamples =
      trace.observations.where((sample) => sample.sprinting != null).toList();
  final activeCount =
      sprintingSamples.where((sample) => sample.sprinting!).length;
  final sampleCount = controlCount + sprintingSamples.length;
  final opportunityCount = trace.controls.length + trace.observations.length;
  final coverage = _ratio(sampleCount, opportunityCount);
  final requestShare = _ratio(requestedCount, controlCount);
  final activeShare = _ratio(activeCount, sprintingSamples.length);
  return BehaviorTraitSummary(
    id: 'sprintBehavior',
    label: 'Sprint behavior',
    sampleCount: sampleCount,
    opportunityCount: opportunityCount,
    coverage: coverage,
    confidence: _confidence(sampleCount, coverage, minimumSamples: 6),
    observedEvidence: <String, Object?>{
      'sprintRequestedSamples': requestedCount,
      'controlSampleCount': controlCount,
      'requestShare': requestShare,
      'requestTransitions': requestTransitions,
      'activeSprintSamples': activeCount,
      'sprintObservationCount': sprintingSamples.length,
      'activeShare': activeShare,
    },
    inferredInterpretation: controlCount == 0 && sprintingSamples.isEmpty
        ? 'No sprint samples were recorded.'
        : 'Sprint was requested in '
            '${(requestShare * 100).toStringAsFixed(1)}% of control samples and '
            'active in ${(activeShare * 100).toStringAsFixed(1)}% of observations '
            'with sprint state.',
  );
}

BehaviorTraitSummary _riskTrait(_RecordedTrace trace) {
  final samples = trace.observations
      .where((sample) =>
          sample.boundaryRisk != null && sample.nearbyThreatCount != null)
      .toList(growable: false);
  final highBoundarySamples =
      samples.where((sample) => sample.boundaryRisk! >= 0.5).length;
  final threatSamples =
      samples.where((sample) => sample.nearbyThreatCount! > 0).length;
  final playerCollisions = trace.events
      .where((event) => event.kind == 'collision' && event.actorId == 'player')
      .length;
  final playerDefeats = trace.events
      .where((event) => event.kind == 'defeat' && event.actorId == 'player')
      .length;
  final nearestDistances = trace.observations
      .map((sample) => sample.nearestThreatDistance)
      .whereType<double>()
      .where((distance) => distance >= 0)
      .toList(growable: false);
  final coverage = _ratio(samples.length, trace.observations.length);
  return BehaviorTraitSummary(
    id: 'riskPosture',
    label: 'Risk and exposure',
    sampleCount: samples.length,
    opportunityCount: trace.observations.length,
    coverage: coverage,
    confidence: _confidence(samples.length, coverage, minimumSamples: 6),
    observedEvidence: <String, Object?>{
      'riskObservationCount': samples.length,
      'highBoundaryRiskSamples': highBoundarySamples,
      'highBoundaryRiskShare': _ratio(highBoundarySamples, samples.length),
      'nearbyThreatSamples': threatSamples,
      'nearbyThreatShare': _ratio(threatSamples, samples.length),
      'minimumThreatDistance': nearestDistances.isEmpty
          ? null
          : nearestDistances.reduce((a, b) => a < b ? a : b),
      'playerCollisionEvents': playerCollisions,
      'playerDefeatEvents': playerDefeats,
    },
    inferredInterpretation: samples.isEmpty
        ? 'No complete risk samples were recorded.'
        : highBoundarySamples * 4 >= samples.length
            ? 'A substantial share of recorded samples was in the boundary '
                'warning band.'
            : 'Recorded boundary and nearby-threat exposure are descriptive; '
                'they do not establish why the player chose an action.',
  );
}

BehaviorTraitSummary _threatResponseTrait(
  List<PressureEpisodeSummary> episodes,
) {
  final completed = episodes.where((episode) => episode.endTick != null).length;
  final responseLatencies = episodes
      .map((episode) => episode.responseLatencyTicks)
      .whereType<int>()
      .toList(growable: false);
  final meanLatency = _mean(
    responseLatencies.map((value) => value.toDouble()).toList(),
  );
  final actions = <String, int>{};
  final outcomes = <String, int>{};
  for (final episode in episodes) {
    if (episode.responseAction != 'baseline unavailable') {
      actions[episode.responseAction] =
          (actions[episode.responseAction] ?? 0) + 1;
    }
    outcomes[episode.outcome] = (outcomes[episode.outcome] ?? 0) + 1;
  }
  final coverage = _ratio(completed, episodes.length);
  final measuredResponseCount = episodes
      .where((episode) =>
          episode.endTick != null &&
          episode.responseAction != 'baseline unavailable')
      .length;
  return BehaviorTraitSummary(
    id: 'threatResponse',
    label: 'Threat response',
    sampleCount: measuredResponseCount,
    opportunityCount: episodes.length,
    coverage: coverage,
    confidence: _confidence(
      measuredResponseCount,
      coverage,
      minimumSamples: 1,
    ),
    observedEvidence: <String, Object?>{
      'pressureEpisodeCount': episodes.length,
      'completedEpisodeCount': completed,
      'measuredResponseCount': measuredResponseCount,
      'meanResponseLatencyTicks': meanLatency,
      'responseActions': actions,
      'outcomes': outcomes,
    },
    inferredInterpretation: episodes.isEmpty
        ? 'No pressure episode was observed; response rate is not estimated.'
        : measuredResponseCount == 0
            ? 'Pressure was recorded, but there is not enough completed input '
                'coverage to measure a response.'
            : 'Mean measured response latency was '
                '${meanLatency!.toStringAsFixed(1)} simulation ticks after '
                'pressure onset.',
  );
}

BehaviorTraitSummary _botCounterStrategyTrait(_RecordedTrace trace) {
  final maneuverTransitions = <String, int>{};
  final roleTransitions = <String, int>{};
  final observedIntents = <String, int>{};
  final observedManeuvers = <String, int>{};
  for (final event in trace.events) {
    if (event.kind == 'botManeuverChanged' && event.detail != null) {
      final maneuver = event.detail!.split(':').first;
      maneuverTransitions[maneuver] = (maneuverTransitions[maneuver] ?? 0) + 1;
    } else if (event.kind == 'botRoleChanged' && event.detail != null) {
      roleTransitions[event.detail!] =
          (roleTransitions[event.detail!] ?? 0) + 1;
    }
  }
  var actorSamples = 0;
  for (final observation in trace.observations) {
    for (final actor in observation.actors.values) {
      if (actor.role != 'bot') continue;
      actorSamples++;
      final intent = actor.intent;
      if (intent != null) {
        observedIntents[intent] = (observedIntents[intent] ?? 0) + 1;
      }
      final maneuver = actor.maneuver;
      if (maneuver != null) {
        observedManeuvers[maneuver] = (observedManeuvers[maneuver] ?? 0) + 1;
      }
    }
  }
  final sampleCount = maneuverTransitions.values.fold<int>(
        0,
        (sum, count) => sum + count,
      ) +
      roleTransitions.values.fold<int>(
        0,
        (sum, count) => sum + count,
      ) +
      actorSamples;
  final opportunityCount = trace.observations.length;
  final coverage = _ratio(actorSamples, opportunityCount);
  final topManeuver = _topKey(observedManeuvers);
  return BehaviorTraitSummary(
    id: 'botCounterStrategies',
    label: 'Bot counter-strategies observed',
    sampleCount: sampleCount,
    opportunityCount: opportunityCount,
    coverage: coverage,
    confidence: _confidence(sampleCount, coverage, minimumSamples: 3),
    observedEvidence: <String, Object?>{
      'botActorObservationCount': actorSamples,
      'observedIntents': observedIntents,
      'observedManeuvers': observedManeuvers,
      'maneuverTransitions': maneuverTransitions,
      'roleTransitions': roleTransitions,
    },
    inferredInterpretation: topManeuver == null
        ? 'No bot maneuver was captured in the available samples.'
        : 'The most frequently observed bot maneuver was $topManeuver. '
            'This describes bot behavior, not its effectiveness.',
  );
}

List<PressureEpisodeSummary> _buildPressureEpisodes(
  _RecordedTrace trace,
  int tickRateHz,
) {
  final open = <String, _PressureDraft>{};
  final completed = <_PressureDraft>[];
  var unidentified = 0;

  for (final event in trace.events) {
    final tick = event.tick;
    if (tick == null) continue;

    if (event.kind == 'botPressureStarted') {
      final key = event.targetId ?? 'unidentified-$unidentified';
      if (event.targetId == null) unidentified++;
      final previous = open.remove(key);
      if (previous != null) {
        previous.endTick = tick;
        previous.outcome = 'superseded pressure onset';
        completed.add(previous);
      }
      open[key] = _PressureDraft(
        key: key,
        actorId: event.targetId ?? 'unknown actor',
        onsetTick: tick,
        urgencyAtOnset: event.value,
        peakUrgency: event.value,
      );
      continue;
    }

    if (event.kind == 'botPressureEscalated') {
      final draft = _findOpenPressure(open, event.targetId);
      if (draft != null && event.value != null) {
        final previousPeak = draft.peakUrgency;
        if (previousPeak == null || event.value! > previousPeak) {
          draft.peakUrgency = event.value;
        }
      }
      continue;
    }

    if (event.kind == 'botPressureEnded') {
      final draft = _removeOpenPressure(open, event.targetId);
      if (draft != null) {
        draft.endTick = tick;
        draft.outcome = 'pressure ended';
        completed.add(draft);
      }
      continue;
    }

    if (event.kind == 'collision' &&
        event.actorId == 'player' &&
        event.targetId != null) {
      final draft = _findOpenPressure(open, event.targetId);
      if (draft != null) draft.playerCollisionCount++;
      continue;
    }

    if (event.kind == 'runEnded' && event.actorId == 'player') {
      for (final draft in open.values) {
        draft.endTick = tick;
        draft.outcome = 'run ended during pressure';
        completed.add(draft);
      }
      open.clear();
    }
  }

  completed.addAll(open.values);
  completed.sort((a, b) {
    final byTick = a.onsetTick.compareTo(b.onsetTick);
    return byTick != 0 ? byTick : a.actorId.compareTo(b.actorId);
  });

  return List<PressureEpisodeSummary>.unmodifiable(
    completed.map((draft) {
      final endTick = draft.endTick;
      final onsetObservation =
          _observationAtOrAfter(trace.observations, draft.onsetTick);
      final endObservation = endTick == null
          ? null
          : _observationAtOrBefore(trace.observations, endTick);
      final baseline = _controlAtOrBefore(trace.controls, draft.onsetTick);
      final response = _measureResponse(
        trace.controls,
        draft.onsetTick,
        endTick,
        baseline,
      );
      final maneuver = onsetObservation?.actors[draft.actorId]?.maneuver ??
          _lastManeuver(trace.events, draft.actorId, draft.onsetTick);
      final onsetLength = onsetObservation?.length;
      final endLength = endObservation?.length;
      return PressureEpisodeSummary(
        onsetTick: draft.onsetTick,
        durationSeconds:
            endTick == null ? null : (endTick - draft.onsetTick) / tickRateHz,
        endTick: endTick,
        actorId: draft.actorId,
        actorManeuver: maneuver,
        urgencyAtOnset: draft.urgencyAtOnset,
        peakUrgency: draft.peakUrgency,
        responseAction: response.action,
        responseLatencyTicks: response.latencyTicks,
        outcome: draft.outcome,
        playerCollisionCount: draft.playerCollisionCount,
        sprintRequestedDuringEpisode: trace.controls.any(
          (sample) =>
              sample.tick >= draft.onsetTick &&
              (endTick == null || sample.tick <= endTick) &&
              sample.sprintRequested,
        ),
        playerLengthAtOnset: onsetLength,
        playerLengthAtEnd: endLength,
        playerLengthChange: onsetLength == null || endLength == null
            ? null
            : endLength - onsetLength,
      );
    }),
  );
}

class _PressureDraft {
  _PressureDraft({
    required this.key,
    required this.actorId,
    required this.onsetTick,
    required this.urgencyAtOnset,
    required this.peakUrgency,
  });

  final String key;
  final String actorId;
  final int onsetTick;
  final double? urgencyAtOnset;
  double? peakUrgency;
  int? endTick;
  String outcome = 'pressure still active at run end';
  int playerCollisionCount = 0;
}

_PressureDraft? _findOpenPressure(
  Map<String, _PressureDraft> open,
  String? actorId,
) {
  if (actorId != null) return open[actorId];
  if (open.length == 1) return open.values.single;
  return null;
}

_PressureDraft? _removeOpenPressure(
  Map<String, _PressureDraft> open,
  String? actorId,
) {
  if (actorId != null) return open.remove(actorId);
  if (open.length == 1) return open.remove(open.keys.single);
  return null;
}

({String action, int? latencyTicks}) _measureResponse(
  List<_ControlSample> controls,
  int onsetTick,
  int? endTick,
  _ControlSample? baseline,
) {
  if (baseline == null) {
    return (action: 'baseline unavailable', latencyTicks: null);
  }
  for (final sample in controls) {
    if (sample.tick <= onsetTick ||
        (endTick != null && sample.tick > endTick)) {
      continue;
    }
    final steerChanged = _steeringChanged(baseline, sample);
    final sprintChanged = sample.sprintRequested != baseline.sprintRequested;
    if (steerChanged || sprintChanged) {
      final action = steerChanged && sprintChanged
          ? 'steering and sprint change'
          : steerChanged
              ? 'steering change'
              : 'sprint change';
      return (action: action, latencyTicks: sample.tick - onsetTick);
    }
  }
  return (
    action:
        endTick == null ? 'response not yet observed' : 'no change observed',
    latencyTicks: null
  );
}

bool _steeringChanged(_ControlSample before, _ControlSample after) {
  final beforeMagnitude = math.sqrt(
    before.steeringX * before.steeringX + before.steeringY * before.steeringY,
  );
  final afterMagnitude = math.sqrt(
    after.steeringX * after.steeringX + after.steeringY * after.steeringY,
  );
  if (beforeMagnitude < 0.0001 || afterMagnitude < 0.0001) {
    return (before.steeringX - after.steeringX).abs() > 0.2 ||
        (before.steeringY - after.steeringY).abs() > 0.2;
  }
  final dot = (before.steeringX * after.steeringX +
          before.steeringY * after.steeringY) /
      (beforeMagnitude * afterMagnitude);
  return math.acos(dot.clamp(-1.0, 1.0)) >= 0.35;
}

_ControlSample? _controlAtOrBefore(
  List<_ControlSample> samples,
  int tick,
) {
  _ControlSample? match;
  for (final sample in samples) {
    if (sample.tick > tick) break;
    match = sample;
  }
  return match;
}

_ObservationSample? _observationAtOrAfter(
  List<_ObservationSample> samples,
  int tick,
) {
  for (final sample in samples) {
    if (sample.tick >= tick) return sample;
  }
  return null;
}

_ObservationSample? _observationAtOrBefore(
  List<_ObservationSample> samples,
  int tick,
) {
  _ObservationSample? match;
  for (final sample in samples) {
    if (sample.tick > tick) break;
    match = sample;
  }
  return match;
}

String? _lastManeuver(
  List<_RunEvent> events,
  String actorId,
  int atOrBeforeTick,
) {
  String? result;
  for (final event in events) {
    if (event.tick == null || event.tick! > atOrBeforeTick) continue;
    if (event.kind != 'botManeuverChanged' || event.actorId != actorId) {
      continue;
    }
    final detail = event.detail;
    if (detail != null) result = detail.split(':').first;
  }
  return result;
}

List<double> _turnAngles(List<_ObservationSample> observations) {
  final result = <double>[];
  _ObservationSample? previous;
  for (final current in observations) {
    if (current.headingX == null || current.headingY == null) continue;
    if (previous != null &&
        previous.headingX != null &&
        previous.headingY != null) {
      final leftMagnitude = math.sqrt(
        previous.headingX! * previous.headingX! +
            previous.headingY! * previous.headingY!,
      );
      final rightMagnitude = math.sqrt(
        current.headingX! * current.headingX! +
            current.headingY! * current.headingY!,
      );
      if (leftMagnitude > 0 && rightMagnitude > 0) {
        final dot = (previous.headingX! * current.headingX! +
                previous.headingY! * current.headingY!) /
            (leftMagnitude * rightMagnitude);
        result.add(math.acos(dot.clamp(-1.0, 1.0)));
      }
    }
    previous = current;
  }
  return result;
}

double? _mean(List<double> values) {
  if (values.isEmpty) return null;
  return values.fold<double>(0, (sum, value) => sum + value) / values.length;
}

double _ratio(int numerator, int denominator) {
  if (denominator <= 0) return 0;
  return (numerator / denominator).clamp(0.0, 1.0).toDouble();
}

FeatureConfidence _confidence(
  int sampleCount,
  double coverage, {
  required int minimumSamples,
}) {
  if (sampleCount < minimumSamples || coverage < 0.25) {
    return FeatureConfidence.insufficient;
  }
  if (sampleCount < 8 || coverage < 0.5) return FeatureConfidence.low;
  if (sampleCount < 20 || coverage < 0.75) return FeatureConfidence.moderate;
  return FeatureConfidence.high;
}

String? _topKey(Map<String, int> counts) {
  if (counts.isEmpty) return null;
  final entries = counts.entries.toList()
    ..sort((a, b) {
      final byCount = b.value.compareTo(a.value);
      return byCount != 0 ? byCount : a.key.compareTo(b.key);
    });
  return entries.first.key;
}

Map<String, Object?> _object(Object? value, String label) {
  final result = _optionalObject(value);
  if (result == null) throw FormatException('Expected $label object.');
  return result;
}

Map<String, Object?>? _optionalObject(Object? value) {
  if (value is! Map) return null;
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key is! String) return null;
    result[entry.key as String] = entry.value;
  }
  return result;
}

List<Object?> _array(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! List) throw FormatException('Expected $key array.');
  return value;
}

int _integer(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! int) throw FormatException('Expected integer field: $key');
  return value;
}

int? _optionalInt(Object? value) => value is int ? value : null;

double? _optionalNumber(Object? value) {
  if (value is! num || !value.isFinite) return null;
  return value.toDouble();
}

String? _optionalString(Object? value) =>
    value is String && value.isNotEmpty ? value : null;
