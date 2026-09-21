import 'package:flutter_test/flutter_test.dart';
import 'package:slither/training/domain/controller_contract.dart';
import 'package:slither/training/domain/recording_contract.dart'
    show currentTrainingRecordSchemaVersion;
import 'package:slither/training/domain/training_models.dart';

void main() {
  test('profile, run, revision, and match records round-trip', () {
    final pen = SnekPenSnapshot(
      sneks: const [
        SnekProfile(id: 'one', name: 'One', colorIndex: 2),
        SnekProfile(id: 'two', name: 'Two', colorIndex: 4),
      ],
      selectedSnekId: 'two',
    );
    expect(
      SnekPenSnapshot.fromJson(pen.toJson()).hasSameContents(pen),
      isTrue,
    );

    final run = TrainingRun(
      id: 'run-1',
      mode: 'arena',
      seed: 19,
      tickRateHz: 30,
      createdAtMs: 100,
      status: TrainingRunStatus.recording,
      config: const {'arenaSize': 1200},
    );
    final restoredRun = TrainingRun.fromJson(run.toJson());
    expect(restoredRun.id, run.id);
    expect(restoredRun.config, run.config);

    final revision = SoulRevision(
      soulId: 'soul-1',
      revisionId: 'revision-1',
      trainerVersion: 'trainer-1',
      featureVersion: 'features-1',
      weights: const {'food': 0.7, 'safety': 0.3},
      sourceRunIds: const ['run-1'],
    );
    expect(
      SoulRevision.fromJson(revision.toJson()).weights,
      revision.weights,
    );

    final match = TrainingMatch(
      id: 'match-1',
      mode: 'arena',
      startedAtMs: 100,
      participants: [
        MatchParticipant(
          actorId: 'player',
          role: ActorRole.player,
          controller: ControllerSource.soul,
          snekProfileId: 'one',
          soulRevisionIds: const ['revision-1'],
        ),
      ],
      outcome: const {'winnerId': 'player'},
    );
    expect(TrainingMatch.fromJson(match.toJson()).id, match.id);
  });

  test('unknown schema versions and invalid references are rejected', () {
    expect(
      () => TrainingRun.fromJson({
        ..._validRunJson,
        'schemaVersion': 99,
      }),
      throwsA(isA<UnsupportedError>()),
    );
    expect(
      () => SnekPenSnapshot(
        sneks: const [
          SnekProfile(id: 'same', name: 'One', colorIndex: 0),
          SnekProfile(id: 'same', name: 'Two', colorIndex: 1),
        ],
        selectedSnekId: 'same',
      ),
      throwsA(isA<TrainingValidationException>()),
    );
    expect(
      () => SoulRevision(
        soulId: 'soul-1',
        revisionId: 'revision-1',
        trainerVersion: 'trainer-1',
        featureVersion: 'features-1',
        weights: const {'food': 0.4, 'safety': 0.4},
        sourceRunIds: const ['run-1'],
      ),
      throwsA(isA<TrainingValidationException>()),
    );
    expect(
      () => SoulRevision(
        soulId: 'soul-1',
        revisionId: 'revision-1',
        trainerVersion: 'trainer-1',
        featureVersion: 'features-1',
        weights: const {'food': 0.5, 'safety': 0.5},
        sourceRunIds: const ['run-1', 'run-1'],
      ),
      throwsA(isA<TrainingValidationException>()),
    );
  });
}

const _validRunJson = <String, Object?>{
  'schemaVersion': currentTrainingRecordSchemaVersion,
  'id': 'run-1',
  'mode': 'arena',
  'seed': 19,
  'tickRateHz': 30,
  'createdAtMs': 100,
  'finalizedAtMs': null,
  'status': 'recording',
  'config': <String, Object?>{},
};
