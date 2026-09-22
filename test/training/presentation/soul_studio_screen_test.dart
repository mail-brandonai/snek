import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:slither/training/application/soul_training.dart';
import 'package:slither/training/domain/soul_feature_extractor.dart';
import 'package:slither/training/domain/training_models.dart';
import 'package:slither/training/domain/training_repositories.dart';
import 'package:slither/training/presentation/soul_studio_screen.dart';

void main() {
  test('Snek profile round-trips an optional Soul binding', () {
    const profile = SnekProfile(
      id: 'snek-1',
      name: 'Scout',
      colorIndex: 2,
      soulId: 'soul-1',
    );

    final restored = SnekProfile.fromJson(profile.toJson());

    expect(restored.id, profile.id);
    expect(restored.name, profile.name);
    expect(restored.colorIndex, profile.colorIndex);
    expect(restored.soulId, 'soul-1');
    expect(SnekProfile.starter.soulId, isNull);
  });

  testWidgets('binds a selected Soul to the selected Snek', (tester) async {
    final bound = <String, String?>{};
    final souls =
        _FakeSouls()
          ..souls['soul-1'] = Soul(
            id: 'soul-1',
            name: 'Resource Scout',
            createdAtMs: 100,
          )
          ..revisions['revision-1'] = SoulRevision(
            soulId: 'soul-1',
            revisionId: 'revision-1',
            trainerVersion: currentSoulTrainerVersion,
            featureVersion: currentSoulFeatureVersion,
            weights: const <String, double>{'resource': 1},
            sourceRunIds: const <String>['run-1'],
          );

    await tester.pumpWidget(
      MaterialApp(
        home: SoulStudioScreen(
          sneks: const <SnekProfile>[SnekProfile.starter],
          selectedSnekId: SnekProfile.starter.id,
          training: SoulTrainingService(runs: _FakeRuns(), souls: souls),
          onBack: () {},
          onBind: (snekId, soulId) async => bound[snekId] = soulId,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SOUL STUDIO'), findsOneWidget);
    expect(find.text('Resource Scout'), findsOneWidget);
    expect(find.text('BIND TO SNEK'), findsOneWidget);

    await tester.tap(find.text('BIND TO SNEK'));
    await tester.pumpAndSettle();

    expect(bound, <String, String?>{SnekProfile.starter.id: 'soul-1'});
  });
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
