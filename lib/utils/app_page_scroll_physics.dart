import 'package:flutter/widgets.dart';

/// Page scrolling physics with a faster spring and earlier settling.
class AppPageScrollPhysics extends ClampingScrollPhysics {
  const AppPageScrollPhysics({
    super.parent,
    this.mass = 0.60,
    this.stiffness = 420.00,
    this.dampingRatio = 1.05,
    this.toleranceDistanceMultiplier = 2.70,
    this.toleranceVelocityMultiplier = 12.00,
  }) : assert(mass > 0),
       assert(stiffness > 0),
       assert(dampingRatio > 0),
       assert(toleranceDistanceMultiplier > 0),
       assert(toleranceVelocityMultiplier > 0);

  final double mass;
  final double stiffness;
  final double dampingRatio;

  final double toleranceDistanceMultiplier;
  final double toleranceVelocityMultiplier;

  @override
  SpringDescription get spring => SpringDescription.withDampingRatio(
    mass: mass,
    stiffness: stiffness,
    ratio: dampingRatio,
  );

  @override
  Tolerance toleranceFor(ScrollMetrics metrics) {
    final original = super.toleranceFor(metrics);

    return Tolerance(
      distance: original.distance * toleranceDistanceMultiplier,
      velocity: original.velocity * toleranceVelocityMultiplier,
      time: original.time,
    );
  }

  @override
  AppPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return AppPageScrollPhysics(
      parent: buildParent(ancestor),
      mass: mass,
      stiffness: stiffness,
      dampingRatio: dampingRatio,
      toleranceDistanceMultiplier: toleranceDistanceMultiplier,
      toleranceVelocityMultiplier: toleranceVelocityMultiplier,
    );
  }
}
