import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/models/course.dart';
import 'package:tattoo/models/score.dart';
import 'package:tattoo/repositories/auth_repository.dart';
import 'package:tattoo/services/course_service.dart';
import 'package:tattoo/services/portal_service.dart';
import 'package:tattoo/services/student_query_service.dart';
import 'package:tattoo/utils/shared_preferences.dart';

typedef ScorePageState = ({
  List<SemesterScoreDto> semesters,
  Map<String, String> names,
  bool refreshedFromNetwork,
});

const _scoreLastUpdatedKeyPrefix = 'score.lastUpdatedAt';

String _normalizeIdentifier(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? '' : normalized;
}

int _compareCourseIdentifiers(String left, String right) {
  if (left == right) return 0;

  final leftAsInt = int.tryParse(left);
  final rightAsInt = int.tryParse(right);
  if (leftAsInt != null && rightAsInt != null) {
    return leftAsInt.compareTo(rightAsInt);
  }

  return left.compareTo(right);
}

int _compareScoresByCourseNumber(ScoreDto left, ScoreDto right) {
  final leftNumber = _normalizeIdentifier(left.number);
  final rightNumber = _normalizeIdentifier(right.number);

  final leftHasNumber = leftNumber.isNotEmpty;
  final rightHasNumber = rightNumber.isNotEmpty;

  if (leftHasNumber && rightHasNumber) {
    final byNumber = _compareCourseIdentifiers(leftNumber, rightNumber);
    if (byNumber != 0) return byNumber;
  } else if (leftHasNumber != rightHasNumber) {
    return leftHasNumber ? -1 : 1;
  }

  final leftCode = _normalizeIdentifier(left.courseCode);
  final rightCode = _normalizeIdentifier(right.courseCode);
  return _compareCourseIdentifiers(leftCode, rightCode);
}

List<SemesterScoreDto> _sortScoresWithinSemesters(
  List<SemesterScoreDto> semesters,
) {
  return semesters.map((semester) {
    final sortedScores = [...semester.scores]
      ..sort(_compareScoresByCourseNumber);
    return (
      semester: semester.semester,
      scores: sortedScores,
      average: semester.average,
      conduct: semester.conduct,
      totalCredits: semester.totalCredits,
      creditsPassed: semester.creditsPassed,
      note: semester.note,
    );
  }).toList();
}

class _CachedSemesterState {
  final int year;
  final int term;
  double? average;
  double? conduct;
  double? totalCredits;
  double? creditsPassed;
  String? note;
  final List<ScoreDto> scores;

  _CachedSemesterState({required this.year, required this.term}) : scores = [];
}

Future<ScorePageState> _loadAcademicPerformanceFromDb({
  required AppDatabase db,
  required int userId,
}) async {
  final semesterStates = <int, _CachedSemesterState>{};
  final names = <String, String>{};

  final scoreRows =
      await (db.select(db.scores).join([
              innerJoin(
                db.semesters,
                db.semesters.id.equalsExp(db.scores.semester),
              ),
              innerJoin(db.courses, db.courses.id.equalsExp(db.scores.course)),
              leftOuterJoin(
                db.courseOfferings,
                db.courseOfferings.id.equalsExp(db.scores.courseOffering),
              ),
            ])
            ..where(db.scores.user.equals(userId))
            ..orderBy([
              OrderingTerm.desc(db.semesters.year),
              OrderingTerm.desc(db.semesters.term),
              OrderingTerm.asc(db.courses.code),
            ]))
          .get();

  for (final row in scoreRows) {
    final scoreRow = row.readTable(db.scores);
    final semester = row.readTable(db.semesters);
    final course = row.readTable(db.courses);
    final courseOffering = row.readTableOrNull(db.courseOfferings);

    final state =
        semesterStates[semester.id] ??
        _CachedSemesterState(year: semester.year, term: semester.term);

    state.scores.add((
      number: courseOffering?.number,
      courseCode: course.code,
      score: scoreRow.score,
      status: scoreRow.status,
    ));

    names[course.code] = course.nameZh ?? course.code;
    semesterStates[semester.id] = state;
  }

  if (semesterStates.isEmpty) {
    return (
      semesters: <SemesterScoreDto>[],
      names: names,
      refreshedFromNetwork: false,
    );
  }

  final summaryRows =
      await (db.select(db.userSemesterSummaries).join([
            innerJoin(
              db.semesters,
              db.semesters.id.equalsExp(db.userSemesterSummaries.semester),
            ),
          ])..where(
            db.userSemesterSummaries.user.equals(userId) &
                db.userSemesterSummaries.semester.isIn(
                  semesterStates.keys.toList(),
                ),
          ))
          .get();

  for (final row in summaryRows) {
    final summary = row.readTable(db.userSemesterSummaries);
    final semester = row.readTable(db.semesters);

    final state = semesterStates[semester.id];
    if (state == null) continue;
    state.average = summary.average;
    state.conduct = summary.conduct;
    state.totalCredits = summary.totalCredits;
    state.creditsPassed = summary.creditsPassed;
    state.note = summary.note;
  }

  final semesters = semesterStates.values.toList()
    ..sort((a, b) {
      final yearCompare = b.year.compareTo(a.year);
      if (yearCompare != 0) return yearCompare;
      return b.term.compareTo(a.term);
    });

  final hydratedSemesters = semesters
      .map(
        (semester) => (
          semester: (year: semester.year, term: semester.term),
          scores: semester.scores,
          average: semester.average,
          conduct: semester.conduct,
          totalCredits: semester.totalCredits,
          creditsPassed: semester.creditsPassed,
          note: semester.note,
        ),
      )
      .toList();

  return (
    semesters: _sortScoresWithinSemesters(hydratedSemesters),
    names: names,
    refreshedFromNetwork: false,
  );
}

