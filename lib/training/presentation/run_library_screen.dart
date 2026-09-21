import 'dart:convert';

import 'package:flutter/material.dart';

import '../../game/presentation/arena_skin.dart';
import '../application/run_review.dart';
import '../data/training_services.dart';
import '../domain/soul_feature_extractor.dart';
import '../domain/training_models.dart';

class RunLibraryScreen extends StatefulWidget {
  const RunLibraryScreen({
    super.key,
    required this.onBack,
    this.initialRunId,
    this.service,
  });

  final VoidCallback onBack;
  final String? initialRunId;
  final RunReviewService? service;

  @override
  State<RunLibraryScreen> createState() => _RunLibraryScreenState();
}

enum _RunFilter { pending, retained, incomplete }

class _RunLibraryScreenState extends State<RunLibraryScreen> {
  late final Future<RunReviewService> _service;
  List<TrainingRun> _runs = const <TrainingRun>[];
  String? _selectedRunId;
  RunReviewItem? _selectedItem;
  _RunFilter _filter = _RunFilter.pending;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedRunId = widget.initialRunId;
    _service = widget.service == null
        ? TrainingServices.runReviewService()
        : Future<RunReviewService>.value(widget.service!);
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service = await _service;
      final runs = await service.listRuns();
      final selectedId = _selectedRunId;
      final detail =
          selectedId == null ? null : await service.loadRun(selectedId);
      if (!mounted) return;
      setState(() {
        _runs = runs;
        _selectedItem = detail;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _errorMessage(error);
      });
    }
  }

  Future<void> _openRun(String runId) async {
    setState(() {
      _selectedRunId = runId;
      _selectedItem = null;
      _loading = true;
      _error = null;
    });
    await _refresh();
  }

  void _back() {
    if (_selectedRunId != null) {
      setState(() {
        _selectedRunId = null;
        _selectedItem = null;
        _error = null;
      });
      return;
    }
    widget.onBack();
  }

  Future<void> _keepRun() async {
    final item = _selectedItem;
    if (item == null || _busy) return;
    setState(() => _busy = true);
    try {
      await (await _service).keepRun(item.run.id);
      await _refresh();
      _showMessage('Run kept. No Soul was created or changed.');
    } catch (error) {
      _showMessage(_errorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmDiscard() async {
    final item = _selectedItem;
    if (item == null || _busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard this run?'),
        content: const Text(
          'This permanently deletes the run and its recorded chunks. '
          'A run referenced by a Soul cannot be discarded.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DISCARD RUN'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await (await _service).discardRun(item.run.id);
      setState(() {
        _selectedRunId = null;
        _selectedItem = null;
      });
      await _refresh();
      _showMessage('Run and recorded chunks discarded.');
    } catch (error) {
      _showMessage(_errorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showSoulActionStub(bool refine) async {
    final message = refine
        ? 'Choose a target Soul before refining. Soul selection and training '
            'are scheduled for later sprints; no data was changed.'
        : 'Soul creation and training are scheduled for Sprint 5. '
            'This run remains unchanged.';
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(refine ? 'REFINE SOUL' : 'CREATE SOUL'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  List<TrainingRun> get _visibleRuns => _runs.where((run) {
        switch (_filter) {
          case _RunFilter.pending:
            return run.status == TrainingRunStatus.pendingReview;
          case _RunFilter.retained:
            return run.status == TrainingRunStatus.retained;
          case _RunFilter.incomplete:
            return run.status == TrainingRunStatus.incomplete;
        }
      }).toList(growable: false);

  int _count(TrainingRunStatus status) =>
      _runs.where((run) => run.status == status).length;

  @override
  Widget build(BuildContext context) {
    final isDetail = _selectedRunId != null;
    return Scaffold(
      backgroundColor: ArenaSkin.background,
      body: SafeArea(
        child: Column(
          children: [
            _header(isDetail),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _messagePanel(_error!)
                      : isDetail
                          ? _detail()
                          : _library(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(bool isDetail) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 18, 12),
        child: Row(
          children: [
            IconButton(
              onPressed: _back,
              tooltip: isDetail ? 'Back to Run Library' : 'Back',
              icon: const Icon(Icons.arrow_back),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                isDetail ? 'RUN DEBRIEF' : 'RUN LIBRARY',
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.6,
                ),
              ),
            ),
            IconButton(
              onPressed: _loading || _busy ? null : _refresh,
              tooltip: 'Refresh runs',
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      );

  Widget _library() {
    final visible = _visibleRuns;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label:
                    Text('PENDING ${_count(TrainingRunStatus.pendingReview)}'),
                selected: _filter == _RunFilter.pending,
                onSelected: (_) => setState(() => _filter = _RunFilter.pending),
              ),
              ChoiceChip(
                label: Text('KEPT ${_count(TrainingRunStatus.retained)}'),
                selected: _filter == _RunFilter.retained,
                onSelected: (_) =>
                    setState(() => _filter = _RunFilter.retained),
              ),
              ChoiceChip(
                label:
                    Text('INCOMPLETE ${_count(TrainingRunStatus.incomplete)}'),
                selected: _filter == _RunFilter.incomplete,
                onSelected: (_) =>
                    setState(() => _filter = _RunFilter.incomplete),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: visible.isEmpty
              ? _messagePanel(
                  switch (_filter) {
                    _RunFilter.pending => 'No pending runs.',
                    _RunFilter.retained => 'No kept runs.',
                    _RunFilter.incomplete => 'No incomplete runs.',
                  },
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  itemCount: visible.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final run = visible[index];
                    final playerName = run.config['playerName'];
                    final title =
                        playerName is String ? playerName : 'Unknown Snek';
                    return Card(
                      color: const Color(0xff101d2a),
                      child: ListTile(
                        title: Text(title),
                        subtitle: Text(
                          '${run.mode.toUpperCase()}  ·  Seed ${run.seed}  ·  '
                          '${_formatDate(run.createdAtMs)}',
                        ),
                        trailing: _statusBadge(run.status),
                        onTap: () => _openRun(run.id),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _detail() {
    final item = _selectedItem;
    if (item == null) {
      return _messagePanel('Run not found or no longer available.');
    }
    final incomplete = item.run.status == TrainingRunStatus.incomplete;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Card(
            color: const Color(0xff101d2a),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.playerName,
                          style: const TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      _statusBadge(item.run.status),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${item.run.mode.toUpperCase()} run  ·  '
                    '${_formatDate(item.run.createdAtMs)}',
                    style: const TextStyle(color: ArenaSkin.textMuted),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _metric('Score', item.score?.toString() ?? '—'),
                      _metric('Length', item.length?.toString() ?? '—'),
                      _metric(
                          'Survival', _formatDuration(item.survivalSeconds)),
                      _metric('Rank', item.rank?.toString() ?? '—'),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _detailLine('Outcome', _outcomeLabel(item.outcome)),
                  _detailLine('Seed', item.run.seed.toString()),
                  _detailLine('Run ID', item.run.id),
                  const SizedBox(height: 14),
                  const Text(
                    'AVAILABLE SAMPLE COVERAGE',
                    style: TextStyle(
                      color: ArenaSkin.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _detailLine(
                      'Player controls', item.controlSampleCount.toString()),
                  _detailLine(
                    'Actor observations',
                    item.observationSampleCount.toString(),
                  ),
                  _detailLine('Semantic events', item.eventCount.toString()),
                  _behaviorSignature(item.featureAnalysis),
                  if (incomplete) ...[
                    const SizedBox(height: 16),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color(0x332d87c8),
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          'This run was interrupted or its recording did not '
                          'finish. It remains incomplete and cannot be used as '
                          'complete training evidence.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  if (item.run.status == TrainingRunStatus.pendingReview ||
                      item.run.status == TrainingRunStatus.retained)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (item.run.status == TrainingRunStatus.pendingReview)
                          FilledButton.icon(
                            onPressed: _busy ? null : _keepRun,
                            icon: const Icon(Icons.bookmark_add_outlined),
                            label: const Text('KEEP RUN'),
                          ),
                        OutlinedButton.icon(
                          onPressed:
                              _busy ? null : () => _showSoulActionStub(false),
                          icon: const Icon(Icons.auto_awesome_outlined),
                          label: const Text('CREATE SOUL'),
                        ),
                        OutlinedButton.icon(
                          onPressed:
                              _busy ? null : () => _showSoulActionStub(true),
                          icon: const Icon(Icons.tune),
                          label: const Text('REFINE SOUL'),
                        ),
                      ],
                    ),
                  if (item.run.status == TrainingRunStatus.incomplete)
                    const Text(
                      'Incomplete runs can be inspected or discarded. '
                      'Keeping or training from them is unavailable.',
                      style: TextStyle(color: ArenaSkin.textMuted),
                    ),
                  const SizedBox(height: 8),
                  if (item.run.status != TrainingRunStatus.recording)
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _confirmDiscard,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('DISCARD RUN'),
                    ),
                  if (_busy) ...[
                    const SizedBox(height: 12),
                    const Center(child: CircularProgressIndicator()),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _behaviorSignature(SoulFeatureExtractionResult result) {
    final signature = result.signature;
    final heading = const Text(
      'BEHAVIOR SIGNATURE',
      style: TextStyle(
        color: ArenaSkin.accent,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
      ),
    );
    if (!result.isReady || signature == null) {
      return Padding(
        padding: const EdgeInsets.only(top: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            heading,
            const SizedBox(height: 8),
            Text(result.message ?? 'Behavior evidence is unavailable.'),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          heading,
          const SizedBox(height: 8),
          Text(
            '${signature.featureVersion} · '
            '${signature.controlSampleCount} controls · '
            '${signature.observationSampleCount} observations · '
            '${signature.eventCount} events',
            style: const TextStyle(color: ArenaSkin.textMuted),
          ),
          const SizedBox(height: 10),
          for (final trait in signature.traits)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0x332f4b64),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          trait.label,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        _confidenceLabel(trait.confidence),
                        style: const TextStyle(
                          color: ArenaSkin.accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${trait.sampleCount} samples · '
                    '${trait.opportunityCount} opportunities · '
                    '${(trait.coverage * 100).round()}% coverage',
                    style: const TextStyle(color: ArenaSkin.textMuted),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'OBSERVED EVIDENCE',
                    style: TextStyle(
                      color: ArenaSkin.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                  SelectableText(jsonEncode(trait.observedEvidence)),
                  const SizedBox(height: 5),
                  const Text(
                    'INFERRED INTERPRETATION',
                    style: TextStyle(
                      color: ArenaSkin.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                  Text(
                    trait.inferredInterpretation ??
                        'No interpretation available.',
                  ),
                ],
              ),
            ),
          const SizedBox(height: 6),
          const Text(
            'PRESSURE EPISODES',
            style: TextStyle(
              color: ArenaSkin.accent,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          if (signature.pressureEpisodes.isEmpty)
            const Text(
              'No pressure episodes were recorded. Threat response has '
              'insufficient evidence.',
              style: TextStyle(color: ArenaSkin.textMuted),
            ),
          for (final episode in signature.pressureEpisodes)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0x332f4b64),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _pressureEpisodeTitle(episode),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(_pressureEpisodeResponse(episode)),
                    Text(
                      _pressureEpisodeOutcome(episode),
                      style: const TextStyle(color: ArenaSkin.textMuted),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) => DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0x332f4b64),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: ArenaSkin.textMuted)),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _detailLine(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 150,
              child: Text(label,
                  style: const TextStyle(color: ArenaSkin.textMuted)),
            ),
            Expanded(child: SelectableText(value)),
          ],
        ),
      );

  Widget _messagePanel(String message) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: ArenaSkin.textMuted),
          ),
        ),
      );

  Widget _statusBadge(TrainingRunStatus status) {
    final label = switch (status) {
      TrainingRunStatus.pendingReview => 'PENDING',
      TrainingRunStatus.retained => 'KEPT',
      TrainingRunStatus.incomplete => 'INCOMPLETE',
      TrainingRunStatus.recording => 'RECORDING',
      TrainingRunStatus.discarded => 'DISCARDED',
    };
    final color = status == TrainingRunStatus.incomplete
        ? ArenaSkin.danger
        : ArenaSkin.accent;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.7)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

String _pressureEpisodeTitle(PressureEpisodeSummary episode) {
  final maneuver = episode.actorManeuver;
  return '${episode.actorId} · tick ${episode.onsetTick}'
      '${maneuver == null ? '' : ' · $maneuver'}';
}

String _pressureEpisodeResponse(PressureEpisodeSummary episode) {
  final urgency = episode.urgencyAtOnset?.toStringAsFixed(2) ?? '—';
  final latency = episode.responseLatencyTicks?.toString() ?? '—';
  final duration = episode.durationSeconds?.toStringAsFixed(2) ?? '—';
  return 'Urgency $urgency · response ${episode.responseAction}'
      ' · latency $latency ticks · duration $duration s';
}

String _pressureEpisodeOutcome(PressureEpisodeSummary episode) =>
    'Outcome: ${episode.outcome} · collisions: ${episode.playerCollisionCount}'
    ' · sprint requested: ${episode.sprintRequestedDuringEpisode}';

String _confidenceLabel(FeatureConfidence confidence) => switch (confidence) {
      FeatureConfidence.insufficient => 'INSUFFICIENT EVIDENCE',
      FeatureConfidence.low => 'LOW CONFIDENCE',
      FeatureConfidence.moderate => 'MODERATE CONFIDENCE',
      FeatureConfidence.high => 'HIGH CONFIDENCE',
    };

String _outcomeLabel(String? outcome) => switch (outcome) {
      'bodyCollision' => 'Body collision',
      'boundary' => 'Arena boundary',
      null || '' => 'Outcome unavailable',
      _ => outcome,
    };

String _formatDate(int milliseconds) {
  final value = DateTime.fromMillisecondsSinceEpoch(milliseconds).toLocal();
  final date = value.toIso8601String().replaceFirst('T', ' ');
  return date.substring(0, 16);
}

String _formatDuration(double? seconds) {
  if (seconds == null || !seconds.isFinite || seconds < 0) return '—';
  final total = seconds.floor();
  final minutes = (total ~/ 60).toString().padLeft(2, '0');
  final remainder = (total % 60).toString().padLeft(2, '0');
  return '$minutes:$remainder';
}

String _errorMessage(Object error) =>
    error.toString().replaceFirst('Bad state: ', '');
