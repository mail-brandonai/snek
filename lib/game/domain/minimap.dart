import 'game_state.dart';
import 'vec2.dart';

class MinimapMarker {
  const MinimapMarker({
    required this.id,
    required this.x,
    required this.y,
    required this.colorIndex,
    required this.isPlayer,
  });

  final String id;
  final double x;
  final double y;
  final int colorIndex;
  final bool isPlayer;
}

class MinimapModel {
  const MinimapModel._();

  static List<MinimapMarker> markers({
    required Iterable<SnakeState> snakes,
    required double arenaRadius,
  }) {
    return [
      for (final snake in snakes)
        if (snake.alive)
          _markerForSnake(snake, arenaRadius),
    ];
  }

  static MinimapMarker _markerForSnake(SnakeState snake, double arenaRadius) {
    final position = project(snake.head, arenaRadius);
    return MinimapMarker(
      id: snake.id,
      x: position.x,
      y: position.y,
      colorIndex: snake.colorIndex,
      isPlayer: snake.kind == SnakeKind.player,
    );
  }

  static Vec2 project(Vec2 position, double arenaRadius) {
    if (arenaRadius <= 0) return const Vec2(0.5, 0.5);

    final double x =
        (0.5 + position.x / (arenaRadius * 2)).clamp(0.0, 1.0).toDouble();
    final double y =
        (0.5 + position.y / (arenaRadius * 2)).clamp(0.0, 1.0).toDouble();
    return Vec2(x, y);
  }
}
