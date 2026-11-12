import 'package:flutter/physics.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

class AppSheetPhysics extends BouncingSheetPhysics {
  const AppSheetPhysics({
    super.bounceExtent,
    super.resistance,
    this.mass = 0.60,
    this.stiffness = 300,
    this.dampingRatio = 1.20,
  }) : assert(mass > 0),
       assert(stiffness > 0),
       assert(dampingRatio > 0);

  final double mass;
  final double stiffness;
  final double dampingRatio;

  @override
  SpringDescription get spring => SpringDescription.withDampingRatio(
    mass: mass,
    stiffness: stiffness,
    ratio: dampingRatio,
  );
}
