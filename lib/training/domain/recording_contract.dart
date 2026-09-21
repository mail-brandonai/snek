import 'controller_contract.dart';

const currentTrainingRecordSchemaVersion = 1;

class RunHeaderDto {
  const RunHeaderDto({
    required this.runId,
    required this.mode,
    required this.seed,
    required this.tickRateHz,
    required this.createdAtMs,
    this.schemaVersion = currentTrainingRecordSchemaVersion,
  });

  final int schemaVersion;
  final String runId;
  final String mode;
  final int seed;
  final int tickRateHz;
  final int createdAtMs;

  Map<String, Object?> toJson() => <String, Object?>{
        'schemaVersion': schemaVersion,
        'runId': runId,
        'mode': mode,
        'seed': seed,
        'tickRateHz': tickRateHz,
        'createdAtMs': createdAtMs,
      };

  factory RunHeaderDto.fromJson(Object? value) {
    final map = _requireObjectMap(value);
    _checkSchemaVersion(map);
    return RunHeaderDto(
      schemaVersion: currentTrainingRecordSchemaVersion,
      runId: _string(map, 'runId'),
      mode: _string(map, 'mode'),
      seed: _integer(map, 'seed'),
      tickRateHz: _integer(map, 'tickRateHz'),
      createdAtMs: _integer(map, 'createdAtMs'),
    );
  }
}

class ControlSampleDto {
  const ControlSampleDto({
    required this.tick,
    required this.headingX,
    required this.headingY,
    required this.sprinting,
    this.schemaVersion = currentTrainingRecordSchemaVersion,
  });

  final int schemaVersion;
  final int tick;
  final double headingX;
  final double headingY;
  final bool sprinting;

  Map<String, Object?> toJson() => <String, Object?>{
        'schemaVersion': schemaVersion,
        'tick': tick,
        'headingX': headingX,
        'headingY': headingY,
        'sprinting': sprinting,
      };

  factory ControlSampleDto.fromJson(Object? value) {
    final map = _requireObjectMap(value);
    _checkSchemaVersion(map);
    return ControlSampleDto(
      tick: _integer(map, 'tick'),
      headingX: _number(map, 'headingX'),
      headingY: _number(map, 'headingY'),
      sprinting: _boolean(map, 'sprinting'),
    );
  }
}

class ObservationSampleDto {
  const ObservationSampleDto({
    required this.tick,
    required this.nearestThreatDistance,
    required this.nearbyThreatCount,
    required this.nearbyPelletCount,
    required this.bodyLength,
    this.schemaVersion = currentTrainingRecordSchemaVersion,
  });

  final int schemaVersion;
  final int tick;
  final double? nearestThreatDistance;
  final int nearbyThreatCount;
  final int nearbyPelletCount;
  final int bodyLength;

  Map<String, Object?> toJson() => <String, Object?>{
        'schemaVersion': schemaVersion,
        'tick': tick,
        'nearestThreatDistance': nearestThreatDistance,
        'nearbyThreatCount': nearbyThreatCount,
        'nearbyPelletCount': nearbyPelletCount,
        'bodyLength': bodyLength,
      };

  factory ObservationSampleDto.fromJson(Object? value) {
    final map = _requireObjectMap(value);
    _checkSchemaVersion(map);
    return ObservationSampleDto(
      tick: _integer(map, 'tick'),
      nearestThreatDistance: _nullableNumber(map, 'nearestThreatDistance'),
      nearbyThreatCount: _integer(map, 'nearbyThreatCount'),
      nearbyPelletCount: _integer(map, 'nearbyPelletCount'),
      bodyLength: _integer(map, 'bodyLength'),
    );
  }
}

class SimulationEventDto {
  const SimulationEventDto({
    required this.tick,
    required this.kind,
    required this.actorId,
    this.targetId,
    this.value,
    this.schemaVersion = currentTrainingRecordSchemaVersion,
  });

  final int schemaVersion;
  final int tick;
  final String kind;
  final String actorId;
  final String? targetId;
  final double? value;

  Map<String, Object?> toJson() => <String, Object?>{
        'schemaVersion': schemaVersion,
        'tick': tick,
        'kind': kind,
        'actorId': actorId,
        'targetId': targetId,
        'value': value,
      };

  factory SimulationEventDto.fromJson(Object? value) {
    final map = _requireObjectMap(value);
    _checkSchemaVersion(map);
    return SimulationEventDto(
      tick: _integer(map, 'tick'),
      kind: _string(map, 'kind'),
      actorId: _string(map, 'actorId'),
      targetId: _nullableString(map, 'targetId'),
      value: _nullableNumber(map, 'value'),
    );
  }
}

