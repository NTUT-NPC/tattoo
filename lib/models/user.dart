/// Student enrollment status from the registration records (註冊編班).
enum EnrollmentStatus {
  /// 在學 — currently enrolled.
  learning,

  /// 休學 — on leave of absence.
  leaveOfAbsence,

  /// 退學 — withdrawn/dropped out.
  droppedOut,
}

extension EnrollmentStatusLabel on EnrollmentStatus {
  String toLabel() => switch (this) {
    EnrollmentStatus.learning => '在學',
    EnrollmentStatus.leaveOfAbsence => '休學',
    EnrollmentStatus.droppedOut => '退學',
  };
}
