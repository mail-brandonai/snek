import 'dart:convert';

import 'package:flutter/material.dart';

import '../../game/presentation/arena_skin.dart';
import '../application/run_review.dart';
import '../application/soul_training.dart';
import '../data/training_review_services.dart';
import '../domain/soul_feature_extractor.dart';
import '../domain/training_models.dart';

class RunLibraryScreen extends StatefulWidget {
  const RunLibraryScreen({
    super.key,
    required this.onBack,
    this.initialRunId,
    this.service,
    this.soulTraining,
  });

  final VoidCallback onBack;
  final String? initialRunId;
  final RunReviewService? service;
  final SoulTrainingService? soulTraining;

  @override
  State<RunLibraryScreen> createState() => _RunLibraryScreenState();
}

class _SoulNameDialog extends StatefulWidget {
  const _SoulNameDialog();

  @override
  State<_SoulNameDialog> createState() => _SoulNameDialogState();
}

class _SoulNameDialogState extends State<_SoulNameDialog> {
  late final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isNotEmpty) Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('CREATE SOUL'),
    content: TextField(
      controller: _controller,
      autofocus: true,
      textCapitalization: TextCapitalization.words,
      decoration: const InputDecoration(labelText: 'Soul name'),
      onSubmitted: (_) => _submit(),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('CANCEL'),
      ),
      FilledButton(onPressed: _submit, child: const Text('CREATE SOUL')),
    ],
  );
}

enum _RunFilter { pending, retained, incomplete }

