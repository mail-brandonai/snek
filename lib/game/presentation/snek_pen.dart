import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'arena_skin.dart';
import '../../training/domain/training_models.dart';

const _snekColorNames = <String>[
  'Solar',
  'Glacier',
  'Nebula',
  'Meadow',
  'Berry',
  'Lemon',
  'Comet',
  'Lagoon',
  'Ember',
  'Lilac',
];

class SnekLandingScreen extends StatelessWidget {
  const SnekLandingScreen({
    super.key,
    required this.selectedSnek,
    required this.onOpenPen,
    required this.onOpenRuns,
    required this.onOpenSouls,
  });

  final SnekProfile selectedSnek;
  final VoidCallback onOpenPen;
  final VoidCallback onOpenRuns;
  final VoidCallback onOpenSouls;

  @override
  Widget build(BuildContext context) {
    return _MenuBackdrop(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: DecoratedBox(
              decoration: ArenaSkin.glassPanel(
                borderColor: const Color(0xff506d8b),
                radius: 24,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _BrandMark(),
                    const SizedBox(height: 13),
                    const Text(
                      'SNEK',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 5,
                        color: ArenaSkin.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Grow bold. Own the arena.',
                      style: TextStyle(color: ArenaSkin.textMuted),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                      decoration: BoxDecoration(
                        color: const Color(0x33040b15),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: ArenaSkin.panelRim),
                      ),
                      child: Column(
                        children: [
                          Text(
                            selectedSnek.name.toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.3,
                              color: ArenaSkin.accent,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SnekPreview(
                            colorIndex: selectedSnek.colorIndex,
                            height: 58,
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'YOUR ACTIVE SNEK',
                            style: TextStyle(
                              fontSize: 9,
                              letterSpacing: 1.2,
                              color: ArenaSkin.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: onOpenPen,
                        icon: const Icon(Icons.pets_outlined),
                        label: const Text('OPEN THE SNEK PEN'),
                        style: _primaryButtonStyle,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: onOpenRuns,
                        icon: const Icon(Icons.history),
                        label: const Text('RUN LIBRARY'),
                        style: _secondaryButtonStyle,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: onOpenSouls,
                        icon: const Icon(Icons.auto_awesome_outlined),
                        label: const Text('SOUL LIBRARY'),
                        style: _secondaryButtonStyle,
                      ),
                    ),
                    const SizedBox(height: 11),
                    const Text(
                      'Pick a favorite or raise a new one before you play.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: ArenaSkin.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SnekPenScreen extends StatelessWidget {
  const SnekPenScreen({
    super.key,
    required this.sneks,
    required this.selectedSnekId,
    required this.onBack,
    required this.onSelect,
    required this.onCreate,
    required this.onPlay,
    required this.onOpenSoulStudio,
  });

  final List<SnekProfile> sneks;
  final String selectedSnekId;
  final VoidCallback onBack;
  final ValueChanged<String> onSelect;
  final VoidCallback onCreate;
  final VoidCallback onPlay;
  final VoidCallback onOpenSoulStudio;

  @override
  Widget build(BuildContext context) {
    final selected = sneks.firstWhere(
      (snek) => snek.id == selectedSnekId,
      orElse: () => sneks.first,
    );
    return _MenuBackdrop(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1020),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: onBack,
                        tooltip: 'Back',
                        icon: const Icon(Icons.arrow_back),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SNEK PEN',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                            Text(
                              'Choose who is joining the arena.',
                              style: TextStyle(
                                fontSize: 12,
                                color: ArenaSkin.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _CountBadge(count: sneks.length),
                    ],
                  ),
                  const SizedBox(height: 17),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final columns =
                            (constraints.maxWidth / 238)
                                .floor()
                                .clamp(1, 4)
                                .toInt();
                        return GridView.builder(
                          padding: const EdgeInsets.only(bottom: 8),
                          itemCount: sneks.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1.28,
                              ),
                          itemBuilder: (context, index) {
                            final snek = sneks[index];
                            return _SnekCard(
                              snek: snek,
                              selected: snek.id == selectedSnekId,
                              onTap: () => onSelect(snek.id),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      OutlinedButton.icon(
                        onPressed: onCreate,
                        icon: const Icon(Icons.add),
                        label: const Text('CREATE A SNEK'),
                        style: _secondaryButtonStyle,
                      ),
                      FilledButton.icon(
                        onPressed: onPlay,
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text('PLAY WITH ${selected.name.toUpperCase()}'),
                        style: _primaryButtonStyle,
                      ),
                      OutlinedButton.icon(
                        onPressed: onOpenSoulStudio,
                        icon: const Icon(Icons.auto_awesome_outlined),
                        label: const Text('SOUL STUDIO'),
                        style: _secondaryButtonStyle,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SnekCreateScreen extends StatefulWidget {
  const SnekCreateScreen({
    super.key,
    required this.initialName,
    required this.initialColorIndex,
    required this.onBack,
    required this.onSave,
  });

  final String initialName;
  final int initialColorIndex;
  final VoidCallback onBack;
  final void Function(String name, int colorIndex) onSave;

  @override
  State<SnekCreateScreen> createState() => _SnekCreateScreenState();
}

class _SnekCreateScreenState extends State<SnekCreateScreen> {
  late final TextEditingController _nameController;
  late int _selectedColorIndex;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _selectedColorIndex =
        widget.initialColorIndex
            .clamp(0, ArenaSkin.snakeColours.length - 1)
            .toInt();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = _nameController.text.trim();
    return _MenuBackdrop(
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: DecoratedBox(
                decoration: ArenaSkin.glassPanel(
                  borderColor: const Color(0xff506d8b),
                  radius: 22,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: widget.onBack,
                            tooltip: 'Back to Snek Pen',
                            icon: const Icon(Icons.arrow_back),
                          ),
                          const SizedBox(width: 6),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'RAISE A NEW SNEK',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.3,
                                  ),
                                ),
                                Text(
                                  'Give them a name and a color.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: ArenaSkin.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SnekPreview(colorIndex: _selectedColorIndex, height: 72),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _nameController,
                        autofocus: true,
                        maxLength: 16,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.done,
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) {
                          if (name.isNotEmpty) {
                            widget.onSave(name, _selectedColorIndex);
                          }
                        },
                        decoration: const InputDecoration(
                          labelText: 'Snek name',
                          hintText: 'e.g. Noodle',
                          prefixIcon: Icon(Icons.badge_outlined),
                          counterStyle: TextStyle(color: ArenaSkin.textMuted),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'CHOOSE A SKIN',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: ArenaSkin.textMuted,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (
                            var index = 0;
                            index < ArenaSkin.snakeColours.length;
                            index++
                          )
                            _ColorChoice(
                              color: ArenaSkin.snakeColours[index],
                              label: _snekColorNames[index],
                              selected: index == _selectedColorIndex,
                              onTap:
                                  () => setState(
                                    () => _selectedColorIndex = index,
                                  ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed:
                            name.isEmpty
                                ? null
                                : () =>
                                    widget.onSave(name, _selectedColorIndex),
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('SAVE TO SNEK PEN'),
                        style: _primaryButtonStyle,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SnekPreview extends StatelessWidget {
  const SnekPreview({super.key, required this.colorIndex, this.height = 52});

  final int colorIndex;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _SnekPreviewPainter(
          color:
              ArenaSkin.snakeColours[colorIndex
                  .clamp(0, ArenaSkin.snakeColours.length - 1)
                  .toInt()],
        ),
      ),
    );
  }
}

class _SnekPreviewPainter extends CustomPainter {
  const _SnekPreviewPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = math.min(12.0, size.height * 0.18);
    final bodyStart = size.width * 0.16;
    final bodyEnd = size.width * 0.75;
    for (var index = 0; index < 9; index++) {
      final progress = index / 8;
      final x = ui.lerpDouble(bodyStart, bodyEnd, progress)!;
      final y =
          size.height * 0.5 +
          math.sin(progress * math.pi * 2.2) * size.height * 0.12;
      _drawSphere(canvas, Offset(x, y), radius, color);
    }

    final head = Offset(size.width * 0.79, size.height * 0.5);
    _drawSphere(canvas, head, radius * 1.12, color);
    final eyePaint = Paint()..color = const Color(0xfff7fbff);
    final pupilPaint = Paint()..color = const Color(0xff07111d);
    for (final side in const <double>[-1, 1]) {
      final eye = Offset(
        head.dx + radius * 0.43,
        head.dy + side * radius * 0.34,
      );
      canvas.drawCircle(eye, radius * 0.24, eyePaint);
      canvas.drawCircle(
        eye + Offset(radius * 0.07, 0),
        radius * 0.12,
        pupilPaint,
      );
    }
  }

  void _drawSphere(Canvas canvas, Offset center, double radius, Color base) {
    canvas.drawCircle(
      center + Offset(0, radius * 0.28),
      radius * 1.04,
      Paint()..color = const Color(0x60000000),
    );
    final paint =
        Paint()
          ..shader = ui.Gradient.radial(
            center + Offset(-radius * 0.36, -radius * 0.42),
            radius * 1.65,
            <Color>[
              Color.lerp(base, Colors.white, 0.72)!,
              base,
              Color.lerp(base, const Color(0xff030812), 0.56)!,
            ],
            const <double>[0, 0.45, 1],
            TileMode.clamp,
          );
    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7,
    );
  }

  @override
  bool shouldRepaint(covariant _SnekPreviewPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _SnekCard extends StatelessWidget {
  const _SnekCard({
    required this.snek,
    required this.selected,
    required this.onTap,
  });

  final SnekProfile snek;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent =
        ArenaSkin.snakeColours[snek.colorIndex
            .clamp(0, ArenaSkin.snakeColours.length - 1)
            .toInt()];
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xcc0b1727),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: selected ? accent : ArenaSkin.panelRim,
              width: selected ? 2 : 1,
            ),
            boxShadow:
                selected
                    ? <BoxShadow>[
                      BoxShadow(
                        color: accent.withValues(alpha: 0.16),
                        blurRadius: 18,
                        spreadRadius: 1,
                      ),
                    ]
                    : null,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        snek.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Icon(
                      selected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: 18,
                      color: selected ? accent : ArenaSkin.textMuted,
                    ),
                  ],
                ),
                Expanded(
                  child: SnekPreview(colorIndex: snek.colorIndex, height: 52),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.5),
                            blurRadius: 7,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      _snekColorNames[snek.colorIndex
                          .clamp(0, _snekColorNames.length - 1)
                          .toInt()],
                      style: const TextStyle(
                        color: ArenaSkin.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    const Spacer(),
                    if (snek.soulId != null)
                      const _SoulBoundBadge(),
                    if (selected)
                      Text(
                        'SELECTED',
                        style: TextStyle(
                          color: accent,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SoulBoundBadge extends StatelessWidget {
  const _SoulBoundBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ArenaSkin.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ArenaSkin.accent.withValues(alpha: 0.65)),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        child: Text(
          'SOUL BOUND',
          style: TextStyle(
            color: ArenaSkin.accent,
            fontSize: 8,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}

class _ColorChoice extends StatelessWidget {
  const _ColorChoice({
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$label skin',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 88,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.16) : Colors.white10,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: selected ? color : Colors.white12,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 21,
                height: 21,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-0.42, -0.48),
                    colors: [
                      Color.lerp(color, Colors.white, 0.58)!,
                      color,
                      Color.lerp(color, Colors.black, 0.28)!,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.36),
                      blurRadius: selected ? 12 : 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                  color: selected ? color : ArenaSkin.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x332c4059),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: ArenaSkin.panelRim),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        child: Text(
          '$count ${count == 1 ? 'SNEK' : 'SNEKS'}',
          style: const TextStyle(
            color: ArenaSkin.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ArenaSkin.accent.withValues(alpha: 0.12),
        border: Border.all(color: ArenaSkin.accent.withValues(alpha: 0.42)),
        boxShadow: const [BoxShadow(color: Color(0x55ffce78), blurRadius: 18)],
      ),
      child: const Icon(Icons.auto_awesome, color: ArenaSkin.accent, size: 28),
    );
  }
}

class _MenuBackdrop extends StatelessWidget {
  const _MenuBackdrop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const RepaintBoundary(child: CustomPaint(painter: _HexMenuPainter())),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topCenter,
              radius: 1.3,
              colors: [Color(0x99223c5a), Color(0x99091421), Color(0xee070d18)],
              stops: [0, 0.46, 1],
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _HexMenuPainter extends CustomPainter {
  const _HexMenuPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const radius = 26.0;
    const stepX = 53.0;
    const stepY = 47.0;
    final fill = Paint()..color = const Color(0xff0b1626);
    final edge =
        Paint()
          ..color = const Color(0xff1a2b41)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
    final path = Path();
    final columns = (size.width / stepX).ceil() + 2;
    final rows = (size.height / stepY).ceil() + 2;
    for (var row = -1; row < rows; row++) {
      for (var column = -1; column < columns; column++) {
        final center = Offset(
          column * stepX + (row.isEven ? 0 : stepX / 2),
          row * stepY,
        );
        path
          ..moveTo(center.dx + radius, center.dy)
          ..lineTo(center.dx + radius / 2, center.dy + radius * 0.866)
          ..lineTo(center.dx - radius / 2, center.dy + radius * 0.866)
          ..lineTo(center.dx - radius, center.dy)
          ..lineTo(center.dx - radius / 2, center.dy - radius * 0.866)
          ..lineTo(center.dx + radius / 2, center.dy - radius * 0.866)
          ..close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, edge);
        path.reset();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HexMenuPainter oldDelegate) => false;
}

const _primaryButtonStyle = ButtonStyle(
  padding: WidgetStatePropertyAll<EdgeInsets>(
    EdgeInsets.symmetric(horizontal: 18, vertical: 14),
  ),
  textStyle: WidgetStatePropertyAll<TextStyle>(
    TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.8),
  ),
  shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
    RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
  ),
);

const _secondaryButtonStyle = ButtonStyle(
  padding: WidgetStatePropertyAll<EdgeInsets>(
    EdgeInsets.symmetric(horizontal: 16, vertical: 13),
  ),
  foregroundColor: WidgetStatePropertyAll<Color>(ArenaSkin.textPrimary),
  backgroundColor: WidgetStatePropertyAll<Color>(Color(0x332a405a)),
  textStyle: WidgetStatePropertyAll<TextStyle>(
    TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.6),
  ),
  shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
    RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      side: BorderSide(color: ArenaSkin.panelRim),
    ),
  ),
);
