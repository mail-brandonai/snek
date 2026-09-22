import 'dart:typed_data';

import 'training_models.dart';

abstract interface class PenRepository {
  Future<SnekPenSnapshot?> loadPen();
  Future<void> savePen(SnekPenSnapshot snapshot);
}

abstract interface class RunChunkRepository {
  Future<void> appendChunk({
    required String runId,
    required int sequence,
    required int firstTick,
    required int lastTick,
    required Uint8List payload,
  });

  Future<void> finalizeRun({
    required String runId,
    required int expectedChunkCount,
    required int finalizedAtMs,
  });

  Future<void> markIncomplete({
    required String runId,
    required int finalizedAtMs,
  });

  Future<int> chunkCountFor(String runId);
  Future<List<Uint8List>> chunkPayloadsFor(String runId);
}

abstract interface class RunRepository {
  Future<void> createRun(TrainingRun run);
  Future<TrainingRun?> getRun(String id);
  Future<List<TrainingRun>> listRuns({TrainingRunStatus? status});
  Future<void> setRunReviewStatus(String id, TrainingRunStatus status);
  Future<void> deleteRun(String id);
}

abstract interface class SoulRepository {
  Future<void> saveSoul(Soul soul);
  Future<Soul?> getSoul(String id);
  Future<List<Soul>> listSouls();
  Future<void> saveRevision(SoulRevision revision);
  Future<void> saveSoulRevision({
    required Soul soul,
    required SoulRevision revision,
  });
  Future<SoulRevision?> getRevision(String revisionId);
  Future<List<SoulRevision>> listRevisions(String soulId);
  Future<void> deleteSoul(String id);
}

abstract interface class MatchRepository {
  Future<void> saveMatch(TrainingMatch match);
  Future<TrainingMatch?> getMatch(String id);
  Future<List<TrainingMatch>> listMatches();
  Future<void> deleteMatch(String id);
}
