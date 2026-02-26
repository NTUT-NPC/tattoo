import 'package:drift/drift.dart' hide Column; // Avoid conflict with Flutter's Column widget
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/models/score.dart';
import 'package:tattoo/repositories/auth_repository.dart';
import 'package:tattoo/services/course_service.dart';
import 'package:tattoo/services/portal_service.dart';
import 'package:tattoo/services/student_query_service.dart';

// ==========================================
// 1. State Management (Providers)
// ==========================================

/// Represents the combined data required for the Score Screen.
/// 
/// Contains both the raw academic performance records and a mapping of 
/// course codes to their resolved human-readable names.
typedef ScorePageState = ({
  List<SemesterScoreDto> semesters,
  Map<String, String> names,
});

/// A FutureProvider that orchestrates the data fetching, SSO authentication, 
/// and local database caching for academic records.
/// 
/// **Logic Flow:**
/// 1. Wraps execution in [AuthRepository.withAuth] to ensure a valid session.
/// 2. Performs SSO to [StudentQueryService] to fetch raw semester/score DTOs.
/// 3. Extracts unique 7-digit course codes from the fetched scores.
/// 4. Queries the local Drift [AppDatabase] (Offline-first) to find existing names.
/// 5. For any missing course codes, performs a secondary SSO to [CourseService] 
///    and fetches details from the course catalog.
/// 6. Persists newly fetched course names into the database (Cache-Aside pattern).
final academicPerformanceProvider = FutureProvider.autoDispose<ScorePageState>((ref) async {
  final authRepo = ref.watch(authRepositoryProvider);
  final portalService = ref.watch(portalServiceProvider);
  final queryService = ref.watch(studentQueryServiceProvider);
  final courseService = ref.watch(courseServiceProvider);
  final db = ref.watch(databaseProvider);

  return authRepo.withAuth(() async {
    // A. Fetch core academic data from NTUT Student Query System
    await portalService.sso(PortalServiceCode.studentQueryService);
    final semesters = await queryService.getAcademicPerformance();

    // B. Collect unique course catalog codes (7-digit identifiers)
    final allCodes = semesters
        .expand((s) => s.scores)
        .map((s) => s.courseCode)
        .whereType<String>()
        .toSet();

    // C. Resolve course names from local database to minimize network requests
    final existingCourses = await (db.select(db.courses)
          ..where((t) => t.code.isIn(allCodes.toList())))
        .get();

    final Map<String, String> courseNames = {
      for (final c in existingCourses) c.code: c.nameZh ?? c.code
    };

    // D. Fetch missing names from NTUT Course System if not in local cache
    final missingCodes = allCodes.where((code) => !courseNames.containsKey(code)).toList();

    if (missingCodes.isNotEmpty) {
      // Re-authentication for Course System subsystem
      await portalService.sso(PortalServiceCode.courseService);

      await Future.wait(missingCodes.map((code) async {
        try {
          final dto = await courseService.getCourse(code);
          if (dto.nameZh != null) {
            // Update local DB using insertOnConflictUpdate for future sessions
            await db.into(db.courses).insertOnConflictUpdate(
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
          debugPrint('Failed to fetch course metadata for code ($code): $e');
        }
      }));
    }

    return (semesters: semesters, names: courseNames);
  });
});

// ==========================================
// 2. Main Screen (ScoreScreen)
// ==========================================

/// The main entry point for the academic performance feature.
/// 
/// Consumes [academicPerformanceProvider] and maintains local state for
/// semester navigation. Implements a responsive layout for displaying
/// semester summaries and detailed grade lists.
class ScoreScreen extends ConsumerStatefulWidget {
  const ScoreScreen({super.key});

  @override
  ConsumerState<ScoreScreen> createState() => _ScoreScreenState();
}

class _ScoreScreenState extends ConsumerState<ScoreScreen> {
  /// Index of the currently selected semester in the list.
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final performanceAsync = ref.watch(academicPerformanceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.nav.scores),
        centerTitle: true,
      ),
      body: performanceAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('成績載入失敗\n$err')),
        data: (data) {
          final semesters = data.semesters;
          
          // Fallback UI for users with no recorded academic history
          if (semesters.isEmpty) {
            return const Center(child: Text('目前沒有任何成績紀錄'));
          }

          // Safety check to prevent IndexOutOfBounds errors during list rebuilds
          if (_selectedIndex >= semesters.length) _selectedIndex = 0;
          final currentData = semesters[_selectedIndex];

          return Column(
            children: [
              // Navigation: Semester dropdown
              _SemesterSelector(
                semesters: semesters,
                selectedIndex: _selectedIndex,
                onChanged: (idx) => setState(() => _selectedIndex = idx),
              ),
              
              // Overview: High-level metrics for the selected term
              _SemesterSummaryCard(data: currentData),
              
              const Divider(height: 1),

              // Detailed Content: Individual course score entries
              Expanded(
                child: ListView.separated(
                  itemCount: currentData.scores.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
                  itemBuilder: (context, index) {
                    final score = currentData.scores[index];
                    
                    // Map course name using the resolved mapping table
                    final name = data.names[score.courseCode] ?? score.courseCode ?? '未知課程';
                    return _ScoreTile(score: score, courseName: name);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ==========================================
// 3. UI Components (Private Widgets)
// ==========================================

/// A sticky header component providing semester navigation via a dropdown.
class _SemesterSelector extends StatelessWidget {
  final List<SemesterScoreDto> semesters;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _SemesterSelector({
    required this.semesters,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('選擇學期', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: selectedIndex,
              onChanged: (val) => val != null ? onChanged(val) : null,
              items: List.generate(semesters.length, (index) {
                final sem = semesters[index].semester;
                return DropdownMenuItem(
                  value: index,
                  child: Text('${sem.year}-${sem.term}', 
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

/// Displays aggregate semester data (GPA/Credits) in a card format.
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

  /// Internal helper to build uniform statistic columns.
  Widget _buildStat(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(value, style: TextStyle(
          fontSize: 22, 
          fontWeight: FontWeight.bold, 
          color: Theme.of(context).colorScheme.primary
        )),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}

/// A specialized [ListTile] displaying individual course performance.
/// 
/// Handles visual indication of passing/failing grades and maps
/// technical score statuses (like "Withdrawal") to human-readable strings.
class _ScoreTile extends StatelessWidget {
  final ScoreDto score;
  final String courseName;

  const _ScoreTile({required this.score, required this.courseName});

  @override
  Widget build(BuildContext context) {
    final scoreColor = _getScoreColor(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      title: Text(courseName, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('代碼: ${score.number ?? "無"}'),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: scoreColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          score.score?.toString() ?? _getStatusText(score.status),
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: scoreColor),
        ),
      ),
    );
  }

  /// Determines tile color based on passing thresholds (>= 60) or specific statuses.
  Color _getScoreColor(BuildContext context) {
    if (score.score != null) {
      return score.score! >= 60 ? Colors.green.shade600 : Theme.of(context).colorScheme.error;
    }
    // Specific colors for statuses like "Pass" (green) or non-numeric entries
    if (score.status == ScoreStatus.pass || score.status == ScoreStatus.creditTransfer) {
      return Colors.green.shade600;
    }
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  /// Maps [ScoreStatus] enums to localized display strings.
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