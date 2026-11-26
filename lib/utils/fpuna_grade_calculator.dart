/// Parses a percentage into hundredths of a percentage point (60% = 6000).
int? parseFpUnaPercentage(String input) {
  final parts =
      RegExp(r'^(\d{1,3})(?:[.,](\d{1,2}))?$').firstMatch(input.trim());
  if (parts == null) return null;
  final whole = int.parse(parts[1]!);
  final fraction = int.parse((parts[2] ?? '').padRight(2, '0'));
  final percentage = whole * 100 + fraction;
  return percentage <= 10000 ? percentage : null;
}

enum FpUnaFinalCall { first, second, insufficientAttendance }

/// FP-UNA undergraduate grading rules from 2026-2, Articles 12, 13 and 15.
/// Inputs are hundredths of a percentage point. Intermediate results retain
/// their exact precision until the official RP rounding step.
class FpUnaGradeCalculator {
  const FpUnaGradeCalculator.fromPep(int pep) : this._(pep * 4);

  factory FpUnaGradeCalculator.fromStages({
    required int partial1,
    required int process1,
    required int partial2,
    required int process2,
  }) {
    final stage1 = partial1 + process1;
    final stage2 = partial2 + process2;
    return FpUnaGradeCalculator._(stage1 + stage2, stage1, stage2);
  }

  const FpUnaGradeCalculator._(
    this._pepTotal, [
    this._stage1Total,
    this._stage2Total,
  ]);

  static const minimumPep = 60;
  static const minimumFinal = 50;
  static const passingThresholds = {2: 60, 3: 71, 4: 81, 5: 91};

  final int _pepTotal;
  final int? _stage1Total;
  final int? _stage2Total;

  double get pep => _pepTotal / 400;
  double? get stage1 => _stage1Total == null ? null : _stage1Total / 200;
  double? get stage2 => _stage2Total == null ? null : _stage2Total / 200;

  bool get meetsPepRequirement => _pepTotal >= minimumPep * 400;

  static FpUnaFinalCall callByAttendance(int attendance) {
    if (attendance >= 7000) return FpUnaFinalCall.first;
    if (attendance >= 5000) return FpUnaFinalCall.second;
    return FpUnaFinalCall.insufficientAttendance;
  }

  ({double rp, int roundedRp, int grade})? resultWithFinal(int finalScore) {
    if (!meetsPepRequirement || finalScore < minimumFinal * 100) return null;

    // RP = (0.6 × PEP) + (0.4 × EF), with a common denominator of 2000.
    final weighted = 3 * _pepTotal + 8 * finalScore;
    final roundedRp = (weighted + 1000) ~/ 2000;
    final grade = passingThresholds.entries.fold(
      1,
      (grade, threshold) =>
          roundedRp >= threshold.value ? threshold.key : grade,
    );
    return (rp: weighted / 2000, roundedRp: roundedRp, grade: grade);
  }

  int? finalRequiredFor(int grade) {
    final threshold = passingThresholds[grade];
    if (!meetsPepRequirement || threshold == null) return null;

    // An unrounded RP ending in .5 reaches the next integer. Round the
    // required EF upward to the nearest hundredth to avoid undershooting.
    final minimumWeightedFinal = threshold * 2000 - 1000 - 3 * _pepTotal;
    final required = (minimumWeightedFinal + 7) ~/ 8;
    if (required > 10000) return null;
    return required.clamp(minimumFinal * 100, 10000);
  }
}
