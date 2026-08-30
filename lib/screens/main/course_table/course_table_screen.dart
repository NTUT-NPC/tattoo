import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/components/app_skeleton.dart';
import 'package:tattoo/components/chip_tab_switcher.dart';
import 'package:tattoo/components/floating_action_bar.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/repositories/course_repository.dart';
import 'package:tattoo/screens/main/course_table_providers.dart';
import 'package:tattoo/screens/main/course_table/course_table_grid.dart';
import 'package:tattoo/screens/main/course_table/course_table_weekly.dart';
import 'package:tattoo/screens/main/user_providers.dart';

const _loadingSemesterTabLabels = ['114-2', '114-1', '113-2'];
const _floatingBarBottomInset = 80.0;
const _floatingBarMargin = 16.0;

enum _CourseTableView { grid, weekly }

class CourseTableScreen extends ConsumerStatefulWidget {
  const CourseTableScreen({super.key});

  @override
  ConsumerState<CourseTableScreen> createState() => _CourseTableScreenState();
}

class _CourseTableScreenState extends ConsumerState<CourseTableScreen> {
  var _view = _CourseTableView.grid;

  Future<void> _refreshCourseTable(Semester semester) async {
    final courseRepository = ref.read(courseRepositoryProvider);
    await [
      courseRepository.refreshSemesters(),
      courseRepository.refreshCourseTable(semesterId: semester.id),
    ].wait;
  }

  void _toggleView() {
    setState(() {
      _view = switch (_view) {
        .grid => .weekly,
        .weekly => .grid,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final semestersAsync = ref.watch(courseTableSemestersProvider);
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
        // A scaffold AppBar to handle status bar height.
        appBar: AppBar(
          toolbarHeight: 0,
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final gridViewportSize = constraints.biggest;
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
              margin: const .all(_floatingBarMargin),
              floatingActionBarBuilder: (context, visible) {
                if (!shouldShowFloatingBar) {
                  return null;
                }

                return FloatingActionBar(
                  visible: visible,
                  actions: [
                    FloatingActionBarActionButton(
                      icon: switch (_view) {
                        .grid => Icons.view_week_outlined,
                        .weekly => Icons.grid_view_outlined,
                      },
                      tooltip: switch (_view) {
                        .grid => t.courseTable.actions.showWeeklyView,
                        .weekly => t.courseTable.actions.showGridView,
                      },
                      onTap: _toggleView,
                    ),
                  ],
                  child: AppSkeleton(
                    enabled: isSemesterLoading,
                    child: ChipTabSwitcher(
                      tabs: displayedSemesterTabLabels,
                      padding: const .symmetric(horizontal: 12),
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
                  Center(
                    child: Center(
                      child: Text(
                        profileAsync.asData?.value == null
                            ? t.general.notLoggedIn
                            : t.courseTable.notFound,
                      ),
                    ),
                  ),

                // LOADED state: show course table with tabs
                AsyncData(value: final semesters) => TabBarView(
                  children: [
                    for (final semester in semesters)
                      Consumer(
                        builder: (context, tabRef, child) {
                          final courseTableAsync = tabRef.watch(
                            courseTableProvider(semester.id),
                          );

                          return switch (courseTableAsync) {
                            AsyncError(:final error) => Center(
                              child: Center(child: Text('Error: $error')),
                            ),
                            _ => switch (_view) {
                              .grid => CourseTableGrid(
                                key: ValueKey(
                                  'grid-${_semesterLabel(semester)}',
                                ),
                                courseTableData:
                                    courseTableAsync.asData?.value ??
                                    emptyCourseTableData,
                                loading:
                                    courseTableAsync.isLoading &&
                                    !courseTableAsync.hasValue,
                                onRefresh: () => _refreshCourseTable(semester),
                                viewportWidth: gridViewportSize.width,
                                viewportHeight: gridViewportSize.height,
                                bottomInset:
                                    _floatingBarBottomInset + bottomInset,
                              ),
                              .weekly => CourseTableWeekly(
                                key: ValueKey(
                                  'weekly-${_semesterLabel(semester)}',
                                ),
                                courseTableData:
                                    courseTableAsync.asData?.value ??
                                    emptyCourseTableData,
                                loading:
                                    courseTableAsync.isLoading &&
                                    !courseTableAsync.hasValue,
                                onRefresh: () => _refreshCourseTable(semester),
                                bottomInset:
                                    _floatingBarBottomInset + bottomInset,
                              ),
                            },
                          };
                        },
                      ),
                  ],
                ),

                // LOADING state: show loading skeleton
                _ => switch (_view) {
                  .grid => CourseTableGrid(
                    courseTableData: emptyCourseTableData,
                    loading: true,
                    viewportWidth: gridViewportSize.width,
                    viewportHeight: gridViewportSize.height,
                    bottomInset: _floatingBarBottomInset + bottomInset,
                  ),
                  .weekly => CourseTableWeekly(
                    courseTableData: emptyCourseTableData,
                    loading: true,
                    bottomInset: _floatingBarBottomInset + bottomInset,
                  ),
                },
              },
            );
          },
        ),
      ),
    );
  }
}

String _semesterLabel(Semester semester) => '${semester.year}-${semester.term}';
