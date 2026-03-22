import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/components/chip_tab_switcher.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/repositories/student_repository.dart';
import 'package:tattoo/screens/main/score/score_providers.dart';
import 'package:tattoo/screens/main/score/score_screen_actions.dart';
import 'package:tattoo/screens/main/score/score_view_helpers.dart';

class ScoreScreen extends ConsumerStatefulWidget {
  const ScoreScreen({super.key});

  @override
  ConsumerState<ScoreScreen> createState() => _ScoreScreenState();
}

class _ScoreScreenState extends ConsumerState<ScoreScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  String? _selectedSemesterKey;
  TabController? _semesterTabController;
  int _semesterTabLength = 0;

  @override
  void dispose() {
    _semesterTabController?.removeListener(_handleSemesterTabChanged);
    _semesterTabController?.dispose();
    super.dispose();
  }

  void _dismissRefreshSnackBar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification ||
        notification is UserScrollNotification) {
      _dismissRefreshSnackBar();
    }
    return false;
  }

  int _findPreferredSemesterIndex(List<SemesterRecordData> records) {
    if (_selectedSemesterKey == null) return -1;
    return records.indexWhere(
      (record) => semesterKey(record) == _selectedSemesterKey,
    );
  }

  int _findDefaultSemesterIndex(List<SemesterRecordData> records) {
    final index = records.indexWhere((record) => record.scores.isNotEmpty);
    return index >= 0 ? index : 0;
  }

  void _handleSemesterTabChanged() {
    final controller = _semesterTabController;
    if (controller == null || controller.indexIsChanging || !mounted) return;

    if (_selectedIndex == controller.index) return;

    setState(() {
      _dismissRefreshSnackBar();
      _selectedIndex = controller.index;
    });
  }

  void _syncSemesterTabController(List<SemesterRecordData> records) {
    if (records.isEmpty) {
      _semesterTabController?.removeListener(_handleSemesterTabChanged);
      _semesterTabController?.dispose();
      _semesterTabController = null;
      _semesterTabLength = 0;
      _selectedIndex = 0;
      _selectedSemesterKey = null;
      return;
    }

    final preferredIndex = _findPreferredSemesterIndex(records);
    final initialIndex = preferredIndex >= 0
        ? preferredIndex
        : _findDefaultSemesterIndex(records);

    if (_semesterTabController == null ||
        _semesterTabLength != records.length) {
      _semesterTabController?.removeListener(_handleSemesterTabChanged);
      _semesterTabController?.dispose();
      _semesterTabController = TabController(
        length: records.length,
        initialIndex: initialIndex,
        vsync: this,
      )..addListener(_handleSemesterTabChanged);
      _semesterTabLength = records.length;
      _selectedIndex = initialIndex;
      return;
    }

    final targetIndex = _selectedIndex >= records.length
        ? initialIndex
        : _selectedIndex;
    if (_semesterTabController!.index != targetIndex) {
      _semesterTabController!.index = targetIndex;
    }
    _selectedIndex = targetIndex;
  }

  Future<void> _reloadScores() async {
    try {
      await refreshSemesterRecords(ref);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.score.refreshSuccess)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.score.refreshFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final recordsAsync = ref.watch(semesterRecordsProvider);

    return Scaffold(
      body: recordsAsync.when(
        loading: () => CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              title: Text(t.nav.scores),
              centerTitle: true,
            ),
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
        error: (err, stack) => CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              title: Text(t.nav.scores),
              centerTitle: true,
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('${t.score.loadFailed}\n$err')),
            ),
          ],
        ),
        data: (records) {
          _syncSemesterTabController(records);

          final hasRecords = records.isNotEmpty;
          if (hasRecords) {
            final activeIndex = _semesterTabController?.index ?? _selectedIndex;
            _selectedIndex = activeIndex >= records.length ? 0 : activeIndex;
            _selectedSemesterKey = semesterKey(records[_selectedIndex]);
          }

          return NotificationListener<ScrollNotification>(
            onNotification: _handleScrollNotification,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  pinned: true,
                  title: Text(t.nav.scores),
                  centerTitle: true,
                  bottom: _semesterTabController != null && records.isNotEmpty
                      ? PreferredSize(
                          preferredSize: const Size.fromHeight(52),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            child: SizedBox(
                              height: 40,
                              child: ChipTabSwitcher(
                                tabs: [
                                  for (final record in records)
                                    '${record.summary.year}-${record.summary.term}',
                                ],
                                controller: _semesterTabController,
                                padding: EdgeInsets.zero,
                                spacing: 6,
                              ),
                            ),
                          ),
                        )
                      : null,
                ),
                if (!hasRecords)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text(t.score.noRecords)),
                  )
                else ...[
                  SliverFillRemaining(
                    child: TabBarView(
                      controller: _semesterTabController,
                      children: [
                        for (final record in records)
                          _SemesterScoreList(
                            record: record,
                            onRefresh: _reloadScores,
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SemesterScoreList extends StatelessWidget {
  final SemesterRecordData record;
  final Future<void> Function() onRefresh;

  const _SemesterScoreList({
    required this.record,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 8, bottom: 12),
        itemCount: record.scores.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _SemesterSummaryCard(summary: record.summary);
          }
          if (index == 1) {
            if (record.scores.isNotEmpty) return const SizedBox(height: 8);
            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Center(child: Text(t.score.noScoresThisSemester)),
            );
          }

          final scoreIndex = index - 2;
          final score = record.scores[scoreIndex];
          return Column(
            children: [
              _ScoreTile(score: score),
              if (scoreIndex != record.scores.length - 1)
                const Divider(height: 1, indent: 16),
            ],
          );
        },
      ),
    );
  }
}

class _SemesterSummaryCard extends StatelessWidget {
  final UserAcademicSummary summary;

  const _SemesterSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            primary: false,
            physics: const ClampingScrollPhysics(),
            child: Row(
              children: [
                _buildStat(
                  context,
                  t.score.summary.cumulativeGpa,
                  _formatDouble(summary.gpa),
                ),
                const SizedBox(width: 24),
                _buildStat(
                  context,
                  t.score.summary.conduct,
                  summary.conduct?.toString() ?? '-',
                ),
                const SizedBox(width: 24),
                _buildStat(
                  context,
                  t.score.summary.semesterAverage,
                  summary.average?.toString() ?? '-',
                ),
                const SizedBox(width: 24),
                _buildStat(
                  context,
                  t.score.summary.creditsPassed,
                  summary.creditsPassed?.toString() ?? '-',
                ),
                const SizedBox(width: 24),
                _buildStat(
                  context,
                  t.score.summary.totalCredits,
                  summary.totalCredits?.toString() ?? '-',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDouble(double? value) {
    if (value == null) return '-';
    return value.toStringAsFixed(2);
  }

  Widget _buildStat(BuildContext context, String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}

class _ScoreTile extends StatelessWidget {
  final ScoreDetail score;

  const _ScoreTile({required this.score});

  @override
  Widget build(BuildContext context) {
    final scoreColor = getScoreColor(context, score);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      title: Text(
        score.nameZh,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        t.score.courseNumber(
          number: score.number ?? t.score.none,
          code: score.code,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: scoreColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          score.score?.toString() ?? getScoreStatusText(score.status),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: scoreColor,
          ),
        ),
      ),
    );
  }
}
