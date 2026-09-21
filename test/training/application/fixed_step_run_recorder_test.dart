import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:slither/game/domain/simulation_capture.dart';
import 'package:slither/training/application/fixed_step_run_recorder.dart';
import 'package:slither/training/domain/training_application.dart';
import 'package:slither/training/domain/training_models.dart';
import 'package:slither/training/domain/training_repositories.dart';

void main() {
  test('finalization flushes a checksummed chunk before closing the run',
      () async {
    final runs = _RunRepository();
    final chunks = _RunChunkRepository();
    final recorder = FixedStepRunRecorder(
      runId: 'run-a',
      lifecycle: RunLifecycleService(runs, chunks),
      chunks: chunks,
      chunkTickCount: 2,
    );
    await recorder.begin(_run());

    recorder.recordControl(
      const SimulationControlSample(
        tick: 1,
        steeringX: 1,
        steeringY: 0,
        sprintRequested: false,
      ),
    );
    recorder.recordObservation(
      SimulationObservationSnapshot(
        tick: 1,
        elapsedSeconds: 1 / 60,
        playerPositionX: 0,
        playerPositionY: 0,
        playerHeadingX: 1,
        playerHeadingY: 0,
        playerLength: 4,
        playerSprinting: false,
        nearestThreatDistance: null,
        nearbyThreatCount: 0,
        nearbyNaturalFoodCount: 0,
        nearbyDroppedMassCount: 0,
        boundaryRisk: 0,
        actors: const <SimulationActorSnapshot>[],
      ),
    );
    recorder.recordControl(
      const SimulationControlSample(
        tick: 2,
        steeringX: 0,
        steeringY: 1,
        sprintRequested: true,
      ),
    );
    recorder.recordEvent(
      const SimulationEventSnapshot(
        tick: 2,
        kind: SimulationEventKind.runEnded,
        actorId: 'player',
        detail: 'bodyCollision',
      ),
    );

    expect(await recorder.finalize(finalizedAtMs: 200), isTrue);
    expect(chunks.finalizedRunId, 'run-a');
    expect(chunks.finalizedChunkCount, 1);
    expect(chunks.incompleteRunId, isNull);
    expect(chunks.savedChunks, hasLength(1));

    final payload = jsonDecode(utf8.decode(chunks.savedChunks.single.payload))
        as Map<String, Object?>;
    expect(payload['schemaVersion'], 1);
    expect(payload['firstTick'], 0);
    expect(payload['lastTick'], 2);
    expect(payload['controls'], hasLength(2));
    expect(payload['observations'], hasLength(1));
    expect(payload['events'], hasLength(2));
  });

  test('recovery marks headers left recording as incomplete', () async {
    final runs = _RunRepository();
    final chunks = _RunChunkRepository();
    await runs.createRun(_run(id: 'interrupted'));
    final lifecycle = RunLifecycleService(runs, chunks);

    final recovered = await lifecycle.recoverInterruptedRuns(
      recoveredAtMs: 400,
    );

    expect(recovered, <String>['interrupted']);
    expect(chunks.incompleteRunId, 'interrupted');
  });

  test('aborted runs keep their chunks and are marked incomplete', () async {
    final runs = _RunRepository();
    final chunks = _RunChunkRepository();
    final recorder = FixedStepRunRecorder(
      runId: 'run-b',
      lifecycle: RunLifecycleService(runs, chunks),
      chunks: chunks,
    );
    await recorder.begin(_run(id: 'run-b'));
    recorder.recordControl(
      const SimulationControlSample(
        tick: 1,
        steeringX: 1,
        steeringY: 0,
        sprintRequested: false,
      ),
    );

    expect(await recorder.abort(finalizedAtMs: 300), isFalse);
    expect(chunks.incompleteRunId, 'run-b');
    expect(chunks.savedChunks, hasLength(1));
    expect(chunks.finalizedRunId, isNull);
  });
}

TrainingRun _run({String id = 'run-a'}) => TrainingRun(
      id: id,
      mode: 'manual',
      seed: 1,
      tickRateHz: 60,
      createdAtMs: 100,
      status: TrainingRunStatus.recording,
      config: const <String, Object?>{'gameRulesVersion': 'snek-v1'},
    );

class _RunRepository implements RunRepository {
  final Map<String, TrainingRun> values = {};

  @override
  Future<void> createRun(TrainingRun run) async {
    values[run.id] = run;
  }

  @override
  Future<void> deleteRun(String id) async {
    values.remove(id);
  }

  @override
  Future<TrainingRun?> getRun(String id) async => values[id];

  @override
  Future<List<TrainingRun>> listRuns({TrainingRunStatus? status}) async =>
      values.values
          .where((run) => status == null || run.status == status)
          .toList(growable: false);

  @override
  Future<void> setRunReviewStatus(
    String id,
    TrainingRunStatus status,
  ) async {}
}

class _StoredChunk {
  const _StoredChunk({
    required this.runId,
    required this.sequence,
    required this.firstTick,
    required this.lastTick,
    required this.payload,
  });

  final String runId;
  final int sequence;
  final int firstTick;
  final int lastTick;
  final Uint8List payload;
}

class _RunChunkRepository implements RunChunkRepository {
  final List<_StoredChunk> savedChunks = [];
  String? finalizedRunId;
  int? finalizedChunkCount;
  String? incompleteRunId;

  @override
  Future<void> appendChunk({
    required String runId,
    required int sequence,
    required int firstTick,
    required int lastTick,
    required Uint8List payload,
  }) async {
    savedChunks.add(
      _StoredChunk(
        runId: runId,
        sequence: sequence,
        firstTick: firstTick,
        lastTick: lastTick,
        payload: payload,
      ),
    );
  }

  @override
  Future<int> chunkCountFor(String runId) async =>
      savedChunks.where((chunk) => chunk.runId == runId).length;

  @override
  Future<List<Uint8List>> chunkPayloadsFor(String runId) async => savedChunks
      .where((chunk) => chunk.runId == runId)
      .map((chunk) => chunk.payload)
      .toList(growable: false);

  @override
  Future<void> finalizeRun({
    required String runId,
    required int expectedChunkCount,
    required int finalizedAtMs,
  }) async {
    finalizedRunId = runId;
    finalizedChunkCount = expectedChunkCount;
  }

  @override
  Future<void> markIncomplete({
    required String runId,
    required int finalizedAtMs,
  }) async {
    incompleteRunId = runId;
  }
}
