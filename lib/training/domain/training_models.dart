import 'dart:convert';

import 'controller_contract.dart';
import 'recording_contract.dart' show currentTrainingRecordSchemaVersion;

class TrainingValidationException implements Exception {
  const TrainingValidationException(this.message);
  final String message;
  @override
  String toString() => 'TrainingValidationException: $message';
}

void _requireId(String value, String field) {
  if (value.trim().isEmpty) {
    throw TrainingValidationException('$field must not be empty');
  }
}

class SnekProfile {
  const SnekProfile({
    required this.id,
    required this.name,
    required this.colorIndex,
  });

  static const starter = SnekProfile(
    id: 'starter-snek',
    name: 'Snek',
    colorIndex: 1,
  );

  final String id;
  final String name;
  final int colorIndex;

  Map<String, Object> toJson() => <String, Object>{
        'id': id,
        'name': name,
        'colorIndex': colorIndex,
      };

  factory SnekProfile.fromJson(Object? value) {
    final map = _object(value, 'profile');
    final id = map['id'];
    final name = map['name'];
    final colorIndex = map['colorIndex'];
    if (id is! String ||
        id.trim().isEmpty ||
        name is! String ||
        colorIndex is! num ||
        !colorIndex.isFinite) {
      throw const FormatException('Invalid saved snek');
    }
    return SnekProfile(
      id: id,
      name: name.trim().isEmpty ? 'Snek' : name.trim(),
      colorIndex: colorIndex.toInt().clamp(0, 9).toInt(),
    );
  }
}

class SnekPenSnapshot {
  SnekPenSnapshot({
    required List<SnekProfile> sneks,
    required this.selectedSnekId,
  }) : sneks = List<SnekProfile>.unmodifiable(sneks) {
    if (this.sneks.isEmpty) {
      throw const TrainingValidationException('Pen must contain a profile');
    }
    final ids = this.sneks.map((profile) => profile.id).toList();
    if (ids.any((id) => id.trim().isEmpty) ||
        ids.toSet().length != ids.length) {
      throw const TrainingValidationException(
        'Profile IDs must be unique and non-empty',
      );
    }
    if (!ids.contains(selectedSnekId)) {
      throw const TrainingValidationException(
        'Selected profile does not exist',
      );
    }
  }

  final List<SnekProfile> sneks;
  final String selectedSnekId;

  static final defaults = SnekPenSnapshot(
    sneks: const <SnekProfile>[SnekProfile.starter],
    selectedSnekId: SnekProfile.starter.id,
  );

  Map<String, Object?> toJson() => <String, Object?>{
        'sneks': sneks.map((profile) => profile.toJson()).toList(),
        'selectedSnekId': selectedSnekId,
      };

  factory SnekPenSnapshot.fromJson(Object? value) {
    final map = _object(value, 'pen');
    final raw = map['sneks'];
    if (raw is! List || raw.isEmpty) {
      throw const FormatException('Expected a non-empty profile list');
    }
    final profiles = raw.map(SnekProfile.fromJson).toList(growable: false);
    final selected = map['selectedSnekId'];
    final selectedId =
        selected is String && profiles.any((profile) => profile.id == selected)
            ? selected
            : profiles.first.id;
    try {
      return SnekPenSnapshot(sneks: profiles, selectedSnekId: selectedId);
    } on TrainingValidationException catch (error) {
      throw FormatException(error.message);
    }
  }

  bool hasSameContents(SnekPenSnapshot other) {
    if (selectedSnekId != other.selectedSnekId ||
        sneks.length != other.sneks.length) {
      return false;
    }
    for (var index = 0; index < sneks.length; index++) {
      final left = sneks[index];
      final right = other.sneks[index];
      if (left.id != right.id ||
          left.name != right.name ||
          left.colorIndex != right.colorIndex) {
        return false;
      }
    }
    return true;
  }
}

enum TrainingRunStatus { recording, pendingReview, retained, discarded }

class TrainingRun {
  TrainingRun({
    required this.id,
    required this.mode,
    required this.seed,
    required this.tickRateHz,
    required this.createdAtMs,
    required this.status,
    required Map<String, Object?> config,
    this.finalizedAtMs,
    this.schemaVersion = currentTrainingRecordSchemaVersion,
  }) : config = Map<String, Object?>.unmodifiable(config) {
    _requireId(id, 'Run ID');
    _requireId(mode, 'Run mode');
    if (tickRateHz <= 0 ||
        createdAtMs < 0 ||
        (finalizedAtMs != null && finalizedAtMs! < createdAtMs)) {
      throw const TrainingValidationException('Invalid run timing or rate');
    }
    _checkJsonValue(this.config);
  }

  final int schemaVersion;
  final String id;
  final String mode;
  final int seed;
  final int tickRateHz;
  final int createdAtMs;
  final int? finalizedAtMs;
  final TrainingRunStatus status;
  final Map<String, Object?> config;

