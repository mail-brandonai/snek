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
    final worker =
        IsolateManager<Map<String, Object?>, Map<String, Object?>>.create(
      analyzeRunReviewChunks,
      workerName: 'analyzeRunReviewChunks',
      debugName: 'run-review-analysis',
    );
    try {
      await worker.start();
      final result = await worker.compute(
        <String, Object?>{
          'runId': run.id,
          'recordSchemaVersion': run.schemaVersion,
          'tickRateHz': run.tickRateHz,
          'chunkPayloads': payloads,
        },
        transferables: payloads
            .map((payload) => payload.buffer)
            .toList(growable: false),
      );
      return RunReviewItem.fromWorkerResult(run, result);
    } finally {
      await worker.stop();
    }
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
