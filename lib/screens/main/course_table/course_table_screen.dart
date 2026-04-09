import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/components/app_skeleton.dart';
import 'package:tattoo/components/chip_tab_switcher.dart';
import 'package:tattoo/components/floating_action_bar.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/repositories/course_repository.dart';
import 'package:tattoo/screens/main/course_table/course_table_grid.dart';
import 'package:tattoo/screens/main/course_table/course_table_providers.dart';
import 'package:tattoo/screens/main/user_providers.dart';

// TODO: Import mock data from demo mode when implemented
const _loadingSemesterTabLabels = ['114-2', '114-1', '113-2'];
const _floatingBarBottomInset = 80.0;
const _floatingBarMargin = 16.0;

enum _CourseTableMenuAction {
  refresh,
  displayOptions,
}

class CourseTableScreen extends ConsumerWidget {
  const CourseTableScreen({super.key});

  Future<void> _refreshCourseTable(WidgetRef ref, Semester semester) async {
    final courseRepository = ref.read(courseRepositoryProvider);
    await [
      courseRepository.refreshSemesters(),
      courseRepository.refreshCourseTable(semesterId: semester.id),
    ].wait;
  }

  void _showDemoTap(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t.general.notImplemented)),
    );
  }

  Semester? _resolveSelectedSemester(
    BuildContext context,
    List<Semester>? semesters,
  ) {
    if (semesters == null || semesters.isEmpty) {
      return null;
    }

    final controller = DefaultTabController.maybeOf(context);
    if (controller == null) {
      return semesters.first;
    }

    final clampedIndex = controller.index
        .clamp(0, semesters.length - 1)
        .toInt();
    return semesters[clampedIndex];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              margin: const EdgeInsets.all(_floatingBarMargin),
              floatingActionBarBuilder: (context, visible) {
                if (!shouldShowFloatingBar) {
                  return null;
                }

                return FloatingActionBar(
                  visible: visible,
                  actions: [
                    // TODO: add day view and week view toggle when implemented
                    Builder(
                      builder: (context) {
                        final semesters = semestersAsync.asData?.value;
                        final selectedSemester = _resolveSelectedSemester(
                          context,
                          semesters,
                        );

                        return FloatingActionBarMenuButton<
                          _CourseTableMenuAction
                        >(
                          icon: Icons.more_vert_outlined,
                          items: [
                            PopupMenuItem(
                              value: _CourseTableMenuAction.displayOptions,
                              child: ListTile(
                                leading: const Icon(Icons.tune_outlined),
                                title: Text(
                                  t.courseTable.actions.displayOptions,
                                ),
                              ),
                            ),
                          ],
                          onSelected: (action) async {
                            switch (action) {
                              case _CourseTableMenuAction.refresh:
                                if (selectedSemester != null) {
                                  try {
                                    await _refreshCourseTable(
                                      ref,
                                      selectedSemester,
                                    );
                                  } catch (error) {
                                    if (!context.mounted) {
                                      return;
                                    }

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $error')),
                                    );
                                  }
                                }
                                break;
                              case _CourseTableMenuAction.displayOptions:
                                _showDemoTap(context);
                                break;
                            }
                          },
                        );
                      },
                    ),
                  ],
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
                            _ => CourseTableGrid(
                              key: ValueKey(_semesterLabel(semester)),
                              courseTableData:
                                  courseTableAsync.asData?.value ??
                                  emptyCourseTableData,
                              loading:
                                  courseTableAsync.isLoading &&
                                  !courseTableAsync.hasValue,
                              onRefresh: () => _refreshCourseTable(
                                ref,
                                semester,
                              ),
                              viewportWidth: gridViewportSize.width,
                              viewportHeight: gridViewportSize.height,
                              bottomInset:
                                  _floatingBarBottomInset + bottomInset,
                            ),
                          };
                        },
                      ),
                  ],
                ),

                // LOADING state: show loading skeleton
                _ => CourseTableGrid(
                  courseTableData: emptyCourseTableData,
                  loading: true,
                  viewportWidth: gridViewportSize.width,
                  viewportHeight: gridViewportSize.height,
                  bottomInset: _floatingBarBottomInset + bottomInset,
                ),
              },
            );
          },
        ),
      ),
    );
  }
}

String _semesterLabel(Semester semester) => '${semester.year}-${semester.term}';
