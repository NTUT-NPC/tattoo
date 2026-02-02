import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:tattoo/services/course_service.dart';
import 'package:tattoo/services/i_school_plus_service.dart';
import 'package:tattoo/services/portal_service.dart';

class TestPage extends StatefulWidget {
  const TestPage({
    super.key,
    required this.username,
    required this.user,
  });

  final String username;
  final UserDTO user;

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  final _portalService = PortalService();
  final _courseService = CourseService();
  final _iSchoolPlusService = ISchoolPlusService();

  bool _isLoading = false;
  PortalServiceCode? _activeService;

  String _serviceLabel(PortalServiceCode service) {
    switch (service) {
      case PortalServiceCode.courseService:
        return 'courseService';
      case PortalServiceCode.iSchoolPlusService:
        return 'iSchoolPlusService';
      case PortalServiceCode.scoreService:
        return 'scoreService';
    }
  }

  Future<void> _showResultSheet({
    required String title,
    required String message,
  }) {
    final maxHeight = MediaQuery.of(context).size.height * 0.85;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      constraints: BoxConstraints(maxHeight: maxHeight),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: SelectableText(message),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _runService(PortalServiceCode service) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _activeService = service;
    });

    final stopwatch = Stopwatch()..start();

    try {
      await _portalService.sso(service);

      final buffer = StringBuffer();
      switch (service) {
        case PortalServiceCode.courseService:
          final semesterList = await _courseService.getCourseSemesterList(
            widget.username,
          );

          buffer.writeln('學期列表:');
          if (semesterList.isEmpty) {
            buffer.writeln('- （無）');
          } else {
            for (final semester in semesterList) {
              buffer.writeln('- ${semester.year}-${semester.semester}');
            }
          }

          if (semesterList.isNotEmpty) {
            final courseSchedule = await _courseService.getCourseTable(
              username: widget.username,
              semester: semesterList.first,
            );
            buffer.writeln('\n課表列表:');
            if (courseSchedule.isEmpty) {
              buffer.writeln('- （無）');
            } else {
              for (final schedule in courseSchedule) {
                final course = schedule.course;
                final courseLabel = course?.name ?? course?.id ?? '未知課程';
                final teacher = schedule.teacher?.name ?? '未知老師';
                final room = schedule.classroom?.name ?? '未知教室';
                final time = schedule.schedule
                    ?.map((pair) => '${pair.$1.name}-${pair.$2.code}')
                    .join(', ');
                buffer.writeln(
                  '- $courseLabel | $teacher | $room${time == null ? '' : ' | $time'}',
                );
              }
            }

            var courseRef = courseSchedule
                .map((schedule) => schedule.course)
                .where((course) => course?.id != null)
                .firstOrNull;
            if (courseRef != null) {
              final course = await _courseService.getCourse(courseRef.id!);
              final courseName =
                  course.nameZh ?? course.nameEn ?? course.id ?? '未知';
              buffer.writeln('\n課程詳情:');
              buffer.writeln('- 名稱: $courseName');
              buffer.writeln('- 代碼: ${course.id ?? '未知'}');
              buffer.writeln('- 學分: ${course.credits ?? '未知'}');
              buffer.writeln('- 時數: ${course.hours ?? '未知'}');
              final description =
                  course.descriptionZh ?? course.descriptionEn ?? '（無）';
              buffer.writeln('- 說明: $description');
            }
          }
          break;
        case PortalServiceCode.iSchoolPlusService:
          const courseNumber = '340689';
          final materials = await _iSchoolPlusService.getMaterials(
            courseNumber,
          );
          buffer.writeln('教材列表:');
          if (materials.isEmpty) {
            buffer.writeln('- （無）');
          } else {
            for (final material in materials) {
              buffer.writeln(
                '- ${material.title ?? '無標題'} (${material.href ?? '無連結'})',
              );
            }
          }

          if (materials.isNotEmpty) {
            final firstMaterial = await _iSchoolPlusService.getMaterial(
              materials.first,
            );
            buffer.writeln('\n第一個教材下載連結:');
            buffer.writeln('- ${materials.first.title ?? '無標題'}');
            buffer.writeln('- ${firstMaterial.downloadUrl}');
          }

          if (materials.length > 1) {
            final secondMaterial = await _iSchoolPlusService.getMaterial(
              materials[1],
            );
            buffer.writeln('\n第二個教材下載連結:');
            buffer.writeln('- ${materials[1].title ?? '無標題'}');
            buffer.writeln('- ${secondMaterial.downloadUrl}');
          }
          break;
        case PortalServiceCode.scoreService:
          buffer.writeln('已完成 SSO，成績服務尚未實作。');
          break;
      }

      stopwatch.stop();
      buffer.writeln('完成時間: ${stopwatch.elapsedMilliseconds} ms');

      if (!mounted) return;
      await _showResultSheet(
        title: '${_serviceLabel(service)} 查詢結果',
        message: buffer.toString(),
      );
    } catch (e, stack) {
      stopwatch.stop();
      log('Test query failed', error: e, stackTrace: stack);
      if (!mounted) return;
      await _showResultSheet(
        title: '${_serviceLabel(service)} 查詢失敗',
        message: e.toString(),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _activeService = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.user.name?.trim();
    final displayName = (name == null || name.isEmpty) ? '（未知姓名）' : name;

    return Scaffold(
      appBar: AppBar(title: const Text('Test')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Text('姓名：$displayName'),
            Text('學號：${widget.username}'),
            if (_isLoading && _activeService != null)
              Text('查詢中：${_serviceLabel(_activeService!)}'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () => _runService(PortalServiceCode.courseService),
              child: const Text('courseService'),
            ),
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () => _runService(PortalServiceCode.iSchoolPlusService),
              child: const Text('iSchoolPlusService'),
            ),
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () => _runService(PortalServiceCode.scoreService),
              child: const Text('scoreService'),
            ),
          ],
        ),
      ),
    );
  }
}

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
