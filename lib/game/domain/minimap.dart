import 'game_state.dart';
import 'vec2.dart';

class MinimapMarker {
  const MinimapMarker({
    required this.id,
    required this.x,
    required this.y,
    required this.colorIndex,
    required this.isPlayer,
    required this.intent,
    required this.sprintAnticipating,
    required this.sprinting,
    required this.threatUrgency,
  });

  final String id;
  final double x;
  final double y;
  final int colorIndex;
  final bool isPlayer;
  final ActorIntent intent;
  final bool sprintAnticipating;
  final bool sprinting;
  final double threatUrgency;
}

class MinimapPing {
  const MinimapPing({
    required this.x,
    required this.y,
    required this.progress,
  });

  final double x;
  final double y;
  final double progress;
}

class MinimapTelegraphEvent {
  const MinimapTelegraphEvent({
    required this.x,
    required this.y,
    required this.progress,
    required this.kind,
  });

  final double x;
  final double y;
  final double progress;
  final TelegraphEventKind kind;
}

class MinimapModel {
  const MinimapModel._();

  static List<MinimapMarker> markers({
    required Iterable<SnakeState> snakes,
    required double arenaRadius,
    Iterable<ThreatSignal> threats = const [],
  }) {
    final threatByActor = {
      for (final threat in threats) threat.actorId: threat.urgency,
    };
    return [
      for (final snake in snakes)
        if (snake.alive)
          _markerForSnake(
            snake,
            arenaRadius,
            threatUrgency: threatByActor[snake.id] ?? 0,
          ),
    ];
  }

  static List<MinimapPing> pings({
    required Iterable<CollisionPing> collisionPings,
    required double arenaRadius,
  }) {
    return [
      for (final ping in collisionPings)
        MinimapPing(
          x: project(ping.position, arenaRadius).x,
          y: project(ping.position, arenaRadius).y,
          progress: ping.progress,
        ),
    ];
  }

  static List<MinimapTelegraphEvent> events({
    required Iterable<TelegraphEvent> telegraphEvents,
    required double arenaRadius,
  }) {
    return [
      for (final event in telegraphEvents)
        MinimapTelegraphEvent(
          x: project(event.position, arenaRadius).x,
          y: project(event.position, arenaRadius).y,
          progress: event.progress,
          kind: event.kind,
        ),
    ];
  }

  static MinimapMarker _markerForSnake(
    SnakeState snake,
    double arenaRadius, {
    required double threatUrgency,
  }) {
    final position = project(snake.head, arenaRadius);
    return MinimapMarker(
      id: snake.id,
      x: position.x,
      y: position.y,
      colorIndex: snake.colorIndex,
      isPlayer: snake.kind == SnakeKind.player,
      intent: snake.publicIntent,
      sprintAnticipating: snake.sprintAnticipating,
      sprinting: snake.sprinting,
      threatUrgency: threatUrgency,
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
