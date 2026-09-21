import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'training_database.g.dart';

class RunHeaders extends Table {
  @override
  String get tableName => 'run_headers';

  TextColumn get id => text()();

  TextColumn get status => text()();

  IntColumn get createdAtMs => integer()();

  IntColumn get finalizedAtMs => integer().nullable()();

  TextColumn get mode => text().withDefault(const Constant('unknown'))();

  IntColumn get seed => integer().withDefault(const Constant(0))();

  IntColumn get tickRateHz => integer().withDefault(const Constant(1))();

  IntColumn get schemaVersion => integer().withDefault(const Constant(1))();

  TextColumn get configJson => text().withDefault(const Constant('{}'))();

  @override
  Set<Column> get primaryKey => {id};
}

class RunChunks extends Table {
  @override
  String get tableName => 'run_chunks';

  TextColumn get runId =>
      text().references(RunHeaders, #id, onDelete: KeyAction.cascade)();

  IntColumn get sequence => integer()();

  IntColumn get firstTick => integer()();

  IntColumn get lastTick => integer()();

  BlobColumn get payload => blob()();

  TextColumn get checksum => text()();

  @override
  Set<Column> get primaryKey => {runId, sequence};
}

class TrainingRecords extends Table {
  @override
  String get tableName => 'training_records';

  TextColumn get kind => text()();

  TextColumn get id => text()();

  TextColumn get payload => text()();

  @override
  Set<Column> get primaryKey => {kind, id};
}

@DriftDatabase(tables: [RunHeaders, RunChunks, TrainingRecords])
class TrainingDatabase extends _$TrainingDatabase {
  TrainingDatabase(super.e);

  factory TrainingDatabase.persistent() {
    return TrainingDatabase(
      driftDatabase(
        name: 'snek_training_arena',
        web: DriftWebOptions(
          sqlite3Wasm: Uri.parse('sqlite3.wasm'),
          driftWorker: Uri.parse('drift_worker.js'),
        ),
      ),
    );
  }

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(runHeaders, runHeaders.mode);
            await m.addColumn(runHeaders, runHeaders.seed);
            await m.addColumn(runHeaders, runHeaders.tickRateHz);
            await m.addColumn(runHeaders, runHeaders.schemaVersion);
            await m.addColumn(runHeaders, runHeaders.configJson);
            await m.createTable(trainingRecords);
          }
        },
      );
}
