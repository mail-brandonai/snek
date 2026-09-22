import 'package:flutter/material.dart';

import '../../game/presentation/arena_skin.dart';
import '../../game/presentation/snek_pen.dart';
import '../application/soul_training.dart';
import '../data/training_review_services.dart';
import '../domain/training_models.dart';

class SoulStudioScreen extends StatefulWidget {
  const SoulStudioScreen({
    super.key,
    required this.sneks,
    required this.selectedSnekId,
    required this.onBack,
    required this.onBind,
    this.training,
  });

  final List<SnekProfile> sneks;
  final String selectedSnekId;
  final VoidCallback onBack;
  final Future<void> Function(String snekId, String? soulId) onBind;
  final SoulTrainingService? training;

  @override
  State<SoulStudioScreen> createState() => _SoulStudioScreenState();
}

class _SoulStudioScreenState extends State<SoulStudioScreen> {
  late Future<List<_SoulStudioItem>> _items;
  late String _selectedSnekId;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _selectedSnekId = widget.selectedSnekId;
    _items = _loadItems();
  }

  @override
  void didUpdateWidget(covariant SoulStudioScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.sneks.any((snek) => snek.id == _selectedSnekId)) {
      _selectedSnekId = widget.selectedSnekId;
    }
  }

  Future<List<_SoulStudioItem>> _loadItems() async {
    final service =
        widget.training ?? await TrainingReviewServices.soulTrainingService();
    final souls = await service.listSouls();
    final items = await Future.wait(
      souls.map((soul) async {
        final revisions = await service.listRevisions(soul.id);
        return _SoulStudioItem(
          soul: soul,
          revisions: revisions,
          latest: revisions.isEmpty
              ? null
              : SoulTrainer.latestRevision(revisions),
        );
      }),
    );
    items.sort(
      (left, right) => right.soul.createdAtMs.compareTo(left.soul.createdAtMs),
    );
    return items;
  }

  void _refresh() {
    setState(() => _items = _loadItems());
  }

  Future<void> _setBinding(String? soulId) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onBind(_selectedSnekId, soulId);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              soulId == null ? 'Soul unbound.' : 'Soul binding saved.',
            ),
          ),
        );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.sneks.firstWhere(
      (snek) => snek.id == _selectedSnekId,
      orElse: () => widget.sneks.first,
    );
    return Scaffold(
      backgroundColor: ArenaSkin.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: widget.onBack,
                        tooltip: 'Back',
                        icon: const Icon(Icons.arrow_back),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SOUL STUDIO',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                            Text(
                              'Pin a learned Soul to a Snek profile.',
                              style: TextStyle(
                                fontSize: 12,
                                color: ArenaSkin.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _refresh,
                        tooltip: 'Refresh Souls',
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                  const SizedBox(height: 17),
                  DecoratedBox(
                    decoration: ArenaSkin.glassPanel(
                      borderColor: const Color(0xff506d8b),
                      radius: 18,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 92,
                            height: 54,
                            child: SnekPreview(
                              colorIndex: selected.colorIndex,
                              height: 54,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedSnekId,
                              decoration: const InputDecoration(
                                labelText: 'SNEK PROFILE',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                for (final snek in widget.sneks)
                                  DropdownMenuItem<String>(
                                    value: snek.id,
                                    child: Text(snek.name),
                                  ),
                              ],
                              onChanged: _busy
                                  ? null
                                  : (value) {
                                      if (value != null) {
                                        setState(
                                          () => _selectedSnekId = value,
                                        );
                                      }
                                    },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              selected.soulId == null
                                  ? 'No Soul bound'
                                  : 'Bound Soul: ${selected.soulId}',
                              style: const TextStyle(
                                color: ArenaSkin.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: FutureBuilder<List<_SoulStudioItem>>(
                      future: _items,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const _SoulStudioLoading();
                        }
                        if (snapshot.hasError) {
                          return _SoulStudioError(
                            message: snapshot.error.toString(),
                            onRetry: _refresh,
                          );
                        }
                        final items =
                            snapshot.data ?? const <_SoulStudioItem>[];
                        if (items.isEmpty) {
                          return const Center(
                            child: Text(
                              'No Souls created yet.',
                              style: TextStyle(color: ArenaSkin.textMuted),
                            ),
                          );
                        }
                        return ListView.separated(
                          padding: const EdgeInsets.only(bottom: 12),
                          itemCount: items.length,
                          separatorBuilder: (_, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return _SoulStudioCard(
                              item: item,
                              bound: selected.soulId == item.soul.id,
                              busy: _busy,
                              onPressed: () => _setBinding(
                                selected.soulId == item.soul.id
                                    ? null
                                    : item.soul.id,
                              ),
                            );
                          },
                        );
                      },
                    ),
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

class _SoulStudioItem {
  const _SoulStudioItem({
    required this.soul,
    required this.revisions,
    required this.latest,
  });

  final Soul soul;
  final List<SoulRevision> revisions;
  final SoulRevision? latest;
}

class _SoulStudioCard extends StatelessWidget {
  const _SoulStudioCard({
    required this.item,
    required this.bound,
    required this.busy,
    required this.onPressed,
  });

  final _SoulStudioItem item;
  final bool bound;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final latest = item.latest;
    return DecoratedBox(
      decoration: ArenaSkin.glassPanel(
        borderColor: bound ? ArenaSkin.accent : ArenaSkin.panelRim,
        radius: 18,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  color: ArenaSkin.accent,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.soul.name,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (bound)
                  const Text(
                    'PINNED',
                    style: TextStyle(
                      color: ArenaSkin.accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              '${item.revisions.length} '
              '${item.revisions.length == 1 ? 'revision' : 'revisions'}',
              style: const TextStyle(
                color: ArenaSkin.textMuted,
                fontSize: 12,
              ),
            ),
            if (latest != null) ...[
              const SizedBox(height: 10),
              Text(
                'Latest ${latest.revisionId}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                '${latest.trainerVersion} · ${latest.featureVersion} · '
                '${latest.sourceRunIds.length} source run(s)',
                style: const TextStyle(
                  color: ArenaSkin.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: busy ? null : onPressed,
                icon: Icon(
                  bound ? Icons.link_off_outlined : Icons.link_outlined,
                ),
                label: Text(bound ? 'UNBIND SOUL' : 'BIND TO SNEK'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoulStudioLoading extends StatelessWidget {
  const _SoulStudioLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _SoulStudioError extends StatelessWidget {
  const _SoulStudioError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Soul Studio unavailable.'),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ArenaSkin.textMuted,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('RETRY'),
          ),
        ],
      ),
    );
  }
}
