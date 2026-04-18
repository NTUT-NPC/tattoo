import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/components/app_skeleton.dart';
import 'package:tattoo/components/chip_tab_switcher.dart';
import 'package:tattoo/components/floating_action_bar.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/repositories/student_repository.dart';
import 'package:tattoo/screens/main/score/score_providers.dart';
import 'package:tattoo/screens/main/score/score_screen_actions.dart';
import 'package:tattoo/screens/main/score/score_view_helpers.dart';

const _loadingSemesterTabLabels = ['114-2', '114-1', '113-2'];
const _floatingBarBottomInset = 80.0;
const _floatingBarMargin = 16.0;

class ScoreScreen extends ConsumerStatefulWidget {
  const ScoreScreen({super.key});

  @override
  ConsumerState<ScoreScreen> createState() => _ScoreScreenState();
}

class _ScoreScreenState extends ConsumerState<ScoreScreen>
    with SingleTickerProviderStateMixin {
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
    final semestersAsync = ref.watch(scoreSemestersProvider);
    final semesterRecordMapAsync = ref.watch(semesterRecordMapProvider);
    final displayedSemesterTabLabels =
        semestersAsync.asData?.value
            .map(_semesterLabel)
            .toList(growable: false) ??
        _loadingSemesterTabLabels;
    final isSemesterLoading =
        semestersAsync.isLoading && !semestersAsync.hasValue;

    final tabLength = displayedSemesterTabLabels.isEmpty
        ? 1
        : displayedSemesterTabLabels.length;

    return DefaultTabController(
      key: ValueKey(tabLength),
      length: tabLength,
      child: Scaffold(
        appBar: AppBar(
          title: Text(t.nav.scores),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final mediaQuery = MediaQuery.of(context);
            final bottomInset = math.max(
              mediaQuery.padding.bottom,
              mediaQuery.viewInsets.bottom,
            );
            final shouldShowFloatingBar = switch (semestersAsync) {
              AsyncError() => false,
              AsyncData(value: final semesters) => semesters.isNotEmpty,
              _ => true,
            };

            return ScrollAwareFloatingActionBar(
              margin: const EdgeInsets.all(_floatingBarMargin),
              floatingActionBarBuilder: (context, visible) {
                if (!shouldShowFloatingBar) {
                  return null;
                }

                return FloatingActionBar(
                  visible: visible,
                  child: AppSkeleton(
                    enabled: isSemesterLoading,
                    child: ChipTabSwitcher(
                      tabs: displayedSemesterTabLabels,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                );
              },
              child: switch (semestersAsync) {
                // ERROR state: show error message
                AsyncError(:final error) => Center(
                  child: Center(child: Text('Error: $error')),
                ),

                // EMPTY state: show not found message
                AsyncData(value: final semesters) when semesters.isEmpty =>
                  Center(child: Text(t.score.noRecords)),

                // LOADED state: score pages with tabs
                AsyncData(value: final semesters) =>
                  switch (semesterRecordMapAsync) {
                    AsyncError(:final error) => Center(
                      child: Center(child: Text('Error: $error')),
                    ),
                    AsyncData(value: final recordMap) => TabBarView(
                      children: [
                        for (final semester in semesters)
                          if (recordMap[semester.id] case final record?)
                            _SemesterScoreList(
                              record: record,
                              onRefresh: _reloadScores,
                            )
                          else
                            _ScorePlaceholder(
                              semesterLabel: _semesterLabel(semester),
                              bottomInset:
                                  _floatingBarBottomInset + bottomInset,
                            ),
                      ],
                    ),
                    _ => TabBarView(
                      children: [
                        for (final semester in semesters)
                          _ScorePlaceholder(
                            semesterLabel: _semesterLabel(semester),
                            bottomInset: _floatingBarBottomInset + bottomInset,
                            loading: true,
                          ),
                      ],
                    ),
                  },

                // LOADING state: show loading placeholder
                _ => _ScorePlaceholder(
                  semesterLabel: _loadingSemesterTabLabels.first,
                  bottomInset: _floatingBarBottomInset + bottomInset,
                  loading: true,
                ),
              },
            );
          },
        ),
      ),
    );
  }
}

class _ScorePlaceholder extends StatelessWidget {
  const _ScorePlaceholder({
    required this.semesterLabel,
    required this.bottomInset,
    this.loading = false,
  });

  final String semesterLabel;
  final double bottomInset;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16, 24, 16, bottomInset + 16),
      children: [
        if (loading)
          const Center(child: CircularProgressIndicator())
        else
          Center(
            child: Text('$semesterLabel ${t.general.notImplemented}'),
          ),
      ],
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

String _semesterLabel(Semester semester) => '${semester.year}-${semester.term}';
