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

@DriftDatabase(tables: [RunHeaders, RunChunks])
class TrainingDatabase extends _$TrainingDatabase {
  TrainingDatabase(QueryExecutor executor) : super(executor);

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
  int get schemaVersion => 1;
}
