import 'package:flutter_test/flutter_test.dart';
import 'package:slither/training/application/soul_controller.dart';
import 'package:slither/training/domain/controller_contract.dart';

void main() {
  group('SoulController', () {
    test('preserves heading and does not sprint without learned weights', () {
      const controller = SoulController(weights: <String, double>{});

      final command = controller.decide(_observation(headingX: 1));

      expect(command.steeringX, closeTo(1, 0.000001));
      expect(command.steeringY, closeTo(0, 0.000001));
      expect(command.sprinting, isFalse);
    });

    test('resource priority bends steering toward a nearby pellet', () {
      const controller = SoulController(
        weights: <String, double>{'resourcePriority': 1},
      );

      final command = controller.decide(
        _observation(
          headingX: 1,
          nearbyPelletCount: 1,
          nearestPelletDirectionY: 1,
        ),
      );

      expect(command.steeringY, greaterThan(0));
    });

    test('threat response steers away from a nearby threat', () {
      const controller = SoulController(
        weights: <String, double>{'riskPosture': 1},
      );

      final command = controller.decide(
        _observation(
          headingX: 1,
          pressured: true,
          nearestThreatDirectionX: 1,
        ),
      );

      expect(command.steeringX, lessThan(0));
    });

    test('sprint behavior requires opportunity and is disabled under pressure', () {
      const controller = SoulController(
        weights: <String, double>{'sprintBehavior': 1},
      );

      final command = controller.decide(
        _observation(nearbyPelletCount: 1, bodyLength: 12),
      );
      final pressuredCommand = controller.decide(
        _observation(
          nearbyPelletCount: 1,
          bodyLength: 12,
          pressured: true,
        ),
      );

      expect(command.sprinting, isTrue);
      expect(pressuredCommand.sprinting, isFalse);
    });
  });
}

ActorObservation _observation({
  double headingX = 1,
  double headingY = 0,
  double nearestThreatDirectionX = 0,
  double nearestThreatDirectionY = 0,
  double nearestPelletDirectionX = 0,
  double nearestPelletDirectionY = 0,
  int nearbyPelletCount = 0,
  int bodyLength = 12,
  bool pressured = false,
}) {
  return ActorObservation(
    tick: 1,
    headingX: headingX,
    headingY: headingY,
    nearestThreatDistance: null,
    nearbyThreatCount: pressured ? 1 : 0,
    nearbyPelletCount: nearbyPelletCount,
    bodyLength: bodyLength,
    pressured: pressured,
    nearestThreatDirectionX: nearestThreatDirectionX,
    nearestThreatDirectionY: nearestThreatDirectionY,
    nearestPelletDirectionX: nearestPelletDirectionX,
    nearestPelletDirectionY: nearestPelletDirectionY,
  );
}
