import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:slither/training/application/soul_training.dart';
import 'package:slither/training/domain/soul_feature_extractor.dart';
import 'package:slither/training/domain/training_models.dart';
import 'package:slither/training/domain/training_repositories.dart';
import 'package:slither/training/presentation/soul_library_screen.dart';

void main() {
  testWidgets('shows the empty Soul Library state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SoulLibraryScreen(
          training: SoulTrainingService(runs: _FakeRuns(), souls: _FakeSouls()),
          onBack: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SOUL LIBRARY'), findsOneWidget);
    expect(find.text('No Souls created yet.'), findsOneWidget);
    expect(find.text('Loading Souls'), findsNothing);
  });

  testWidgets('shows latest revision weights and source runs', (tester) async {
    final souls =
        _FakeSouls()
          ..souls['soul-1'] = Soul(
            id: 'soul-1',
            name: 'Resource Scout',
            createdAtMs: 100,
          )
          ..revisions['revision-1'] = _revision(
            revisionId: 'revision-1',
            weights: const <String, double>{'resource': 1},
            sourceRunIds: const <String>['run-1'],
          )
          ..revisions['revision-2'] = _revision(
            revisionId: 'revision-2',
            weights: const <String, double>{'resource': 0.75, 'movement': 0.25},
            sourceRunIds: const <String>['run-1', 'run-2'],
          );

    await tester.pumpWidget(
      MaterialApp(
        home: SoulLibraryScreen(
          training: SoulTrainingService(runs: _FakeRuns(), souls: souls),
          onBack: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Resource Scout'), findsOneWidget);
    expect(find.text('2 REVISIONS'), findsOneWidget);
    expect(find.text('revision-2'), findsOneWidget);
    expect(find.text('resource 75.0%'), findsOneWidget);
    expect(find.text('movement 25.0%'), findsOneWidget);
    expect(find.text('SOURCE RUNS  2'), findsOneWidget);
    expect(find.text('run-1 · run-2'), findsOneWidget);
  });
}

SoulRevision _revision({
  required String revisionId,
  required Map<String, double> weights,
  required List<String> sourceRunIds,
}) {
  return SoulRevision(
    soulId: 'soul-1',
    revisionId: revisionId,
    trainerVersion: currentSoulTrainerVersion,
    featureVersion: currentSoulFeatureVersion,
    weights: weights,
    sourceRunIds: sourceRunIds,
  );
}

class _FakeRuns implements RunRepository {
  @override
  Future<void> createRun(TrainingRun run) async {}

  @override
  Future<void> deleteRun(String id) async {}

  @override
  Future<TrainingRun?> getRun(String id) async => null;

  @override
  Future<List<TrainingRun>> listRuns({TrainingRunStatus? status}) async =>
      const <TrainingRun>[];

  @override
  Future<void> setRunReviewStatus(String id, TrainingRunStatus status) async {}
}

class _FakeSouls implements SoulRepository {
  final Map<String, Soul> souls = <String, Soul>{};
  final Map<String, SoulRevision> revisions = <String, SoulRevision>{};

  @override
  Future<void> deleteSoul(String id) async {
    souls.remove(id);
    revisions.removeWhere((key, value) => value.soulId == id);
  }

  @override
  Future<Soul?> getSoul(String id) async => souls[id];

  @override
  Future<SoulRevision?> getRevision(String revisionId) async =>
      revisions[revisionId];

  @override
  Future<List<Soul>> listSouls() async => souls.values.toList(growable: false);

  @override
  Future<List<SoulRevision>> listRevisions(String soulId) async => revisions
      .values
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
}
