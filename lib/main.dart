import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/domain/game_state.dart';
import 'game/domain/minimap.dart';
import 'game/domain/simulation.dart';
import 'game/domain/vec2.dart';

const _snakeColours = <Color>[
  Color(0xffffa72f),
  Color(0xff55d7ff),
  Color(0xffd875ff),
  Color(0xff79e36c),
  Color(0xffff6f91),
  Color(0xfff2d15c),
  Color(0xff8d9eff),
  Color(0xff48d1b5),
  Color(0xffff8a4c),
  Color(0xffc77dff),
];

void main() {
  runApp(const SlitherApp());
}

class SlitherApp extends StatefulWidget {
  const SlitherApp({super.key});

  @override
  State<SlitherApp> createState() => _SlitherAppState();
}

class _SlitherAppState extends State<SlitherApp> {
  late final SlitherGame game;
  late final FocusNode _focusNode;
  bool _pointerButtonHeld = false;

  @override
  void initState() {
    super.initState();
    game = SlitherGame();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    game.hud.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (event.kind == PointerDeviceKind.mouse && (event.buttons & 1) == 0) {
      return;
    }
    _pointerButtonHeld = true;
    _focusNode.requestFocus();
    game.setPointer(event.localPosition);
    game.setPointerSprint(true);
  }