  Map<String, Object?> toJson() => <String, Object?>{
        'schemaVersion': schemaVersion,
        'id': id,
        'mode': mode,
        'seed': seed,
        'tickRateHz': tickRateHz,
        'createdAtMs': createdAtMs,
        'finalizedAtMs': finalizedAtMs,
        'status': status.name,
        'config': config,
      };

  factory TrainingRun.fromJson(Object? value) {
    final map = _versionedObject(value);
    return TrainingRun(
      schemaVersion: currentTrainingRecordSchemaVersion,
      id: _string(map, 'id'),
      mode: _string(map, 'mode'),
      seed: _integer(map, 'seed'),
      tickRateHz: _integer(map, 'tickRateHz'),
      createdAtMs: _integer(map, 'createdAtMs'),
      finalizedAtMs: _nullableInteger(map, 'finalizedAtMs'),
      status: _enumByName(TrainingRunStatus.values, _string(map, 'status')),
      config: _object(map['config'], 'config'),
    );
  }
}

class Soul {
  Soul({
    required this.id,
    required this.name,
    required this.createdAtMs,
    this.schemaVersion = currentTrainingRecordSchemaVersion,
  }) {
    _requireId(id, 'Soul ID');
    _requireId(name, 'Soul name');
    if (createdAtMs < 0) {
      throw const TrainingValidationException('Soul creation time is invalid');
    }
  }

  final int schemaVersion;
  final String id;
  final String name;
  final int createdAtMs;

  Map<String, Object?> toJson() => {
        'schemaVersion': schemaVersion,
        'id': id,
        'name': name,
        'createdAtMs': createdAtMs,
      };

  factory Soul.fromJson(Object? value) {
    final map = _versionedObject(value);
    return Soul(
      id: _string(map, 'id'),
      name: _string(map, 'name'),
      createdAtMs: _integer(map, 'createdAtMs'),
    );
  }
}

class SoulRevision {
  SoulRevision({
    required this.soulId,
    required this.revisionId,
    required this.trainerVersion,
    required this.featureVersion,
    required Map<String, double> weights,
    required List<String> sourceRunIds,
    this.parentRevisionId,
    this.schemaVersion = currentTrainingRecordSchemaVersion,
  })  : weights = Map<String, double>.unmodifiable(weights),
        sourceRunIds = List<String>.unmodifiable(sourceRunIds) {
    _requireId(soulId, 'Soul ID');
    _requireId(revisionId, 'Revision ID');
    _requireId(trainerVersion, 'Trainer version');
    _requireId(featureVersion, 'Feature version');
    if (parentRevisionId != null) {
      _requireId(parentRevisionId!, 'Parent revision ID');
    }
    if (this.sourceRunIds.isEmpty ||
        this.sourceRunIds.any((id) => id.trim().isEmpty) ||
        this.sourceRunIds.toSet().length != this.sourceRunIds.length) {
      throw const TrainingValidationException(
        'Source run IDs must be unique and non-empty',
      );
    }
    if (this.weights.isEmpty ||
        this.weights.keys.any((key) => key.trim().isEmpty) ||
        this.weights.values.any((weight) => !weight.isFinite || weight < 0)) {
      throw const TrainingValidationException(
        'Soul weights must be finite and non-negative',
      );
    }
    final total = this.weights.values.fold<double>(
          0,
          (sum, value) => sum + value,
        );
    if ((total - 1).abs() > 0.000001) {
      throw const TrainingValidationException('Soul weights must sum to 1');
    }
  }

  final int schemaVersion;
  final String soulId;
  final String revisionId;
  final String? parentRevisionId;
  final String trainerVersion;
  final String featureVersion;
  final Map<String, double> weights;
  final List<String> sourceRunIds;

  Map<String, Object?> toJson() => {
        'schemaVersion': schemaVersion,
        'soulId': soulId,
        'revisionId': revisionId,
        'parentRevisionId': parentRevisionId,
        'trainerVersion': trainerVersion,
        'featureVersion': featureVersion,
        'weights': weights,
        'sourceRunIds': sourceRunIds,
      };

  factory SoulRevision.fromJson(Object? value) {
    final map = _versionedObject(value);
    final rawWeights = _object(map['weights'], 'weights');
    final weights = <String, double>{};
    for (final entry in rawWeights.entries) {
      final value = entry.value;
      if (value is! num || !value.isFinite) {
        throw const FormatException('Expected finite Soul weight');
      }
      weights[entry.key] = value.toDouble();
    }
    final rawSources = map['sourceRunIds'];
    if (rawSources is! List || rawSources.any((value) => value is! String)) {
      throw const FormatException('Expected source run ID list');
    }
    return SoulRevision(
      soulId: _string(map, 'soulId'),
      revisionId: _string(map, 'revisionId'),
      parentRevisionId: _nullableString(map, 'parentRevisionId'),
      trainerVersion: _string(map, 'trainerVersion'),
      featureVersion: _string(map, 'featureVersion'),
      weights: weights,
      sourceRunIds: rawSources.cast<String>(),
    );
  }
}

