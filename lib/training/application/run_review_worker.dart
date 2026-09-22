import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:isolate_manager/isolate_manager.dart';

import '../domain/recording_contract.dart'
    show currentTrainingRecordSchemaVersion;
import '../domain/soul_feature_extractor.dart';

@pragma('vm:entry-point')
@isolateManagerCustomWorker
void analyzeRunReviewChunksWorker(dynamic params) {
  unawaited(
    IsolateManagerFunction.customFunction<Map<String, Object?>, dynamic>(
      params,
      onEvent: (_, message) => analyzeRunReviewChunks(_reviewInput(message)),
    ),
  );
}

Map<String, Object?> _reviewInput(dynamic message) {
  if (message is! Map) {
    throw const FormatException('Run review worker input is not a map.');
  }
  return Map<String, Object?>.from(message);
}

Map<String, Object?> analyzeRunReviewChunks(Map<String, Object?> input) {
  final runId = _requiredString(input, 'runId');
  final recordSchemaVersion = _requiredInt(input, 'recordSchemaVersion');
  final tickRateHz = _requiredInt(input, 'tickRateHz');
  final rawPayloads = input['chunkPayloads'];
  if (rawPayloads is! List) {
    throw const FormatException('Run chunk payloads are missing.');
  }

  var controlCount = 0;
  var observationCount = 0;
  var eventCount = 0;
  int? firstTick;
  int? lastTick;
  Map<String, Object?>? outcomeMetadata;
  String? outcome;
  final decodedChunks = <Object?>[];

  for (var sequence = 0; sequence < rawPayloads.length; sequence++) {
    final payload = rawPayloads[sequence];
    if (payload is! Uint8List) {
      throw const FormatException('Run chunk payload is not byte data.');
    }
    final decoded = jsonDecode(utf8.decode(payload));
    if (decoded is! Map) throw StateError('Run chunk is not an object');
    final chunk = Map<String, Object?>.from(decoded);
    if (chunk['format'] != 'snek-run-chunk' ||
        chunk['schemaVersion'] != currentTrainingRecordSchemaVersion ||
        chunk['runId'] != runId ||
        chunk['sequence'] != sequence) {
      throw StateError('Run chunk metadata is invalid');
    }
    final chunkFirst = chunk['firstTick'];
    final chunkLast = chunk['lastTick'];
    if (chunkFirst is! int ||
        chunkLast is! int ||
        chunkFirst < 0 ||
        chunkLast < chunkFirst ||
        (lastTick != null && chunkFirst <= lastTick)) {
      throw StateError('Run chunk tick range is invalid');
    }
    firstTick ??= chunkFirst;
    lastTick = chunkLast;

    controlCount += _array(chunk, 'controls').length;
    observationCount += _array(chunk, 'observations').length;
    final events = _array(chunk, 'events');
    eventCount += events.length;
    for (final value in events) {
      if (value is! Map) throw StateError('Run event is not an object');
      final event = Map<String, Object?>.from(value);
      if (event['kind'] != 'runEnded') continue;
      final metadata = event['metadata'];
      if (metadata is Map) {
        outcomeMetadata = Map<String, Object?>.from(metadata);
      }
      final detail = event['detail'];
      outcome = detail is String ? detail : null;
    }
    decodedChunks.add(chunk);
  }

  final featureAnalysis = const SoulFeatureExtractor().extractDecoded(
    runId: runId,
    recordSchemaVersion: recordSchemaVersion,
    tickRateHz: tickRateHz,
    decodedChunks: decodedChunks,
  );
  return <String, Object?>{
    'controlSampleCount': controlCount,
    'observationSampleCount': observationCount,
    'eventCount': eventCount,
    'score': _integer(outcomeMetadata?['score']),
    'length': _integer(outcomeMetadata?['length']),
    'survivalSeconds': _decimal(outcomeMetadata?['survivalSeconds']),
    'rank': _integer(outcomeMetadata?['rank']),
    'outcome': outcome,
    'firstTick': firstTick,
    'lastTick': lastTick,
    'featureAnalysis': featureAnalysis.toJson(),
  };
}

List<Object?> _array(Map<String, Object?> object, String key) {
  final value = object[key];
  if (value is! List) throw StateError('Run chunk $key is not an array');
  return value;
}

String _requiredString(Map<String, Object?> object, String key) {
  final value = object[key];
  if (value is! String) throw FormatException('Expected string field: $key');
  return value;
}

int _requiredInt(Map<String, Object?> object, String key) {
  final value = object[key];
  if (value is! int) throw FormatException('Expected integer field: $key');
  return value;
}

int? _integer(Object? value) => value is int ? value : null;

double? _decimal(Object? value) => value is num ? value.toDouble() : null;
