import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slither/training/application/run_review.dart';
import 'package:slither/training/data/drift_run_store.dart';
import 'package:slither/training/data/drift_training_repositories.dart';
import 'package:slither/training/data/training_database.dart';
import 'package:slither/training/domain/training_application.dart';
import 'package:slither/training/domain/training_models.dart';
import 'package:slither/training/domain/soul_feature_extractor.dart';

void main() {
  test('review service analyzes a run through its native isolate', () async {
    final database = TrainingDatabase(NativeDatabase.memory());
    try {
      final runs = DriftTrainingRepositories(database);
      final chunks = DriftRunStore(database);
      final lifecycle = RunLifecycleService(runs, chunks);
      const runId = 'run-worker';
      final run = TrainingRun(
        id: runId,
        mode: 'manual',
        seed: 7,
        tickRateHz: 30,
        createdAtMs: 100,
        status: TrainingRunStatus.recording,
        config: const <String, Object?>{'playerName': 'Test Snek'},
      );
      await lifecycle.start(run);

      final payload = Uint8List.fromList(
        utf8.encode(
          jsonEncode(<String, Object?>{
            'format': 'snek-run-chunk',
            'schemaVersion': 1,
            'runId': runId,
            'sequence': 0,
            'firstTick': 1,
            'lastTick': 2,
            'controls': <Object?>[
              <String, Object?>{
                'tick': 1,
                'steeringX': 1.0,
                'steeringY': 0.0,
                'sprintRequested': false,
              },
            ],
            'observations': <Object?>[
              <String, Object?>{
                'tick': 1,
                'playerPositionX': 0.0,
                'playerPositionY': 0.0,
                'playerHeadingX': 1.0,
                'playerHeadingY': 0.0,
                'playerLength': 5,
                'playerSprinting': false,
                'nearbyThreatCount': 0,
                'nearbyNaturalFoodCount': 1,
                'nearbyDroppedMassCount': 0,
                'boundaryRisk': 0.0,
                'actors': <Object?>[],
              },
            ],
            'events': <Object?>[
              <String, Object?>{
                'tick': 2,
                'kind': 'runEnded',
                'actorId': 'player',
                'detail': 'Body collision',
                'metadata': <String, Object?>{
                  'score': 42,
                  'length': 5,
                  'survivalSeconds': 1.0,
                  'rank': 3,
                },
              },
            ],
          }),
        ),
      );
      await chunks.appendChunk(
        runId: runId,
        sequence: 0,
        firstTick: 1,
        lastTick: 2,
        payload: payload,
      );
      await lifecycle.finalize(
        runId: runId,
        expectedChunkCount: 1,
        finalizedAtMs: 200,
      );

      final review = RunReviewService(
        runs: runs,
        chunks: chunks,
        lifecycle: lifecycle,
      );
      final item = await review.loadRun(runId);

      expect(item, isNotNull);
      expect(item!.controlSampleCount, 1);
      expect(item.observationSampleCount, 1);
      expect(item.eventCount, 1);
      expect(item.score, 42);
      expect(item.length, 5);
      expect(item.survivalSeconds, 1.0);
      expect(item.rank, 3);
      expect(item.outcome, 'Body collision');
      expect(item.featureAnalysis.status, SoulFeatureStatus.ready);
      expect(item.featureAnalysis.signature?.controlSampleCount, 1);
      expect(item.featureAnalysis.signature?.observationSampleCount, 1);
      expect(item.featureAnalysis.signature?.eventCount, 1);
    } finally {
      await database.close();
    }
  });
}
