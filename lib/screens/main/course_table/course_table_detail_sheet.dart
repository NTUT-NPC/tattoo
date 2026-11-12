import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tattoo/components/chip_tab_switcher.dart';
import 'package:tattoo/components/dot_separated_wrap.dart';
import 'package:tattoo/components/i_school_plus_network_guide.dart';
import 'package:tattoo/components/tap_to_copy.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/repositories/course_repository.dart';
import 'package:tattoo/repositories/preferences_repository.dart';
import 'package:tattoo/screens/main/course_table/course_detail_info_card.dart';
import 'package:tattoo/screens/main/course_table/course_materials_list.dart';
import 'package:tattoo/screens/main/course_table/course_table_providers.dart';
import 'package:tattoo/screens/main/i_school_plus_providers.dart';
import 'package:tattoo/screens/main/profile/preference_providers.dart';
import 'package:tattoo/shells/centered_max_width_frame.dart';
import 'package:tattoo/utils/auto_spacing.dart';
import 'package:tattoo/utils/localized.dart';

Future<void> showCourseTableDetailSheet(
  BuildContext context, {
  required String number,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: false,
    isScrollControlled: true,
    useSafeArea: true,
    sheetAnimationStyle: const AnimationStyle(
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeOutCubic,
    ),
    builder: (context) => Align(
      alignment: Alignment.bottomCenter,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: contentMaxWidth),
        child: CourseTableDetailSheet(number: number),
      ),
    ),
  );
}

class CourseTableDetailSheet extends ConsumerStatefulWidget {
  const CourseTableDetailSheet({super.key, required this.number});

  /// The course number (課號) identifying the offering to show.
  final String number;

  @override
  ConsumerState<CourseTableDetailSheet> createState() =>
      _CourseTableDetailSheetState();
}

