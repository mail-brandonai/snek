import 'dart:convert';
import 'dart:typed_data';

import '../domain/recording_contract.dart'
    show currentTrainingRecordSchemaVersion;
import '../domain/training_application.dart';
import '../domain/training_models.dart';
import '../domain/training_repositories.dart';

class RunReviewItem {
  const RunReviewItem({
    required this.run,
    required this.controlSampleCount,
    required this.observationSampleCount,
    required this.eventCount,
    required this.score,
    required this.length,
    required this.survivalSeconds,
    required this.rank,
    required this.outcome,
    required this.firstTick,
    required this.lastTick,
  });

  final TrainingRun run;
  final int controlSampleCount;
  final int observationSampleCount;
  final int eventCount;
  final int? score;
  final int? length;
  final double? survivalSeconds;
  final int? rank;
  final String? outcome;
  final int? firstTick;
  final int? lastTick;

  String get playerName {
    final value = run.config['playerName'];
    return value is String && value.trim().isNotEmpty ? value : 'Unknown Snek';
  }

  factory RunReviewItem.fromChunks(
    TrainingRun run,
    List<Uint8List> payloads,
  ) {
    var controlCount = 0;
    var observationCount = 0;
    var eventCount = 0;
    int? firstTick;
    int? lastTick;
    Map<String, Object?>? outcomeMetadata;
    String? outcome;

    for (var sequence = 0; sequence < payloads.length; sequence++) {
      final decoded = jsonDecode(utf8.decode(payloads[sequence]));
      if (decoded is! Map) throw StateError('Run chunk is not an object');
      final chunk = Map<String, Object?>.from(decoded);
      if (chunk['format'] != 'snek-run-chunk' ||
          chunk['schemaVersion'] != currentTrainingRecordSchemaVersion ||
          chunk['runId'] != run.id ||
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

      controlCount += _arrayLength(chunk, 'controls');
      observationCount += _arrayLength(chunk, 'observations');
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
    }

    return RunReviewItem(
      run: run,
      controlSampleCount: controlCount,
      observationSampleCount: observationCount,
      eventCount: eventCount,
      score: _integer(outcomeMetadata?['score']),
      length: _integer(outcomeMetadata?['length']),
      survivalSeconds: _decimal(outcomeMetadata?['survivalSeconds']),
      rank: _integer(outcomeMetadata?['rank']),
      outcome: outcome,
      firstTick: firstTick,
      lastTick: lastTick,
    );
  }
}

class RunReviewService {
  const RunReviewService({
    required this.runs,
    required this.chunks,
    required this.lifecycle,
  });

  final RunRepository runs;
  final RunChunkRepository chunks;
  final RunLifecycleService lifecycle;

  Future<List<TrainingRun>> listRuns() async {
    final all = await runs.listRuns();
    return all
        .where(
          (run) =>
              run.status == TrainingRunStatus.pendingReview ||
              run.status == TrainingRunStatus.retained ||
              run.status == TrainingRunStatus.incomplete,
        )
        .toList(growable: false);
  }

  Future<RunReviewItem?> loadRun(String runId) async {
    final run = await runs.getRun(runId);
    if (run == null) return null;
    if (run.status == TrainingRunStatus.recording ||
        run.status == TrainingRunStatus.discarded) {
      throw StateError('Run is not available for review');
    }
    final payloads = await chunks.chunkPayloadsFor(runId);
    return RunReviewItem.fromChunks(run, payloads);
  }

  Future<void> keepRun(String runId) async {
    final run = await runs.getRun(runId);
    if (run == null) throw StateError('Run does not exist');
    if (run.status != TrainingRunStatus.pendingReview) {
      throw StateError('Only complete pending runs can be kept');
    }
    await lifecycle.review(runId, retain: true);
  }

  Future<void> discardRun(String runId) async {
    final run = await runs.getRun(runId);
    if (run == null) throw StateError('Run does not exist');
    if (run.status != TrainingRunStatus.pendingReview &&
        run.status != TrainingRunStatus.retained &&
        run.status != TrainingRunStatus.incomplete) {
      throw StateError('Run cannot be discarded from its current state');
    }
    await runs.deleteRun(runId);
  }
}

int _arrayLength(Map<String, Object?> object, String key) =>
    _array(object, key).length;

List<Object?> _array(Map<String, Object?> object, String key) {
  final value = object[key];
  if (value is! List) throw StateError('Run chunk $key is not an array');
  return value;
}

int? _integer(Object? value) => value is int ? value : null;

double? _decimal(Object? value) => value is num ? value.toDouble() : null;
