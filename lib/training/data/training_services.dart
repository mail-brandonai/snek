import 'package:shared_preferences/shared_preferences.dart';

import '../application/fixed_step_run_recorder.dart';
import '../domain/training_application.dart';
import '../domain/training_models.dart';
import 'drift_run_store.dart';
import 'drift_training_repositories.dart';
import 'training_database.dart';

class _SharedPreferencesLegacyPenStorage implements LegacyPenStorage {
  static const _key = 'snek.pen.profiles.v1';
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  @override
  Future<String?> readV1() => _preferences.getString(_key);

  @override
  Future<void> removeV1() => _preferences.remove(_key);
}

class TrainingServiceBundle {
  TrainingServiceBundle(this.database, this.repositories, this.runChunks)
      : penMigration = SnekPenMigrationService(
          repositories,
          _SharedPreferencesLegacyPenStorage(),
        ),
        runLifecycle = RunLifecycleService(repositories, runChunks);

  final TrainingDatabase database;
  final DriftTrainingRepositories repositories;
  final DriftRunStore runChunks;
  final RunLifecycleService runLifecycle;
  final SnekPenMigrationService penMigration;
}

class TrainingServices {
  TrainingServices._();

  static final Future<TrainingServiceBundle> _instance = _open();

  static Future<TrainingServiceBundle> open() => _instance;

  static Future<TrainingServiceBundle> _open() async {
    final database = TrainingDatabase.persistent();
    await database.customSelect('SELECT 1').get();
    final services = TrainingServiceBundle(
      database,
      DriftTrainingRepositories(database),
      DriftRunStore(database),
    );
    await services.runLifecycle.recoverInterruptedRuns(
      recoveredAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    return services;
  }

  static Future<SnekPenSnapshot> loadPen() async =>
      (await _instance).penMigration.loadOrMigrate();

  static Future<void> savePen(SnekPenSnapshot snapshot) async =>
      (await _instance).penMigration.save(snapshot);

  static Future<FixedStepRunRecorder> beginRun(TrainingRun run) async {
    final services = await _instance;
    final recorder = FixedStepRunRecorder(
      runId: run.id,
      lifecycle: services.runLifecycle,
      chunks: services.runChunks,
    );
    await recorder.begin(run);
    return recorder;
  }
}
