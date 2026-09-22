import 'package:flutter_test/flutter_test.dart';

import 'package:slither/training/application/soul_training.dart';
import 'package:slither/training/domain/soul_feature_extractor.dart';
import 'package:slither/training/domain/training_models.dart';
import 'package:slither/training/domain/training_repositories.dart';

void main() {
  test('creates normalized weights from trait evidence', () {
    final revision = SoulTrainer.createRevision(
      soulId: 'soul-1',
      revisionId: 'revision-1',
      signature: _signature('run-1', <int>[2, 1]),
      sourceRunIds: const <String>['run-1'],
    );

    expect(revision.trainerVersion, currentSoulTrainerVersion);
    expect(revision.weights['resource'], closeTo(2 / 3, 0.000001));
    expect(revision.weights['movement'], closeTo(1 / 3, 0.000001));
    expect(revision.sourceRunIds, const <String>['run-1']);
  });

  test('refinement averages the prior source set with the new run', () {
    final parent = SoulTrainer.createRevision(
      soulId: 'soul-1',
      revisionId: 'revision-1',
      signature: _signature('run-1', <int>[3, 1]),
      sourceRunIds: const <String>['run-1'],
    );
    final refined = SoulTrainer.refineRevision(
      parent: parent,
      revisionId: 'revision-2',
      signature: _signature('run-2', <int>[1, 3]),
      sourceRunIds: const <String>['run-1', 'run-2'],
    );

    expect(refined.parentRevisionId, parent.revisionId);
    expect(refined.weights['resource'], closeTo(0.5, 0.000001));
    expect(refined.weights['movement'], closeTo(0.5, 0.000001));
    expect(refined.sourceRunIds, const <String>['run-1', 'run-2']);
  });

  test('service rejects a run that was not explicitly retained', () async {
    final runs = _FakeRuns(
      TrainingRun(
        id: 'run-1',
        mode: 'manual',
        seed: 1,
        tickRateHz: 30,
        createdAtMs: 1,
        status: TrainingRunStatus.pendingReview,
        config: const <String, Object?>{},
      ),
    );
    final service = SoulTrainingService(
      runs: runs,
      souls: _FakeSouls(),
      nowMs: () => 100,
    );

    await expectLater(
      service.createFromRun(
        name: 'First Soul',
        signature: _signature('run-1', <int>[1, 1]),
      ),
      throwsA(isA<TrainingValidationException>()),
    );
  });

  test('service creates and refines immutable revisions', () async {
    final runs = _FakeRuns(
      TrainingRun(
        id: 'run-1',
        mode: 'manual',
        seed: 1,
        tickRateHz: 30,
        createdAtMs: 1,
        status: TrainingRunStatus.retained,
        config: const <String, Object?>{},
      ),
    )..add(
        TrainingRun(
          id: 'run-2',
          mode: 'manual',
          seed: 2,
          tickRateHz: 30,
          createdAtMs: 2,
          status: TrainingRunStatus.retained,
          config: const <String, Object?>{},
        ),
      );
    final souls = _FakeSouls();
    final service = SoulTrainingService(
      runs: runs,
      souls: souls,
      nowMs: () => 100,
    );

    final soul = await service.createFromRun(
      name: 'First Soul',
      signature: _signature('run-1', <int>[2, 1]),
    );
    final revision = await service.refineFromRun(
      soul: soul,
      signature: _signature('run-2', <int>[1, 2]),
    );

    expect(soul.name, 'First Soul');
    expect(revision.parentRevisionId, 'soul-100-revision-100');
    expect(revision.sourceRunIds, const <String>['run-1', 'run-2']);
    expect((await souls.listRevisions(soul.id)).length, 2);
  });
}

SoulBehaviorSignature _signature(String runId, List<int> sampleCounts) {
  return SoulBehaviorSignature(
    runId: runId,
    recordSchemaVersion: 1,
    featureVersion: currentSoulFeatureVersion,
    traits: [
      BehaviorTraitSummary(
        id: 'resource',
        label: 'Resource',
        sampleCount: sampleCounts[0],
        opportunityCount: sampleCounts[0],
        coverage: 1,
        confidence: FeatureConfidence.high,
        observedEvidence: const <String, Object?>{},
      ),
      BehaviorTraitSummary(
        id: 'movement',
        label: 'Movement',
        sampleCount: sampleCounts[1],
        opportunityCount: sampleCounts[1],
        coverage: 1,
        confidence: FeatureConfidence.high,
        observedEvidence: const <String, Object?>{},
      ),
    ],
    pressureEpisodes: const <PressureEpisodeSummary>[],
    controlSampleCount: 1,
    observationSampleCount: 1,
    eventCount: 0,
  );
}

class _FakeRuns implements RunRepository {
  _FakeRuns(TrainingRun initial) : _runs = <String, TrainingRun>{initial.id: initial};

  final Map<String, TrainingRun> _runs;

  void add(TrainingRun run) => _runs[run.id] = run;

  @override
  Future<void> createRun(TrainingRun run) async => _runs[run.id] = run;

  @override
  Future<void> deleteRun(String id) async => _runs.remove(id);

  @override
  Future<TrainingRun?> getRun(String id) async => _runs[id];

  @override
  Future<List<TrainingRun>> listRuns({TrainingRunStatus? status}) async =>
      _runs.values
          .where((run) => status == null || run.status == status)
          .toList(growable: false);

  @override
  Future<void> setRunReviewStatus(
    String id,
    TrainingRunStatus status,
  ) async {
    final run = _runs[id];
    if (run == null) return;
    _runs[id] = TrainingRun(
      id: run.id,
      mode: run.mode,
      seed: run.seed,
      tickRateHz: run.tickRateHz,
      createdAtMs: run.createdAtMs,
      finalizedAtMs: run.finalizedAtMs,
      status: status,
      config: run.config,
    );
  }
}

class _FakeSouls implements SoulRepository {
  final Map<String, Soul> souls = <String, Soul>{};
  final Map<String, SoulRevision> revisions = <String, SoulRevision>{};

  @override
  Future<Soul?> getSoul(String id) async => souls[id];

  @override
  Future<List<Soul>> listSouls() async => souls.values.toList(growable: false);

  @override
  Future<List<SoulRevision>> listRevisions(String soulId) async =>
      revisions.values
          .where((revision) => revision.soulId == soulId)
          .toList(growable: false);

  @override
  Future<void> saveRevision(SoulRevision revision) async =>
      revisions[revision.revisionId] = revision;

  @override
  Future<void> saveSoul(Soul soul) async => souls[soul.id] = soul;

  @override
  Future<void> saveSoulRevision({
    required Soul soul,
    required SoulRevision revision,
  }) async {
    souls[soul.id] = soul;
    revisions[revision.revisionId] = revision;
  }

  @override
  Future<void> deleteSoul(String id) async => souls.remove(id);
}
