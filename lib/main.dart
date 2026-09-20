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
import 'game/presentation/arena_skin.dart';

const _snakeColours = ArenaSkin.snakeColours;

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
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: ArenaSkin.accent,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: ArenaSkin.background,
      ),
      home: Scaffold(
        backgroundColor: ArenaSkin.background,
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
    required this.tacticalDiagnostics,
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
  final String tacticalDiagnostics;
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
            tacticalDiagnostics: '',
            advancedHudEnabled: false,
          ),
        );

  final GameSimulation simulation;
  final ValueNotifier<GameHud> hud;
  final ui.Paint _gridPaint = ui.Paint()
    ..color = ArenaSkin.tileLine
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 1.2;
  final ui.Paint _gridFacePaint = ui.Paint()..color = ArenaSkin.tileFace;
  final ui.Paint _gridLightEdgePaint = ui.Paint()
    ..color = ArenaSkin.tileHighlight.withValues(alpha: 0.72)
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 1.4;
  final ui.Paint _gridShadeEdgePaint = ui.Paint()
    ..color = ArenaSkin.tileShade.withValues(alpha: 0.92)
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 1.8;
  final ui.Paint _naturalPelletPaint = ArenaSkin.naturalPelletPaint;
  final List<ui.Paint> _droppedPelletPaints = ArenaSkin.droppedPelletPaints;
  final List<ui.Paint> _droppedGlowPaints = List<ui.Paint>.generate(
    _snakeColours.length,
    (index) => ui.Paint()..color = _snakeColours[index].withValues(alpha: 0.13),
  );
  final List<ui.Paint> _snakeBodyPaints = ArenaSkin.snakeBodyPaints;
  final ui.Paint _effectPaint = ui.Paint();
  final ui.Paint _eyePaint = ui.Paint()..color = const Color(0xfff7fbff);
  final ui.Paint _pupilPaint = ui.Paint()..color = const Color(0xff07111d);
  final ui.Paint _eyeGlintPaint = ui.Paint()
    ..color = const Color(0xffffffff).withValues(alpha: 0.92);
  final ui.Path _visibleGridPath = ui.Path();
  final ui.Path _visibleGridFacePath = ui.Path();
  final ui.Path _visibleGridLightEdgePath = ui.Path();
  final ui.Path _visibleGridShadeEdgePath = ui.Path();
  int _gridStartColumn = -1;
  int _gridEndColumn = -1;
  int _gridStartRow = -1;
  int _gridEndRow = -1;
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
    canvas.drawColor(ArenaSkin.background, ui.BlendMode.srcOver);
    if (size.x == 0 || size.y == 0) return;

    canvas.save();
    canvas.translate(
      size.x / 2 - simulation.player.head.x,
      size.y / 2 - simulation.player.head.y,
    );
    _drawArena(canvas);
    _drawPellets(canvas, simulation.pellets, dropped: false);
    _drawPellets(canvas, simulation.droppedMass, dropped: true);
    for (final snake in simulation.snakes) {
      if (snake.alive) _drawSnake(canvas, snake);
    }
    canvas.restore();
  }

  void _publishHud() {
    final threats = simulation.playerThreats;
    hud.value = GameHud(
      score: simulation.score,
      length: simulation.player.length,
      rank: simulation.playerRank,
      survivalSeconds: simulation.elapsed,
      sprinting: simulation.player.sprinting,
      gameOver: simulation.gameOver,
      gameOverReason: simulation.gameOverReason,
      finalStats: simulation.finalStats,
      threats: threats,
      leaderboard: simulation.leaderboard,
      minimap: MinimapModel.markers(
        snakes: simulation.snakes,
        arenaRadius: simulation.config.arenaRadius,
        threats: threats,
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
      tacticalDiagnostics: simulation.tacticalDiagnostics,
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
    const spacing = 92.0;
    final radius = simulation.config.arenaRadius;
    final camera = simulation.player.head;
    final minimumX = camera.x - size.x / 2 - spacing;
    final maximumX = camera.x + size.x / 2 + spacing;
    final minimumY = camera.y - size.y / 2 - spacing;
    final maximumY = camera.y + size.y / 2 + spacing;
    final maximumGridIndex = (radius * 2 / spacing).floor();
    final startColumn = ((minimumX + radius) / spacing)
        .floor()
        .clamp(0, maximumGridIndex)
        .toInt();
    final endColumn = ((maximumX + radius) / spacing)
        .ceil()
        .clamp(0, maximumGridIndex)
        .toInt();
    final startRow = ((minimumY + radius) / spacing)
        .floor()
        .clamp(0, maximumGridIndex)
        .toInt();
    final endRow = ((maximumY + radius) / spacing)
        .ceil()
        .clamp(0, maximumGridIndex)
        .toInt();
    if (startColumn != _gridStartColumn ||
        endColumn != _gridEndColumn ||
        startRow != _gridStartRow ||
        endRow != _gridEndRow) {
      _gridStartColumn = startColumn;
      _gridEndColumn = endColumn;
      _gridStartRow = startRow;
      _gridEndRow = endRow;
      _visibleGridPath.reset();
      _visibleGridFacePath.reset();
      _visibleGridLightEdgePath.reset();
      _visibleGridShadeEdgePath.reset();
      for (var column = startColumn; column <= endColumn; column++) {
        final x = -radius + column * spacing;
        for (var row = startRow; row <= endRow; row++) {
          final y = -radius + row * spacing;
          final centre = Offset(
            x + ((y ~/ spacing).isOdd ? spacing / 2 : 0),
            y,
          );
          final vertices = <Offset>[];
          for (var index = 0; index < 6; index++) {
            final angle = index * 3.141592653589793 / 3;
            final point = Offset(
              centre.dx + 44 * math.cos(angle),
              centre.dy + 44 * math.sin(angle),
            );
            vertices.add(point);
            if (index == 0) {
              _visibleGridPath.moveTo(point.dx, point.dy);
              _visibleGridFacePath.moveTo(point.dx, point.dy);
            } else {
              _visibleGridPath.lineTo(point.dx, point.dy);
              _visibleGridFacePath.lineTo(point.dx, point.dy);
            }
          }
          _visibleGridPath.close();
          _visibleGridFacePath.close();

          for (var index = 0; index < 6; index++) {
            final start = vertices[index];
            final end = vertices[(index + 1) % 6];
            if (index == 3 || index == 4) {
              _visibleGridLightEdgePath
                ..moveTo(start.dx, start.dy)
                ..lineTo(end.dx, end.dy);
            }
            if (index == 0 || index == 1) {
              _visibleGridShadeEdgePath
                ..moveTo(start.dx, start.dy)
                ..lineTo(end.dx, end.dy);
            }
          }
        }
      }
    }

    canvas.drawPath(_visibleGridFacePath, _gridFacePaint);
    canvas.drawPath(_visibleGridPath, _gridPaint);
    canvas.drawPath(_visibleGridLightEdgePath, _gridLightEdgePaint);
    canvas.drawPath(_visibleGridShadeEdgePath, _gridShadeEdgePaint);

    final viewportRadius = math.sqrt(size.x * size.x + size.y * size.y) / 2;
    final warningRadius = math
        .max(
          0.0,
          radius - simulation.config.arenaBoundaryWarningBuffer,
        )
        .toDouble();
    if ((camera.length - warningRadius).abs() <= viewportRadius + 24) {
      _effectPaint
        ..color = const Color(0xffff9f43).withValues(alpha: 0.08)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 18;
      canvas.drawCircle(Offset.zero, warningRadius, _effectPaint);
      _effectPaint
        ..color = const Color(0xffffb347).withValues(alpha: 0.72)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(Offset.zero, warningRadius, _effectPaint);
    }

    if ((camera.length - radius).abs() <= viewportRadius + 28) {
      _effectPaint
        ..color = const Color(0xffff4d5f).withValues(alpha: 0.16)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 16;
      canvas.drawCircle(Offset.zero, radius, _effectPaint);
      _effectPaint
        ..color = const Color(0xffff5263)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 5;
      canvas.drawCircle(Offset.zero, radius, _effectPaint);
      _effectPaint
        ..color = const Color(0xffff8d78).withValues(alpha: 0.85)
        ..style = ui.PaintingStyle.fill
        ..strokeWidth = 3;
      for (var index = 0; index < 48; index++) {
        final angle = index * math.pi / 24;
        final inner = radius - 13;
        final outer = radius + 13;
        canvas.drawLine(
          Offset(math.cos(angle) * inner, math.sin(angle) * inner),
          Offset(math.cos(angle) * outer, math.sin(angle) * outer),
          _effectPaint,
        );
      }
    }
  }

  void _drawPellets(
    ui.Canvas canvas,
    List<FoodPellet> items, {
    required bool dropped,
  }) {
    for (final pellet in items) {
      if (!_isVisible(pellet.position, dropped ? 28 : 12)) continue;
      final isDefeatDrop = pellet.kind == FoodPelletKind.defeatDrop;
      final colourIndex =
          (pellet.sourceColorIndex ?? 0).abs() % _snakeColours.length;
      final paint =
          dropped ? _droppedPelletPaints[colourIndex] : _naturalPelletPaint;
      _drawShadedCircle(
        canvas,
        Offset(pellet.position.x, pellet.position.y),
        isDefeatDrop ? 8 : 4,
        paint,
      );
      if (isDefeatDrop) {
        canvas.drawCircle(
          Offset(pellet.position.x, pellet.position.y),
          18,
          _droppedGlowPaints[colourIndex],
        );
      }
    }
  }

  void _drawSnake(ui.Canvas canvas, SnakeState snake) {
    if (snake.body.isEmpty) return;
    final renderStride = snake.body.length > 420 ? 2 : 1;
    final minimumTaper =
        simulation.config.collisionTailTaper.clamp(0.0, 1.0).toDouble();
    final viewMinimumX = simulation.player.head.x - size.x / 2;
    final viewMaximumX = simulation.player.head.x + size.x / 2;
    final viewMinimumY = simulation.player.head.y - size.y / 2;
    final viewMaximumY = simulation.player.head.y + size.y / 2;
    final padding = snake.radius + 12;
    var hasVisibleChunk = false;
    for (final chunk in snake.bodyChunks) {
      if (chunk.intersects(
        minimumX: viewMinimumX - padding,
        maximumX: viewMaximumX + padding,
        minimumY: viewMinimumY - padding,
        maximumY: viewMaximumY + padding,
      )) {
        hasVisibleChunk = true;
        break;
      }
    }
    if (!hasVisibleChunk) return;
    final colourIndex = snake.colorIndex.abs() % _snakeColours.length;
    final colour = _snakeColours[colourIndex];
    if (snake.sprintAnticipating || snake.sprinting) {
      final double pulse = (snake.sprinting
              ? snake.sprintPulseRemaining /
                  math.max(simulation.config.sprintPulseDuration, 0.0001)
              : snake.sprintAnticipationRemaining /
                  math.max(
                      simulation.config.sprintAnticipationDuration, 0.0001))
          .toDouble();
      _effectPaint
        ..color = colour.withValues(
          alpha: (0.22 + pulse.clamp(0.0, 1.0) * 0.34).toDouble(),
        )
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = snake.sprinting ? 3 : 2;
      if (_isVisible(snake.head, snake.radius + 20)) {
        canvas.drawCircle(
          Offset(snake.head.x, snake.head.y),
          snake.radius + 8 + (1 - pulse.clamp(0.0, 1.0)) * 8,
          _effectPaint,
        );
      }
    }
    if (snake.kind == SnakeKind.player && snake.sprinting) {
      final pulse = (math.sin(simulation.elapsed * 10) + 1) / 2;
      _effectPaint
        ..color = const Color(0xffffc766).withValues(
          alpha: 0.12 + pulse * 0.1,
        )
        ..style = ui.PaintingStyle.fill;
      final auraStride = snake.body.length > 420 ? 2 : 1;
      for (final chunk in snake.bodyChunks) {
        if (!chunk.intersects(
          minimumX: viewMinimumX - padding,
          maximumX: viewMaximumX + padding,
          minimumY: viewMinimumY - padding,
          maximumY: viewMaximumY + padding,
        )) {
          continue;
        }
        var index = chunk.startIndex;
        final strideOffset = index % auraStride;
        if (strideOffset != 0) index += auraStride - strideOffset;
        final end = math.min(chunk.endIndex, snake.body.length);
        for (; index < end; index += auraStride) {
          final segment = snake.body[index];
          if (!_isVisible(segment, padding)) continue;
          canvas.drawCircle(
            Offset(segment.x, segment.y),
            snake.radius * (1.45 + pulse * 0.18),
            _effectPaint,
          );
        }
      }
      _effectPaint
        ..color = const Color(0xffffd166).withValues(
          alpha: 0.45 + pulse * 0.25,
        )
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 1.5 + pulse;
      if (_isVisible(snake.head, snake.radius + 20)) {
        canvas.drawCircle(
          Offset(snake.head.x, snake.head.y),
          snake.radius * (1.55 + pulse * 0.25),
          _effectPaint,
        );
      }
    }
    final bodyPaint = _snakeBodyPaints[colourIndex];
    // body[0] is the head position and is rendered separately below. Skipping
    // it here keeps the visible segment count equal to the HUD length instead
    // of making every snake appear one segment longer at spawn.
    for (var chunkIndex = snake.bodyChunks.length - 1;
        chunkIndex >= 0;
        chunkIndex--) {
      final chunk = snake.bodyChunks[chunkIndex];
      if (!chunk.intersects(
        minimumX: viewMinimumX - padding,
        maximumX: viewMaximumX + padding,
        minimumY: viewMinimumY - padding,
        maximumY: viewMaximumY + padding,
      )) {
        continue;
      }
      var index = math.min(chunk.endIndex, snake.body.length).toInt() - 1;
      final tailStrideOffset = (snake.body.length - 1 - index) % renderStride;
      if (tailStrideOffset != 0) index -= renderStride - tailStrideOffset;
      for (; index >= math.max(1, chunk.startIndex); index -= renderStride) {
        final segment = snake.body[index];
        if (!_isVisible(segment, padding)) continue;
        final double taper = (1 - index / (snake.body.length * 1.5))
            .clamp(minimumTaper, 1.0)
            .toDouble();
        _drawShadedCircle(
          canvas,
          Offset(segment.x, segment.y),
          snake.radius * taper * (renderStride == 1 ? 1 : 1.22),
          bodyPaint,
        );
      }
    }
    final head = snake.head;
    if (!_isVisible(head, snake.radius + 12)) return;
    _drawShadedCircle(
      canvas,
      Offset(head.x, head.y),
      snake.radius + 2,
      bodyPaint,
    );
    final perpendicular = Vec2(-snake.heading.y, snake.heading.x);
    for (final side in const [-1.0, 1.0]) {
      final eye = head + snake.heading * 5 + perpendicular * (side * 5);
      canvas.drawCircle(Offset(eye.x, eye.y), 3.8, _eyePaint);
      canvas.drawCircle(
        Offset(
          eye.x + snake.heading.x * 1.5,
          eye.y + snake.heading.y * 1.5,
        ),
        1.9,
        _pupilPaint,
      );
      canvas.drawCircle(
        Offset(eye.x - 0.9, eye.y - 1.1),
        0.8,
        _eyeGlintPaint,
      );
    }
  }

  void _drawShadedCircle(
    ui.Canvas canvas,
    Offset centre,
    double radius,
    ui.Paint paint,
  ) {
    canvas
      ..save()
      ..translate(centre.dx, centre.dy)
      ..scale(radius);
    canvas.drawCircle(Offset.zero, 1, paint);
    canvas.restore();
  }

  bool _isVisible(Vec2 position, double padding) {
    final centre = simulation.player.head;
    return (position.x - centre.x).abs() <= size.x / 2 + padding &&
        (position.y - centre.y).abs() <= size.y / 2 + padding;
  }
}

class _HudMetric extends StatelessWidget {
  const _HudMetric({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: ArenaSkin.textMuted,
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: accent,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _HudStatusBadge extends StatelessWidget {
  const _HudStatusBadge({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: accent.withValues(alpha: 0.48)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        child: Text(
          label,
          style: TextStyle(
            color: accent,
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.9,
          ),
        ),
      ),
    );
  }
}

class _StatsPanel extends StatelessWidget {
  const _StatsPanel({required this.state});

  final GameHud state;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: ArenaSkin.glassPanel(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 11,
          runSpacing: 5,
          children: [
            _HudMetric(
              label: 'SCORE',
              value: state.score.toString(),
              accent: ArenaSkin.accent,
            ),
            _HudMetric(
              label: 'LENGTH',
              value: state.length.toString(),
              accent: const Color(0xff72e5f2),
            ),
            _HudMetric(
              label: 'RANK',
              value: '#' + state.rank.toString(),
              accent: const Color(0xffc9d8ef),
            ),
            _HudMetric(
              label: 'TIME',
              value: _formatDuration(state.survivalSeconds),
              accent: const Color(0xffc9d8ef),
            ),
            if (state.sprinting)
              const _HudStatusBadge(
                label: 'SPRINT',
                accent: ArenaSkin.accent,
              ),
            if (state.boundaryWarningProgress > 0.45)
              const _HudStatusBadge(
                label: 'EDGE',
                accent: ArenaSkin.danger,
              ),
          ],
        ),
      ),
    );
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
    final compact = MediaQuery.sizeOf(context).width < 420;
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
          top: compact ? 92 : 16,
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
            dimension: compact ? 112 : 142,
            markers: state.minimap,
            pings: state.minimapPings,
            events: state.minimapTelegraphEvents,
            showTacticalSignals: state.advancedHudEnabled,
          ),
        ),
        if (state.advancedHudEnabled && state.threats.isNotEmpty)
          Positioned(
            left: 16,
            top: compact ? 156 : 58,
            child: _ThreatPanel(threat: state.threats.first),
          ),
        if (state.advancedHudEnabled && state.tacticalDiagnostics.isNotEmpty)
          Positioned(
            left: 16,
            bottom: 74,
            child: _TacticalDiagnosticsPanel(
              diagnostics: state.tacticalDiagnostics,
            ),
          ),
        const Positioned(
          left: 16,
          bottom: 16,
          child: _ControlHint(),
        ),
        Positioned(
          top: 16,
          left: 16,
          child: _StatsPanel(state: state),
        ),
        if (state.gameOver)
          Center(
            child: DecoratedBox(
              decoration: ArenaSkin.glassPanel(
                borderColor: const Color(0xff7191b1),
                radius: 18,
              ),
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
        foregroundColor:
            enabled ? ArenaSkin.accent : ArenaSkin.textPrimary,
        backgroundColor: ArenaSkin.panelBottom,
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        textStyle: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9),
          side: const BorderSide(color: ArenaSkin.panelRim),
        ),
        elevation: enabled ? 4 : 1,
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
      decoration: ArenaSkin.glassPanel(),
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
      decoration: ArenaSkin.glassPanel(),
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
    required this.dimension,
    required this.markers,
    required this.pings,
    required this.events,
    required this.showTacticalSignals,
  });

  final double dimension;
  final List<MinimapMarker> markers;
  final List<MinimapPing> pings;
  final List<MinimapTelegraphEvent> events;
  final bool showTacticalSignals;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: dimension,
      height: dimension,
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

