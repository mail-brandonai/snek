import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:isolate_manager/isolate_manager.dart';

import '../../game/domain/simulation.dart';
import '../../game/domain/simulation_capture.dart';
import '../../game/domain/vec2.dart';
import '../domain/recording_contract.dart'
    show currentTrainingRecordSchemaVersion;
import '../domain/soul_feature_extractor.dart';

@pragma('vm:entry-point')
@isolateManagerCustomWorker
void analyzeRunReviewChunksWorker(dynamic params) {
  unawaited(
    IsolateManagerFunction.customFunction<dynamic, dynamic>(
      params,
      onEvent: (_, message) => analyzeRunReviewChunks(_reviewInput(message)),
    ),
  );
}

Map<String, Object?> _reviewInput(dynamic message) {
  if (message is! Map) {
    throw const FormatException('Run review worker input is not a map.');
  }
  return Map<String, Object?>.from(message);
}

Map<String, Object?> analyzeRunReviewChunks(Map<String, Object?> input) {
  final runId = _requiredString(input, 'runId');
  final recordSchemaVersion = _requiredInt(input, 'recordSchemaVersion');
  final tickRateHz = _requiredInt(input, 'tickRateHz');
  final rawPayloads = input['chunkPayloads'];
  if (rawPayloads is! List) {
    throw const FormatException('Run chunk payloads are missing.');
  }

  var controlCount = 0;
  var observationCount = 0;
  var eventCount = 0;
  int? firstTick;
  int? lastTick;
  Map<String, Object?>? outcomeMetadata;
  String? outcome;
  final decodedChunks = <Object?>[];

  for (var sequence = 0; sequence < rawPayloads.length; sequence++) {
    final payload = rawPayloads[sequence];
    if (payload is! Uint8List) {
      throw const FormatException('Run chunk payload is not byte data.');
    }
    final decoded = jsonDecode(utf8.decode(payload));
    if (decoded is! Map) throw StateError('Run chunk is not an object');
    final chunk = Map<String, Object?>.from(decoded);
    if (chunk['format'] != 'snek-run-chunk' ||
        chunk['schemaVersion'] != currentTrainingRecordSchemaVersion ||
        chunk['runId'] != runId ||
        chunk['sequence'] != sequence) {
      throw StateError('Run chunk metadata is invalid');
    }
    final chunkFirst = chunk['firstTick'];
    final chunkLast = chunk['lastTick'];
    if (chunkFirst is! int ||
        chunkLast is! int ||
        chunkFirst < 0 ||
        chunkLast < chunkFirst ||
        (lastTick != null && chunkFirst <= lastTick)) {
      throw StateError('Run chunk tick range is invalid');
    }
    firstTick ??= chunkFirst;
    lastTick = chunkLast;

    controlCount += _array(chunk, 'controls').length;
    observationCount += _array(chunk, 'observations').length;
    final events = _array(chunk, 'events');
    eventCount += events.length;
    for (final value in events) {
      if (value is! Map) throw StateError('Run event is not an object');
      final event = Map<String, Object?>.from(value);
      if (event['kind'] != 'runEnded') continue;
      final metadata = event['metadata'];
      if (metadata is Map) {
        outcomeMetadata = Map<String, Object?>.from(metadata);
      }
      final detail = event['detail'];
      outcome = detail is String ? detail : null;
    }
    decodedChunks.add(chunk);
  }

  final replay = _tryReplayTacticalAnalysis(input, decodedChunks);
  final analysisChunks =
      replay == null ? decodedChunks : _mergeReplayData(decodedChunks, replay);
  eventCount = _countEvents(analysisChunks);

  final featureAnalysis = const SoulFeatureExtractor().extractDecoded(
    runId: runId,
    recordSchemaVersion: recordSchemaVersion,
    tickRateHz: tickRateHz,
    decodedChunks: analysisChunks,
  );
  return <String, Object?>{
    'controlSampleCount': controlCount,
    'observationSampleCount': observationCount,
    'eventCount': eventCount,
    'score': _integer(outcomeMetadata?['score']),
    'length': _integer(outcomeMetadata?['length']),
    'survivalSeconds': _decimal(outcomeMetadata?['survivalSeconds']),
    'rank': _integer(outcomeMetadata?['rank']),
    'outcome': outcome,
    'firstTick': firstTick,
    'lastTick': lastTick,
    'featureAnalysis': featureAnalysis.toJson(),
    'analysisSource': replay == null ? 'stored-events' : 'post-run-replay',
  };
}

const _tacticalEventKinds = <String>{
  'botPressureStarted',
  'botPressureEscalated',
  'botPressureEnded',
  'botRoleChanged',
  'botManeuverChanged',
};

class _ReplayCaptureSink
    implements SimulationCaptureSink, TacticalAnalysisCaptureSink {
  final List<SimulationObservationSnapshot> observations =
      <SimulationObservationSnapshot>[];
  final List<SimulationEventSnapshot> tacticalEvents =
      <SimulationEventSnapshot>[];

  @override
  bool get captureTacticalAnalysis => true;

  @override
  void recordControl(SimulationControlSample sample) {}

  @override
  void recordObservation(SimulationObservationSnapshot observation) {
    observations.add(observation);
  }

  @override
  void completeStep(int tick) {}

  @override
  void recordEvent(SimulationEventSnapshot event) {
    if (_tacticalEventKinds.contains(event.kind.name)) {
      tacticalEvents.add(event);
    }
  }
}

