import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:slither/game/domain/simulation.dart';
import 'package:slither/training/application/run_review_worker.dart';

void main() {
  test('review worker replays controls for deferred tactical analysis', () {
    const runId = 'run-replay-fixture';
    final controls = <Map<String, Object?>>[
      for (var tick = 1; tick <= 6; tick++)
        <String, Object?>{
          'tick': tick,
          'steeringX': 1.0,
          'steeringY': 0.0,
          'sprintRequested': false,
        },
    ];
    final chunk = <String, Object?>{
      'format': 'snek-run-chunk',
      'schemaVersion': 1,
      'runId': runId,
      'sequence': 0,
      'firstTick': 0,
      'lastTick': 6,
      'controls': controls,
      'observations': const <Object?>[],
      'events': const <Object?>[],
    };
    final payload = Uint8List.fromList(utf8.encode(jsonEncode(chunk)));

    final simulationConfig = SimulationConfig().toJson();
    simulationConfig['botCount'] = 0;
    simulationConfig['maxBotCount'] = 0;
    simulationConfig['initialPellets'] = 0;

    final result = analyzeRunReviewChunks(<String, Object?>{
      'runId': runId,
      'recordSchemaVersion': 1,
      'tickRateHz': 60,
      'seed': 7,
      'runConfig': <String, Object?>{
        'simulation': simulationConfig,
        'playerColorIndex': 0,
      },
      'chunkPayloads': <Uint8List>[payload],
    });

    expect(result['analysisSource'], 'post-run-replay');
    expect(result['controlSampleCount'], 6);
    expect(result['observationSampleCount'], 1);
  });
}
