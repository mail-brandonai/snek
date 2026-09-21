import 'dart:convert';

import 'training_models.dart';
import 'training_repositories.dart';

abstract interface class LegacyPenStorage {
  Future<String?> readV1();
  Future<void> removeV1();
}

class SnekPenMigrationService {
  const SnekPenMigrationService(this.repository, this.legacyStorage);

  final PenRepository repository;
  final LegacyPenStorage legacyStorage;

  Future<SnekPenSnapshot> loadOrMigrate() async {
    final existing = await repository.loadPen();
    if (existing != null) return existing;

    final saved = await legacyStorage.readV1();
    var snapshot = SnekPenSnapshot.defaults;
    if (saved != null) {
      try {
        snapshot = SnekPenSnapshot.fromJson(jsonDecode(saved));
      } on FormatException {
        snapshot = SnekPenSnapshot.defaults;
      } on TypeError {
        snapshot = SnekPenSnapshot.defaults;
      } on TrainingValidationException {
        snapshot = SnekPenSnapshot.defaults;
      }
    }

    await repository.savePen(snapshot);
    final persisted = await repository.loadPen();
    if (persisted == null || !persisted.hasSameContents(snapshot)) {
      throw StateError('Snek Pen migration readback did not match');
    }
    if (saved != null) await legacyStorage.removeV1();
    return persisted;
  }

  Future<void> save(SnekPenSnapshot snapshot) => repository.savePen(snapshot);
}

class RunLifecycleService {
  const RunLifecycleService(this.runs, [this.chunks]);

  final RunRepository runs;
  final RunChunkRepository? chunks;

  Future<void> start(TrainingRun run) {
    if (run.status != TrainingRunStatus.recording) {
      throw const TrainingValidationException('New runs must start recording');
    }
    return runs.createRun(run);
  }

  Future<void> finalize({
    required String runId,
    required int expectedChunkCount,
    required int finalizedAtMs,
  }) {
    final chunkRepository = chunks;
    if (chunkRepository == null) {
      throw StateError('A run chunk repository is required to finalize runs');
    }
    return chunkRepository.finalizeRun(
      runId: runId,
      expectedChunkCount: expectedChunkCount,
      finalizedAtMs: finalizedAtMs,
    );
  }

  Future<void> review(String runId, {required bool retain}) =>
      runs.setRunReviewStatus(
        runId,
        retain ? TrainingRunStatus.retained : TrainingRunStatus.discarded,
      );
}

class SoulRevisionService {
  const SoulRevisionService(this.souls);

  final SoulRepository souls;

  Future<void> publish(Soul soul, SoulRevision revision) async {
    if (soul.id != revision.soulId) {
      throw const TrainingValidationException(
        'Revision belongs to a different Soul',
      );
    }
    await souls.saveSoulRevision(soul: soul, revision: revision);
  }
}