class SoulRevisionDto {
  SoulRevisionDto({
    required this.soulId,
    required this.revisionId,
    required this.trainerVersion,
    required this.featureVersion,
    required Map<String, double> weights,
    required List<String> sourceRunIds,
    this.parentRevisionId,
    this.schemaVersion = currentTrainingRecordSchemaVersion,
  })  : weights = Map<String, double>.unmodifiable(weights),
        sourceRunIds = List<String>.unmodifiable(sourceRunIds);

  final int schemaVersion;
  final String soulId;
  final String revisionId;
  final String? parentRevisionId;
  final String trainerVersion;
  final String featureVersion;
  final Map<String, double> weights;
  final List<String> sourceRunIds;

  Map<String, Object?> toJson() => <String, Object?>{
        'schemaVersion': schemaVersion,
        'soulId': soulId,
        'revisionId': revisionId,
        'parentRevisionId': parentRevisionId,
        'trainerVersion': trainerVersion,
        'featureVersion': featureVersion,
        'weights': weights,
        'sourceRunIds': sourceRunIds,
      };

  factory SoulRevisionDto.fromJson(Object? value) {
    final map = _requireObjectMap(value);
    _checkSchemaVersion(map);
    return SoulRevisionDto(
      soulId: _string(map, 'soulId'),
      revisionId: _string(map, 'revisionId'),
      parentRevisionId: _nullableString(map, 'parentRevisionId'),
      trainerVersion: _string(map, 'trainerVersion'),
      featureVersion: _string(map, 'featureVersion'),
      weights: _numberMap(map, 'weights'),
      sourceRunIds: _stringList(map, 'sourceRunIds'),
    );
  }
}

class MatchParticipantDto {
  MatchParticipantDto({
    required this.actorId,
    required this.role,
    required this.controller,
    required List<String> soulRevisionIds,
    this.snekProfileId,
    this.schemaVersion = currentTrainingRecordSchemaVersion,
  }) : soulRevisionIds = List<String>.unmodifiable(soulRevisionIds);

  final int schemaVersion;
  final String actorId;
  final ActorRole role;
  final ControllerSource controller;
  final String? snekProfileId;
  final List<String> soulRevisionIds;

  Map<String, Object?> toJson() => <String, Object?>{
        'schemaVersion': schemaVersion,
        'actorId': actorId,
        'role': role.name,
        'controller': controller.name,
        'snekProfileId': snekProfileId,
        'soulRevisionIds': soulRevisionIds,
      };

  factory MatchParticipantDto.fromJson(Object? value) {
    final map = _requireObjectMap(value);
    _checkSchemaVersion(map);
    return MatchParticipantDto(
      actorId: _string(map, 'actorId'),
      role: _enumValue(ActorRole.values, _string(map, 'role')),
      controller:
          _enumValue(ControllerSource.values, _string(map, 'controller')),
      snekProfileId: _nullableString(map, 'snekProfileId'),
      soulRevisionIds: _stringList(map, 'soulRevisionIds'),
    );
  }
}

Map<String, Object?> _requireObjectMap(Object? value) {
  if (value is! Map) throw const FormatException('Expected a JSON object');
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      throw const FormatException('Expected string object keys');
    }
    result[entry.key as String] = entry.value;
  }
  return result;
}

void _checkSchemaVersion(Map<String, Object?> map) {
  final value = map['schemaVersion'];
  if (value is! int) {
    throw const FormatException('Missing training record schema version');
  }
  if (value != currentTrainingRecordSchemaVersion) {
    throw UnsupportedError('Unsupported training record schema version');
  }
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

double _number(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! num || !value.isFinite) {
    throw FormatException('Expected finite number field: $key');
  }
  return value.toDouble();
}

double? _nullableNumber(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value == null) return null;
  if (value is! num || !value.isFinite) {
    throw FormatException('Expected nullable finite number: $key');
  }
  return value.toDouble();
}

bool _boolean(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! bool) throw FormatException('Expected boolean field: $key');
  return value;
}

List<String> _stringList(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! List || value.any((entry) => entry is! String)) {
    throw FormatException('Expected string list field: $key');
  }
  return List<String>.unmodifiable(value.cast<String>());
}

Map<String, double> _numberMap(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! Map) throw FormatException('Expected number map field: $key');
  final result = <String, double>{};
  for (final entry in value.entries) {
    final raw = entry.value;
    if (entry.key is! String || raw is! num || !raw.isFinite) {
      throw FormatException('Expected finite number map field: $key');
    }
    result[entry.key as String] = raw.toDouble();
  }
  return result;
}

T _enumValue<T extends Enum>(Iterable<T> values, String name) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  throw FormatException('Unknown enum value: $name');
}