Future<int> _getOrCreateCourseId(AppDatabase db, String code) async {
  return (await db
          .into(db.courses)
          .insertReturning(
            CoursesCompanion.insert(code: code, credits: 0, hours: 0),
            onConflict: DoUpdate(
              (old) => CoursesCompanion(code: Value(code)),
              target: [db.courses.code],
            ),
          ))
      .id;
}

Future<int> _getOrCreateCourseOfferingId({
  required AppDatabase db,
  required int courseId,
  required int semesterId,
  required String number,
}) async {
  final existing =
      await (db.select(db.courseOfferings)
            ..where((t) => t.number.equals(number))
            ..limit(1))
          .getSingleOrNull();
  if (existing != null) return existing.id;

  return (await db
          .into(db.courseOfferings)
          .insertReturning(
            CourseOfferingsCompanion.insert(
              course: courseId,
              semester: semesterId,
              number: number,
              phase: 0,
              courseType: CourseType.commonElective,
            ),
            onConflict: DoUpdate(
              (old) => CourseOfferingsCompanion(
                course: Value(courseId),
                semester: Value(semesterId),
              ),
              target: [db.courseOfferings.number],
            ),
          ))
      .id;
}

String? _resolveScoreCourseCode(ScoreDto score) {
  final normalizedCode = score.courseCode?.trim();
  if (normalizedCode != null && normalizedCode.isNotEmpty) {
    return normalizedCode;
  }

  final fallback = score.number?.trim();
  if (fallback != null && fallback.isNotEmpty) {
    return fallback;
  }
  return null;
}

Future<void> _persistAcademicPerformance({
  required AppDatabase db,
  required int userId,
  required List<SemesterScoreDto> semesters,
}) async {
  await db.transaction(() async {
    final semesterIds = <String, int>{};
    final courseIds = <String, int>{};
    final fetchedSemesterIds = <int>{};
    final emptySemesterIds = <int>{};

    for (final semesterData in semesters) {
      final year = semesterData.semester.year;
      final term = semesterData.semester.term;
      if (year == null || term == null) {
        continue;
      }

      final semesterKey = '$year-$term';
      final semesterId =
          semesterIds[semesterKey] ?? await db.getOrCreateSemester(year, term);
      semesterIds[semesterKey] = semesterId;
      fetchedSemesterIds.add(semesterId);

      final hasScoreRows = semesterData.scores
          .map(_resolveScoreCourseCode)
          .whereType<String>()
          .isNotEmpty;

      if (!hasScoreRows) {
        emptySemesterIds.add(semesterId);
      }

      await db
          .into(db.userSemesterSummaries)
          .insert(
            UserSemesterSummariesCompanion.insert(
              user: userId,
              semester: semesterId,
              average: Value(semesterData.average),
              conduct: Value(semesterData.conduct),
              totalCredits: Value(semesterData.totalCredits),
              creditsPassed: Value(semesterData.creditsPassed),
              note: Value(semesterData.note),
            ),
            onConflict: DoUpdate(
              (old) => UserSemesterSummariesCompanion(
                average: Value(semesterData.average),
                conduct: Value(semesterData.conduct),
                totalCredits: Value(semesterData.totalCredits),
                creditsPassed: Value(semesterData.creditsPassed),
                note: Value(semesterData.note),
              ),
              target: [
                db.userSemesterSummaries.user,
                db.userSemesterSummaries.semester,
              ],
            ),
          );

      await (db.delete(db.scores)..where(
            (t) => t.user.equals(userId) & t.semester.equals(semesterId),
          ))
          .go();

      for (final score in semesterData.scores) {
        final courseCode = _resolveScoreCourseCode(score);
        if (courseCode == null) {
          continue;
        }

        var courseId = courseIds[courseCode];
        if (courseId == null) {
          courseId = await _getOrCreateCourseId(db, courseCode);
          courseIds[courseCode] = courseId;
        }

        int? offeringId;
        final number = score.number?.trim();
        if (number != null && number.isNotEmpty) {
          offeringId = await _getOrCreateCourseOfferingId(
            db: db,
            courseId: courseId,
            semesterId: semesterId,
            number: number,
          );
        }

        await db
            .into(db.scores)
            .insert(
              ScoresCompanion.insert(
                user: userId,
                semester: semesterId,
                course: courseId,
                courseOffering: Value(offeringId),
                score: Value(score.score),
                status: Value(score.status),
              ),
              onConflict: DoUpdate(
                (old) => ScoresCompanion(
                  courseOffering: Value(offeringId),
                  score: Value(score.score),
                  status: Value(score.status),
                ),
                target: [db.scores.user, db.scores.course, db.scores.semester],
              ),
            );
      }
    }

    if (fetchedSemesterIds.isEmpty) {
      await (db.delete(db.scores)..where((t) => t.user.equals(userId))).go();
    } else {
      await (db.delete(db.scores)..where(
            (t) =>
                t.user.equals(userId) &
                t.semester.isNotIn(fetchedSemesterIds.toList()),
          ))
          .go();
    }

    if (emptySemesterIds.isNotEmpty) {
      await (db.delete(db.userSemesterSummaries)..where(
            (t) =>
                t.user.equals(userId) &
                t.semester.isIn(emptySemesterIds.toList()) &
                t.className.isNull() &
                t.enrollmentStatus.isNull() &
                t.registered.isNull() &
                t.graduated.isNull(),
          ))
          .go();
    }

    if (fetchedSemesterIds.isNotEmpty) {
      await (db.delete(db.userSemesterSummaries)..where(
            (t) =>
                t.user.equals(userId) &
                t.semester.isNotIn(fetchedSemesterIds.toList()) &
                t.className.isNull() &
                t.enrollmentStatus.isNull() &
                t.registered.isNull() &
                t.graduated.isNull(),
          ))
          .go();
    }
  });
}

