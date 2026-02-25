import 'package:tattoo/i18n/strings.g.dart';

// dart format off
/// Student enrollment status from the registration records (註冊編班).
enum EnrollmentStatus {
  /// 在學 — currently enrolled.
  learning,

  /// 休學 — on leave of absence.
  leaveOfAbsence,

  /// 退學 — withdrawn/dropped out.
  droppedOut;

  String toLabel() => switch (this) {
    EnrollmentStatus.learning => t.enrollmentStatus.learning,
    EnrollmentStatus.leaveOfAbsence => t.enrollmentStatus.leaveOfAbsence,
    EnrollmentStatus.droppedOut => t.enrollmentStatus.droppedOut,
  };
}
// dart format on
