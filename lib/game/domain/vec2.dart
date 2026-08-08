import 'dart:math' as math;

class Vec2 {
  const Vec2(this.x, this.y);

  factory Vec2.fromAngle(double angle) =>
      Vec2(math.cos(angle), math.sin(angle));

  final double x;
  final double y;

  static const zero = Vec2(0, 0);

  Vec2 operator +(Vec2 other) => Vec2(x + other.x, y + other.y);
  Vec2 operator -(Vec2 other) => Vec2(x - other.x, y - other.y);
  Vec2 operator *(double scalar) => Vec2(x * scalar, y * scalar);

  double get length => math.sqrt(x * x + y * y);
  double get angle => math.atan2(y, x);

  Vec2 normalized() {
    final magnitude = length;
    return magnitude == 0 ? zero : this * (1 / magnitude);
  }

  double distanceTo(Vec2 other) => (this - other).length;

  Vec2 clampedTo(double maxLength) {
    final magnitude = length;
    return magnitude > maxLength ? normalized() * maxLength : this;
  }

  @override
  bool operator ==(Object other) =>
      other is Vec2 && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}
