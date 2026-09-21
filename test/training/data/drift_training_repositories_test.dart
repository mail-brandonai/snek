import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slither/training/data/drift_run_store.dart';
import 'package:slither/training/data/drift_training_repositories.dart';
import 'package:slither/training/data/training_database.dart';
import 'package:slither/training/domain/controller_contract.dart';
import 'package:slither/training/domain/training_application.dart';
import 'package:slither/training/domain/training_models.dart';

void main() {
  late TrainingDatabase database;
  late DriftTrainingRepositories repositories;

  setUp(() {
    database = TrainingDatabase(NativeDatabase.memory());
    repositories = DriftTrainingRepositories(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('run lifecycle, Soul revision, and match persist through repositories',
      () async {
    final run = TrainingRun(
      id: 'run-1',
      mode: 'arena',
      seed: 42,
      tickRateHz: 30,
      createdAtMs: 100,
      status: TrainingRunStatus.recording,
      config: const {'map': 'default'},
    );
    final lifecycle = RunLifecycleService(
      repositories,
      DriftRunStore(database),
    );
    await lifecycle.start(run);
    expect((await repositories.getRun(run.id))?.config, run.config);

    await lifecycle.finalize(
      runId: run.id,
      expectedChunkCount: 0,
      finalizedAtMs: 200,
    );
    await lifecycle.review(run.id, retain: true);
    expect(
      (await repositories.getRun(run.id))?.status,
      TrainingRunStatus.retained,
    );

    await repositories.savePen(SnekPenSnapshot.defaults);
    final revision = SoulRevision(
      soulId: 'soul-1',
      revisionId: 'revision-1',
      trainerVersion: 'trainer-1',
      featureVersion: 'features-1',
      weights: const {'food': 0.65, 'safety': 0.35},
      sourceRunIds: const ['run-1'],
    );
    await SoulRevisionService(repositories).publish(
      Soul(id: 'soul-1', name: 'Learner', createdAtMs: 100),
      revision,
    );
    expect(
      (await repositories.getRevision('revision-1'))?.sourceRunIds,
      ['run-1'],
    );

    final match = TrainingMatch(
      id: 'match-1',
      mode: 'arena',
      startedAtMs: 210,
      participants: [
        MatchParticipant(
          actorId: 'player',
          role: ActorRole.player,
          controller: ControllerSource.soul,
          snekProfileId: 'starter-snek',
          soulRevisionIds: const ['revision-1'],
        ),
      ],
      outcome: const {'winnerId': 'player'},
    );
    await repositories.saveMatch(match);
    expect((await repositories.getMatch('match-1'))?.id, 'match-1');
    await expectLater(
      repositories.deleteRun('run-1'),
      throwsA(isA<StateError>()),
    );
  });

  test('missing source runs are rejected and the Soul write rolls back',
      () async {
    final revision = SoulRevision(
      soulId: 'soul-1',
      revisionId: 'revision-1',
      trainerVersion: 'trainer-1',
      featureVersion: 'features-1',
      weights: const {'food': 1.0},
      sourceRunIds: const ['missing-run'],
    );
    await expectLater(
      SoulRevisionService(repositories).publish(
        Soul(id: 'soul-1', name: 'Learner', createdAtMs: 100),
        revision,
      ),
      throwsA(isA<StateError>()),
    );
    expect(await repositories.getSoul('soul-1'), isNull);
    expect(await repositories.getRevision('revision-1'), isNull);
  });
}
