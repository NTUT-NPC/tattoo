import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

export 'package:skeletonizer/skeletonizer.dart';

/// App-wide skeleton loader with consistent styling.
///
/// Wraps content with [Skeletonizer] using [PulseEffect].
///
/// ```dart
/// AppSkeleton(
///   enabled: isLoading,
///   child: MyContent(),
/// )
/// ```
class AppSkeleton extends StatelessWidget {
  const AppSkeleton({
    super.key,
    required this.child,
    this.enabled = true,
  });

  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: enabled,
      effect: const PulseEffect(),
      child: child,
    );
  }
}
