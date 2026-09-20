import 'dart:ui' as ui;

import 'package:flutter/material.dart';

abstract final class ArenaSkin {
  static const background = Color(0xff070d18);
  static const tileFace = Color(0xff0d1828);
  static const tileLine = Color(0xff132238);
  static const tileHighlight = Color(0xff20344b);
  static const tileShade = Color(0xff07111e);

  static const panelTop = Color(0xf01b2c43);
  static const panelBottom = Color(0xed0a1423);
  static const panelRim = Color(0x994e6c89);
  static const textPrimary = Color(0xfff1f6ff);
  static const textMuted = Color(0xff9aacc4);
  static const accent = Color(0xffffce78);
  static const naturalFood = Color(0xff54e8d1);
  static const danger = Color(0xffff7180);

  static const snakeColours = <Color>[
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

  static ui.Paint _spherePaint(Color base, {required double gloss}) {
    final highlight = Color.lerp(base, Colors.white, gloss)!;
    final shade = Color.lerp(base, const Color(0xff030812), 0.58)!;
    return ui.Paint()
      ..shader = ui.Gradient.radial(
        const ui.Offset(-0.3, -0.36),
        1.35,
        <Color>[highlight, base, shade],
        const <double>[0, 0.43, 1],
        ui.TileMode.clamp,
      );
  }

  static final snakeBodyPaints = List<ui.Paint>.unmodifiable(
    snakeColours.map((color) => _spherePaint(color, gloss: 0.34)),
  );

  static final naturalPelletPaint = _spherePaint(naturalFood, gloss: 0.78);

  static final droppedPelletPaints = List<ui.Paint>.unmodifiable(
    snakeColours.map((color) => _spherePaint(color, gloss: 0.72)),
  );

  static BoxDecoration glassPanel({
    Color borderColor = panelRim,
    double radius = 12,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[panelTop, panelBottom],
      ),
      border: Border.all(color: borderColor, width: 1),
      boxShadow: const <BoxShadow>[
        BoxShadow(
          color: Color(0x80000000),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
        BoxShadow(
          color: Color(0x1686cfff),
          blurRadius: 3,
          offset: Offset(0, -1),
        ),
      ],
    );
  }
}
