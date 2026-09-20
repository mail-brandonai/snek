import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:slither/training/data/drift_run_store.dart';
import 'package:slither/training/data/training_database.dart';

Future<void> verifyPersistentRunRoundTrip(String runId) async {
  var database = TrainingDatabase.persistent();
  var databaseOpen = true;
  var store = DriftRunStore(database);
  const firstPayload = <int>[1, 3, 5, 7, 9];
  const secondPayload = <int>[2, 4, 6, 8, 10];

  try {
    await store.deleteRun(runId);
    await store.createRun(id: runId, createdAtMs: 1000);

    await expectLater(
      store.appendChunk(
        runId: runId,
        sequence: 1,
        firstTick: 0,
        lastTick: 9,
        payload: Uint8List.fromList(firstPayload),
      ),
      throwsStateError,
    );

    await store.appendChunk(
      runId: runId,
      sequence: 0,
      firstTick: 0,
      lastTick: 9,
      payload: Uint8List.fromList(firstPayload),
    );
    expect(await store.statusFor(runId), 'recording');
    expect(await store.chunkCountFor(runId), 1);

    await database.close();
    databaseOpen = false;

    database = TrainingDatabase.persistent();
    databaseOpen = true;
    store = DriftRunStore(database);
    expect(await store.statusFor(runId), 'recording');
    expect(await store.chunkCountFor(runId), 1);

    await store.appendChunk(
      runId: runId,
      sequence: 1,
      firstTick: 10,
      lastTick: 19,
      payload: Uint8List.fromList(secondPayload),
    );
    await store.finalizeRun(
      runId: runId,
      expectedChunkCount: 2,
      finalizedAtMs: 2000,
    );
    await store.finalizeRun(
      runId: runId,
      expectedChunkCount: 2,
      finalizedAtMs: 3000,
    );

    await database.close();
    databaseOpen = false;

    database = TrainingDatabase.persistent();
    databaseOpen = true;
    store = DriftRunStore(database);
    expect(await store.statusFor(runId), 'pendingReview');
    expect(
      await store.pendingRunIdsSince(1000),
      contains(runId),
    );
    expect(
      (await store.chunkPayloadsFor(runId))
          .map((payload) => payload.toList())
          .toList(),
      <List<int>>[firstPayload, secondPayload],
    );

    await store.deleteRun(runId);
    expect(await store.statusFor(runId), isNull);
    expect(await store.chunkCountFor(runId), 0);
  } finally {
    if (databaseOpen) await database.close();
  }
}
