import '../domain/soul_feature_extractor.dart';
import '../domain/training_models.dart';
import '../domain/training_repositories.dart';

const currentSoulTrainerVersion = 'snek-trainer-v1';

class SoulTrainingService {
  const SoulTrainingService({
    required this.runs,
    required this.souls,
    this.nowMs = _currentTimeMs,
  });

  final RunRepository runs;
  final SoulRepository souls;
  final int Function() nowMs;

  Future<Soul> createFromRun({
    required String name,
    required SoulBehaviorSignature signature,
  }) async {
    await _requireRetainedRun(signature.runId);
    final createdAtMs = nowMs();
    final soul = Soul(
      id: 'soul-$createdAtMs',
      name: name,
      createdAtMs: createdAtMs,
    );
    final revision = SoulTrainer.createRevision(
      soulId: soul.id,
      revisionId: '${soul.id}-revision-$createdAtMs',
      signature: signature,
      sourceRunIds: <String>[signature.runId],
    );
    await souls.saveSoulRevision(soul: soul, revision: revision);
    return soul;
  }

  Future<SoulRevision> refineFromRun({
    required Soul soul,
    required SoulBehaviorSignature signature,
  }) async {
    await _requireRetainedRun(signature.runId);
    final revisions = await souls.listRevisions(soul.id);
    if (revisions.isEmpty) {
      throw StateError('Soul has no revision to refine');
    }
    final parent = SoulTrainer.latestRevision(revisions);
    final revisedAtMs = nowMs();
    final revision = SoulTrainer.refineRevision(
      parent: parent,
      revisionId: '${soul.id}-revision-$revisedAtMs-${revisions.length + 1}',
      signature: signature,
      sourceRunIds: <String>[...parent.sourceRunIds, signature.runId],
    );
    await souls.saveRevision(revision);
    return revision;
  }

  Future<void> _requireRetainedRun(String runId) async {
    final run = await runs.getRun(runId);
    if (run == null) throw StateError('Source run does not exist');
    if (run.status != TrainingRunStatus.retained) {
      throw const TrainingValidationException(
        'Only retained runs can train a Soul',
      );
    }
  }
}

class SoulTrainer {
  const SoulTrainer._();

  static SoulRevision createRevision({
    required String soulId,
    required String revisionId,
    required SoulBehaviorSignature signature,
    required List<String> sourceRunIds,
  }) {
    return SoulRevision(
      soulId: soulId,
      revisionId: revisionId,
      trainerVersion: currentSoulTrainerVersion,
      featureVersion: signature.featureVersion,
      weights: _weightsFor(signature),
      sourceRunIds: sourceRunIds,
    );
  }

  static SoulRevision refineRevision({
    required SoulRevision parent,
    required String revisionId,
    required SoulBehaviorSignature signature,
    required List<String> sourceRunIds,
  }) {
    final incoming = _weightsFor(signature);
    final parentCount = parent.sourceRunIds.length;
    final totalCount = parentCount + 1;
    final keys = <String>{...parent.weights.keys, ...incoming.keys};
    final weights = <String, double>{
      for (final key in keys)
        key:
            ((parent.weights[key] ?? 0) * parentCount + (incoming[key] ?? 0)) /
            totalCount,
    };
    return SoulRevision(
      soulId: parent.soulId,
      revisionId: revisionId,
      parentRevisionId: parent.revisionId,
      trainerVersion: currentSoulTrainerVersion,
      featureVersion: signature.featureVersion,
      weights: _normalize(weights),
      sourceRunIds: sourceRunIds,
    );
  }

  static SoulRevision latestRevision(List<SoulRevision> revisions) {
    if (revisions.isEmpty) throw StateError('Soul has no revisions');
    final sorted = [...revisions]
      ..sort((left, right) => left.revisionId.compareTo(right.revisionId));
    return sorted.last;
  }

  static Map<String, double> _weightsFor(SoulBehaviorSignature signature) {
    if (signature.traits.isEmpty) {
      throw const TrainingValidationException(
        'A Soul requires at least one behavior trait',
      );
    }
    final raw = <String, double>{
      for (final trait in signature.traits)
        trait.id: trait.sampleCount * trait.coverage,
    };
    final total = raw.values.fold<double>(0, (sum, value) => sum + value);
    if (total <= 0) {
      final equal = 1 / raw.length;
      return <String, double>{for (final key in raw.keys) key: equal};
    }
    return _normalize(raw);
  }

  static Map<String, double> _normalize(Map<String, double> values) {
    final total = values.values.fold<double>(0, (sum, value) => sum + value);
    if (total <= 0 || !total.isFinite) {
      throw const TrainingValidationException(
        'Soul weights are not normalizable',
      );
    }
    return <String, double>{
      for (final entry in values.entries) entry.key: entry.value / total,
    };
  }
}

int _currentTimeMs() => DateTime.now().millisecondsSinceEpoch;
