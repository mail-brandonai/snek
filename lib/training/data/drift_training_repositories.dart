import 'dart:convert';

import 'package:drift/drift.dart';

import '../domain/training_models.dart';
import '../domain/training_repositories.dart';
import 'training_database.dart';

class DriftTrainingRepositories
    implements PenRepository, RunRepository, SoulRepository, MatchRepository {
  const DriftTrainingRepositories(this.database);

  final TrainingDatabase database;

  static const _penKind = 'pen';
  static const _soulKind = 'soul';
  static const _revisionKind = 'soulRevision';
  static const _matchKind = 'match';
  static const _penId = 'current';

  Future<TrainingRecord?> _record(String kind, String id) =>
      (database.select(database.trainingRecords)
            ..where((row) => row.kind.equals(kind) & row.id.equals(id)))
          .getSingleOrNull();

  Future<void> _writeRecord(String kind, String id, Object? value) async {
    await database.into(database.trainingRecords).insertOnConflictUpdate(
          TrainingRecordsCompanion.insert(
            kind: kind,
            id: id,
            payload: jsonEncode(value),
          ),
        );
  }

  Future<List<TrainingRecord>> _records(String kind) =>
      (database.select(database.trainingRecords)
            ..where((row) => row.kind.equals(kind)))
          .get();

  @override
  Future<SnekPenSnapshot?> loadPen() async {
    final row = await _record(_penKind, _penId);
    if (row == null) return null;
    return SnekPenSnapshot.fromJson(jsonDecode(row.payload));
  }

  @override
  Future<void> savePen(SnekPenSnapshot snapshot) =>
      database.transaction(() async {
        await _writeRecord(_penKind, _penId, snapshot.toJson());
      });

  TrainingRun _run(RunHeader row) => TrainingRun.fromJson({
        'schemaVersion': row.schemaVersion,
        'id': row.id,
        'mode': row.mode,
        'seed': row.seed,
        'tickRateHz': row.tickRateHz,
        'createdAtMs': row.createdAtMs,
        'finalizedAtMs': row.finalizedAtMs,
        'status': row.status,
        'config': jsonDecode(row.configJson),
      });

  @override
  Future<void> createRun(TrainingRun run) async {
    if (run.status != TrainingRunStatus.recording) {
      throw const TrainingValidationException('New runs must start recording');
    }
    await database.into(database.runHeaders).insert(
          RunHeadersCompanion.insert(
            id: run.id,
            status: run.status.name,
            createdAtMs: run.createdAtMs,
            mode: Value(run.mode),
            seed: Value(run.seed),
            tickRateHz: Value(run.tickRateHz),
            schemaVersion: Value(run.schemaVersion),
            configJson: Value(jsonEncode(run.config)),
          ),
        );
  }

  @override
  Future<TrainingRun?> getRun(String id) async {
    final row = await (database.select(database.runHeaders)
          ..where((item) => item.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _run(row);
  }

  @override
  Future<List<TrainingRun>> listRuns({TrainingRunStatus? status}) async {
    final query = database.select(database.runHeaders);
    if (status != null) query.where((item) => item.status.equals(status.name));
    query.orderBy([(item) => OrderingTerm.desc(item.createdAtMs)]);
    return (await query.get()).map(_run).toList(growable: false);
  }

  @override
  Future<void> setRunReviewStatus(
    String id,
    TrainingRunStatus status,
  ) async {
    if (status != TrainingRunStatus.retained &&
        status != TrainingRunStatus.discarded) {
      throw const TrainingValidationException(
        'Review status must be retained or discarded',
      );
    }
    await database.transaction(() async {
      final row = await (database.select(database.runHeaders)
            ..where((item) => item.id.equals(id)))
          .getSingleOrNull();
      if (row == null) throw StateError('Run does not exist');
      if (row.status != TrainingRunStatus.pendingReview.name) {
        throw StateError('Only pending runs can be reviewed');
      }
      await (database.update(database.runHeaders)
            ..where((item) => item.id.equals(id)))
          .write(RunHeadersCompanion(status: Value(status.name)));
    });
  }

  @override
  Future<void> deleteRun(String id) async {
    await database.transaction(() async {
      final rows = await _records(_revisionKind);
      for (final row in rows) {
        final revision = SoulRevision.fromJson(jsonDecode(row.payload));
        if (revision.sourceRunIds.contains(id)) {
          throw StateError(
            'Run is referenced by Soul revision ${revision.revisionId}',
          );
        }
      }
      await (database.delete(database.runChunks)
            ..where((item) => item.runId.equals(id)))
          .go();
      await (database.delete(database.runHeaders)
            ..where((item) => item.id.equals(id)))
          .go();
    });
  }

  @override
  Future<void> saveSoul(Soul soul) async {
    await database.transaction(() async {
      await _writeRecord(_soulKind, soul.id, soul.toJson());
    });
  }

  @override
  Future<Soul?> getSoul(String id) async {
    final row = await _record(_soulKind, id);
    return row == null ? null : Soul.fromJson(jsonDecode(row.payload));
  }

  Future<void> _insertRevision(SoulRevision revision) async {
    if (await _record(_soulKind, revision.soulId) == null) {
      throw StateError('Soul does not exist');
    }
    if (await _record(_revisionKind, revision.revisionId) != null) {
      throw StateError('Soul revision IDs are immutable and must be unique');
    }
    final parentId = revision.parentRevisionId;
    if (parentId != null) {
      final parentRow = await _record(_revisionKind, parentId);
      if (parentRow == null) throw StateError('Parent revision does not exist');
      final parent = SoulRevision.fromJson(jsonDecode(parentRow.payload));
      if (parent.soulId != revision.soulId) {
        throw StateError('Parent revision belongs to a different Soul');
      }
    }
    for (final runId in revision.sourceRunIds) {
      final exists = await (database.select(database.runHeaders)
            ..where((item) => item.id.equals(runId)))
          .getSingleOrNull();
      if (exists == null) throw StateError('Source run does not exist: $runId');
    }
    await _writeRecord(_revisionKind, revision.revisionId, revision.toJson());
  }

  @override
  Future<void> saveRevision(SoulRevision revision) =>
      database.transaction(() => _insertRevision(revision));

  @override
  Future<void> saveSoulRevision({
    required Soul soul,
    required SoulRevision revision,
  }) async {
    if (soul.id != revision.soulId) {
      throw const TrainingValidationException(
        'Revision belongs to a different Soul',
      );
    }
    await database.transaction(() async {
      await _writeRecord(_soulKind, soul.id, soul.toJson());
      await _insertRevision(revision);
    });
  }

  @override
  Future<SoulRevision?> getRevision(String revisionId) async {
    final row = await _record(_revisionKind, revisionId);
    return row == null ? null : SoulRevision.fromJson(jsonDecode(row.payload));
  }

  @override
  Future<List<SoulRevision>> listRevisions(String soulId) async {
    final rows = await _records(_revisionKind);
    return rows
        .map((row) => SoulRevision.fromJson(jsonDecode(row.payload)))
        .where((revision) => revision.soulId == soulId)
        .toList(growable: false);
  }

  @override
  Future<void> deleteSoul(String id) async {
    await database.transaction(() async {
      final revisions = await listRevisions(id);
      if (revisions.isNotEmpty) {
        throw StateError('Soul with revisions cannot be deleted');
      }
      await (database.delete(database.trainingRecords)
            ..where((row) => row.kind.equals(_soulKind) & row.id.equals(id)))
          .go();
    });
  }

  @override
  Future<void> saveMatch(TrainingMatch match) async {
    await database.transaction(() async {
      final pen = await loadPen();
      final profileIds =
          pen?.sneks.map((profile) => profile.id).toSet() ?? <String>{};
      for (final participant in match.participants) {
        final profileId = participant.snekProfileId;
        if (profileId != null && !profileIds.contains(profileId)) {
          throw StateError(
            'Match references a missing Snek profile: $profileId',
          );
        }
        for (final revisionId in participant.soulRevisionIds) {
          if (await _record(_revisionKind, revisionId) == null) {
            throw StateError(
              'Match references a missing Soul revision: $revisionId',
            );
          }
        }
      }
      await _writeRecord(_matchKind, match.id, match.toJson());
    });
  }

  @override
  Future<TrainingMatch?> getMatch(String id) async {
    final row = await _record(_matchKind, id);
    return row == null ? null : TrainingMatch.fromJson(jsonDecode(row.payload));
  }

  @override
  Future<List<TrainingMatch>> listMatches() async {
    final rows = await _records(_matchKind);
    return rows
        .map((row) => TrainingMatch.fromJson(jsonDecode(row.payload)))
        .toList(growable: false);
  }

  @override
  Future<void> deleteMatch(String id) async {
    await (database.delete(database.trainingRecords)
          ..where((row) => row.kind.equals(_matchKind) & row.id.equals(id)))
        .go();
  }
}
