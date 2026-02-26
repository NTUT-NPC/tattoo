import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/components/chip_tab_switcher.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/screens/main/score/score_screen_actions.dart';
import 'package:tattoo/screens/main/score/score_view_helpers.dart';
import 'package:tattoo/services/student_query_service.dart';
import 'package:tattoo/screens/main/score/score_providers.dart';

class ScoreScreen extends ConsumerStatefulWidget {
  const ScoreScreen({super.key});

  @override
  ConsumerState<ScoreScreen> createState() => _ScoreScreenState();
}

class _ScoreScreenState extends ConsumerState<ScoreScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  String? _selectedSemesterKey;
  DateTime? _lastUpdatedAt;
  TabController? _semesterTabController;
  int _semesterTabLength = 0;

  @override
  void initState() {
    super.initState();
    _loadLastUpdatedFromCache();
  }

  void _dismissRefreshSnackBar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  @override
  void dispose() {
    _semesterTabController?.removeListener(_handleSemesterTabChanged);
    _semesterTabController?.dispose();
    super.dispose();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification ||
        notification is UserScrollNotification) {
      _dismissRefreshSnackBar();
    }
    return false;
  }

  Future<void> _loadLastUpdatedFromCache() async {
    final parsed = await loadScoreLastUpdatedFromCache(ref);
    if (!mounted || parsed == null) return;

    setState(() {
      _lastUpdatedAt = parsed;
    });
  }

  int _findPreferredSemesterIndex(List<SemesterScoreDto> semesters) {
    if (_selectedSemesterKey == null) return -1;
    return semesters.indexWhere(
      (semester) => semesterKey(semester) == _selectedSemesterKey,
    );
  }

  int _findDefaultSemesterIndex(List<SemesterScoreDto> semesters) {
    final index = semesters.indexWhere(
      (semester) => semester.scores.isNotEmpty,
    );
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

  void _syncSemesterTabController(List<SemesterScoreDto> semesters) {
    if (semesters.isEmpty) {
      _semesterTabController?.removeListener(_handleSemesterTabChanged);
      _semesterTabController?.dispose();
      _semesterTabController = null;
      _semesterTabLength = 0;
      _selectedIndex = 0;
      _selectedSemesterKey = null;
      return;
    }

    final preferredIndex = _findPreferredSemesterIndex(semesters);
    final initialIndex = preferredIndex >= 0
        ? preferredIndex
        : _findDefaultSemesterIndex(semesters);

    if (_semesterTabController == null ||
        _semesterTabLength != semesters.length) {
      _semesterTabController?.removeListener(_handleSemesterTabChanged);
      _semesterTabController?.dispose();
      _semesterTabController = TabController(
        length: semesters.length,
        initialIndex: initialIndex,
        vsync: this,
      )..addListener(_handleSemesterTabChanged);
      _semesterTabLength = semesters.length;
      _selectedIndex = initialIndex;
      return;
    }

    final targetIndex = _selectedIndex >= semesters.length
        ? initialIndex
        : _selectedIndex;
    if (_semesterTabController!.index != targetIndex) {
      _semesterTabController!.index = targetIndex;
    }
    _selectedIndex = targetIndex;
  }

  /// Executes pull-to-refresh and reports the actual refresh outcome to users.
  ///
  /// This method invalidates the provider, awaits the next resolved state, and
  /// then maps provider semantics into user-facing feedback. A successful await
  /// does not always mean remote data was refreshed, because offline fallback
  /// may still resolve with cached data. Therefore the method checks
  /// `refreshedFromNetwork` to decide whether to (1) persist a new last-updated
  /// timestamp and show a true "updated" message, or (2) keep the previous
  /// timestamp and show an offline-cache message. Hard failures that produce no
  /// valid state are surfaced as an explicit refresh failure snackbar.
  Future<void> _reloadScores() async {
    try {
      final result = await reloadScoresAndPersistTimestamp(ref);
      if (result.updatedAt != null) {
        _lastUpdatedAt = result.updatedAt;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            result.refreshedFromNetwork ? '成績資料已更新' : '目前離線，顯示快取資料',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('成績更新失敗')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final performanceAsync = ref.watch(academicPerformanceProvider);

    return Scaffold(
      body: performanceAsync.when(
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
              child: Center(child: Text('成績載入失敗\n$err')),
            ),
          ],
        ),
        data: (data) {
          final semesters = data.semesters;
          _syncSemesterTabController(semesters);

          final hasSemesters = semesters.isNotEmpty;
          if (hasSemesters) {
            final activeIndex = _semesterTabController?.index ?? _selectedIndex;
            _selectedIndex = activeIndex >= semesters.length ? 0 : activeIndex;
            _selectedSemesterKey = semesterKey(semesters[_selectedIndex]);
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
                  bottom: _semesterTabController != null && semesters.isNotEmpty
                      ? PreferredSize(
                          preferredSize: const Size.fromHeight(52),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            child: SizedBox(
                              height: 40,
                              child: ChipTabSwitcher(
                                tabs: [
                                  for (final semester in semesters)
                                    '${semester.semester.year}-${semester.semester.term}',
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
                if (!hasSemesters)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text('目前沒有任何成績紀錄')),
                  )
                else ...[
                  SliverFillRemaining(
                    child: TabBarView(
                      controller: _semesterTabController,
                      children: [
                        for (final semester in semesters)
                          _SemesterScoreList(
                            data: semester,
                            gpa: data.gpaBySemester[semesterKey(semester)],
                            names: data.names,
                            lastUpdatedAt: _lastUpdatedAt,
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
  final SemesterScoreDto data;
  final GpaDto? gpa;
  final Map<String, String> names;
  final DateTime? lastUpdatedAt;
  final Future<void> Function() onRefresh;

  const _SemesterScoreList({
    required this.data,
    required this.gpa,
    required this.names,
    required this.lastUpdatedAt,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 8, bottom: 12),
        itemCount: data.scores.length + 3,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _SemesterSummaryCard(data: data, gpa: gpa);
          }
          if (index == 1) {
            if (data.scores.isNotEmpty) return const SizedBox(height: 8);
            return const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Center(child: Text('本學期尚無成績')),
            );
          }
          if (index == data.scores.length + 2) {
            if (lastUpdatedAt == null) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '最後更新：${formatLastUpdated(lastUpdatedAt!)}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }

          final scoreIndex = index - 2;
          final score = data.scores[scoreIndex];
          final name = names[score.courseCode] ?? score.courseCode ?? '未知課程';
          return Column(
            children: [
              _ScoreTile(score: score, courseName: name),
              if (scoreIndex != data.scores.length - 1)
                const Divider(height: 1, indent: 16),
            ],
          );
        },
      ),
    );
  }
}

class _SemesterSummaryCard extends StatelessWidget {
  final SemesterScoreDto data;
  final GpaDto? gpa;

  const _SemesterSummaryCard({
    required this.data,
    required this.gpa,
  });

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
                  '歷年 GPA',
                  _formatDouble(gpa?.grandTotalGpa),
                ),
                const SizedBox(width: 24),
                _buildStat(context, '操行成績', data.conduct?.toString() ?? '-'),
                const SizedBox(width: 24),
                _buildStat(context, '學期平均', data.average?.toString() ?? '-'),
                const SizedBox(width: 24),
                _buildStat(
                  context,
                  '實得學分',
                  data.creditsPassed?.toString() ?? '-',
                ),
                const SizedBox(width: 24),
                _buildStat(
                  context,
                  '修課總學分',
                  data.totalCredits?.toString() ?? '-',
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
  final ScoreDto score;
  final String courseName;

  const _ScoreTile({required this.score, required this.courseName});

  @override
  Widget build(BuildContext context) {
    final scoreColor = getScoreColor(context, score);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      title: Text(
        courseName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '課號: ${score.number ?? "無"}  編碼: ${score.courseCode ?? "無"}',
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