/// Provides score screen state using a cache-first, revalidate-on-demand flow.
///
/// This provider is the single integration point between UI rendering, local
/// persistence, and remote NTUT systems. On normal screen entry, it reads from
/// Drift and emits quickly so users can see cached scores without waiting for
/// network round-trips. It then attempts authenticated SSO fetches, resolves
/// missing course metadata, persists normalized results back to the database,
/// and emits refreshed data. During explicit pull-to-refresh, the provider
/// intentionally does not emit cached data first, so the loading indicator only
/// finishes after the full refresh pipeline completes. If remote fetch fails but
/// cached data exists, it emits that fallback instead of throwing, allowing the
/// screen to recover gracefully while clearly distinguishing offline fallback
/// from a true network refresh through `refreshedFromNetwork`.
final academicPerformanceProvider = StreamProvider.autoDispose<ScorePageState>((
  ref,
) async* {
  final authRepo = ref.watch(authRepositoryProvider);
  final portalService = ref.watch(portalServiceProvider);
  final queryService = ref.watch(studentQueryServiceProvider);
  final courseService = ref.watch(courseServiceProvider);
  final db = ref.watch(databaseProvider);

  final user = await db.select(db.users).getSingleOrNull();
  if (user == null) {
    throw StateError('User not found. Please login again.');
  }

  final cached = await _loadAcademicPerformanceFromDb(db: db, userId: user.id);
  final shouldEmitCachedFirst = !ref.isRefresh;
  if (shouldEmitCachedFirst && cached.semesters.isNotEmpty) {
    yield cached;
  }

  try {
    final refreshed = await authRepo.withAuth(() async {
      await portalService.sso(PortalServiceCode.studentQueryService);
      final semesters = _sortScoresWithinSemesters(
        await queryService.getAcademicPerformance(),
      );

      final allCodes = semesters
          .expand((s) => s.scores)
          .map((s) => s.courseCode)
          .whereType<String>()
          .map((code) => code.trim())
          .where((code) => code.isNotEmpty)
          .toSet();

      final existingCourses = await (db.select(
        db.courses,
      )..where((t) => t.code.isIn(allCodes.toList()))).get();

      final Map<String, String> courseNames = {
        for (final c in existingCourses) c.code: c.nameZh ?? c.code,
      };

      final missingCodes = allCodes
          .where((code) => !courseNames.containsKey(code))
          .toList();

      if (missingCodes.isNotEmpty) {
        await portalService.sso(PortalServiceCode.courseService);

        await Future.wait(
          missingCodes.map((code) async {
            try {
              final dto = await courseService.getCourse(code);
              if (dto.nameZh != null) {
                await db
                    .into(db.courses)
                    .insertOnConflictUpdate(
                      CoursesCompanion.insert(
                        code: code,
                        credits: dto.credits ?? 0,
                        hours: dto.hours ?? 0,
                        nameZh: Value(dto.nameZh),
                        nameEn: Value(dto.nameEn),
                        fetchedAt: Value(DateTime.now()),
                      ),
                    );
                courseNames[code] = dto.nameZh!;
              }
            } catch (e) {
              debugPrint(
                'Failed to fetch course metadata for code ($code): $e',
              );
            }
          }),
        );
      }

      await _persistAcademicPerformance(
        db: db,
        userId: user.id,
        semesters: semesters,
      );

      return (
        semesters: semesters,
        names: courseNames,
        refreshedFromNetwork: true,
      );
    });
    yield refreshed;
  } catch (error) {
    if (cached.semesters.isEmpty) {
      rethrow;
    }
    debugPrint('Score refresh failed, showing cached data: $error');
    yield cached;
  }
});

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

  String _semesterKey(SemesterScoreDto semester) {
    final year = semester.semester.year;
    final term = semester.semester.term;
    return '$year-$term';
  }

  int _findPreferredSemesterIndex(List<SemesterScoreDto> semesters) {
    if (_selectedSemesterKey == null) return -1;
    return semesters.indexWhere((semester) {
      return _semesterKey(semester) == _selectedSemesterKey;
    });
  }

  int _findDefaultSemesterIndex(List<SemesterScoreDto> semesters) {
    final index = semesters.indexWhere(
      (semester) => semester.scores.isNotEmpty,
    );
    return index >= 0 ? index : 0;
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

  String _lastUpdatedCacheKey(String studentId) {
    return '$_scoreLastUpdatedKeyPrefix.$studentId';
  }

  Future<void> _loadLastUpdatedFromCache() async {
    final db = ref.read(databaseProvider);
    final prefs = ref.read(sharedPreferencesProvider);
    final user = await db.select(db.users).getSingleOrNull();
    if (user == null) return;

    final raw = await prefs.getString(_lastUpdatedCacheKey(user.studentId));
    final parsed = raw != null ? DateTime.tryParse(raw) : null;
    if (!mounted || parsed == null) return;

    setState(() {
      _lastUpdatedAt = parsed;
    });
  }

  Future<void> _saveLastUpdatedToCache(DateTime dateTime) async {
    final db = ref.read(databaseProvider);
    final prefs = ref.read(sharedPreferencesProvider);
    final user = await db.select(db.users).getSingleOrNull();
    if (user == null) return;

    await prefs.setString(
      _lastUpdatedCacheKey(user.studentId),
      dateTime.toIso8601String(),
    );
  }

  String _formatLastUpdated(DateTime dateTime) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    final year = dateTime.year;
    final month = twoDigits(dateTime.month);
    final day = twoDigits(dateTime.day);
    final hour = twoDigits(dateTime.hour);
    final minute = twoDigits(dateTime.minute);
    return '$year/$month/$day $hour:$minute';
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
      ref.invalidate(academicPerformanceProvider);
      final refreshedState = await ref.read(academicPerformanceProvider.future);
      if (refreshedState.refreshedFromNetwork) {
        final now = DateTime.now();
        _lastUpdatedAt = now;
        await _saveLastUpdatedToCache(now);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            refreshedState.refreshedFromNetwork ? '成績資料已更新' : '目前離線，顯示快取資料',
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
                  _selectedSemesterKey = _semesterKey(appBarSemesters[idx]);
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

          final preferredIndex = _findPreferredSemesterIndex(semesters);
          if (preferredIndex >= 0) {
            _selectedIndex = preferredIndex;
          } else {
            _selectedIndex = _findDefaultSemesterIndex(semesters);
          }
          final currentData = semesters[_selectedIndex];
          _selectedSemesterKey = _semesterKey(currentData);

          return Column(
            children: [
              if (_lastUpdatedAt != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '最後更新：${_formatLastUpdated(_lastUpdatedAt!)}',
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
    final scoreColor = _getScoreColor(context);

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
          score.score?.toString() ?? _getStatusText(score.status),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: scoreColor,
          ),
        ),
      ),
    );
  }

  Color _getScoreColor(BuildContext context) {
    if (score.score != null) {
      return score.score! >= 60
          ? Colors.green.shade600
          : Theme.of(context).colorScheme.error;
    }
    if (score.status == ScoreStatus.pass ||
        score.status == ScoreStatus.creditTransfer) {
      return Colors.green.shade600;
    }
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  String _getStatusText(ScoreStatus? status) {
    return switch (status) {
      ScoreStatus.notEntered => '未輸入',
      ScoreStatus.withdraw => '撤選',
      ScoreStatus.undelivered => '未送成績',
      ScoreStatus.pass => '通過',
      ScoreStatus.fail => '不通過',
      ScoreStatus.creditTransfer => '抵免',
      _ => '-',
    };
  }
}