class MatchParticipant {
  MatchParticipant({
    required this.actorId,
    required this.role,
    required this.controller,
    required List<String> soulRevisionIds,
    this.snekProfileId,
  }) : soulRevisionIds = List<String>.unmodifiable(soulRevisionIds) {
    _requireId(actorId, 'Actor ID');
    if (snekProfileId != null) _requireId(snekProfileId!, 'Profile ID');
    if (this.soulRevisionIds.any((id) => id.trim().isEmpty) ||
        this.soulRevisionIds.toSet().length != this.soulRevisionIds.length) {
      throw const TrainingValidationException(
        'Participant revision IDs must be unique and non-empty',
      );
    }
  }

  final String actorId;
  final ActorRole role;
  final ControllerSource controller;
  final String? snekProfileId;
  final List<String> soulRevisionIds;

  Map<String, Object?> toJson() => {
        'actorId': actorId,
        'role': role.name,
        'controller': controller.name,
        'snekProfileId': snekProfileId,
        'soulRevisionIds': soulRevisionIds,
      };

  factory MatchParticipant.fromJson(Object? value) {
    final map = _object(value, 'match participant');
    final raw = map['soulRevisionIds'];
    if (raw is! List || raw.any((entry) => entry is! String)) {
      throw const FormatException('Expected revision ID list');
    }
    return MatchParticipant(
      actorId: _string(map, 'actorId'),
      role: _enumByName(ActorRole.values, _string(map, 'role')),
      controller:
          _enumByName(ControllerSource.values, _string(map, 'controller')),
      snekProfileId: _nullableString(map, 'snekProfileId'),
      soulRevisionIds: raw.cast<String>(),
    );
  }
}

class TrainingMatch {
  TrainingMatch({
    required this.id,
    required this.mode,
    required this.startedAtMs,
    required List<MatchParticipant> participants,
    required Map<String, Object?> outcome,
    this.endedAtMs,
  })  : participants = List<MatchParticipant>.unmodifiable(participants),
        outcome = Map<String, Object?>.unmodifiable(outcome) {
    _requireId(id, 'Match ID');
    _requireId(mode, 'Match mode');
    if (startedAtMs < 0 || (endedAtMs != null && endedAtMs! < startedAtMs)) {
      throw const TrainingValidationException('Invalid match timing');
    }
    if (this.participants.isEmpty ||
        this.participants.map((item) => item.actorId).toSet().length !=
            this.participants.length) {
      throw const TrainingValidationException(
        'Match participants must be non-empty with distinct IDs',
      );
    }
    _checkJsonValue(this.outcome);
  }

  final String id;
  final String mode;
  final int startedAtMs;
  final int? endedAtMs;
  final List<MatchParticipant> participants;
  final Map<String, Object?> outcome;

  Map<String, Object?> toJson() => {
        'schemaVersion': currentTrainingRecordSchemaVersion,
        'id': id,
        'mode': mode,
        'startedAtMs': startedAtMs,
        'endedAtMs': endedAtMs,
        'participants': participants.map((item) => item.toJson()).toList(),
        'outcome': outcome,
      };

  factory TrainingMatch.fromJson(Object? value) {
    final map = _versionedObject(value);
    final rawParticipants = map['participants'];
    if (rawParticipants is! List) {
      throw const FormatException('Expected match participant list');
    }
    return TrainingMatch(
      id: _string(map, 'id'),
      mode: _string(map, 'mode'),
      startedAtMs: _integer(map, 'startedAtMs'),
      endedAtMs: _nullableInteger(map, 'endedAtMs'),
      participants: rawParticipants
          .map(MatchParticipant.fromJson)
          .toList(growable: false),
      outcome: _object(map['outcome'], 'outcome'),
    );
  }
}

Map<String, Object?> _object(Object? value, String label) {
  if (value is! Map) throw FormatException('Expected $label object');
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      throw FormatException('Expected string key in $label');
    }
    result[entry.key as String] = entry.value;
  }
  return result;
}

Map<String, Object?> _versionedObject(Object? value) {
  final map = _object(value, 'record');
  final version = map['schemaVersion'];
  if (version is! int) throw const FormatException('Missing schema version');
  if (version != currentTrainingRecordSchemaVersion) {
    throw UnsupportedError(
      'Unsupported training record schema version: $version',
    );
  }
  return map;
}

String _string(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! String) throw FormatException('Expected string field: $key');
  return value;
}

String? _nullableString(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value == null) return null;
  if (value is! String) throw FormatException('Expected nullable string: $key');
  return value;
}

int _integer(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! int) throw FormatException('Expected integer field: $key');
  return value;
}

int? _nullableInteger(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value == null) return null;
  if (value is! int) throw FormatException('Expected nullable integer: $key');
  return value;
}

T _enumByName<T extends Enum>(Iterable<T> values, String name) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  throw FormatException('Unknown enum value: $name');
}

void _checkJsonValue(Object? value) {
  try {
    jsonEncode(value);
  } on Object catch (error) {
    throw FormatException('Value is not JSON serializable: $error');
  }
}
