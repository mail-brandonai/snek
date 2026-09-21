import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

import '../domain/training_repositories.dart';

import 'training_database.dart';

const _recordingStatus = 'recording';
const _pendingReviewStatus = 'pendingReview';
const _incompleteStatus = 'incomplete';

class DriftRunStore implements RunChunkRepository {
  const DriftRunStore(this.database);

  final TrainingDatabase database;

  Future<void> createRun({
    required String id,
    required int createdAtMs,
  }) {
    return database.into(database.runHeaders).insert(
          RunHeadersCompanion.insert(
            id: id,
            status: _recordingStatus,
            createdAtMs: createdAtMs,
          ),
        );
  }

  @override
  Future<void> appendChunk({
    required String runId,
    required int sequence,
    required int firstTick,
    required int lastTick,
    required Uint8List payload,
  }) async {
    if (sequence < 0 || firstTick < 0 || lastTick < firstTick) {
      throw ArgumentError('Invalid run chunk range');
    }

    await database.transaction(() async {
      final header = await (database.select(database.runHeaders)
            ..where((row) => row.id.equals(runId)))
          .getSingleOrNull();
      if (header == null || header.status != _recordingStatus) {
        throw StateError('Run is not recording');
      }

      final previous = await (database.select(database.runChunks)
            ..where((row) => row.runId.equals(runId))
            ..orderBy([(row) => OrderingTerm.desc(row.sequence)])
            ..limit(1))
          .getSingleOrNull();
      final expectedSequence = (previous?.sequence ?? -1) + 1;
      if (sequence != expectedSequence ||
          (previous != null && firstTick <= previous.lastTick)) {
        throw StateError('Run chunks must be contiguous and ordered');
      }

      await database.into(database.runChunks).insert(
            RunChunksCompanion.insert(
              runId: runId,
              sequence: sequence,
              firstTick: firstTick,
              lastTick: lastTick,
              payload: Uint8List.fromList(payload),
              checksum: sha256.convert(payload).toString(),
            ),
          );
    });
  }

  @override
  Future<void> finalizeRun({
    required String runId,
    required int expectedChunkCount,
    required int finalizedAtMs,
  }) async {
    if (expectedChunkCount < 0) {
      throw ArgumentError.value(expectedChunkCount, 'expectedChunkCount');
    }

    await database.transaction(() async {
      final header = await (database.select(database.runHeaders)
            ..where((row) => row.id.equals(runId)))
          .getSingleOrNull();
      if (header == null) throw StateError('Run does not exist');

      final chunks = await (database.select(database.runChunks)
            ..where((row) => row.runId.equals(runId))
            ..orderBy([(row) => OrderingTerm.asc(row.sequence)]))
          .get();

      _verifyChunks(chunks, expectedChunkCount);
      if (header.status == _pendingReviewStatus) return;
      if (header.status != _recordingStatus) {
        throw StateError('Run cannot be finalized from its current state');
      }

      await (database.update(database.runHeaders)
            ..where((row) => row.id.equals(runId)))
          .write(
        RunHeadersCompanion(
          status: const Value(_pendingReviewStatus),
          finalizedAtMs: Value(finalizedAtMs),
        ),
      );
    });
  }

  @override
  Future<void> markIncomplete({
    required String runId,
    required int finalizedAtMs,
  }) async {
    await database.transaction(() async {
      final header = await (database.select(database.runHeaders)
            ..where((row) => row.id.equals(runId)))
          .getSingleOrNull();
      if (header == null) throw StateError('Run does not exist');
      if (header.status == _incompleteStatus) return;
      if (header.status != _recordingStatus) {
        throw StateError('Only a recording run can be marked incomplete');
      }
      await (database.update(database.runHeaders)
            ..where((row) => row.id.equals(runId)))
          .write(
        RunHeadersCompanion(
          status: const Value(_incompleteStatus),
          finalizedAtMs: Value(finalizedAtMs),
        ),
      );
    });
  }

  void _verifyChunks(List<RunChunk> chunks, int expectedChunkCount) {
    if (chunks.length != expectedChunkCount) {
      throw StateError('Run is missing one or more chunks');
    }

    for (var index = 0; index < chunks.length; index++) {
      final chunk = chunks[index];
      if (chunk.sequence != index ||
          chunk.checksum != sha256.convert(chunk.payload).toString()) {
        throw StateError('Run chunk integrity check failed');
      }
    }
  }

  Future<String?> statusFor(String runId) async {
    final row = await (database.select(database.runHeaders)
          ..where((header) => header.id.equals(runId)))
        .getSingleOrNull();
    return row?.status;
  }

  @override
  Future<int> chunkCountFor(String runId) async {
    final rows = await (database.select(database.runChunks)
          ..where((chunk) => chunk.runId.equals(runId)))
        .get();
    return rows.length;
  }

  Future<List<String>> pendingRunIdsSince(int createdAtMs) async {
    final rows = await (database.select(database.runHeaders)
          ..where(
            (header) =>
                header.status.equals(_pendingReviewStatus) &
                header.createdAtMs.isBiggerOrEqualValue(createdAtMs),
          )
          ..orderBy([(header) => OrderingTerm.desc(header.createdAtMs)]))
        .get();
    return rows.map((row) => row.id).toList(growable: false);
  }

  @override
  Future<List<Uint8List>> chunkPayloadsFor(String runId) async {
    final rows = await (database.select(database.runChunks)
          ..where((chunk) => chunk.runId.equals(runId))
          ..orderBy([(chunk) => OrderingTerm.asc(chunk.sequence)]))
        .get();
    for (var index = 0; index < rows.length; index++) {
      final row = rows[index];
      if (row.sequence != index ||
          row.checksum != sha256.convert(row.payload).toString()) {
        throw StateError('Run chunk integrity check failed');
      }
    }
    return rows
        .map((row) => Uint8List.fromList(row.payload))
        .toList(growable: false);
  }

  Future<void> deleteRun(String runId) async {
    await database.transaction(() async {
      await (database.delete(database.runChunks)
            ..where((chunk) => chunk.runId.equals(runId)))
          .go();
      await (database.delete(database.runHeaders)
            ..where((header) => header.id.equals(runId)))
          .go();
    });
  }
}