  void _handlePointerMove(PointerMoveEvent event) {
    game.setPointer(event.localPosition);
    // Reassert sprint from the browser's button bitmask. Some platforms emit
    // a transient pointer cancellation while a held mouse is moved across a
    // Flutter/HTML boundary; that cancellation must not end a held sprint.
    if (_pointerButtonHeld &&
        (event.kind != PointerDeviceKind.mouse || (event.buttons & 1) != 0)) {
      game.setPointerSprint(true);
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    _pointerButtonHeld = false;
    game.setPointerSprint(false);
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    // Keep mouse sprint alive through transient cancellation. A subsequent
    // PointerUpEvent remains the authoritative release. Touch cancellation,
    // which has no reliable held-button continuation, should release it.
    if (event.kind != PointerDeviceKind.mouse) {
      _pointerButtonHeld = false;
      game.setPointerSprint(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        backgroundColor: const Color(0xff080d18),
        body: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Focus(
                focusNode: _focusNode,
                autofocus: true,
                onFocusChange: (focused) {
                  if (!focused) game.setKeyboardSprint(false);
                },
                onKeyEvent: (node, event) {
                  if (event.logicalKey == LogicalKeyboardKey.space) {
                    final isPressed =
                        event is KeyDownEvent || event is KeyRepeatEvent;
                    final isReleased = event is KeyUpEvent;
                    if (isPressed || isReleased) {
                      game.setKeyboardSprint(isPressed);
                    }
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: MouseRegion(
                  onHover: (event) => game.setPointer(event.localPosition),
                  child: Listener(
                    onPointerDown: _handlePointerDown,
                    onPointerMove: _handlePointerMove,
                    onPointerUp: _handlePointerUp,
                    onPointerCancel: _handlePointerCancel,
                    child: GameWidget(game: game),
                  ),
                ),
              ),
              ValueListenableBuilder<GameHud>(
                valueListenable: game.hud,
                builder: (context, state, child) => Stack(
                  children: [
                    IgnorePointer(
                      // During play, the HUD must not become a competing
                      // hit-test target while the mouse is being dragged.
                      // It remains interactive after game over for PLAY AGAIN.
                      ignoring: !state.gameOver,
                      child: _Hud(
                        state: state,
                        onRestart: game.restart,
                      ),
                    ),
                    Positioned(
                      top: 62,
                      left: 16,
                      child: _TacticsHudToggle(
                        enabled: state.advancedHudEnabled,
                        onPressed: game.toggleAdvancedHud,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GameHud {
  const GameHud({
    required this.score,
    required this.length,
    required this.rank,
    required this.survivalSeconds,
    required this.sprinting,
    required this.gameOver,
    required this.gameOverReason,
    required this.finalStats,
    required this.leaderboard,
    required this.minimap,
    required this.minimapPings,
    required this.collisionAlertProgress,
    required this.boundaryWarningProgress,
    required this.minimapTelegraphEvents,
    required this.threats,
    required this.advancedHudEnabled,
  });

  final int score;
  final int length;
  final int rank;
  final double survivalSeconds;
  final bool sprinting;
  final bool gameOver;
  final GameOverReason? gameOverReason;
  final RunStats? finalStats;
  final List<LeaderboardEntry> leaderboard;
  final List<MinimapMarker> minimap;
  final List<MinimapPing> minimapPings;
  final double collisionAlertProgress;
  final double boundaryWarningProgress;
  final List<MinimapTelegraphEvent> minimapTelegraphEvents;
  final List<ThreatSignal> threats;
  final bool advancedHudEnabled;
}

class SlitherGame extends FlameGame {
  SlitherGame({SimulationConfig config = const SimulationConfig()})
      : simulation = GameSimulation(config: config),
        hud = ValueNotifier(
          const GameHud(
            score: 0,
            length: 0,
            rank: 1,
            survivalSeconds: 0,
            sprinting: false,
            gameOver: false,
            gameOverReason: null,
            finalStats: null,
            leaderboard: <LeaderboardEntry>[],
            minimap: <MinimapMarker>[],
            minimapPings: <MinimapPing>[],
            collisionAlertProgress: 0,
            boundaryWarningProgress: 0,
            minimapTelegraphEvents: <MinimapTelegraphEvent>[],
            threats: <ThreatSignal>[],
            advancedHudEnabled: false,
          ),
        );

  final GameSimulation simulation;
  final ValueNotifier<GameHud> hud;
  Vec2 steering = const Vec2(1, 0);
  bool _pointerSprint = false;
  bool _keyboardSprint = false;
  bool advancedHudEnabled = false;
  double _hudTimer = 0;

  bool get sprinting =>
      simulation.canSprint && (_pointerSprint || _keyboardSprint);

  void setPointer(Offset point) {
    final centre = Offset(size.x / 2, size.y / 2);
    steering = Vec2(point.dx - centre.dx, point.dy - centre.dy);
  }

  void restart() {
    _pointerSprint = false;
    _keyboardSprint = false;
    simulation.restart();
    _publishHud();
  }

  void setPointerSprint(bool active) {
    _pointerSprint = active;
  }

  void setKeyboardSprint(bool active) {
    _keyboardSprint = active;
  }

  void toggleAdvancedHud() {
    advancedHudEnabled = !advancedHudEnabled;
    _publishHud();
  }

  @override
  void update(double dt) {
    super.update(dt);
    simulation.update(dt, steering, sprinting: sprinting);
    _hudTimer += dt;
    if (_hudTimer >= 0.1) {
      _hudTimer = 0;
      _publishHud();
    }
  }

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);
    canvas.drawColor(const Color(0xff080d18), ui.BlendMode.srcOver);
    if (size.x == 0 || size.y == 0) return;

    canvas.save();
    canvas.translate(
      size.x / 2 - simulation.player.head.x,
      size.y / 2 - simulation.player.head.y,
    );
    _drawArena(canvas);
    _drawPellets(canvas, simulation.pellets, dropped: false);
    _drawPellets(canvas, simulation.droppedMass, dropped: true);
    for (final snake in simulation.snakes.where((item) => item.alive)) {
      _drawSnake(canvas, snake);
    }
    canvas.restore();
  }

  void _publishHud() {
    hud.value = GameHud(
      score: simulation.score,
      length: simulation.player.length,
      rank: simulation.playerRank,
      survivalSeconds: simulation.elapsed,
      sprinting: simulation.player.sprinting,
      gameOver: simulation.gameOver,
      gameOverReason: simulation.gameOverReason,
      finalStats: simulation.finalStats,
      threats: simulation.playerThreats,
      leaderboard: simulation.leaderboard,
      minimap: MinimapModel.markers(
        snakes: simulation.snakes,
        arenaRadius: simulation.config.arenaRadius,
        threats: simulation.playerThreats,
      ),
      minimapPings: MinimapModel.pings(
        collisionPings: simulation.collisionPings,
        arenaRadius: simulation.config.arenaRadius,
      ),
      collisionAlertProgress: simulation.collisionPings.fold<double>(
        0,
        (maximum, ping) => math.max(maximum, ping.progress).toDouble(),
      ),
      boundaryWarningProgress: _boundaryWarningProgress(),
      minimapTelegraphEvents: MinimapModel.events(
        telegraphEvents: simulation.telegraphEvents,
        arenaRadius: simulation.config.arenaRadius,
      ),
      advancedHudEnabled: advancedHudEnabled,
    );
  }

  double _boundaryWarningProgress() {
    final buffer = simulation.config.arenaBoundaryWarningBuffer;
    if (buffer <= 0) return 0;
    final warningRadius = simulation.config.arenaRadius - buffer;
    return ((simulation.player.head.length - warningRadius) / buffer)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  void _drawArena(ui.Canvas canvas) {
    final gridPaint = ui.Paint()
      ..color = const Color(0xff172238)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1;
    const spacing = 92.0;
    final radius = simulation.config.arenaRadius;
    for (var x = -radius; x <= radius; x += spacing) {
      for (var y = -radius; y <= radius; y += spacing) {
        final centre = Offset(
          x + ((y ~/ spacing).isOdd ? spacing / 2 : 0),
          y,
        );
        final path = ui.Path();
        for (var index = 0; index < 6; index++) {
          final angle = index * 3.141592653589793 / 3;
          final point = Offset(
            centre.dx + 44 * math.cos(angle),
            centre.dy + 44 * math.sin(angle),
          );
          if (index == 0) {
            path.moveTo(point.dx, point.dy);
          } else {
            path.lineTo(point.dx, point.dy);
          }
        }
        path.close();
        canvas.drawPath(path, gridPaint);
      }
    }
    final warningRadius = math
        .max(
          0.0,
          radius - simulation.config.arenaBoundaryWarningBuffer,
        )
        .toDouble();
    final warningGlow = ui.Paint()
      ..color = const Color(0xffff9f43).withValues(alpha: 0.08)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 18;
    canvas.drawCircle(Offset.zero, warningRadius, warningGlow);

    final warningPaint = ui.Paint()
      ..color = const Color(0xffffb347).withValues(alpha: 0.72)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset.zero, warningRadius, warningPaint);

    final boundaryGlow = ui.Paint()
      ..color = const Color(0xffff4d5f).withValues(alpha: 0.16)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 16;
    canvas.drawCircle(Offset.zero, radius, boundaryGlow);

    final boundaryPaint = ui.Paint()
      ..color = const Color(0xffff5263)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawCircle(Offset.zero, radius, boundaryPaint);

    final tickPaint = ui.Paint()
      ..color = const Color(0xffff8d78).withValues(alpha: 0.85)
      ..strokeWidth = 3;
    for (var index = 0; index < 48; index++) {
      final angle = index * math.pi / 24;
      final inner = radius - 13;
      final outer = radius + 13;
      canvas.drawLine(
        Offset(math.cos(angle) * inner, math.sin(angle) * inner),
        Offset(math.cos(angle) * outer, math.sin(angle) * outer),
        tickPaint,
      );
    }
  }

  void _drawPellets(
    ui.Canvas canvas,
    List<FoodPellet> items, {
    required bool dropped,
  }) {
    for (final pellet in items) {
      final colour = dropped
          ? _snakeColour(pellet.sourceColorIndex ?? 0)
          : const Color(0xff54e8d1);
      final isDefeatDrop = pellet.kind == FoodPelletKind.defeatDrop;
      final paint = ui.Paint()
        ..color = colour.withValues(alpha: dropped ? 0.95 : 0.8);
      canvas.drawCircle(
        Offset(pellet.position.x, pellet.position.y),
        isDefeatDrop ? 8 : 4,
        paint,
      );
      if (isDefeatDrop) {
        final glow = ui.Paint()..color = colour.withValues(alpha: 0.13);
        canvas.drawCircle(
          Offset(pellet.position.x, pellet.position.y),
          18,
          glow,
        );
      }
    }
  }

  void _drawSnake(ui.Canvas canvas, SnakeState snake) {
    final colour = _snakeColour(snake.colorIndex);
    if (snake.sprintAnticipating || snake.sprinting) {
      final double pulse = (snake.sprinting
              ? snake.sprintPulseRemaining /
                  math.max(simulation.config.sprintPulseDuration, 0.0001)
              : snake.sprintAnticipationRemaining /
                  math.max(
                      simulation.config.sprintAnticipationDuration, 0.0001))
          .toDouble();
      final ringPaint = ui.Paint()
        ..color = colour.withValues(
          alpha: (0.22 + pulse.clamp(0.0, 1.0) * 0.34).toDouble(),
        )
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = snake.sprinting ? 3 : 2;
      canvas.drawCircle(
        Offset(snake.head.x, snake.head.y),
        snake.radius + 8 + (1 - pulse.clamp(0.0, 1.0)) * 8,
        ringPaint,
      );
    }
    if (snake.kind == SnakeKind.player && snake.sprinting) {
      final pulse = (math.sin(simulation.elapsed * 10) + 1) / 2;
      final auraPaint = ui.Paint()
        ..color = const Color(0xffffc766).withValues(
          alpha: 0.12 + pulse * 0.1,
        )
        ..style = ui.PaintingStyle.fill;
      for (final segment in snake.body) {
        canvas.drawCircle(
          Offset(segment.x, segment.y),
          snake.radius * (1.45 + pulse * 0.18),
          auraPaint,
        );
      }
      final auraRing = ui.Paint()
        ..color = const Color(0xffffd166).withValues(
          alpha: 0.45 + pulse * 0.25,
        )
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 1.5 + pulse;
      canvas.drawCircle(
        Offset(snake.head.x, snake.head.y),
        snake.radius * (1.55 + pulse * 0.25),
        auraRing,
      );
    }
    final bodyPaint = ui.Paint()
      ..color = colour
      ..style = ui.PaintingStyle.fill;
    // body[0] is the head position and is rendered separately below. Skipping
    // it here keeps the visible segment count equal to the HUD length instead
    // of making every snake appear one segment longer at spawn.
    for (var index = snake.body.length - 1; index >= 1; index--) {
      final segment = snake.body[index];
      final double taper =
          (1 - index / (snake.body.length * 1.5)).clamp(0.72, 1.0).toDouble();
      canvas.drawCircle(
        Offset(segment.x, segment.y),
        snake.radius * taper,
        bodyPaint,
      );
    }
    final head = snake.head;
    canvas.drawCircle(Offset(head.x, head.y), snake.radius + 2, bodyPaint);
    final eyePaint = ui.Paint()..color = Colors.white;
    final pupilPaint = ui.Paint()..color = const Color(0xff142033);
    final perpendicular = Vec2(-snake.heading.y, snake.heading.x);
    for (final side in [-1.0, 1.0]) {
      final eye = head + snake.heading * 5 + perpendicular * (side * 5);
      canvas.drawCircle(Offset(eye.x, eye.y), 3.5, eyePaint);
      canvas.drawCircle(
        Offset(
          eye.x + snake.heading.x * 1.5,
          eye.y + snake.heading.y * 1.5,
        ),
        1.8,
        pupilPaint,
      );
    }
  }
}

class _Hud extends StatelessWidget {
  const _Hud({required this.state, required this.onRestart});

  final GameHud state;
  final VoidCallback onRestart;

  String get _gameOverTitle {
    switch (state.gameOverReason) {
      case GameOverReason.bodyCollision:
        return 'BODY COLLISION';
      case GameOverReason.boundary:
      case null:
        return 'OUT OF BOUNDS';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (state.boundaryWarningProgress > 0)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _BoundaryWarningPainter(
                  state.boundaryWarningProgress,
                ),
              ),
            ),
          ),
        if (state.collisionAlertProgress > 0)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _CollisionAlertPainter(state.collisionAlertProgress),
              ),
            ),
          ),
        Positioned(
          top: 16,
          right: 16,
          child: _LeaderboardPanel(
            entries: state.leaderboard,
            playerRank: state.rank,
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: _Minimap(
            markers: state.minimap,
            pings: state.minimapPings,
            events: state.minimapTelegraphEvents,
            showTacticalSignals: state.advancedHudEnabled,
          ),
        ),
        if (state.advancedHudEnabled && state.threats.isNotEmpty)
          Positioned(
            left: 16,
            top: 58,
            child: _ThreatPanel(threat: state.threats.first),
          ),
        const Positioned(
          left: 16,
          bottom: 16,
          child: _ControlHint(),
        ),
        Positioned(
          top: 16,
          left: 16,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xcc0b1323),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 9,
              ),
              child: Text(
                'SCORE  ${state.score}   LENGTH  ${state.length}'
                '   RANK  ${state.rank}   TIME  ${_formatDuration(state.survivalSeconds)}'
                '${state.sprinting ? '   SPRINT' : ''}'
                '${state.boundaryWarningProgress > 0.45 ? '   EDGE' : ''}',
                style: const TextStyle(fontSize: 12, letterSpacing: 1.2),
              ),
            ),
          ),
        ),
        if (state.gameOver)
          Center(
            child: Card(
              color: const Color(0xee101b30),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _gameOverTitle,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'The run has ended',
                      style: TextStyle(color: Colors.white60),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Score ${state.score}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Length ${state.finalStats?.length ?? state.length}  ·  '
                      'Time ${_formatDuration(state.finalStats?.survivalSeconds ?? state.survivalSeconds)}  ·  '
                      'Rank ${state.finalStats?.rank ?? state.rank}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: onRestart,
                      child: const Text('PLAY AGAIN'),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TacticsHudToggle extends StatelessWidget {
  const _TacticsHudToggle({
    required this.enabled,
    required this.onPressed,
  });

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: enabled ? const Color(0xffffc766) : Colors.white70,
        backgroundColor: const Color(0xcc0b1323),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        textStyle: const TextStyle(fontSize: 9, letterSpacing: 0.8),
      ),
      icon: Icon(
        enabled ? Icons.visibility : Icons.visibility_off,
        size: 14,
      ),
      label: Text(enabled ? 'TACTICS HUD ON' : 'TACTICS HUD OFF'),
    );
  }
}

String _formatDuration(double seconds) {
  final totalSeconds = seconds.floor();
  final minutes = totalSeconds ~/ 60;
  final remainder = totalSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${remainder.toString().padLeft(2, '0')}';
}

class _LeaderboardPanel extends StatelessWidget {
  const _LeaderboardPanel({required this.entries, required this.playerRank});

  final List<LeaderboardEntry> entries;
  final int playerRank;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xcc0b1323),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'LEADERBOARD',
              style: TextStyle(fontSize: 10, letterSpacing: 1.2),
            ),
            const SizedBox(height: 5),
            for (final entry in entries) _LeaderboardRow(entry: entry),
            if (entries.every((entry) => !entry.isPlayer)) ...[
              const Divider(height: 8, color: Colors.white24),
              Text(
                'YOU  #$playerRank',
                style: const TextStyle(
                  color: Color(0xffffc766),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({required this.entry});

  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        '${entry.rank}. ${entry.isPlayer ? 'YOU' : entry.id.toUpperCase()}  ${entry.length}',
        style: TextStyle(
          color: entry.isPlayer ? const Color(0xffffc766) : Colors.white70,
          fontSize: 10,
          fontWeight: entry.isPlayer ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

class _ControlHint extends StatelessWidget {
  const _ControlHint();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xcc0b1323),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Text(
          'MOVE POINTER / DRAG TO STEER\nCLICK AND HOLD OR SPACE TO SPRINT',
          style: TextStyle(fontSize: 10, letterSpacing: 1.05),
        ),
      ),
    );
  }
}

class _Minimap extends StatelessWidget {
  const _Minimap({
    required this.markers,
    required this.pings,
    required this.events,
    required this.showTacticalSignals,
  });

  final List<MinimapMarker> markers;
  final List<MinimapPing> pings;
  final List<MinimapTelegraphEvent> events;
  final bool showTacticalSignals;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 142,
      height: 142,
      child: CustomPaint(
        painter: _MinimapPainter(
          markers,
          pings,
          events,
          showTacticalSignals,
        ),
      ),
    );
  }
}

