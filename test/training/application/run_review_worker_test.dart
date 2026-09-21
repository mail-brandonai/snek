import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:isolate_manager/isolate_manager.dart';
import 'package:slither/training/application/run_review_worker.dart';
import 'package:slither/training/domain/soul_feature_extractor.dart';

void main() {
  test('review worker extracts summary and features in an isolate', () async {
    final payload = Uint8List.fromList(
      utf8.encode(
        jsonEncode(<String, Object?>{
          'format': 'snek-run-chunk',
          'schemaVersion': 1,
          'runId': 'run-worker',
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

    final payloads = <Uint8List>[payload];
    final worker =
        IsolateManager<Map<String, Object?>, Map<String, Object?>>.create(
      analyzeRunReviewChunks,
      workerName: 'analyzeRunReviewChunks',
    );
    late final Map<String, Object?> result;
    try {
      await worker.start();
      result = await worker.compute(
        <String, Object?>{
          'runId': 'run-worker',
          'recordSchemaVersion': 1,
          'tickRateHz': 30,
          'chunkPayloads': payloads,
        },
        transferables: payloads
            .map((payload) => payload.buffer)
            .toList(growable: false),
      );
    } finally {
      await worker.stop();
    }

    expect(result['controlSampleCount'], 1);
    expect(result['observationSampleCount'], 1);
    expect(result['eventCount'], 1);
    expect(result['score'], 42);
    expect(result['length'], 5);
    expect(result['survivalSeconds'], 1.0);
    expect(result['rank'], 3);
    expect(result['outcome'], 'Body collision');
    final featureAnalysis = SoulFeatureExtractionResult.fromJson(
      result['featureAnalysis'],
    );
    expect(featureAnalysis.status, SoulFeatureStatus.ready);
    expect(featureAnalysis.signature?.controlSampleCount, 1);
    expect(featureAnalysis.signature?.observationSampleCount, 1);
    expect(featureAnalysis.signature?.eventCount, 1);
  });
}
