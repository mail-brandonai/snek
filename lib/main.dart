import 'dart:async';
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
import 'game/presentation/snek_pen.dart';
import 'training/application/fixed_step_run_recorder.dart';
import 'training/data/training_services.dart';
import 'training/domain/training_models.dart';
import 'training/presentation/run_library_screen.dart' deferred as run_library;
import 'training/presentation/soul_library_screen.dart';
import 'training/presentation/soul_studio_screen.dart';

const _snakeColours = ArenaSkin.snakeColours;

void main() {
  runApp(const SlitherApp());
}

class SlitherApp extends StatefulWidget {
  const SlitherApp({super.key});

  @override
  State<SlitherApp> createState() => _SlitherAppState();
}

enum _AppScreen { landing, pen, create, playing, runs, souls, soulStudio }

class _SlitherAppState extends State<SlitherApp> {
  late final SlitherGame game;
  late final FocusNode _focusNode;
  bool _pointerButtonHeld = false;
  bool _penLoaded = false;
  bool _penLoading = false;
  _AppScreen _screen = _AppScreen.landing;
  String? _runToReview;
  List<SnekProfile> _sneks = <SnekProfile>[SnekProfile.starter];
  String _selectedSnekId = SnekProfile.starter.id;

  SnekProfile get _selectedSnek => _sneks.firstWhere(
    (snek) => snek.id == _selectedSnekId,
    orElse: () => _sneks.first,
  );