class _RunLibraryScreenState extends State<RunLibraryScreen> {
  late final Future<RunReviewService> _service;
  Future<SoulTrainingService>? _soulTraining;
  List<TrainingRun> _runs = const <TrainingRun>[];
  String? _selectedRunId;
  TrainingRun? _selectedRun;
  RunReviewItem? _selectedItem;
  _RunFilter _filter = _RunFilter.pending;
  bool _loading = true;
  bool _analysisLoading = false;
  bool _analysisExpanded = false;
  bool _busy = false;
  int _loadGeneration = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedRunId = widget.initialRunId;
    _service =
        widget.service == null
            ? TrainingReviewServices.runReviewService()
            : Future<RunReviewService>.value(widget.service!);
    _soulTraining =
        widget.soulTraining == null
            ? null
            : Future<SoulTrainingService>.value(widget.soulTraining!);
    _refresh();
  }

  Future<SoulTrainingService> get _soulTrainingService =>
      _soulTraining ??= TrainingReviewServices.soulTrainingService();

  Future<void> _refresh() async {
    final generation = ++_loadGeneration;
    setState(() {
      _loading = true;
      _analysisLoading = false;
      _analysisExpanded = false;
      _error = null;
    });
    try {
      final service = await _service;
      final runs = await service.listRuns();
      final selectedId = _selectedRunId;
      final selectedRun =
          selectedId == null ? null : await service.loadRunHeader(selectedId);
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _runs = runs;
        _selectedRun = selectedRun;
        _selectedItem = null;
        _loading = false;
        _analysisLoading = selectedRun != null;
      });
      if (selectedRun == null) return;

      final detail = await service.analyzeRun(selectedRun);
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _selectedItem = detail;
        _analysisLoading = false;
      });
    } catch (error) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _loading = false;
        _analysisLoading = false;
        _error = _errorMessage(error);
      });
    }
  }

  Future<void> _openRun(String runId) async {
    setState(() {
      _selectedRunId = runId;
      _selectedRun = null;
      _selectedItem = null;
      _loading = true;
      _analysisLoading = false;
      _analysisExpanded = false;
      _error = null;
    });
    await _refresh();
  }

  void _back() {
    if (_selectedRunId != null) {
      _loadGeneration++;
      setState(() {
        _selectedRunId = null;
        _selectedRun = null;
        _selectedItem = null;
        _analysisLoading = false;
        _analysisExpanded = false;
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
      builder:
          (context) => AlertDialog(
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

  SoulBehaviorSignature? _trainingSignature() {
    final item = _selectedItem;
    final signature = item?.featureAnalysis.signature;
    if (item == null || !item.featureAnalysis.isReady || signature == null) {
      _showMessage('Behavior evidence is not ready for Soul training.');
      return null;
    }
    return signature;
  }

  Future<void> _createSoul() async {
    final item = _selectedItem;
    if (item == null || _busy) return;
    final signature = _trainingSignature();
    if (signature == null) return;

    final name = await showDialog<String>(
      context: context,
      builder: (context) => const _SoulNameDialog(),
    );
    if (name == null || !mounted) return;

    setState(() => _busy = true);
    try {
      final soul = await (await _soulTrainingService).createFromRun(
        name: name,
        signature: signature,
      );
      _showMessage('Soul "${soul.name}" created from this run.');
    } catch (error) {
      _showMessage(_errorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refineSoul() async {
    final item = _selectedItem;
    if (item == null || _busy) return;
    final signature = _trainingSignature();
    if (signature == null) return;

    setState(() => _busy = true);
    try {
      final souls = await (await _soulTrainingService).listSouls();
      if (!mounted) return;
      if (souls.isEmpty) {
        _showMessage('Create a Soul before refining one.');
        return;
      }
      setState(() => _busy = false);
      final target = await showDialog<Soul>(
        context: context,
        builder:
            (context) => SimpleDialog(
              title: const Text('REFINE SOUL'),
              children: [
                for (final soul in souls)
                  SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, soul),
                    child: Text(soul.name),
                  ),
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL'),
                ),
              ],
            ),
      );
      if (target == null || !mounted) return;
      setState(() => _busy = true);
      final revision = await (await _soulTrainingService).refineFromRun(
        soul: target,
        signature: signature,
      );
      _showMessage('Soul "${target.name}" refined to ${revision.revisionId}.');
    } catch (error) {
      _showMessage(_errorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  List<TrainingRun> get _visibleRuns => _runs
      .where((run) {
        switch (_filter) {
          case _RunFilter.pending:
            return run.status == TrainingRunStatus.pendingReview;
          case _RunFilter.retained:
            return run.status == TrainingRunStatus.retained;
          case _RunFilter.incomplete:
            return run.status == TrainingRunStatus.incomplete;
        }
      })
      .toList(growable: false);

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
              child:
                  _loading
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
          onPressed: _loading || _analysisLoading || _busy ? null : _refresh,
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
                label: Text(
                  'PENDING ${_count(TrainingRunStatus.pendingReview)}',
                ),
                selected: _filter == _RunFilter.pending,
                onSelected: (_) => setState(() => _filter = _RunFilter.pending),
              ),
              ChoiceChip(
                label: Text('KEPT ${_count(TrainingRunStatus.retained)}'),
                selected: _filter == _RunFilter.retained,
                onSelected:
                    (_) => setState(() => _filter = _RunFilter.retained),
              ),
              ChoiceChip(
                label: Text(
                  'INCOMPLETE ${_count(TrainingRunStatus.incomplete)}',
                ),
                selected: _filter == _RunFilter.incomplete,
                onSelected:
                    (_) => setState(() => _filter = _RunFilter.incomplete),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child:
              visible.isEmpty
                  ? _messagePanel(switch (_filter) {
                    _RunFilter.pending => 'No pending runs.',
                    _RunFilter.retained => 'No kept runs.',
                    _RunFilter.incomplete => 'No incomplete runs.',
                  })
                  : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                    itemCount: visible.length,
                    separatorBuilder:
                        (context, index) => const SizedBox(height: 8),
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

  Widget _analysisLoadingDetail(TrainingRun run) {
    final configuredName = run.config['playerName'];
    final playerName =
        configuredName is String && configuredName.trim().isNotEmpty
            ? configuredName
            : 'Unknown Snek';
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
                          playerName,
                          style: const TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      _statusBadge(run.status),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${run.mode.toUpperCase()} run  ·  '
                    '${_formatDate(run.createdAtMs)}',
                    style: const TextStyle(color: ArenaSkin.textMuted),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _metric('Score', '—'),
                      _metric('Length', '—'),
                      _metric('Survival', '—'),
                      _metric('Rank', '—'),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _detailLine('Seed', run.seed.toString()),
                  _detailLine('Run ID', run.id),
                  const SizedBox(height: 20),
                  const Text(
                    'BEHAVIOR SIGNATURE',
                    style: TextStyle(
                      color: ArenaSkin.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 10),
                      Expanded(child: Text('Analyzing recorded behavior')),
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

  Widget _detail() {
    final item = _selectedItem;
    final run = item?.run ?? _selectedRun;
    if (run == null) {
      return _messagePanel('Run not found or no longer available.');
    }
    if (item == null) return _analysisLoadingDetail(run);
    final incomplete = item.run.status == TrainingRunStatus.incomplete;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _detailActions(item, incomplete),
        Expanded(
          child: SingleChildScrollView(
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
                              'Survival',
                              _formatDuration(item.survivalSeconds),
                            ),
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
                          'Player controls',
                          item.controlSampleCount.toString(),
                        ),
                        _detailLine(
                          'Actor observations',
                          item.observationSampleCount.toString(),
                        ),
                        _detailLine(
                          'Semantic events',
                          item.eventCount.toString(),
                        ),
                        _behaviorSignature(item.featureAnalysis),
                        if (incomplete) ...[
                          const SizedBox(height: 16),
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              color: Color(0x332d87c8),
                              borderRadius: BorderRadius.all(
                                Radius.circular(10),
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                'This run was interrupted or its recording did '
                                'not finish. It remains incomplete and cannot '
                                'be used as complete training evidence.',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _detailActions(RunReviewItem item, bool incomplete) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xff101d2a),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ArenaSkin.panelRim),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (item.run.status == TrainingRunStatus.pendingReview)
                    FilledButton.icon(
                      onPressed: _busy ? null : _keepRun,
                      icon: const Icon(Icons.bookmark_add_outlined),
                      label: const Text('KEEP RUN'),
                    ),
                  if (item.run.status == TrainingRunStatus.retained) ...[
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _createSoul,
                      icon: const Icon(Icons.auto_awesome_outlined),
                      label: const Text('CREATE SOUL'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _refineSoul,
                      icon: const Icon(Icons.tune),
                      label: const Text('REFINE SOUL'),
                    ),
                  ],
                  if (item.run.status != TrainingRunStatus.recording)
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _confirmDiscard,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('DISCARD RUN'),
                    ),
                  if (incomplete)
                    const Text(
                      'Inspection only',
                      style: TextStyle(color: ArenaSkin.textMuted),
                    ),
                  if (_busy)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
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
    const heading = Text(
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
          Row(
            children: [
              const Expanded(
                child: Text(
                  'BEHAVIOR SIGNATURE',
                  style: TextStyle(
                    color: ArenaSkin.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed:
                    () =>
                        setState(() => _analysisExpanded = !_analysisExpanded),
                icon: Icon(
                  _analysisExpanded ? Icons.unfold_less : Icons.unfold_more,
                ),
                label: Text(_analysisExpanded ? 'COLLAPSE' : 'EXPAND ANALYSIS'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${signature.featureVersion} · '
            '${signature.controlSampleCount} controls · '
            '${signature.observationSampleCount} observations · '
            '${signature.eventCount} events',
            style: const TextStyle(color: ArenaSkin.textMuted),
          ),
          if (_analysisExpanded) ...[
            const SizedBox(height: 10),
            for (final trait in signature.traits)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: const Color(0x332f4b64),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                    childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    title: Row(
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
                    subtitle: Text(
                      '${trait.sampleCount} samples · '
                      '${trait.opportunityCount} opportunities · '
                      '${(trait.coverage * 100).round()}% coverage',
                      style: const TextStyle(color: ArenaSkin.textMuted),
                    ),
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'OBSERVED EVIDENCE',
                          style: TextStyle(
                            color: ArenaSkin.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SelectableText(
                          jsonEncode(trait.observedEvidence),
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'INFERRED INTERPRETATION',
                          style: TextStyle(
                            color: ArenaSkin.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          trait.inferredInterpretation ??
                              'No interpretation available.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                color: const Color(0x332f4b64),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Material(
                color: Colors.transparent,
                child: ExpansionTile(
                  title: const Text(
                    'PRESSURE EPISODES',
                    style: TextStyle(
                      color: ArenaSkin.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                  subtitle: Text(
                    signature.pressureEpisodes.isEmpty
                        ? 'No episodes recorded'
                        : '${signature.pressureEpisodes.length} episodes',
                    style: const TextStyle(color: ArenaSkin.textMuted),
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  children: [
                    if (signature.pressureEpisodes.isEmpty)
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'No pressure episodes were recorded. Threat response '
                          'has insufficient evidence.',
                          style: TextStyle(color: ArenaSkin.textMuted),
                        ),
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(_pressureEpisodeResponse(episode)),
                              Text(
                                _pressureEpisodeOutcome(episode),
                                style: const TextStyle(
                                  color: ArenaSkin.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
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
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
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
          child: Text(
            label,
            style: const TextStyle(color: ArenaSkin.textMuted),
          ),
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
    final color =
        status == TrainingRunStatus.incomplete
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
  'timeLimit' => 'Time limit',
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
