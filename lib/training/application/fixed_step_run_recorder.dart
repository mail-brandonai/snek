import 'dart:convert';
import 'dart:typed_data';

import '../../game/domain/simulation_capture.dart';
import '../domain/recording_contract.dart'
    show currentTrainingRecordSchemaVersion;
import '../domain/training_application.dart';
import '../domain/training_models.dart';
import '../domain/training_repositories.dart';

class FixedStepRunRecorder
    implements SimulationCaptureSink, TacticalAnalysisCaptureSink {
  FixedStepRunRecorder({
    required this.runId,
    required this.lifecycle,
    required this.chunks,
    this.chunkTickCount = 240,
    this.maximumPendingChunks = 2,
    this.captureTacticalAnalysis = false,
  }) {
    if (runId.trim().isEmpty ||
        chunkTickCount <= 0 ||
        maximumPendingChunks <= 0) {
      throw ArgumentError('Invalid run recorder configuration');
    }
  }

  final String runId;
  final RunLifecycleService lifecycle;
  final RunChunkRepository chunks;
  final int chunkTickCount;
  final int maximumPendingChunks;

  /// Tactical events are reconstructed by the review worker after the run.
  @override
  final bool captureTacticalAnalysis;

  final List<SimulationControlSample> _controls = [];
  final List<SimulationObservationSnapshot> _observations = [];
  final List<SimulationEventSnapshot> _events = [];
  Future<void> _writeTail = Future<void>.value();
  Future<bool>? _completion;
  Object? _writeError;
  int _nextSequence = 0;
  int _lastControlTick = 0;
  int _pendingChunkWrites = 0;
  int? _firstTick;
  int? _lastTick;
  bool _started = false;
  bool _accepting = false;
  bool _captureIncomplete = false;

  bool get captureIncomplete => _captureIncomplete || _writeError != null;
  Object? get writeError => _writeError;

  Future<void> begin(TrainingRun run) async {
    if (run.id != runId) {
      throw ArgumentError.value(run.id, 'run.id', 'Run ID does not match');
    }
    if (_started) throw StateError('Run recorder has already started');
    await lifecycle.start(run);
    _started = true;
    _accepting = true;
    recordEvent(
      const SimulationEventSnapshot(
        tick: 0,
        kind: SimulationEventKind.runStarted,
        actorId: 'player',
      ),
    );
  }

  @override
  void recordControl(SimulationControlSample sample) {
    if (!_accepting) return;
    if (_lastControlTick != 0 && sample.tick != _lastControlTick + 1) {
      _captureIncomplete = true;
      _accepting = false;
      return;
    }
    _lastControlTick = sample.tick;
    _includeTick(sample.tick);
    _controls.add(sample);
  }

  @override
  void recordObservation(SimulationObservationSnapshot observation) {
    if (!_accepting) return;
    _includeTick(observation.tick);
    _observations.add(observation);
  }

  @override
  void recordEvent(SimulationEventSnapshot event) {
    if (!_accepting) return;
    _includeTick(event.tick);
    _events.add(event);
  }

  Future<bool> finalize({required int finalizedAtMs}) =>
      _completeRun(finalizedAtMs: finalizedAtMs, complete: true);

  Future<bool> abort({required int finalizedAtMs}) =>
      _completeRun(finalizedAtMs: finalizedAtMs, complete: false);

  Future<bool> _completeRun({
    required int finalizedAtMs,
    required bool complete,
  }) {
    final existing = _completion;
    if (existing != null) return existing;
    if (!_started) return Future<bool>.value(false);
    _accepting = false;
    final completion = _finish(
      finalizedAtMs: finalizedAtMs,
      complete: complete,
    );
    _completion = completion;
    return completion;
  }

  Future<bool> _finish({
    required int finalizedAtMs,
    required bool complete,
  }) async {
    _queueCurrentChunk();
    await _writeTail;

    if (complete && !captureIncomplete) {
      try {
        await lifecycle.finalize(
          runId: runId,
          expectedChunkCount: _nextSequence,
          finalizedAtMs: finalizedAtMs,
        );
        return true;
      } catch (error) {
        _writeError ??= error;
      }
    }

    try {
      await lifecycle.markIncomplete(
        runId: runId,
        finalizedAtMs: finalizedAtMs,
      );
    } catch (error) {
      _writeError ??= error;
    }
    return false;
  }

  @override
  void completeStep(int tick) {
    if (!_accepting) return;
    if (tick != _lastControlTick) {
      _captureIncomplete = true;
      _accepting = false;
      return;
    }
    if (_controls.length >= chunkTickCount) _queueCurrentChunk();
  }

  void _includeTick(int tick) {
    if (_firstTick == null || tick < _firstTick!) _firstTick = tick;
    if (_lastTick == null || tick > _lastTick!) _lastTick = tick;
  }

  void _queueCurrentChunk() {
    final firstTick = _firstTick;
    final lastTick = _lastTick;
    if (firstTick == null || lastTick == null) return;
    if (_controls.isEmpty && _observations.isEmpty && _events.isEmpty) return;

    final controls = List<SimulationControlSample>.of(_controls);
    final observations = List<SimulationObservationSnapshot>.of(_observations);
    final events = List<SimulationEventSnapshot>.of(_events);
    _controls.clear();
    _observations.clear();
    _events.clear();
    _firstTick = null;
    _lastTick = null;

    if (_pendingChunkWrites >= maximumPendingChunks) {
      _captureIncomplete = true;
      _accepting = false;
      return;
    }

    final sequence = _nextSequence++;
    _pendingChunkWrites++;
    _writeTail = _writeTail
        .then<void>((_) async {
          if (_writeError != null) return;
          final payload = Uint8List.fromList(
            utf8.encode(
              jsonEncode(<String, Object?>{
                'format': 'snek-run-chunk',
                'schemaVersion': currentTrainingRecordSchemaVersion,
                'runId': runId,
                'sequence': sequence,
                'firstTick': firstTick,
                'lastTick': lastTick,
                'controls': controls
                    .map((sample) => sample.toJson())
                    .toList(growable: false),
                'observations': observations
                    .map((sample) => sample.toJson())
                    .toList(growable: false),
                'events': events
                    .map((event) => event.toJson())
                    .toList(growable: false),
              }),
            ),
          );
          await chunks.appendChunk(
            runId: runId,
            sequence: sequence,
            firstTick: firstTick,
            lastTick: lastTick,
            payload: payload,
          );
        })
        .catchError((Object error) {
          _writeError ??= error;
          _captureIncomplete = true;
          _accepting = false;
        })
        .whenComplete(() {
          _pendingChunkWrites--;
        });
  }
}
