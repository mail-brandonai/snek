import 'vec2.dart';

enum SnakeKind { player, bot }

enum GameOverReason { boundary, bodyCollision }

class FoodPellet {
  FoodPellet({required this.position, this.value = 1});

  final Vec2 position;
  final int value;
}

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.id,
    required this.kind,
    required this.colorIndex,
    required this.length,
    required this.rank,
  });

  final String id;
  final SnakeKind kind;
  final int colorIndex;
  final int length;
  final int rank;

  bool get isPlayer => kind == SnakeKind.player;
}

class RunStats {
  const RunStats({
    required this.score,
    required this.length,
    required this.survivalSeconds,
    required this.rank,
  });

  final int score;
  final int length;
  final double survivalSeconds;
  final int rank;
}

class SnakeState {
  SnakeState({
    required this.id,
    required this.kind,
    required Vec2 position,
    required this.colorIndex,
    this.speed = 130,
    this.radius = 10,
    this.segmentSpacing = 12,
    int initialLength = 12,
  })  : heading = const Vec2(1, 0),
        spawnLength = initialLength,
        body = List<Vec2>.generate(
          initialLength,
          (index) => position - Vec2(index * segmentSpacing, 0),
        ) {
    movementTrail.addAll(body);
  }

  final String id;
  final SnakeKind kind;
  final int colorIndex;
  final double speed;
  final double radius;
  final double segmentSpacing;
  final int spawnLength;
  final List<Vec2> body;
  final List<Vec2> movementTrail = [];
  Vec2 heading;
  int growth = 0;
  double sprintDrainAccumulator = 0;
  bool sprinting = false;
  bool alive = true;

  Vec2 get head => body.first;
  int get length => body.length + growth;

  void grow([int amount = 1]) {
    growth += amount;
  }

  void resetAt(Vec2 position) {
    body
      ..clear()
      ..addAll(
        List<Vec2>.generate(
          spawnLength,
          (index) => position - Vec2(index * segmentSpacing, 0),
        ),
      );
    movementTrail
      ..clear()
      ..addAll(body);
    heading = const Vec2(1, 0);
    growth = 0;
    sprintDrainAccumulator = 0;
    sprinting = false;
    alive = true;
  }

  Vec2? shedMass({required int minimumLength}) {
    if (length <= minimumLength) return null;

    final position = body.last;
    if (growth > 0) {
      growth--;
      return position;
    }
    if (body.length <= minimumLength) return null;
    return body.removeLast();
  }
}
