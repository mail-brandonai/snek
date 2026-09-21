import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slither/game/domain/simulation_capture.dart';
import 'package:slither/training/application/run_review.dart';
import 'package:slither/training/data/drift_run_store.dart';
import 'package:slither/training/data/drift_training_repositories.dart';
import 'package:slither/training/data/training_database.dart';
import 'package:slither/training/domain/training_application.dart';
import 'package:slither/training/domain/training_models.dart';
import 'package:slither/training/presentation/run_library_screen.dart';

void main() {
  late TrainingDatabase database;
  late DriftTrainingRepositories runs;
  late DriftRunStore chunks;
  late RunLifecycleService lifecycle;
  late RunReviewService review;

  setUp(() {
    database = TrainingDatabase(NativeDatabase.memory());
    runs = DriftTrainingRepositories(database);
    chunks = DriftRunStore(database);
    lifecycle = RunLifecycleService(runs, chunks);
    review = RunReviewService(
      runs: runs,
      chunks: chunks,
      lifecycle: lifecycle,
    );
  });

  tearDown(() async {
    await database.close();
  });

  testWidgets('debrief shows run results and Keep persists without Soul edits',
      (tester) async {
    await _createPendingRun(lifecycle, chunks, 'run-1');
    await tester.pumpWidget(
      MaterialApp(
        home: RunLibraryScreen(
          service: review,
          initialRunId: 'run-1',
          onBack: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('RUN DEBRIEF'), findsOneWidget);
    expect(find.text('Body collision'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    expect(find.text('00:19'), findsOneWidget);
    expect(find.text('Player controls'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('KEEP RUN'), findsOneWidget);

    await tester.tap(find.text('KEEP RUN'));
    await tester.pumpAndSettle();

    expect(
      (await runs.getRun('run-1'))?.status,
      TrainingRunStatus.retained,
    );
    expect(await runs.listRevisions('soul-1'), isEmpty);
  });

  testWidgets('Discard confirms then deletes the run and all chunks',
      (tester) async {
    await _createPendingRun(lifecycle, chunks, 'run-2');
    await tester.pumpWidget(
      MaterialApp(
        home: RunLibraryScreen(
          service: review,
          initialRunId: 'run-2',
          onBack: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('DISCARD RUN').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('DISCARD RUN').first);
    await tester.pumpAndSettle();
    expect(find.text('Discard this run?'), findsOneWidget);

    await tester.tap(find.text('DISCARD RUN').last);
    await tester.pumpAndSettle();

    expect(await runs.getRun('run-2'), isNull);
    expect(await chunks.chunkCountFor('run-2'), 0);
    expect(find.text('No pending runs.'), findsOneWidget);
  });

  testWidgets('Soul entry points do not create or refine implicitly',
      (tester) async {
    await _createPendingRun(lifecycle, chunks, 'run-soul-stub');
    await tester.pumpWidget(
      MaterialApp(
        home: RunLibraryScreen(
          service: review,
          initialRunId: 'run-soul-stub',
          onBack: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('CREATE SOUL'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CREATE SOUL'));
    await tester.pumpAndSettle();
    expect(find.textContaining('scheduled for Sprint 5'), findsOneWidget);
    await tester.tap(find.text('CLOSE'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('REFINE SOUL'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('REFINE SOUL'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Choose a target Soul'), findsOneWidget);
    await tester.tap(find.text('CLOSE'));
    await tester.pumpAndSettle();

    expect(
      (await runs.getRun('run-soul-stub'))?.status,
      TrainingRunStatus.pendingReview,
    );
    expect(await runs.getSoul('soul-1'), isNull);
    expect(await runs.listRevisions('soul-1'), isEmpty);
  });

  testWidgets('incomplete runs are marked and cannot be kept', (tester) async {
    final run = _run('run-3');
    await lifecycle.start(run);
    await lifecycle.markIncomplete(
      runId: run.id,
      finalizedAtMs: 200,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: RunLibraryScreen(
          service: review,
          initialRunId: run.id,
          onBack: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('INCOMPLETE'), findsOneWidget);
    expect(
      find.textContaining('cannot be used as complete training evidence'),
      findsOneWidget,
    );
    expect(find.text('KEEP RUN'), findsNothing);
    expect(find.text('DISCARD RUN'), findsOneWidget);
  });

  testWidgets('referenced runs cannot be discarded from the library',
      (tester) async {
    await _createPendingRun(lifecycle, chunks, 'run-4');
    await runs.saveSoulRevision(
      soul: Soul(id: 'soul-1', name: 'Learner', createdAtMs: 100),
      revision: SoulRevision(
        soulId: 'soul-1',
        revisionId: 'revision-1',
        trainerVersion: 'trainer-1',
        featureVersion: 'features-1',
        weights: const {'food': 1.0},
        sourceRunIds: const ['run-4'],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: RunLibraryScreen(
          service: review,
          initialRunId: 'run-4',
          onBack: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('DISCARD RUN').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('DISCARD RUN').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('DISCARD RUN').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(
      find.textContaining('Run is referenced by Soul revision revision-1'),
      findsOneWidget,
    );
    expect((await runs.getRun('run-4'))?.status, TrainingRunStatus.pendingReview);
    expect(await chunks.chunkCountFor('run-4'), 1);
  });
}

Future<void> _createPendingRun(
  RunLifecycleService lifecycle,
  DriftRunStore chunks,
  String id,
) async {
  await lifecycle.start(_run(id));
  final payload = Uint8List.fromList(
    utf8.encode(
      jsonEncode(<String, Object?>{
        'format': 'snek-run-chunk',
        'schemaVersion': 1,
        'runId': id,
        'sequence': 0,
        'firstTick': 0,
        'lastTick': 6,
        'controls': <Object?>[
          <String, Object?>{'tick': 1},
          <String, Object?>{'tick': 2},
        ],
        'observations': <Object?>[
          <String, Object?>{'tick': 6},
        ],
        'events': <Object?>[
          <String, Object?>{
            'kind': SimulationEventKind.runEnded.name,
            'actorId': 'player',
            'targetId': 'bot-1',
            'detail': 'bodyCollision',
            'metadata': <String, Object?>{
              'score': 42,
              'length': 8,
              'survivalSeconds': 19.2,
              'rank': 3,
            },
          },
        ],
      }),
    ),
  );
  await chunks.appendChunk(
    runId: id,
    sequence: 0,
    firstTick: 0,
    lastTick: 6,
    payload: payload,
  );
  await lifecycle.finalize(
    runId: id,
    expectedChunkCount: 1,
    finalizedAtMs: 200,
  );
}

TrainingRun _run(String id) => TrainingRun(
      id: id,
      mode: 'manual',
      seed: 7,
      tickRateHz: 60,
      createdAtMs: 100,
      status: TrainingRunStatus.recording,
      config: const <String, Object?>{
        'playerName': 'Test Snek',
        'playerProfileId': 'starter-snek',
      },
    );