class _ReplayResult {
  const _ReplayResult({required this.observations, required this.events});

  final List<SimulationObservationSnapshot> observations;
  final List<SimulationEventSnapshot> events;
}

_ReplayResult? _tryReplayTacticalAnalysis(
  Map<String, Object?> input,
  List<Object?> decodedChunks,
) {
  final seed = _optionalInt(input['seed']);
  final runConfig = _optionalObject(input['runConfig']);
  if (seed == null || runConfig == null) return null;

  try {
    final simulationConfig = SimulationConfig.fromJson(runConfig['simulation']);
    final playerColorIndex = _optionalInt(runConfig['playerColorIndex']) ?? 0;
    final controls = <SimulationControlSample>[];
    for (final decoded in decodedChunks) {
      final chunk = _object(decoded, 'run chunk');
      for (final value in _array(chunk, 'controls')) {
        final sample = _optionalObject(value);
        if (sample == null) continue;
        final tick = _optionalInt(sample['tick']);
        final steeringX = _optionalNumber(sample['steeringX']);
        final steeringY = _optionalNumber(sample['steeringY']);
        final sprintRequested = sample['sprintRequested'];
        if (tick == null ||
            steeringX == null ||
            steeringY == null ||
            sprintRequested is! bool) {
          continue;
        }
        controls.add(
          SimulationControlSample(
            tick: tick,
            steeringX: steeringX,
            steeringY: steeringY,
            sprintRequested: sprintRequested,
          ),
        );
      }
    }
    controls.sort((left, right) => left.tick.compareTo(right.tick));
  if (controls.isEmpty) return null;
    final sink = _ReplayCaptureSink();
    final simulation = GameSimulation(
      config: simulationConfig,
      seed: seed,
      playerColorIndex: playerColorIndex,
      captureSink: sink,
    );
    for (final control in controls) {
      if (simulation.gameOver) break;
      simulation.update(
        simulation.config.simulationStep,
        Vec2(control.steeringX, control.steeringY),
        sprinting: control.sprintRequested,
      );
      if (simulation.simulationTick != control.tick) return null;
    }
    return _ReplayResult(
      observations: List<SimulationObservationSnapshot>.unmodifiable(
        sink.observations,
      ),
      events: List<SimulationEventSnapshot>.unmodifiable(sink.tacticalEvents),
    );
  } catch (_) {
    // A legacy or non-deterministic recording must remain reviewable from its
    // stored observations/events rather than failing the entire debrief.
    return null;
  }
}

List<Object?> _mergeReplayData(
  List<Object?> decodedChunks,
  _ReplayResult replay,
) {
  final result = <Object?>[];
  for (final decoded in decodedChunks) {
    final chunk = _object(decoded, 'run chunk');
    final firstTick = _requiredInt(chunk, 'firstTick');
    final lastTick = _requiredInt(chunk, 'lastTick');
    final replacement = Map<String, Object?>.from(chunk);
    replacement['observations'] = replay.observations
        .where((sample) => sample.tick >= firstTick && sample.tick <= lastTick)
        .map((sample) => sample.toJson())
        .toList(growable: false);
    final storedEvents = _array(chunk, 'events').where((value) {
      final event = _optionalObject(value);
      final kind = event?['kind'];
      return kind is! String || !_tacticalEventKinds.contains(kind);
    });
    final replayEvents = replay.events
        .where((event) => event.tick >= firstTick && event.tick <= lastTick)
        .map((event) => event.toJson());
    replacement['events'] = <Object?>[...storedEvents, ...replayEvents];
    result.add(replacement);
  }
  return List<Object?>.unmodifiable(result);
}

int _countEvents(List<Object?> decodedChunks) {
  var count = 0;
  for (final decoded in decodedChunks) {
    count += _array(_object(decoded, 'run chunk'), 'events').length;
  }
  return count;
}

Map<String, Object?> _object(Object? value, String label) {
  final result = _optionalObject(value);
  if (result == null) throw FormatException('Expected $label object.');
  return result;
}

List<Object?> _array(Map<String, Object?> object, String key) {
  final value = object[key];
  if (value is! List) throw StateError('Run chunk $key is not an array');
  return value;
}

String _requiredString(Map<String, Object?> object, String key) {
  final value = object[key];
  if (value is! String) throw FormatException('Expected string field: $key');
  return value;
}

int _requiredInt(Map<String, Object?> object, String key) {
  final value = object[key];
  if (value is! int) throw FormatException('Expected integer field: $key');
  return value;
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

int? _optionalInt(Object? value) {
  if (value is int) return value;
  if (value is num && value.isFinite && value == value.roundToDouble()) {
    return value.toInt();
  }
  return null;
}

double? _optionalNumber(Object? value) {
  if (value is! num || !value.isFinite) return null;
  return value.toDouble();
}

int? _integer(Object? value) => value is int ? value : null;

double? _decimal(Object? value) => value is num ? value.toDouble() : null;

