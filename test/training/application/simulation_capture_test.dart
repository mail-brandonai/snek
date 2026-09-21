import 'package:flutter_test/flutter_test.dart';
import 'package:slither/game/domain/simulation.dart';
import 'package:slither/game/domain/simulation_capture.dart';
import 'package:slither/game/domain/vec2.dart';

void main() {
  test('capture records processed fixed steps without changing game outcomes',
      () {
    const config = SimulationConfig(
      botCount: 0,
      maxBotCount: 0,
      initialPellets: 0,
    );
    final unrecorded = GameSimulation(config: config, seed: 41);
    final capture = _CaptureSink();
    final recorded = GameSimulation(
      config: config,
      seed: 41,
      captureSink: capture,
    );

    for (var frame = 0; frame < 30; frame++) {
      final dt = frame.isEven ? 1 / 60 : 1 / 30;
      final steering = frame % 3 == 0 ? const Vec2(0, 1) : const Vec2(1, 0);
      unrecorded.update(dt, steering);
      recorded.update(dt, steering);
    }

    expect(capture.controls, hasLength(recorded.simulationTick));
    expect(
      capture.controls.map((sample) => sample.tick),
      orderedEquals(
        List<int>.generate(recorded.simulationTick, (index) => index + 1),
      ),
    );
    expect(recorded.player.head, unrecorded.player.head);
    expect(recorded.player.heading, unrecorded.player.heading);
    expect(recorded.score, unrecorded.score);
    expect(recorded.currentRunStats.length, unrecorded.currentRunStats.length);
    expect(
      recorded.currentRunStats.survivalSeconds,
      unrecorded.currentRunStats.survivalSeconds,
    );
  });
}

class _CaptureSink implements SimulationCaptureSink {
  final List<SimulationControlSample> controls = [];

  @override
  void recordControl(SimulationControlSample sample) {
    controls.add(sample);
  }

  @override
  void completeStep(int tick) {}

  @override
  void recordEvent(SimulationEventSnapshot event) {}

  @override
  void recordObservation(SimulationObservationSnapshot observation) {}
}
