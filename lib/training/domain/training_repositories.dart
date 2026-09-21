import 'training_models.dart';

abstract interface class PenRepository {
  Future<SnekPenSnapshot?> loadPen();
  Future<void> savePen(SnekPenSnapshot snapshot);
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
  Future<void> saveRevision(SoulRevision revision);
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