class _ThreatPanel extends StatelessWidget {
  const _ThreatPanel({required this.threat});

  final ThreatSignal threat;

  String get _intentLabel {
    switch (threat.intent) {
      case ActorIntent.wandering:
        return 'NEARBY';
      case ActorIntent.pursuing:
        return 'APPROACHING';
      case ActorIntent.contestingFood:
        return 'CONTESTING';
      case ActorIntent.retreating:
        return 'RETREATING';
      case ActorIntent.sprinting:
        return 'SPRINTING';
      case ActorIntent.repositioning:
        return 'REPOSITIONING';
    }
  }

  @override
  Widget build(BuildContext context) {
    final urgency = (threat.urgency * 100).round();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xcc301923),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xffa64655)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        child: Text(
          'THREAT  ${threat.actorId.toUpperCase()}  $_intentLabel\n'
          '${threat.distance.round()}m  URGENCY $urgency%'
          '${threat.sprinting || threat.sprintAnticipating ? '  BURST' : ''}',
          style: const TextStyle(
            color: Color(0xffffc0b8),
            fontSize: 10,
            letterSpacing: 0.9,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}

class _CollisionAlertPainter extends CustomPainter {
  const _CollisionAlertPainter(this.progress);

  final double progress;

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final fade = (1 - progress).clamp(0.0, 1.0).toDouble();
    final shimmer = (math.sin(progress * math.pi * 5) + 1) / 2;
    final alpha = (0.07 + shimmer * 0.08) * fade;
    final borderPaint = ui.Paint()
      ..color = const Color(0xffffd166).withValues(alpha: alpha)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        ui.Rect.fromLTWH(5, 5, size.width - 10, size.height - 10),
        const ui.Radius.circular(16),
      ),
      borderPaint,
    );

    final sweepPaint = ui.Paint()
      ..color = const Color(0xffffd166).withValues(alpha: alpha * 1.5)
      ..strokeWidth = 3;
    final sweepX = size.width * (0.15 + progress * 0.7);
    canvas.drawLine(
      Offset(sweepX - 42, 5),
      Offset(sweepX + 42, 5),
      sweepPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CollisionAlertPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _BoundaryWarningPainter extends CustomPainter {
  const _BoundaryWarningPainter(this.progress);

  final double progress;

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final pulse = (math.sin(progress * math.pi * 8) + 1) / 2;
    final alpha =
        (0.02 + progress * 0.045 + pulse * 0.025).clamp(0.0, 0.13).toDouble();
    final paint = ui.Paint()
      ..color = const Color(0xffff4259).withValues(alpha: alpha)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 10 + progress * 8;
    canvas.drawRect(
      ui.Rect.fromLTWH(5, 5, size.width - 10, size.height - 10),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _BoundaryWarningPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _MinimapPainter extends CustomPainter {
  const _MinimapPainter(
    this.markers,
    this.pings,
    this.events,
    this.showTacticalSignals,
  );

  final List<MinimapMarker> markers;
  final List<MinimapPing> pings;
  final List<MinimapTelegraphEvent> events;
  final bool showTacticalSignals;

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final rect = ui.Rect.fromLTWH(0, 0, size.width, size.height);
    final panelPaint = ui.Paint()..color = const Color(0xcc0b1323);
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(rect, const ui.Radius.circular(12)),
      panelPaint,
    );

    final borderPaint = ui.Paint()
      ..color = const Color(0xff31415f)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        rect.deflate(1),
        const ui.Radius.circular(11),
      ),
      borderPaint,
    );

    final arenaPaint = ui.Paint()
      ..color = const Color(0xffff5263).withValues(alpha: 0.7)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.37,
      arenaPaint,
    );

    for (final ping in pings) {
      final position = Offset(
        ping.x * size.width,
        ping.y * size.height,
      );
      final progress = ping.progress;
      final ring = ui.Paint()
        ..color = const Color(0xffffd166).withValues(
          alpha: 0.9 * (1 - progress),
        )
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(position, 5 + progress * 17, ring);
      final centre = ui.Paint()
        ..color = const Color(0xffffd166).withValues(
          alpha: 0.75 * (1 - progress),
        );
      canvas.drawCircle(position, 2, centre);
    }

    if (showTacticalSignals) {
      for (final event in events) {
        final position = Offset(event.x * size.width, event.y * size.height);
        final colour = event.kind == TelegraphEventKind.sprintStarted
            ? const Color(0xffffa72f)
            : const Color(0xff55d7ff);
        final ring = ui.Paint()
          ..color = colour.withValues(alpha: 0.55 * (1 - event.progress))
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 1.2;
        canvas.drawCircle(position, 4 + event.progress * 12, ring);
      }
    }

    for (final marker in markers) {
      final position = Offset(
        marker.x * size.width,
        marker.y * size.height,
      );
      final colour = _snakeColour(marker.colorIndex);
      final paint = ui.Paint()..color = colour;
      canvas.drawCircle(position, marker.isPlayer ? 5 : 3, paint);
      if (marker.sprintAnticipating || marker.sprinting) {
        final ring = ui.Paint()
          ..color = colour.withValues(
            alpha: marker.sprinting ? 0.8 : 0.45,
          )
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = marker.sprinting ? 2 : 1;
        canvas.drawCircle(position, marker.isPlayer ? 10 : 7, ring);
      }
      if (showTacticalSignals && marker.intent == ActorIntent.retreating) {
        final retreatPaint = ui.Paint()
          ..color = colour.withValues(alpha: 0.65)
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 1;
        canvas.drawCircle(position, marker.isPlayer ? 12 : 6, retreatPaint);
      }
      if (showTacticalSignals && marker.threatUrgency > 0) {
        final threatPaint = ui.Paint()
          ..color = const Color(0xffff5f56).withValues(
            alpha: 0.35 + marker.threatUrgency * 0.55,
          )
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawCircle(
          position,
          (marker.isPlayer ? 12 : 7) + marker.threatUrgency * 7,
          threatPaint,
        );
      }
      if (marker.isPlayer) {
        final ring = ui.Paint()
          ..color = colour.withValues(alpha: 0.35)
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 1;
        canvas.drawCircle(position, 9, ring);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MinimapPainter oldDelegate) =>
      oldDelegate.markers != markers ||
      oldDelegate.pings != pings ||
      oldDelegate.events != events ||
      oldDelegate.showTacticalSignals != showTacticalSignals;
}

Color _snakeColour(int colorIndex) =>
    _snakeColours[colorIndex.abs() % _snakeColours.length];
