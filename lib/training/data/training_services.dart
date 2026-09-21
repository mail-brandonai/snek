import 'package:shared_preferences/shared_preferences.dart';

import '../domain/training_application.dart';
import '../domain/training_models.dart';
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

class _TrainingServices {
  _TrainingServices(this.database, this.repositories)
      : penMigration = SnekPenMigrationService(
          repositories,
          _SharedPreferencesLegacyPenStorage(),
        );

  final TrainingDatabase database;
  final DriftTrainingRepositories repositories;
  final SnekPenMigrationService penMigration;
}

class TrainingServices {
  TrainingServices._();

  static final Future<_TrainingServices> _instance = _open();

  static Future<_TrainingServices> _open() async {
    final database = TrainingDatabase.persistent();
    await database.customSelect('SELECT 1').get();
    return _TrainingServices(database, DriftTrainingRepositories(database));
  }

  static Future<SnekPenSnapshot> loadPen() async =>
      (await _instance).penMigration.loadOrMigrate();

  static Future<void> savePen(SnekPenSnapshot snapshot) async =>
      (await _instance).penMigration.save(snapshot);
}
