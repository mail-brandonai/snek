import 'dart:typed_data';

import 'package:isolate_manager/isolate_manager.dart';

import '../domain/soul_feature_extractor.dart';
import '../domain/training_application.dart';
import '../domain/training_models.dart';
import '../domain/training_repositories.dart';
import 'run_review_worker.dart';

class RunReviewItem {
  const RunReviewItem({
    required this.run,
    required this.featureAnalysis,
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
  final SoulFeatureExtractionResult featureAnalysis;
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

  factory RunReviewItem.fromWorkerResult(
    TrainingRun run,
    Map<String, Object?> result,
  ) {
    return RunReviewItem(
      run: run,
      featureAnalysis: SoulFeatureExtractionResult.fromJson(
        result['featureAnalysis'],
      ),
      controlSampleCount: _integer(result['controlSampleCount']) ?? 0,
      observationSampleCount: _integer(result['observationSampleCount']) ?? 0,
      eventCount: _integer(result['eventCount']) ?? 0,
      score: _integer(result['score']),
      length: _integer(result['length']),
      survivalSeconds: _decimal(result['survivalSeconds']),
      rank: _integer(result['rank']),
      outcome: _string(result['outcome']),
      firstTick: _integer(result['firstTick']),
      lastTick: _integer(result['lastTick']),
    );
  }
}

typedef RunReviewAnalysisRunner =
    Future<Map<String, Object?>> Function(Map<String, Object?> input);

class RunReviewService {
  const RunReviewService({
    required this.runs,
    required this.chunks,
    required this.lifecycle,
    this.analysisRunner = _analyzeRunReviewInBackground,
  });

  final RunRepository runs;
  final RunChunkRepository chunks;
  final RunLifecycleService lifecycle;
  final RunReviewAnalysisRunner analysisRunner;

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

  Future<TrainingRun?> loadRunHeader(String runId) async {
    final run = await runs.getRun(runId);
    if (run == null) return null;
    if (run.status == TrainingRunStatus.recording ||
        run.status == TrainingRunStatus.discarded) {
      throw StateError('Run is not available for review');
    }
    return run;
  }

  Future<RunReviewItem> analyzeRun(TrainingRun run) async {
    final payloads = await chunks.chunkPayloadsFor(run.id);
    final result = await analysisRunner(<String, Object?>{
      'runId': run.id,
      'recordSchemaVersion': run.schemaVersion,
      'tickRateHz': run.tickRateHz,
      'chunkPayloads': payloads,
    });
    return RunReviewItem.fromWorkerResult(run, result);
  }

  Future<RunReviewItem?> loadRun(String runId) async {
    final run = await loadRunHeader(runId);
    if (run == null) return null;
    return analyzeRun(run);
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

int? _integer(Object? value) {
  if (value is int) return value;
  if (value is num && value.isFinite && value == value.roundToDouble()) {
    return value.toInt();
  }
  return null;
}

double? _decimal(Object? value) => value is num ? value.toDouble() : null;
String? _string(Object? value) => value is String ? value : null;

const _runReviewAnalysisTimeout = Duration(seconds: 30);

Future<Map<String, Object?>> _analyzeRunReviewInBackground(
  Map<String, Object?> input,
) async {
  final rawPayloads = input['chunkPayloads'];
  if (rawPayloads is! List<Uint8List>) {
    throw StateError('Run chunk payloads are unavailable for analysis');
  }
  final worker = IsolateManager<dynamic, dynamic>.createCustom(
    analyzeRunReviewChunksWorker,
    workerName: 'analyzeRunReviewChunksWorker',
    debugName: 'run-review-analysis',
  );
  var started = false;
  try {
    await worker.start().timeout(_runReviewAnalysisTimeout);
    started = true;
    final result = await worker
        .compute(
          input,
          transferables: rawPayloads
              .map((payload) => payload.buffer)
              .toList(growable: false),
        )
        .timeout(_runReviewAnalysisTimeout);
    return _reviewOutput(result);
  } finally {
    if (started) await worker.stop();
  }
}

Map<String, Object?> _reviewOutput(dynamic result) {
  if (result is! Map) {
    throw const FormatException('Run review worker output is not a map.');
  }
  return Map<String, Object?>.from(result);
}