class _TacticalDiagnosticsPanel extends StatelessWidget {
  const _TacticalDiagnosticsPanel({required this.diagnostics});

  final String diagnostics;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: ArenaSkin.glassPanel(
        borderColor: const Color(0xff5d83a3),
        radius: 10,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        child: Text(
          diagnostics,
          style: const TextStyle(
            color: Color(0xffbcd7ef),
            fontSize: 9,
            letterSpacing: 0.8,
          ),
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
      decoration: ArenaSkin.glassPanel(
        borderColor: const Color(0xffc35d6d),
        radius: 10,
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
    final panelRect = ui.RRect.fromRectAndRadius(
      rect,
      const ui.Radius.circular(12),
    );
    final panelPath = ui.Path()..addRRect(panelRect);
    canvas.drawShadow(
      panelPath,
      const Color(0xc0000000),
      7,
      true,
    );
    final panelPaint = ui.Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(size.width, size.height),
        const <Color>[ArenaSkin.panelTop, ArenaSkin.panelBottom],
        null,
        ui.TileMode.clamp,
      );
    canvas.drawRRect(panelRect, panelPaint);

    final borderPaint = ui.Paint()
      ..color = ArenaSkin.panelRim
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        rect.deflate(1),
        const ui.Radius.circular(11),
      ),
      borderPaint,
    );