class _CourseTableDetailSheetState
    extends ConsumerState<CourseTableDetailSheet> {
  static const _fallbackSheetSize = 0.58;
  static const _dismissExtentFactor = 0.7;
  static const _maximumSheetSize = 1.0;
  static const _dragHandleHeight = kMinInteractiveDimension;
  static const _contentPadding = EdgeInsets.fromLTRB(12, 4, 12, 16);

  double? _headerHeight;
  List<double> _snapSizes = const [_fallbackSheetSize];
  Drag? _handleDrag;

  Widget _buildDragHandle(
    BuildContext context, [
    ScrollController? controller,
  ]) {
    final theme = Theme.of(context);
    final handleSize =
        theme.bottomSheetTheme.dragHandleSize ?? const Size(32, 4);
    return GestureDetector(
      behavior: .opaque,
      onVerticalDragStart: controller == null
          ? null
          : (details) {
              _handleDrag?.cancel();
              if (!controller.hasClients) return;
              // Use the sheet's scroll position for resizing, fling and snap.
              _handleDrag = controller.position.drag(
                details,
                () => _handleDrag = null,
              );
            },
      onVerticalDragUpdate: controller == null
          ? null
          : (details) => _handleDrag?.update(details),
      onVerticalDragEnd: controller == null
          ? null
          : (details) {
              _handleDrag?.end(details);
              _handleDrag = null;
            },
      onVerticalDragCancel: controller == null
          ? null
          : () {
              _handleDrag?.cancel();
              _handleDrag = null;
            },
      child: SizedBox(
        height: _dragHandleHeight,
        width: .infinity,
        child: Center(
          child: Container(
            width: handleSize.width,
            height: handleSize.height,
            decoration: BoxDecoration(
              color:
                  theme.bottomSheetTheme.dragHandleColor ??
                  theme.colorScheme.onSurfaceVariant,
              borderRadius: .circular(handleSize.height / 2),
            ),
          ),
        ),
      ),
    );
  }

  void _updateHeaderHeight(double height) {
    if (!mounted || _headerHeight == height) return;
    setState(() => _headerHeight = height);
  }

  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  void _expandSheet() {
    if (!_sheetController.isAttached ||
        _sheetController.size >= _maximumSheetSize) {
      return;
    }
    _sheetController.animateTo(
      _maximumSheetSize,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _handleDrag?.cancel();
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(courseOfferingProvider(widget.number));

    final content = switch (detailAsync) {
      AsyncData(value: final detail?) => LayoutBuilder(
        builder: (context, constraints) {
          final initialSize = switch (_headerHeight) {
            final height? =>
              ((height +
                          _dragHandleHeight +
                          _contentPadding.vertical +
                          MediaQuery.paddingOf(context).bottom) /
                      constraints.maxHeight)
                  .clamp(0.01, _maximumSheetSize),
            null => _fallbackSheetSize,
          };
          final minimumSize = initialSize * _dismissExtentFactor;
          if (_snapSizes.single != initialSize) {
            _snapSizes = [initialSize];
          }
          return DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: initialSize,
            minChildSize: minimumSize,
            maxChildSize: _maximumSheetSize,
            snap: true,
            snapSizes: _snapSizes,
            shouldCloseOnMinExtent: true,
            expand: false,
            builder: (context, scrollController) => SafeArea(
              top: false,
              child: Column(
                children: [
                  _buildDragHandle(context, scrollController),
                  Expanded(
                    child: Padding(
                      padding: _contentPadding,
                      child: _CourseDetailContent(
                        detail: detail,
                        scrollController: scrollController,
                        onTabSelected: _expandSheet,
                        onHeaderHeightChanged: _updateHeaderHeight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      AsyncData() => SafeArea(
        top: false,
        child: _DetailState(
          icon: Icons.search_off_outlined,
          message: t.courseTable.notFound,
        ),
      ),
      AsyncError(:final error) => SafeArea(
        top: false,
        child: _DetailState(
          icon: Icons.error_outline,
          message: 'Error: $error',
        ),
      ),
      _ => const SizedBox(
        height: 160,
        child: Center(child: CircularProgressIndicator()),
      ),
    };
    if (detailAsync case AsyncData(value: _?)) {
      return content;
    }
    return Column(
      mainAxisSize: .min,
      children: [_buildDragHandle(context), content],
    );
  }
}

class _CourseDetailContent extends ConsumerWidget {
  const _CourseDetailContent({
    required this.detail,
    required this.scrollController,
    required this.onTabSelected,
    required this.onHeaderHeightChanged,
  });

  final CourseOfferingDetail detail;
  final ScrollController scrollController;
  final VoidCallback onTabSelected;
  final ValueChanged<double> onHeaderHeightChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final overview = detail.overview;
    final title =
        _normalizedText(localized(overview.nameZh, overview.nameEn)) ??
        _normalizedText(overview.number) ??
        t.general.unknown;
    final syllabusAsync = switch (overview.number) {
      final courseNumber? => ref.watch(
        syllabusProvider((
          courseNumber: courseNumber,
          language: switch (LocaleSettings.currentLocale) {
            .zhTw => .zhTw,
            .enUs => .enUs,
          },
        )),
      ),
      null => null,
    };
    final syllabus = switch (syllabusAsync) {
      AsyncData(value: final syllabuses) => _SyllabusTabs(
        details: syllabuses,
        onTabSelected: onTabSelected,
      ),
      AsyncError(:final error) => _DetailState(
        icon: Icons.error_outline,
        message: 'Error: $error',
      ),
      AsyncLoading() => const Padding(
        padding: .symmetric(horizontal: 8),
        child: LinearProgressIndicator(),
      ),
      null => const SizedBox.shrink(),
    };
    final iSchoolKey = switch ((overview.id, overview.number)) {
      (final id, final number?) when id >= 0 => (
        courseOfferingId: id,
        courseNumber: number,
      ),
      _ => null,
    };
    final showCourseRoster =
        iSchoolKey != null && ref.pref(PrefKey.showCourseRoster);
    final showCourseMaterials =
        iSchoolKey != null && ref.pref(PrefKey.showCourseMaterials);
    final typeTooltipKey = GlobalKey<TooltipState>();

    final header = Column(
      mainAxisSize: .min,
      children: [
        SizedBox(
          width: .infinity,
          child: Column(
            spacing: 2,
            children: [
              Text(
                title.spaced,
                textAlign: .center,
                style: theme.textTheme.titleLarge,
              ),
              DotSeparatedWrap(
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                children: [
                  Text(
                    '${detail.semesterYear}-${detail.semesterTerm}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  TapToCopy(
                    copyText: overview.number.toString(),
                    child: Text(
                      overview.number.toString(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Tooltip(
                    key: typeTooltipKey,
                    message: t.courseDetail.infoCard.typeDescription.spaced,
                    textAlign: TextAlign.left,
                    triggerMode: TooltipTriggerMode.manual,
                    showDuration: const Duration(seconds: 5),
                    child: Semantics(
                      button: true,
                      child: Material(
                        type: MaterialType.transparency,
                        child: InkWell(
                          onTap: () => typeTooltipKey.currentState
                              ?.ensureTooltipVisible(),
                          customBorder: const StadiumBorder(),
                          child: Padding(
                            padding: const .fromLTRB(0, 1, 2, 1),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Transform.translate(
                                  offset: const Offset(0, -2),
                                  child: Text(
                                    overview.courseType?.symbol ?? '-',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          color: theme
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                  ),
                                ),
                                Icon(
                                  Icons.help_outline,
                                  size: 12,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        CourseDetailInfoCard(detail: detail),
      ],
    );

    return ListView(
      controller: scrollController,
      padding: .zero,
      children: [
        if (showCourseRoster || showCourseMaterials)
          _CourseDetailTabs(
            key: ValueKey((showCourseRoster, showCourseMaterials)),
            iSchoolKey: iSchoolKey,
            syllabus: syllabus,
            showRoster: showCourseRoster,
            showMaterials: showCourseMaterials,
            onTabSelected: onTabSelected,
            header: header,
            onHeaderHeightChanged: onHeaderHeightChanged,
          )
        else ...[
          _DetailHeaderHeight(
            onChanged: onHeaderHeightChanged,
            child: header,
          ),
          syllabus,
        ],
        SizedBox(height: MediaQuery.viewInsetsOf(context).bottom),
      ],
    );
  }
}

enum _CourseDetailTab { syllabus, roster, materials }

class _CourseDetailTabs extends StatefulWidget {
  const _CourseDetailTabs({
    super.key,
    required this.iSchoolKey,
    required this.syllabus,
    required this.showRoster,
    required this.showMaterials,
    required this.onTabSelected,
    required this.header,
    required this.onHeaderHeightChanged,
  });
  final bool showRoster;
  final bool showMaterials;
  final VoidCallback onTabSelected;

  final Widget header;
  final ValueChanged<double> onHeaderHeightChanged;

  final CourseISchoolKey iSchoolKey;
  final Widget syllabus;

  @override
  State<_CourseDetailTabs> createState() => _CourseDetailTabsState();
}

class _CourseDetailTabsState extends State<_CourseDetailTabs>
    with SingleTickerProviderStateMixin {
  late final TabController _controller;
  late final List<_CourseDetailTab> _tabs;
  var _rosterVisited = false;
  var _materialsVisited = false;

  @override
  void initState() {
    super.initState();
    _tabs = [
      .syllabus,
      if (widget.showRoster) .roster,
      if (widget.showMaterials) .materials,
    ];
    _controller = TabController(length: _tabs.length, vsync: this)
      ..addListener(_handleTabChanged);
  }

  void _handleTabChanged() {
    if (!mounted) return;
    setState(() {
      if (_tabs[_controller.index] == .roster) _rosterVisited = true;
      if (_tabs[_controller.index] == .materials) _materialsVisited = true;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _DetailHeaderHeight(
          onChanged: widget.onHeaderHeightChanged,
          child: Column(
            mainAxisSize: .min,
            children: [
              widget.header,
              TabBar(
                controller: _controller,
                onTap: (_) => widget.onTabSelected(),
                tabs: [
                  for (final tab in _tabs)
                    Tab(
                      text: switch (tab) {
                        .syllabus => t.courseTable.detail.tabs.syllabus.spaced,
                        .roster => t.courseTable.detail.tabs.roster.spaced,
                        .materials =>
                          t.courseTable.detail.tabs.materials.spaced,
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
        Offstage(
          offstage: _tabs[_controller.index] != .syllabus,
          child: Padding(
            padding: const .only(top: 8),
            child: widget.syllabus,
          ),
        ),
        if (_rosterVisited)
          Offstage(
            key: const ValueKey<_CourseDetailTab>(.roster),
            offstage: _tabs[_controller.index] != .roster,
            child: Padding(
              padding: const .only(top: 8),
              child: _CourseISchoolPane(
                iSchoolKey: widget.iSchoolKey,
                type: .roster,
              ),
            ),
          ),
        if (_materialsVisited)
          Offstage(
            key: const ValueKey<_CourseDetailTab>(.materials),
            offstage: _tabs[_controller.index] != .materials,
            child: Padding(
              padding: const .only(top: 8),
              child: _CourseISchoolPane(
                iSchoolKey: widget.iSchoolKey,
                type: .materials,
              ),
            ),
          ),
      ],
    );
  }
}

enum _CourseISchoolPaneType { roster, materials }

class _DetailHeaderHeight extends SingleChildRenderObjectWidget {
  const _DetailHeaderHeight({required this.onChanged, required super.child});

  final ValueChanged<double> onChanged;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderDetailHeaderHeight(onChanged);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderDetailHeaderHeight renderObject,
  ) {
    renderObject.onChanged = onChanged;
  }
}

class _RenderDetailHeaderHeight extends RenderProxyBox {
  _RenderDetailHeaderHeight(this.onChanged);

  ValueChanged<double> onChanged;
  double? _lastHeight;

  @override
  void performLayout() {
    super.performLayout();
    final height = size.height;
    if (_lastHeight == height) return;
    _lastHeight = height;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (attached) onChanged(height);
    });
  }
}

class _CourseISchoolPane extends ConsumerStatefulWidget {
  const _CourseISchoolPane({
    required this.iSchoolKey,
    required this.type,
  });

  final _CourseISchoolPaneType type;

  final CourseISchoolKey iSchoolKey;

  @override
  ConsumerState<_CourseISchoolPane> createState() => _CourseISchoolPaneState();
}

class _CourseISchoolPaneState extends ConsumerState<_CourseISchoolPane> {
  var _showNetworkGuide = false;
  var _probeSnackbarShown = false;
  var _isInitialAttempt = true;
  // Keep the last attempt's outcome available to the guide and retry UI.
  // A new detail pane starts with the automatic, TTL-aware providers again.
  var _manualMaterialsRefresh = false;

  FutureProvider<CourseISchoolRefreshResult> get _materialsRefreshProvider =>
      _manualMaterialsRefresh
      ? courseMaterialsManualRefreshProvider(widget.iSchoolKey)
      : courseMaterialsRefreshProvider(widget.iSchoolKey);

  FutureProvider<void> get _materialsAvailabilityProvider =>
      _manualMaterialsRefresh
      ? courseMaterialsManualAvailabilityProvider(widget.iSchoolKey)
      : courseMaterialsAvailabilityProvider(widget.iSchoolKey);

  void _refreshMaterials() {
    if (ref.read(_materialsRefreshProvider).isLoading ||
        ref.read(_materialsAvailabilityProvider).isLoading) {
      return;
    }
    setState(() {
      _manualMaterialsRefresh = true;
      _showNetworkGuide = false;
      _probeSnackbarShown = false;
      _isInitialAttempt = false;
    });
    ref
      ..invalidate(courseMaterialsManualAvailabilityProvider(widget.iSchoolKey))
      ..invalidate(courseMaterialsManualRefreshProvider(widget.iSchoolKey));
  }

  void _retry() {
    if (widget.type == .materials) {
      _refreshMaterials();
      return;
    }
    final refresh = ref.read(
      courseStudentRosterRefreshProvider(widget.iSchoolKey),
    );
    final availability = ref.read(
      courseStudentRosterAvailabilityProvider(widget.iSchoolKey),
    );
    if (refresh.isLoading || availability.isLoading) return;
    setState(() {
      _showNetworkGuide = false;
      _probeSnackbarShown = false;
      _isInitialAttempt = false;
    });
    ref
      ..invalidate(iSchoolPlusAvailabilityProvider)
      ..invalidate(
        courseStudentRosterProvider(widget.iSchoolKey),
      )
      ..invalidate(
        courseStudentRosterAvailabilityProvider(widget.iSchoolKey),
      )
      ..invalidate(
        courseStudentRosterRefreshProvider(widget.iSchoolKey),
      );
  }

  void _openNetworkGuide() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() => _showNetworkGuide = true);
  }

  void _showUpdateSnackbar(String message, String actionLabel) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message.spaced),
          persist: false,
          action: SnackBarAction(
            label: actionLabel.spaced,
            onPressed: _openNetworkGuide,
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);
    if (widget.type != .materials) return content;
    final refreshing =
        ref.watch(_materialsRefreshProvider).isLoading ||
        ref.watch(_materialsAvailabilityProvider).isLoading;
    return Column(
      mainAxisSize: .min,
      children: [
        content,
        Padding(
          padding: const .fromLTRB(8, 8, 8, 16),
          child: OutlinedButton.icon(
            onPressed: refreshing ? null : _refreshMaterials,
            icon: SizedBox.square(
              dimension: 24,
              child: refreshing
                  ? const CircularProgressIndicator(strokeWidth: 2)
                  : const Icon(Icons.refresh),
            ),
            label: Text(
              Translations.of(context)
                  .courseTable
                  .detail
                  .materials
                  .refresh
                  .spaced,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    final refreshProvider = widget.type == .materials
        ? _materialsRefreshProvider
        : courseStudentRosterRefreshProvider(widget.iSchoolKey);
    final availabilityProvider = widget.type == .materials
        ? _materialsAvailabilityProvider
        : courseStudentRosterAvailabilityProvider(widget.iSchoolKey);
    final cacheAsync = widget.type == .materials
        ? ref
              .watch(courseMaterialsProvider(widget.iSchoolKey))
              .whenData(
                (list) => (
                  fetchedAt: list.fetchedAt,
                  isEmpty: list.materials.isEmpty,
                  content: CourseMaterialsList(
                    materials: list.materials,
                    onLearnMore: _openNetworkGuide,
                  ),
                ),
              )
        : ref
              .watch(courseStudentRosterProvider(widget.iSchoolKey))
              .whenData(
                (roster) => (
                  fetchedAt: roster.fetchedAt,
                  isEmpty: roster.students.isEmpty,
                  content:
                      _CourseRosterTable(students: roster.students) as Widget,
                ),
              );
    bool hasCacheNow() => widget.type == .materials
        ? ref
                  .read(courseMaterialsProvider(widget.iSchoolKey))
                  .value
                  ?.fetchedAt !=
              null
        : ref
                  .read(courseStudentRosterProvider(widget.iSchoolKey))
                  .value
                  ?.fetchedAt !=
              null;
    final refreshAsync = ref.watch(refreshProvider);
    final availabilityAsync = ref.watch(availabilityProvider);
    final rosterStrings = Translations.of(context).courseTable.detail.roster;
    final materialStrings = Translations.of(context)
        .courseTable
        .detail
        .materials;
    final strings = widget.type == .materials
        ? (
            empty: materialStrings.empty,
            loadFailed: materialStrings.loadFailed,
            networkSnackbar: materialStrings.networkSnackbar,
            updateFailed: materialStrings.updateFailed,
            updateSuccess: materialStrings.updateSuccess,
            backToList: materialStrings.backToMaterials,
          )
        : (
            empty: rosterStrings.empty,
            loadFailed: rosterStrings.loadFailed,
            networkSnackbar: rosterStrings.networkSnackbar,
            updateFailed: rosterStrings.updateFailed,
            updateSuccess: rosterStrings.updateSuccess,
            backToList: rosterStrings.backToRoster,
          );
    final networkStrings = Translations.of(context).iSchoolPlus.network;

    ref.listen(availabilityProvider, (previous, next) {
      if (!_hasNewError(previous, next)) return;
      final hasCache = hasCacheNow();
      final refresh = ref.read(refreshProvider);
      if (!hasCache ||
          refresh.value?.refreshed == true ||
          _probeSnackbarShown) {
        return;
      }
      _probeSnackbarShown = true;
      _showUpdateSnackbar(
        strings.networkSnackbar,
        networkStrings.learnMore,
      );
    });

    ref.listen(refreshProvider, (previous, next) {
      if (_hasNewError(previous, next)) {
        final hasCache = hasCacheNow();
        if (hasCache) {
          _showUpdateSnackbar(
            strings.updateFailed,
            networkStrings.learnMore,
          );
        }
        return;
      }
      if (widget.type == .materials && (next.isLoading || next.hasError)) {
        return;
      }
      final result = next.value;
      if (result == null || !result.refreshed) return;
      if (_showNetworkGuide && mounted) {
        setState(() => _showNetworkGuide = false);
      }
      if (!result.hadCacheAtStart || !mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(strings.updateSuccess.spaced),
            persist: false,
          ),
        );
    });

    final guideUrl = iSchoolPlusNetworkGuideUri(
      ref.pref(PrefKey.iSchoolPlusNetworkGuideUrl),
    );
    final roster = cacheAsync.value;
    final hasCache = roster?.fetchedAt != null;
    final attemptRunning =
        refreshAsync.isLoading || availabilityAsync.isLoading;
    final retryEnabled = canRetryCourseISchool(
      refreshAsync,
      availabilityAsync,
    );

    if (cacheAsync.isLoading) {
      return _CourseISchoolLoading(
        onLearnMore: _openNetworkGuide,
      );
    }
    if (cacheAsync.hasError) {
      return _DetailState(
        icon: Icons.error_outline,
        message: strings.loadFailed,
        onRetry: _retry,
      );
    }

    final presentation = widget.type == .materials && _showNetworkGuide
        ? CourseISchoolPresentation.guide
        : courseISchoolPresentation(
            hasCache: hasCache,
            showNetworkGuide: _showNetworkGuide,
            allowEarlyNetworkGuide: _isInitialAttempt,
            refresh: refreshAsync.whenData(
              (result) =>
                  result.refreshed &&
                  (widget.type != .materials ||
                      (!refreshAsync.isLoading && !refreshAsync.hasError)),
            ),
            availability: availabilityAsync,
          );
    switch (presentation) {
      case .guide:
        return ISchoolPlusNetworkGuide(
          guideUrl: guideUrl,
          onBack: hasCache
              ? (
                  label: strings.backToList,
                  onPressed: () => setState(() => _showNetworkGuide = false),
                )
              : null,
          onRetry: _retry,
          retryEnabled: retryEnabled,
          retryInProgress: attemptRunning,
        );
      case .genericFailure:
        return _DetailState(
          icon: Icons.error_outline,
          message: strings.loadFailed,
          onRetry: retryEnabled ? _retry : null,
        );
      case .loading:
        return _CourseISchoolLoading(onLearnMore: _openNetworkGuide);
      case .content:
        if (roster!.isEmpty) {
          return _DetailState(
            icon: widget.type == .materials
                ? Icons.folder_off_outlined
                : Icons.group_off_outlined,
            message: strings.empty,
          );
        }
        return roster.content;
    }
  }
}

bool _hasNewError<T>(AsyncValue<T>? previous, AsyncValue<T> next) {
  return next.hasError &&
      (previous?.hasError != true ||
          !identical(previous?.error, next.error) ||
          !identical(previous?.stackTrace, next.stackTrace));
}

class _CourseISchoolLoading extends StatelessWidget {
  const _CourseISchoolLoading({required this.onLearnMore});

  final VoidCallback onLearnMore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = Translations.of(context).iSchoolPlus.network;
    final hintStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return SizedBox(
      height: 160,
      child: Center(
        child: Column(
          mainAxisSize: .min,
          spacing: 16,
          children: [
            const CircularProgressIndicator(),
            Wrap(
              alignment: .center,
              crossAxisAlignment: .center,
              children: [
                Text(strings.loadingNetworkHint.spaced, style: hintStyle),
                Semantics(
                  link: true,
                  child: GestureDetector(
                    behavior: .opaque,
                    onTap: onLearnMore,
                    child: Text(
                      strings.learnMore.spaced,
                      style: hintStyle?.copyWith(
                        color: theme.colorScheme.primary,
                        decoration: .underline,
                        decorationColor: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseRosterTable extends StatelessWidget {
  const _CourseRosterTable({required this.students});

  final List<Student> students;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = Translations.of(context).courseTable.detail.roster;
    return Card(
      margin: const .all(8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: .circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      color: theme.colorScheme.surfaceContainer,
      clipBehavior: .antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          scrollDirection: .horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              columns: [
                DataColumn(label: Text(strings.studentId.spaced)),
                DataColumn(label: Text(strings.name.spaced)),
              ],
              rows: [
                for (final student in students)
                  DataRow(
                    cells: [
                      DataCell(Text(student.studentId.spaced)),
                      DataCell(Text((student.name ?? '-').spaced)),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SyllabusTabs extends StatefulWidget {
  const _SyllabusTabs({
    required this.details,
    required this.onTabSelected,
  });

  final List<TeacherSyllabusDetail> details;
  final VoidCallback onTabSelected;

  @override
  State<_SyllabusTabs> createState() => _SyllabusTabsState();
}

class _SyllabusTabsState extends State<_SyllabusTabs>
    with SingleTickerProviderStateMixin {
  late TabController _controller;
  var _lastSelectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = _createController();
  }

  @override
  void didUpdateWidget(_SyllabusTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.details.length == widget.details.length) {
      return;
    }

    final previousTeacherCode = oldWidget.details.isEmpty
        ? null
        : oldWidget.details[_controller.index].teacher.code;
    final updatedIndex = previousTeacherCode == null
        ? -1
        : widget.details.indexWhere(
            (detail) => detail.teacher.code == previousTeacherCode,
          );
    _controller.dispose();
    _controller = _createController(
      initialIndex: updatedIndex < 0 ? 0 : updatedIndex,
    );
  }

  TabController _createController({int initialIndex = 0}) {
    _lastSelectedIndex = initialIndex;
    final controller = TabController(
      length: widget.details.length,
      initialIndex: initialIndex,
      vsync: this,
    );
    controller.addListener(_handleTabChanged);
    return controller;
  }

  void _handleTabChanged() {
    if (_controller.index != _lastSelectedIndex) {
      _lastSelectedIndex = _controller.index;
      widget.onTabSelected();
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.details.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        if (widget.details.length > 1)
          ChipTabSwitcher(
            controller: _controller,
            padding: const .symmetric(horizontal: 8),
            tabs: [
              for (final detail in widget.details)
                (_normalizedText(
                          localized(
                            detail.teacher.nameZh,
                            detail.teacher.nameEn,
                          ),
                        ) ??
                        t.general.unknown)
                    .spaced,
            ],
          ),
        _SyllabusSections(detail: widget.details[_controller.index]),
      ],
    );
  }
}

class _SyllabusSections extends StatelessWidget {
  const _SyllabusSections({required this.detail});

  final TeacherSyllabusDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const .all(8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: .circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      color: theme.colorScheme.surfaceContainer,
      child: SelectionArea(
        child: Padding(
          padding: const .all(12),
          child: Column(
            crossAxisAlignment: .start,
            children: [
              for (final (index, section)
                  in detail.syllabus.sections.indexed) ...[
                if (index > 0) const Divider(height: 24),
                Text(
                  section.title.spaced,
                  style: theme.textTheme.titleMedium,
                ),
                if (_normalizedText(section.content) case final content?)
                  Padding(
                    padding: const .only(top: 6),
                    child: Text(content.spaced),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailState extends StatelessWidget {
  const _DetailState({
    required this.icon,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 160,
      child: Center(
        child: Column(
          mainAxisSize: .min,
          spacing: 8,
          children: [
            Icon(icon, color: colorScheme.onSurfaceVariant),
            Text(
              message.spaced,
              textAlign: .center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            if (onRetry case final onRetry?)
              TextButton(
                onPressed: onRetry,
                child: Text(t.general.retry.spaced),
              ),
          ],
        ),
      ),
    );
  }
}

String? _normalizedText(String? value) {
  return switch (value?.trim()) {
    final value? when value.isNotEmpty => value,
    _ => null,
  };
}
