import 'package:flutter_test/flutter_test.dart';
import 'package:slither/training/domain/training_application.dart';
import 'package:slither/training/domain/training_models.dart';
import 'package:slither/training/domain/training_repositories.dart';

void main() {
  test('v1 migration preserves profiles and selection before clearing old data',
      () async {
    final raw = '{"sneks":['
        '{"id":"a","name":"Alpha","colorIndex":3},'
        '{"id":"b","name":"Beta","colorIndex":7}],'
        '"selectedSnekId":"b"}';
    final repository = _MemoryPenRepository();
    final legacy = _LegacyStorage(raw);
    final service = SnekPenMigrationService(repository, legacy);

    final migrated = await service.loadOrMigrate();

    expect(migrated.sneks.map((profile) => profile.id), ['a', 'b']);
    expect(migrated.sneks.map((profile) => profile.name), ['Alpha', 'Beta']);
    expect(migrated.sneks.map((profile) => profile.colorIndex), [3, 7]);
    expect(migrated.selectedSnekId, 'b');
    expect(legacy.value, isNull);
    expect(legacy.removeCount, 1);
  });

  test('failed migration keeps v1 readable and retryable', () async {
    const raw = '{"sneks":[{"id":"legacy","name":"Old","colorIndex":5}],'
        '"selectedSnekId":"legacy"}';
    final repository = _MemoryPenRepository()..failNextSave = true;
    final legacy = _LegacyStorage(raw);
    final service = SnekPenMigrationService(repository, legacy);

    await expectLater(service.loadOrMigrate(), throwsA(isA<StateError>()));
    expect(legacy.value, raw);
    expect(repository.snapshot, isNull);

    final migrated = await service.loadOrMigrate();
    expect(migrated.sneks.single.id, 'legacy');
    expect(legacy.value, isNull);
  });
}

class _MemoryPenRepository implements PenRepository {
  SnekPenSnapshot? snapshot;
  bool failNextSave = false;

  @override
  Future<SnekPenSnapshot?> loadPen() async => snapshot;

  @override
  Future<void> savePen(SnekPenSnapshot value) async {
    if (failNextSave) {
      failNextSave = false;
      throw StateError('simulated interrupted write');
    }
    snapshot = value;
  }
}

class _LegacyStorage implements LegacyPenStorage {
  _LegacyStorage(this.value);

  String? value;
  int removeCount = 0;

  @override
  Future<String?> readV1() async => value;

  @override
  Future<void> removeV1() async {
    removeCount++;
    value = null;
  }
}
