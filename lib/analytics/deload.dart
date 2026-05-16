import 'volume.dart';

double _totalWeeklyVolume(WeekRollup w) =>
    w.volumeByMuscle.values.fold<double>(0, (a, b) => a + b);

class DeloadResult {
  const DeloadResult({required this.isDeload, required this.dropPct});
  final bool isDeload;
  final double? dropPct;
}

DeloadResult detectDeload(List<WeekRollup> weeks) {
  if (weeks.length < 2) return const DeloadResult(isDeload: false, dropPct: null);
  final last = weeks.last;
  final prev = weeks[weeks.length - 2];
  final lastV = _totalWeeklyVolume(last);
  final prevV = _totalWeeklyVolume(prev);
  if (prevV <= 0) return const DeloadResult(isDeload: false, dropPct: null);
  final drop = (prevV - lastV) / prevV;
  return DeloadResult(isDeload: drop > 0.3, dropPct: drop);
}
