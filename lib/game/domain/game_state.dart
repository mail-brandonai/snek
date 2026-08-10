import 'vec2.dart';

enum SnakeKind { player, bot }

enum GameOverReason { boundary, bodyCollision }

enum FoodPelletKind { natural, sprintDrop, defeatDrop }

enum BotDisposition { defensive, aggressive, opportunistic, wanderer }

enum ActorIntent {
  wandering,
  pursuing,
  contestingFood,
  retreating,
  sprinting,
  repositioning,
}

enum TelegraphEventKind {
  sprintAnticipation,
  sprintStarted,
  sprintEnded,
}

class FoodPellet {
  const FoodPellet({
    required this.position,
    this.value = 1,
    this.kind = FoodPelletKind.natural,
    this.sourceColorIndex,
  });

  final Vec2 position;
  final int value;
  final FoodPelletKind kind;
  final int? sourceColorIndex;
}

class CollisionPing {
  CollisionPing({required this.position, required this.durationSeconds})
      : remainingSeconds = durationSeconds;

  final Vec2 position;
  final double durationSeconds;
  double remainingSeconds;

  double get progress =>
      (1 - remainingSeconds / durationSeconds).clamp(0.0, 1.0).toDouble();
}

class TelegraphEvent {
  TelegraphEvent({
    required this.actorId,
    required this.kind,
    required this.position,
    required this.heading,
    required this.durationSeconds,
  }) : remainingSeconds = durationSeconds;

  final String actorId;
  final TelegraphEventKind kind;
  final Vec2 position;
  final Vec2 heading;
  final double durationSeconds;
  double remainingSeconds;

  double get progress =>
      (1 - remainingSeconds / durationSeconds).clamp(0.0, 1.0).toDouble();
}

class ActorTelegraph {
  const ActorTelegraph({
    required this.actorId,
    required this.position,
    required this.heading,
    required this.length,
    required this.speed,
    required this.intent,
    required this.sprintAnticipating,
    required this.sprinting,
    required this.movementCommitment,
  });

  final String actorId;
  final Vec2 position;
  final Vec2 heading;
  final int length;
  final double speed;
  final ActorIntent intent;
  final bool sprintAnticipating;
  final bool sprinting;
  final double movementCommitment;
}

class ThreatSignal {
  const ThreatSignal({
    required this.actorId,
    required this.direction,
    required this.distance,
    required this.urgency,
    required this.actorLength,
    required this.playerLength,
    required this.projectedPath,
    required this.intent,
    required this.sprintAnticipating,
    required this.sprinting,
  });

  final String actorId;
  final Vec2 direction;
  final double distance;
  final double urgency;
  final int actorLength;
  final int playerLength;
  final bool projectedPath;
  final ActorIntent intent;
  final bool sprintAnticipating;
  final bool sprinting;
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
    this.disposition = BotDisposition.opportunistic,
    this.speed = 130,
    this.radius = 10,
    this.segmentSpacing = 12,
    int initialLength = 12,
  })  : heading = const Vec2(1, 0),
        spawnLength = initialLength,
        _logicalLength = initialLength,
        body = List<Vec2>.generate(
          initialLength,
          (index) => position - Vec2(index * segmentSpacing, 0),
        ) {
    movementTrail.addAll(body.reversed);
  }

  final String id;
  final SnakeKind kind;
  final int colorIndex;
  final BotDisposition disposition;
  final double speed;
  final double radius;
  final double segmentSpacing;
  final int spawnLength;
  final List<Vec2> body;
  final List<Vec2> movementTrail = [];
  Vec2 heading;
  int _logicalLength;
  double _growthExpressionRemaining = 0;
  double sprintDrainAccumulator = 0;
  double botSprintCooldownRemaining = 0;
  double botSprintRemaining = 0;
  double sprintAnticipationRemaining = 0;
  double sprintPulseRemaining = 0;
  double tacticalSpeedMultiplier = 1;
  double tacticalTurnRateMultiplier = 1;
  double movementCommitment = 0;
  double headingChange = 0;
  bool sprintRequested = false;
  bool sprinting = false;
  bool retreating = false;
  ActorIntent publicIntent = ActorIntent.wandering;
  bool alive = true;

  Vec2 get head => body.first;

  /// Logical length used for score, rank, bot scaling, and sprint eligibility.
  ///
  /// This can be ahead of the visible body while newly acquired length is
  /// being expressed through movement.
  int get length => _logicalLength;

  /// Number of newly acquired segments that have not been fully expressed.
  int get pendingGrowthSegments {
    if (_growthExpressionRemaining <= 0) return 0;
    return (_growthExpressionRemaining / segmentSpacing).ceil();
  }

  /// Number of full segments currently represented by the visible path.
  int get fullyExpressedLength => _logicalLength - pendingGrowthSegments;

  /// Distance of the fractional terminal extension beyond the last full
  /// segment. This is always smaller than one segment spacing.
  double get growthExtensionDistance {
    final extension =
        pendingGrowthSegments * segmentSpacing - _growthExpressionRemaining;
    return extension.clamp(0.0, segmentSpacing).toDouble();
  }

  /// Distance still required before newly acquired length is fully expressed.
  ///
  /// During this transition the existing body keeps its normal spacing while
  /// only a fractional terminal tail segment is extended. The expression rate
  /// is controlled by the simulation so the tail is not moved backward by the
  /// full amount in a single frame.
  double get growthExpressionRemaining => _growthExpressionRemaining;

  void expressGrowth(double distance) {
    if (distance <= 0 || _growthExpressionRemaining <= 0) return;
    _growthExpressionRemaining = (_growthExpressionRemaining - distance)
        .clamp(0.0, double.infinity)
        .toDouble();
  }

  void grow([int amount = 1]) {
    if (amount <= 0 || body.isEmpty) return;

    _logicalLength += amount;
    _growthExpressionRemaining += amount * segmentSpacing;
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
      ..addAll(body.reversed);
    heading = const Vec2(1, 0);
    _logicalLength = spawnLength;
    _growthExpressionRemaining = 0;
    sprintDrainAccumulator = 0;
    botSprintCooldownRemaining = 0;
    botSprintRemaining = 0;
    sprintAnticipationRemaining = 0;
    sprintPulseRemaining = 0;
    tacticalSpeedMultiplier = 1;
    tacticalTurnRateMultiplier = 1;
    movementCommitment = 0;
    headingChange = 0;
    sprintRequested = false;
    sprinting = false;
    retreating = false;
    publicIntent = ActorIntent.wandering;
    alive = true;
  }

  bool get sprintAnticipating => sprintAnticipationRemaining > 0;

  Vec2? shedMass({required int minimumLength}) {
    if (length <= minimumLength) return null;

    final position = body.last;
    _logicalLength -= 1;
    if (_growthExpressionRemaining > 0) {
      _growthExpressionRemaining = (_growthExpressionRemaining - segmentSpacing)
          .clamp(0.0, double.infinity)
          .toDouble();
      if (body.length == _logicalLength + 1 && body.length > 1) {
        body.removeLast();
      }
    } else if (body.length > 1) {
      body.removeLast();
    }
    return position;
  }
}