  @override
  void initState() {
    super.initState();
    game = SlitherGame(onRunFinalized: _openCompletedRun);
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    game.leaveGame();
    game.hud.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _openPen() async {
    if (_penLoading) return;
    if (!_penLoaded) {
      setState(() => _penLoading = true);
      var snapshot = SnekPenSnapshot.defaults;
      try {
        snapshot = await TrainingServices.loadPen();
      } catch (_) {
        // Keep the starter snek available if local storage is unavailable.
      }
      if (!mounted) return;
      setState(() {
        _sneks =
            snapshot.sneks.isEmpty
                ? <SnekProfile>[SnekProfile.starter]
                : snapshot.sneks;
        _selectedSnekId =
            _sneks.any((snek) => snek.id == snapshot.selectedSnekId)
                ? snapshot.selectedSnekId
                : _sneks.first.id;
        _penLoaded = true;
        _penLoading = false;
        _screen = _AppScreen.pen;
      });
      return;
    }
    setState(() => _screen = _AppScreen.pen);
  }

  void _selectSnek(String id) {
    setState(() => _selectedSnekId = id);
    unawaited(_persistPen());
  }

  Future<void> _bindSoulToSnek(String snekId, String? soulId) async {
    setState(() {
      _sneks = _sneks
          .map(
            (snek) =>
                snek.id == snekId ? snek.withSoul(soulId) : snek,
          )
          .toList(growable: false);
    });
    await _persistPen();
  }

  void _saveNewSnek(String name, int colorIndex) {
    final snek = SnekProfile(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      colorIndex: colorIndex,
    );
    setState(() {
      _sneks = <SnekProfile>[..._sneks, snek];
      _selectedSnekId = snek.id;
      _screen = _AppScreen.pen;
    });
    unawaited(_persistPen());
  }

  Future<void> _persistPen() async {
    try {
      await TrainingServices.savePen(
        SnekPenSnapshot(sneks: _sneks, selectedSnekId: _selectedSnekId),
      );
    } catch (error) {
      debugPrint('Could not save the Snek Pen: $error');
    }
  }

  void _playSelectedSnek() {
    unawaited(game.startWithSnek(_selectedSnek));
    setState(() => _screen = _AppScreen.playing);
    _focusNode.requestFocus();
  }

  void _openRunLibrary() {
    unawaited(_loadRunLibrary());
  }

  void _openSoulLibrary() {
    setState(() => _screen = _AppScreen.souls);
  }

  void _openSoulStudio() {
    setState(() => _screen = _AppScreen.soulStudio);
  }

  Future<void> _loadRunLibrary({String? runId}) async {
    await run_library.loadLibrary();
    if (!mounted) return;
    setState(() {
      _runToReview = runId;
      _screen = _AppScreen.runs;
    });
  }

  void _openCompletedRun(String runId) {
    unawaited(_loadRunLibrary(runId: runId));
  }

  void _returnHome() {
    game.leaveGame();
    setState(() {
      _runToReview = null;
      _screen = _AppScreen.landing;
    });
  }

  void _returnToPen() {
    game.leaveGame();
    setState(() {
      _runToReview = null;
      _screen = _AppScreen.pen;
    });
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
              if (_screen == _AppScreen.playing)
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
                )
              else
                const ColoredBox(color: ArenaSkin.background),
              if (_screen == _AppScreen.playing)
                ValueListenableBuilder<GameHud>(
                  valueListenable: game.hud,
                  builder:
                      (context, state, child) => Stack(
                        children: [
                          IgnorePointer(
                            ignoring:
                                _screen != _AppScreen.playing ||
                                !state.gameOver,
                            child: _Hud(
                              state: state,
                              onRestart: game.restart,
                              onChangeSnek: _returnToPen,
                            ),
                          ),
                          if (_screen == _AppScreen.playing)
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
              if (_screen == _AppScreen.landing)
                Positioned.fill(
                  child: SnekLandingScreen(
                    selectedSnek: _selectedSnek,
                    onOpenPen: _openPen,
                    onOpenRuns: _openRunLibrary,
                    onOpenSouls: _openSoulLibrary,
                  ),
                ),
              if (_screen == _AppScreen.pen)
                Positioned.fill(
                  child: SnekPenScreen(
                    sneks: _sneks,
                    selectedSnekId: _selectedSnekId,
                    onBack: _returnHome,
                    onSelect: _selectSnek,
                    onCreate: () => setState(() => _screen = _AppScreen.create),
                    onPlay: _playSelectedSnek,
                    onOpenSoulStudio: _openSoulStudio,
                  ),
                ),
              if (_screen == _AppScreen.create)
                Positioned.fill(
                  child: SnekCreateScreen(
                    initialName: 'Snek ${_sneks.length + 1}',
                    initialColorIndex: _selectedSnek.colorIndex,
                    onBack: () => setState(() => _screen = _AppScreen.pen),
                    onSave: _saveNewSnek,
                  ),
                ),
              if (_screen == _AppScreen.soulStudio)
                Positioned.fill(
                  child: SoulStudioScreen(
                    sneks: _sneks,
                    selectedSnekId: _selectedSnekId,
                    onBack: _returnToPen,
                    onBind: _bindSoulToSnek,
                  ),
                ),
              if (_screen == _AppScreen.souls)
                Positioned.fill(child: SoulLibraryScreen(onBack: _returnHome)),
              if (_screen == _AppScreen.runs)
                Positioned.fill(
                  child: run_library.RunLibraryScreen(
                    key: ValueKey<String>(_runToReview ?? 'all-runs'),
                    initialRunId: _runToReview,
                    onBack: _returnHome,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
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
}

class GameHud {
  const GameHud({
    required this.score,
    required this.playerName,
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
  final String playerName;
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
  SlitherGame({
    SimulationConfig config = const SimulationConfig(),
    this.onRunFinalized,
  }) : simulation = GameSimulation(config: config),
       hud = ValueNotifier(
         const GameHud(
           score: 0,
           playerName: 'Snek',
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

  final ValueChanged<String>? onRunFinalized;
  final GameSimulation simulation;
  final ValueNotifier<GameHud> hud;
  final ui.Paint _gridPaint =
      ui.Paint()
        ..color = ArenaSkin.tileLine
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 1.2;
  final ui.Paint _gridFacePaint = ui.Paint()..color = ArenaSkin.tileFace;
  final ui.Paint _gridLightEdgePaint =
      ui.Paint()
        ..color = ArenaSkin.tileHighlight.withValues(alpha: 0.72)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 1.4;
  final ui.Paint _gridShadeEdgePaint =
      ui.Paint()
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
  final ui.Paint _eyeGlintPaint =
      ui.Paint()..color = const Color(0xffffffff).withValues(alpha: 0.92);
  final ui.Path _visibleGridPath = ui.Path();
  final ui.Path _visibleGridFacePath = ui.Path();
  final ui.Path _visibleGridLightEdgePath = ui.Path();
  final ui.Path _visibleGridShadeEdgePath = ui.Path();
  SnekProfile? _activeSnek;
  FixedStepRunRecorder? _recorder;
  int _runGeneration = 0;
  bool _recorderFinalizing = false;
  int _gridStartColumn = -1;
  int _gridEndColumn = -1;
  int _gridStartRow = -1;
  int _gridEndRow = -1;
  Vec2 steering = const Vec2(1, 0);
  bool _pointerSprint = false;
  bool _keyboardSprint = false;
  bool advancedHudEnabled = false;
  double _hudTimer = 0;
  double _renderCameraX = 0;
  double _renderCameraY = 0;
  String playerName = 'Snek';
  bool _isActive = false;

  bool get sprinting =>
      simulation.canSprint && (_pointerSprint || _keyboardSprint);

  void setPointer(Offset point) {
    final centre = Offset(size.x / 2, size.y / 2);
    steering = Vec2(point.dx - centre.dx, point.dy - centre.dy);
  }

  Future<void> startWithSnek(SnekProfile snek) async {
    final generation = ++_runGeneration;
    final previous = _recorder;
    if (previous != null && !simulation.gameOver) simulation.abandon();
    simulation.captureSink = null;
    if (previous != null) {
      final completedAtMs = DateTime.now().millisecondsSinceEpoch;
      if (simulation.gameOver) {
        await previous.finalize(finalizedAtMs: completedAtMs);
      } else {
        await previous.abort(finalizedAtMs: completedAtMs);
      }
    }
    if (generation != _runGeneration) return;

    _recorder = null;
    _recorderFinalizing = false;
    _activeSnek = snek;
    playerName = snek.name;
    simulation.playerColorIndex = snek.colorIndex;
    simulation.restart();
    _pointerSprint = false;
    _keyboardSprint = false;

    final createdAtMs = DateTime.now().millisecondsSinceEpoch;
    final participants = simulation.snakes
        .map(
          (actor) => <String, Object?>{
            'actorId': actor.id,
            'role': actor.kind.name,
            'controller': actor.kind == SnakeKind.player ? 'human' : 'builtin',
            'profileId': actor.kind == SnakeKind.player ? snek.id : null,
          },
        )
        .toList(growable: false);
    final run = TrainingRun(
      id: 'run-${DateTime.now().microsecondsSinceEpoch}',
      mode: 'manual',
      seed: simulation.seed,
      tickRateHz:
          (1 / math.max(0.001, simulation.config.simulationStep)).round(),
      createdAtMs: createdAtMs,
      status: TrainingRunStatus.recording,
      config: <String, Object?>{
        'gameRulesVersion': 'snek-v1',
        'simulation': simulation.config.toJson(),
        'playerProfileId': snek.id,
        'playerName': snek.name,
        'playerColorIndex': snek.colorIndex,
        'participants': participants,
      },
    );

    FixedStepRunRecorder? recorder;
    try {
      recorder = await TrainingServices.beginRun(run);
    } catch (error) {
      debugPrint('Could not start the run recorder: $error');
    }
    if (generation != _runGeneration) {
      if (recorder != null) {
        await recorder.abort(
          finalizedAtMs: DateTime.now().millisecondsSinceEpoch,
        );
      }
      return;
    }

    _recorder = recorder;
    simulation.captureSink = recorder;
    _isActive = true;
    _publishHud();
  }

  void leaveGame() {
    _runGeneration++;
    _isActive = false;
    _pointerSprint = false;
    _keyboardSprint = false;
    final recorder = _recorder;
    _recorder = null;
    if (recorder == null) {
      simulation.captureSink = null;
      return;
    }
    if (!simulation.gameOver) simulation.abandon();
    simulation.captureSink = null;

    final finalizedAtMs = DateTime.now().millisecondsSinceEpoch;
    final completion =
        simulation.gameOver
            ? recorder.finalize(finalizedAtMs: finalizedAtMs)
            : recorder.abort(finalizedAtMs: finalizedAtMs);
    unawaited(
      completion.then<void>((_) {}).catchError((Object error) {
        debugPrint('Could not close the run recorder: $error');
      }),
    );
  }

  void restart() {
    unawaited(startWithSnek(_activeSnek ?? SnekProfile.starter));
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
    if (!_isActive) return;
    super.update(dt);
    simulation.update(dt, steering, sprinting: sprinting);
    _finalizeCompletedRun();
    _hudTimer += dt;
    if (_hudTimer >= 0.1) {
      _hudTimer = 0;
      _publishHud();
    }
  }

  void _finalizeCompletedRun() {
    final recorder = _recorder;
    if (!simulation.gameOver || recorder == null || _recorderFinalizing) return;
    _recorderFinalizing = true;
    unawaited(
      recorder
          .finalize(finalizedAtMs: DateTime.now().millisecondsSinceEpoch)
          .then<void>((_) {
            if (!identical(_recorder, recorder)) return;
            _recorder = null;
            _recorderFinalizing = false;
            _isActive = false;
            _publishHud();
            onRunFinalized?.call(recorder.runId);
          })
          .catchError((Object error) {
            debugPrint('Could not finalize the run recorder: $error');
            _recorderFinalizing = false;
          }),
    );
  }

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);
    canvas.drawColor(ArenaSkin.background, ui.BlendMode.srcOver);
    if (size.x == 0 || size.y == 0) return;

    final interpolation = simulation.renderInterpolationAlpha;
    _renderCameraX = simulation.renderBodyX(
      simulation.player,
      0,
      interpolation,
    );
    _renderCameraY = simulation.renderBodyY(
      simulation.player,
      0,
      interpolation,
    );
    canvas.save();
    canvas.translate(size.x / 2 - _renderCameraX, size.y / 2 - _renderCameraY);
    _drawArena(canvas, _renderCameraX, _renderCameraY);
    _drawPellets(canvas, simulation.pellets, dropped: false);
    _drawPellets(canvas, simulation.droppedMass, dropped: true);
    for (final snake in simulation.snakes) {
      if (snake.alive) _drawSnake(canvas, snake, interpolation);
    }
    canvas.restore();
  }

  void _publishHud() {
    final threats = simulation.playerThreats;
    hud.value = GameHud(
      score: simulation.score,
      playerName: playerName,
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
      tacticalDiagnostics:
          advancedHudEnabled ? simulation.tacticalDiagnostics : '',
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

  void _drawArena(ui.Canvas canvas, double cameraX, double cameraY) {
    const spacing = 92.0;
    final radius = simulation.config.arenaRadius;
    final minimumX = cameraX - size.x / 2 - spacing;
    final maximumX = cameraX + size.x / 2 + spacing;
    final minimumY = cameraY - size.y / 2 - spacing;
    final maximumY = cameraY + size.y / 2 + spacing;
    final maximumGridIndex = (radius * 2 / spacing).floor();
    final startColumn =
        ((minimumX + radius) / spacing)
            .floor()
            .clamp(0, maximumGridIndex)
            .toInt();
    final endColumn =
        ((maximumX + radius) / spacing)
            .ceil()
            .clamp(0, maximumGridIndex)
            .toInt();
    final startRow =
        ((minimumY + radius) / spacing)
            .floor()
            .clamp(0, maximumGridIndex)
            .toInt();
    final endRow =
        ((maximumY + radius) / spacing)
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
    final cameraDistance = math.sqrt(cameraX * cameraX + cameraY * cameraY);
    final warningRadius =
        math
            .max(0.0, radius - simulation.config.arenaBoundaryWarningBuffer)
            .toDouble();
    if ((cameraDistance - warningRadius).abs() <= viewportRadius + 24) {
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

    if ((cameraDistance - radius).abs() <= viewportRadius + 28) {
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

  void _drawSnake(ui.Canvas canvas, SnakeState snake, double interpolation) {
    if (snake.body.isEmpty) return;
    final renderStride = snake.body.length > 420 ? 2 : 1;
    final headX = simulation.renderBodyX(snake, 0, interpolation);
    final headY = simulation.renderBodyY(snake, 0, interpolation);
    final minimumTaper =
        simulation.config.collisionTailTaper.clamp(0.0, 1.0).toDouble();
    final viewMinimumX = _renderCameraX - size.x / 2;
    final viewMaximumX = _renderCameraX + size.x / 2;
    final viewMinimumY = _renderCameraY - size.y / 2;
    final viewMaximumY = _renderCameraY + size.y / 2;
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
      final double pulse =
          (snake.sprinting
                  ? snake.sprintPulseRemaining /
                      math.max(simulation.config.sprintPulseDuration, 0.0001)
                  : snake.sprintAnticipationRemaining /
                      math.max(
                        simulation.config.sprintAnticipationDuration,
                        0.0001,
                      ))
              .toDouble();
      _effectPaint
        ..color = colour.withValues(
          alpha: (0.22 + pulse.clamp(0.0, 1.0) * 0.34).toDouble(),
        )
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = snake.sprinting ? 3 : 2;
      if (_isVisibleAt(headX, headY, snake.radius + 20)) {
        canvas.drawCircle(
          Offset(headX, headY),
          snake.radius + 8 + (1 - pulse.clamp(0.0, 1.0)) * 8,
          _effectPaint,
        );
      }
    }
    if (snake.kind == SnakeKind.player && snake.sprinting) {
      final pulse = (math.sin(simulation.elapsed * 10) + 1) / 2;
      _effectPaint
        ..color = const Color(0xffffc766).withValues(alpha: 0.12 + pulse * 0.1)
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
          final x = simulation.renderBodyX(snake, index, interpolation);
          final y = simulation.renderBodyY(snake, index, interpolation);
          if (!_isVisibleAt(x, y, padding)) continue;
          canvas.drawCircle(
            Offset(x, y),
            snake.radius * (1.45 + pulse * 0.18),
            _effectPaint,
          );
        }
      }
      _effectPaint
        ..color = const Color(0xffffd166).withValues(alpha: 0.45 + pulse * 0.25)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 1.5 + pulse;
      if (_isVisibleAt(headX, headY, snake.radius + 20)) {
        canvas.drawCircle(
          Offset(headX, headY),
          snake.radius * (1.55 + pulse * 0.25),
          _effectPaint,
        );
      }
    }
    final bodyPaint = _snakeBodyPaints[colourIndex];
    // body[0] is the head position and is rendered separately below. Skipping
    // it here keeps the visible segment count equal to the HUD length instead
    // of making every snake appear one segment longer at spawn.
    for (
      var chunkIndex = snake.bodyChunks.length - 1;
      chunkIndex >= 0;
      chunkIndex--
    ) {
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
        final x = simulation.renderBodyX(snake, index, interpolation);
        final y = simulation.renderBodyY(snake, index, interpolation);
        if (!_isVisibleAt(x, y, padding)) continue;
        final double taper =
            (1 - index / (snake.body.length * 1.5))
                .clamp(minimumTaper, 1.0)
                .toDouble();
        _drawShadedCircle(
          canvas,
          Offset(x, y),
          snake.radius * taper * (renderStride == 1 ? 1 : 1.22),
          bodyPaint,
        );
      }
    }
    if (!_isVisibleAt(headX, headY, snake.radius + 12)) return;
    _drawShadedCircle(
      canvas,
      Offset(headX, headY),
      snake.radius + 2,
      bodyPaint,
    );
    final headingX = snake.heading.x;
    final headingY = snake.heading.y;
    final perpendicularX = -headingY;
    final perpendicularY = headingX;
    for (final side in const [-1.0, 1.0]) {
      final eyeX = headX + headingX * 5 + perpendicularX * (side * 5);
      final eyeY = headY + headingY * 5 + perpendicularY * (side * 5);
      canvas.drawCircle(Offset(eyeX, eyeY), 3.8, _eyePaint);
      canvas.drawCircle(
        Offset(eyeX + headingX * 1.5, eyeY + headingY * 1.5),
        1.9,
        _pupilPaint,
      );
      canvas.drawCircle(Offset(eyeX - 0.9, eyeY - 1.1), 0.8, _eyeGlintPaint);
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

  bool _isVisible(Vec2 position, double padding) =>
      _isVisibleAt(position.x, position.y, padding);

  bool _isVisibleAt(double x, double y, double padding) {
    return (x - _renderCameraX).abs() <= size.x / 2 + padding &&
        (y - _renderCameraY).abs() <= size.y / 2 + padding;
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
              value: '#${state.rank}',
              accent: const Color(0xffc9d8ef),
            ),
            _HudMetric(
              label: 'TIME',
              value: _formatDuration(state.survivalSeconds),
              accent: const Color(0xffc9d8ef),
            ),
            if (state.sprinting)
              const _HudStatusBadge(label: 'SPRINT', accent: ArenaSkin.accent),
            if (state.boundaryWarningProgress > 0.45)
              const _HudStatusBadge(label: 'EDGE', accent: ArenaSkin.danger),
          ],
        ),
      ),
    );
  }
}

class _Hud extends StatelessWidget {
  const _Hud({
    required this.state,
    required this.onRestart,
    required this.onChangeSnek,
  });

  final GameHud state;
  final VoidCallback onRestart;
  final VoidCallback onChangeSnek;

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
                painter: _BoundaryWarningPainter(state.boundaryWarningProgress),
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
            playerName: state.playerName,
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
        const Positioned(left: 16, bottom: 16, child: _ControlHint()),
        Positioned(top: 16, left: 16, child: _StatsPanel(state: state)),
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
                    const SizedBox(height: 5),
                    Text(
                      'Snek ${state.playerName}',
                      style: const TextStyle(
                        color: ArenaSkin.accent,
                        fontWeight: FontWeight.w700,
                      ),
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
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        FilledButton(
                          onPressed: onRestart,
                          child: const Text('PLAY AGAIN'),
                        ),
                        OutlinedButton(
                          onPressed: onChangeSnek,
                          child: const Text('SNEK PEN'),
                        ),
                      ],
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
  const _TacticsHudToggle({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: enabled ? ArenaSkin.accent : ArenaSkin.textPrimary,
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
      icon: Icon(enabled ? Icons.visibility : Icons.visibility_off, size: 14),
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
  const _LeaderboardPanel({
    required this.entries,
    required this.playerRank,
    required this.playerName,
  });

  final List<LeaderboardEntry> entries;
  final int playerRank;
  final String playerName;

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
            for (final entry in entries)
              _LeaderboardRow(entry: entry, playerName: playerName),
            if (entries.every((entry) => !entry.isPlayer)) ...[
              const Divider(height: 8, color: Colors.white24),
              Text(
                '${playerName.toUpperCase()}  #$playerRank',
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
  const _LeaderboardRow({required this.entry, required this.playerName});

  final LeaderboardEntry entry;
  final String playerName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        '${entry.rank}. ${entry.isPlayer ? playerName.toUpperCase() : entry.id.toUpperCase()}  ${entry.length}',
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
        painter: _MinimapPainter(markers, pings, events, showTacticalSignals),
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
    final borderPaint =
        ui.Paint()
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

    final sweepPaint =
        ui.Paint()
          ..color = const Color(0xffffd166).withValues(alpha: alpha * 1.5)
          ..strokeWidth = 3;
    final sweepX = size.width * (0.15 + progress * 0.7);
    canvas.drawLine(Offset(sweepX - 42, 5), Offset(sweepX + 42, 5), sweepPaint);
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
    final paint =
        ui.Paint()
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

  static ui.Size? _backgroundSize;
  static ui.Path? _panelPath;
  static ui.RRect? _panelRect;
  static ui.RRect? _panelBorderRect;
  static final ui.Paint _panelPaint = ui.Paint();
  static final ui.Paint _panelBorderPaint =
      ui.Paint()
        ..color = ArenaSkin.panelRim
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 1;
  static final ui.Paint _arenaFillPaint = ui.Paint();
  static final ui.Paint _gridPaint =
      ui.Paint()
        ..color = const Color(0x1e9fc0e0)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 0.7;
  static final ui.Paint _arenaPaint =
      ui.Paint()
        ..color = const Color(0xffff7180).withValues(alpha: 0.84)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 2;
  static final ui.Paint _ringPaint =
      ui.Paint()..style = ui.PaintingStyle.stroke;
  static final ui.Paint _fillPaint = ui.Paint();
  static final ui.Paint _markerShadowPaint =
      ui.Paint()..color = const Color(0x99000000);

  static void _prepareStaticBackground(ui.Size size) {
    if (_backgroundSize == size) return;
    _backgroundSize = size;

    final rect = ui.Rect.fromLTWH(0, 0, size.width, size.height);
    final panelRect = ui.RRect.fromRectAndRadius(
      rect,
      const ui.Radius.circular(12),
    );
    _panelPath = ui.Path()..addRRect(panelRect);
    _panelRect = panelRect;
    _panelBorderRect = ui.RRect.fromRectAndRadius(
      rect.deflate(1),
      const ui.Radius.circular(11),
    );
    _panelPaint.shader = ui.Gradient.linear(
      Offset.zero,
      Offset(size.width, size.height),
      const <Color>[ArenaSkin.panelTop, ArenaSkin.panelBottom],
      null,
      ui.TileMode.clamp,
    );

    final arenaCentre = Offset(size.width / 2, size.height / 2);
    _arenaFillPaint.shader = ui.Gradient.radial(
      arenaCentre,
      size.width * 0.37,
      const <Color>[Color(0xff172941), Color(0xff091421)],
      null,
      ui.TileMode.clamp,
    );
  }

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    _prepareStaticBackground(size);
    final panelRect = _panelRect!;
    canvas.drawShadow(_panelPath!, const Color(0xc0000000), 7, true);
    canvas.drawRRect(panelRect, _panelPaint);
    canvas.drawRRect(_panelBorderRect!, _panelBorderPaint);

    final arenaCentre = Offset(size.width / 2, size.height / 2);
    final arenaRadius = size.width * 0.37;
    canvas.drawCircle(arenaCentre, arenaRadius, _arenaFillPaint);
    for (var index = 1; index <= 3; index++) {
      canvas.drawCircle(arenaCentre, arenaRadius * index / 4, _gridPaint);
    }
    canvas.drawCircle(arenaCentre, arenaRadius, _arenaPaint);

    for (final ping in pings) {
      final position = Offset(ping.x * size.width, ping.y * size.height);
      final progress = ping.progress;
      _ringPaint
        ..color = const Color(
          0xffffd166,
        ).withValues(alpha: 0.9 * (1 - progress))
        ..strokeWidth = 1.5;
      canvas.drawCircle(position, 5 + progress * 17, _ringPaint);
      _fillPaint.color = const Color(
        0xffffd166,
      ).withValues(alpha: 0.75 * (1 - progress));
      canvas.drawCircle(position, 2, _fillPaint);
    }

    if (showTacticalSignals) {
      for (final event in events) {
        final position = Offset(event.x * size.width, event.y * size.height);
        final colour =
            event.kind == TelegraphEventKind.sprintStarted
                ? const Color(0xffffa72f)
                : const Color(0xff55d7ff);
        _ringPaint
          ..color = colour.withValues(alpha: 0.55 * (1 - event.progress))
          ..strokeWidth = 1.2;
        canvas.drawCircle(position, 4 + event.progress * 12, _ringPaint);
      }
    }

    for (final marker in markers) {
      final position = Offset(marker.x * size.width, marker.y * size.height);
      final colour = _snakeColour(marker.colorIndex);
      canvas.drawCircle(
        position + const Offset(1, 1.5),
        marker.isPlayer ? 5.5 : 3.5,
        _markerShadowPaint,
      );
      _fillPaint
        ..color = colour
        ..style = ui.PaintingStyle.fill;
      canvas.drawCircle(position, marker.isPlayer ? 5 : 3, _fillPaint);
      if (marker.isPlayer) {
        _fillPaint.color = const Color(0xfff7fbff);
        canvas.drawCircle(position - const Offset(1.4, 1.4), 1.25, _fillPaint);
      }
      if (marker.sprintAnticipating || marker.sprinting) {
        _ringPaint
          ..color = colour.withValues(alpha: marker.sprinting ? 0.8 : 0.45)
          ..strokeWidth = marker.sprinting ? 2 : 1;
        canvas.drawCircle(position, marker.isPlayer ? 10 : 7, _ringPaint);
      }
      if (showTacticalSignals && marker.intent == ActorIntent.retreating) {
        _ringPaint
          ..color = colour.withValues(alpha: 0.65)
          ..strokeWidth = 1;
        canvas.drawCircle(position, marker.isPlayer ? 12 : 6, _ringPaint);
      }
      if (showTacticalSignals && marker.threatUrgency > 0) {
        _ringPaint
          ..color = const Color(
            0xffff5f56,
          ).withValues(alpha: 0.35 + marker.threatUrgency * 0.55)
          ..strokeWidth = 1.5;
        canvas.drawCircle(
          position,
          (marker.isPlayer ? 12 : 7) + marker.threatUrgency * 7,
          _ringPaint,
        );
      }
      if (marker.isPlayer) {
        _ringPaint
          ..color = colour.withValues(alpha: 0.35)
          ..strokeWidth = 1;
        canvas.drawCircle(position, 9, _ringPaint);
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
