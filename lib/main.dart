import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'game/domain/game_state.dart';
import 'game/domain/simulation.dart';
import 'game/domain/vec2.dart';

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

  @override
  void initState() {
    super.initState();
    game = SlitherGame();
  }

  @override
  void dispose() {
    game.hud.dispose();
    super.dispose();
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
              MouseRegion(
                onHover: (event) => game.setPointer(event.localPosition),
                child: Listener(
                  onPointerMove: (event) => game.setPointer(event.localPosition),
                  child: GameWidget(game: game),
                ),
              ),
              ValueListenableBuilder<GameHud>(
                valueListenable: game.hud,
                builder: (context, state, child) => _Hud(
                  state: state,
                  onRestart: game.restart,
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
  const GameHud({required this.score, required this.length, required this.gameOver});

  final int score;
  final int length;
  final bool gameOver;
}

class SlitherGame extends FlameGame {
  SlitherGame({SimulationConfig config = const SimulationConfig()})
      : simulation = GameSimulation(config: config),
        hud = ValueNotifier(const GameHud(score: 0, length: 0, gameOver: false));

  final GameSimulation simulation;
  final ValueNotifier<GameHud> hud;
  Vec2 steering = const Vec2(1, 0);
  double _hudTimer = 0;

  void setPointer(Offset point) {
    final centre = Offset(size.x / 2, size.y / 2);
    steering = Vec2(point.dx - centre.dx, point.dy - centre.dy);
  }

  void restart() {
    simulation.restart();
    _publishHud();
  }

  @override
  void update(double dt) {
    simulation.update(dt, steering);
    _hudTimer += dt;
    if (_hudTimer >= 0.1) {
      _hudTimer = 0;
      _publishHud();
    }
  }

  @override
  void render(ui.Canvas canvas) {
    canvas.drawColor(const Color(0xff080d18));
    if (size.x == 0 || size.y == 0) return;

    canvas.save();
    canvas.translate(size.x / 2 - simulation.player.head.x, size.y / 2 - simulation.player.head.y);
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
      gameOver: simulation.gameOver,
    );
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
        final centre = Offset(x + ((y ~/ spacing).isOdd ? spacing / 2 : 0), y);
        final path = ui.Path();
        for (var index = 0; index < 6; index++) {
          final angle = index * 3.141592653589793 / 3;
          final point = Offset(centre.dx + 44 * math.cos(angle), centre.dy + 44 * math.sin(angle));
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
    canvas.drawCircle(Offset.zero, radius, gridPaint);
  }

  void _drawPellets(ui.Canvas canvas, List<FoodPellet> items, {required bool dropped}) {
    for (final pellet in items) {
      final colour = dropped ? const Color(0xffffb43b) : const Color(0xff54e8d1);
      final paint = ui.Paint()..color = colour.withOpacity(dropped ? 0.95 : 0.8);
      canvas.drawCircle(Offset(pellet.position.x, pellet.position.y), dropped ? 8 : 4, paint);
      if (dropped) {
        final glow = ui.Paint()..color = colour.withOpacity(0.13);
        canvas.drawCircle(Offset(pellet.position.x, pellet.position.y), 18, glow);
      }
    }
  }

  void _drawSnake(ui.Canvas canvas, SnakeState snake) {
    final colours = [
      const Color(0xffffa72f),
      const Color(0xff55d7ff),
      const Color(0xffd875ff),
      const Color(0xff79e36c),
    ];
    final colour = colours[snake.colorIndex % colours.length];
    final bodyPaint = ui.Paint()
      ..color = colour
      ..style = ui.PaintingStyle.fill;
    for (var index = snake.body.length - 1; index >= 0; index--) {
      final segment = snake.body[index];
      final taper = (1 - index / (snake.body.length * 1.5)).clamp(0.72, 1.0) as double;
      canvas.drawCircle(Offset(segment.x, segment.y), snake.radius * taper, bodyPaint);
    }
    final head = snake.head;
    canvas.drawCircle(Offset(head.x, head.y), snake.radius + 2, bodyPaint);
    final eyePaint = ui.Paint()..color = Colors.white;
    final pupilPaint = ui.Paint()..color = const Color(0xff142033);
    final perpendicular = Vec2(-snake.heading.y, snake.heading.x);
    for (final side in [-1.0, 1.0]) {
      final eye = head + snake.heading * 5 + perpendicular * (side * 5);
      canvas.drawCircle(Offset(eye.x, eye.y), 3.5, eyePaint);
      canvas.drawCircle(Offset(eye.x + snake.heading.x * 1.5, eye.y + snake.heading.y * 1.5), 1.8, pupilPaint);
    }
  }
}

class _Hud extends StatelessWidget {
  const _Hud({required this.state, required this.onRestart});

  final GameHud state;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 16,
          left: 16,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xcc0b1323),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              child: Text('SCORE  ${state.score}   LENGTH  ${state.length}', style: const TextStyle(fontSize: 12, letterSpacing: 1.2)),
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
                    const Text('OUT OF BOUNDS', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Score ${state.score}', style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: onRestart, child: const Text('PLAY AGAIN')),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
