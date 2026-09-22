import 'package:flutter/material.dart';

import '../application/soul_training.dart';
import '../data/training_review_services.dart';
import '../domain/training_models.dart';
import '../../game/presentation/arena_skin.dart';

class SoulLibraryScreen extends StatefulWidget {
  const SoulLibraryScreen({
    super.key,
    required this.onBack,
    this.training,
  });

  final VoidCallback onBack;
  final SoulTrainingService? training;

  @override
  State<SoulLibraryScreen> createState() => _SoulLibraryScreenState();
}

class _SoulLibraryScreenState extends State<SoulLibraryScreen> {
  late Future<List<_SoulLibraryItem>> _items;

  @override
  void initState() {
    super.initState();
    _items = _loadItems();
  }

  Future<List<_SoulLibraryItem>> _loadItems() async {
    final service =
        widget.training ?? await TrainingReviewServices.soulTrainingService();
    final souls = await service.listSouls();
    final items = await Future.wait(
      souls.map((soul) async {
        final revisions = await service.listRevisions(soul.id);
        return _SoulLibraryItem(
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

  @override
  Widget build(BuildContext context) {
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
                              'SOUL LIBRARY',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                            Text(
                              'Browse learned behavior before binding it.',
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
                  Expanded(
                    child: FutureBuilder<List<_SoulLibraryItem>>(
                      future: _items,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const _SoulLibraryLoading();
                        }
                        if (snapshot.hasError) {
                          return _SoulLibraryError(
                            message: snapshot.error.toString(),
                            onRetry: _refresh,
                          );
                        }
                        final items = snapshot.data ?? const <_SoulLibraryItem>[];
                        if (items.isEmpty) {
                          return const _SoulLibraryEmpty();
                        }
                        return ListView.separated(
                          padding: const EdgeInsets.only(bottom: 12),
                          itemCount: items.length,
                          separatorBuilder: (_, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) =>
                              _SoulCard(item: items[index]),
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

class _SoulLibraryItem {
  const _SoulLibraryItem({
    required this.soul,
    required this.revisions,
    required this.latest,
  });

  final Soul soul;
  final List<SoulRevision> revisions;
  final SoulRevision? latest;
}

class _SoulCard extends StatelessWidget {
  const _SoulCard({required this.item});

  final _SoulLibraryItem item;

  @override
  Widget build(BuildContext context) {
    final latest = item.latest;
    final sourceRuns = latest?.sourceRunIds ?? const <String>[];
    return DecoratedBox(
      decoration: ArenaSkin.glassPanel(
        borderColor: const Color(0xff506d8b),
        radius: 18,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  '\${item.revisions.length} '
                  '\${item.revisions.length == 1 ? 'REVISION' : 'REVISIONS'}',
                  style: const TextStyle(
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
              'Created \${_formatDate(item.soul.createdAtMs)}',
              style: const TextStyle(
                color: ArenaSkin.textMuted,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'LATEST REVISION',
              style: TextStyle(
                color: ArenaSkin.accent,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 7),
            if (latest == null)
              const Text(
                'No revision has been saved yet.',
                style: TextStyle(color: ArenaSkin.textMuted),
              )
            else ...[
              Text(
                latest.revisionId,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                '\${latest.trainerVersion} · \${latest.featureVersion}',
                style: const TextStyle(
                  color: ArenaSkin.textMuted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'TRAIT WEIGHTS',
                style: TextStyle(
                  color: ArenaSkin.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  for (final entry in latest.weights.entries)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0x332c4059),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: ArenaSkin.panelRim),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 7,
                        ),
                        child: Text(
                          '\${entry.key} \${(entry.value * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'SOURCE RUNS  \${sourceRuns.length}',
                style: const TextStyle(
                  color: ArenaSkin.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              if (sourceRuns.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  sourceRuns.join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _SoulLibraryLoading extends StatelessWidget {
  const _SoulLibraryLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: ArenaSkin.accent),
          SizedBox(height: 12),
          Text(
            'Loading Souls',
            style: TextStyle(color: ArenaSkin.textMuted),
          ),
        ],
      ),
    );
  }
}

class _SoulLibraryEmpty extends StatelessWidget {
  const _SoulLibraryEmpty();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'No Souls created yet.',
        style: TextStyle(color: ArenaSkin.textMuted),
      ),
    );
  }
}

class _SoulLibraryError extends StatelessWidget {
  const _SoulLibraryError({
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
          const Text('Soul Library unavailable.'),
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

String _formatDate(int millisecondsSinceEpoch) {
  final date = DateTime.fromMillisecondsSinceEpoch(
    millisecondsSinceEpoch,
  ).toLocal();
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  return '\${date.year}-\${twoDigits(date.month)}-\${twoDigits(date.day)}';
}
