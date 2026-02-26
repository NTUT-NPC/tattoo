import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class _ScoreScreenState extends ConsumerState<ScoreScreen> {
  int _selectedIndex = 0;
  String? _selectedSemesterKey;
  DateTime? _lastUpdatedAt;

  @override
  void initState() {
    super.initState();
    _loadLastUpdatedFromCache();
  }

  void _dismissRefreshSnackBar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification ||
        notification is UserScrollNotification ||
        notification is ScrollUpdateNotification) {
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
    final appBarSemesters =
        performanceAsync.asData?.value.semesters ?? const <SemesterScoreDto>[];
    final appBarSelectedIndex = appBarSemesters.isEmpty
        ? 0
        : (_selectedIndex >= appBarSemesters.length ? 0 : _selectedIndex);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.nav.scores),
        centerTitle: true,
        actions: [
          if (appBarSemesters.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _SemesterAppBarSelector(
                semesters: appBarSemesters,
                selectedIndex: appBarSelectedIndex,
                onChanged: (idx) => setState(() {
                  _dismissRefreshSnackBar();
                  _selectedIndex = idx;
                  _selectedSemesterKey = semesterKey(appBarSemesters[idx]);
                }),
              ),
            ),
        ],
      ),
      body: performanceAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('成績載入失敗\n$err')),
        data: (data) {
          final semesters = data.semesters;

          if (semesters.isEmpty) {
            return RefreshIndicator(
              onRefresh: _reloadScores,
              child: NotificationListener<ScrollNotification>(
                onNotification: _handleScrollNotification,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 240),
                    Center(child: Text('目前沒有任何成績紀錄')),
                  ],
                ),
              ),
            );
          }

          if (_selectedIndex >= semesters.length) _selectedIndex = 0;

          final preferredIndex = findPreferredSemesterIndex(
            semesters,
            _selectedSemesterKey,
          );
          if (preferredIndex >= 0) {
            _selectedIndex = preferredIndex;
          } else {
            _selectedIndex = findDefaultSemesterIndex(semesters);
          }
          final currentData = semesters[_selectedIndex];
          _selectedSemesterKey = semesterKey(currentData);

          return Column(
            children: [
              if (_lastUpdatedAt != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '最後更新：${formatLastUpdated(_lastUpdatedAt!)}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              _SemesterSummaryCard(data: currentData),

              const Divider(height: 1),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _reloadScores,
                  child: NotificationListener<ScrollNotification>(
                    onNotification: _handleScrollNotification,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: currentData.scores.length,
                      separatorBuilder: (_, separatorIndex) =>
                          const Divider(height: 1, indent: 16),
                      itemBuilder: (context, index) {
                        final score = currentData.scores[index];
                        final name =
                            data.names[score.courseCode] ??
                            score.courseCode ??
                            '未知課程';
                        return _ScoreTile(score: score, courseName: name);
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SemesterAppBarSelector extends StatelessWidget {
  final List<SemesterScoreDto> semesters;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _SemesterAppBarSelector({
    required this.semesters,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<int>(
        value: selectedIndex,
        onChanged: (val) => val != null ? onChanged(val) : null,
        borderRadius: BorderRadius.circular(12),
        items: List.generate(semesters.length, (index) {
          final sem = semesters[index].semester;
          return DropdownMenuItem(
            value: index,
            child: Text(
              '${sem.year}-${sem.term}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          );
        }),
      ),
    );
  }
}

class _SemesterSummaryCard extends StatelessWidget {
  final SemesterScoreDto data;
  const _SemesterSummaryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStat(context, '學期平均', data.average?.toString() ?? '-'),
            _buildStat(context, '實得學分', data.creditsPassed?.toString() ?? '-'),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(BuildContext context, String label, String value) {
    return Column(
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
