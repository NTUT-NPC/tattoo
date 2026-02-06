/// Special score statuses from the student query system (學生查詢專區).
///
/// When a course has no numeric grade, it receives one of these statuses instead.
enum ScoreStatus {
  /// N — 未輸入 (Not entered).
  notEntered,

  /// W — 撤選 (Withdraw).
  withdraw,

  /// # — 未送成績 (Undelivered).
  undelivered,

  /// P — 通過 (Pass).
  pass,

  /// F — 不通過 (Fail).
  fail,

  /// 抵免 (Credit transfer from another institution).
  creditTransfer,
}
