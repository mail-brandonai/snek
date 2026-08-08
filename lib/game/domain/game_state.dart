import 'vec2.dart';

enum SnakeKind { player, bot }

enum GameOverReason { boundary, bodyCollision, selfCollision }

class FoodPellet {
  FoodPellet({required this.position, this.value = 1});

  final Vec2 position;
  final int value;
}

class SnakeState {
  SnakeState({
    required this.id,
    required this.kind,
    required Vec2 position,
    required this.colorIndex,
    this.speed = 130,
    this.radius = 10,
    int initialLength = 12,
  })  : heading = const Vec2(1, 0),
        body = List<Vec2>.generate(
          initialLength,
          (index) => position - Vec2(index * 12.0, 0),
        );

  final String id;
  final SnakeKind kind;
  final int colorIndex;
  final double speed;
  final double radius;
  final List<Vec2> body;
  Vec2 heading;
  int growth = 0;
  bool alive = true;

  Vec2 get head => body.first;
  int get length => body.length + growth;

  void grow([int amount = 1]) {
    growth += amount;
  }
}
