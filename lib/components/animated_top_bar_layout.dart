import 'package:flutter/material.dart';

/// A reusable layout that animates a top bar in/out without rebuilding a
/// surrounding [Scaffold.appBar].
///
/// Useful when screens/tabs need to switch between:
/// 1. an outer default app bar
/// 2. no outer app bar (for in-page custom bars like SliverAppBar)
///
/// Usage example:
///
/// ```dart
/// Scaffold(
///   body: AnimatedTopBarLayout(
///     topBarIdentity: currentTabIndex,
///     topBar: showDefaultAppBar
///         ? const AnimatedDefaultTopBar(title: '成績')
///         : null,
///     body: Center(child: Text('Content goes here')),
///   ),
/// );
/// ```
///
/// For a sub-screen that owns its own `SliverAppBar`, set [topBar] to `null`.
class AnimatedTopBarLayout extends StatelessWidget {
  const AnimatedTopBarLayout({
    super.key,
    required this.body,
    this.topBar,
    this.topBarIdentity,
    this.duration = const Duration(milliseconds: 220),
    this.switchInCurve = Curves.easeOutCubic,
    this.switchOutCurve = Curves.easeInCubic,
    this.useTopSafeArea = true,
  });

  /// Main content rendered below the animated top bar.
  final Widget body;

  /// Top bar widget to animate in/out.
  ///
  /// Pass `null` to hide the outer top bar.
  final Widget? topBar;

  /// Identity key used by [AnimatedSwitcher] to decide when to animate.
  ///
  /// Use a stable value (e.g., tab index, route name) so transitions happen
  /// only when the top bar state actually changes.
  final Object? topBarIdentity;

  /// Duration of top bar show/hide transition.
  final Duration duration;

  /// Curve for the entering top bar animation.
  final Curve switchInCurve;

  /// Curve for the exiting top bar animation.
  final Curve switchOutCurve;

  /// Whether to wrap the top bar with `SafeArea(top: true, bottom: false)`.
  ///
  /// Disable this if the parent already handles safe area insets.
  final bool useTopSafeArea;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedSwitcher(
          duration: duration,
          switchInCurve: switchInCurve,
          switchOutCurve: switchOutCurve,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SizeTransition(
                sizeFactor: animation,
                axisAlignment: -1,
                child: child,
              ),
            );
          },
          child: _buildTopBar(),
        ),
        Expanded(child: body),
      ],
    );
  }

  Widget _buildTopBar() {
    if (topBar == null) {
      return const SizedBox.shrink(key: ValueKey('animated-top-bar-hidden'));
    }

    final keyedBar = KeyedSubtree(
      key: ValueKey(topBarIdentity ?? topBar.runtimeType),
      child: topBar!,
    );

    if (!useTopSafeArea) {
      return keyedBar;
    }

    return SafeArea(bottom: false, child: keyedBar);
  }
}

/// A simple default top bar to use with [AnimatedTopBarLayout].
///
/// Usage example:
///
/// ```dart
/// AnimatedTopBarLayout(
///   topBarIdentity: 'score-tab',
///   topBar: const AnimatedDefaultTopBar(
///     title: '成績',
///     actions: [Icon(Icons.filter_list)],
///   ),
///   body: const ScoreTab(),
/// )
/// ```
class AnimatedDefaultTopBar extends StatelessWidget {
  const AnimatedDefaultTopBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.centerTitle,
    this.automaticallyImplyLeading = false,
  });

  /// Title text shown in the center/leading area based on platform style.
  final String title;

  /// Optional leading widget (e.g., back button, menu icon).
  final Widget? leading;

  /// Optional trailing action widgets.
  final List<Widget>? actions;

  /// Whether to center the title. `null` uses platform/theme defaults.
  final bool? centerTitle;

  /// Whether to infer leading widget automatically from navigation context.
  final bool automaticallyImplyLeading;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      primary: false,
      title: Text(title),
      leading: leading,
      actions: actions,
      centerTitle: centerTitle,
      automaticallyImplyLeading: automaticallyImplyLeading,
    );
  }
}