    final arenaCentre = Offset(size.width / 2, size.height / 2);
    final arenaRadius = size.width * 0.37;
    final arenaFillPaint = ui.Paint()
      ..shader = ui.Gradient.radial(
        arenaCentre,
        arenaRadius,
        const <Color>[Color(0xff172941), Color(0xff091421)],
        null,
        ui.TileMode.clamp,
      );
    canvas.drawCircle(arenaCentre, arenaRadius, arenaFillPaint);
    final gridPaint = ui.Paint()
      ..color = const Color(0x1e9fc0e0)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 0.7;
    for (var index = 1; index <= 3; index++) {
      canvas.drawCircle(arenaCentre, arenaRadius * index / 4, gridPaint);
    }
    final arenaPaint = ui.Paint()
      ..color = const Color(0xffff7180).withValues(alpha: 0.84)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(arenaCentre, arenaRadius, arenaPaint);

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
      final paint = ui.Paint()
        ..color = colour
        ..style = ui.PaintingStyle.fill;
      canvas.drawCircle(
        position + const Offset(1, 1.5),
        marker.isPlayer ? 5.5 : 3.5,
        ui.Paint()..color = const Color(0x99000000),
      );
      canvas.drawCircle(position, marker.isPlayer ? 5 : 3, paint);
      if (marker.isPlayer) {
        canvas.drawCircle(
          position - const Offset(1.4, 1.4),
          1.25,
          ui.Paint()..color = const Color(0xfff7fbff),
        );
      }
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
