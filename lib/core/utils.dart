/// Numeric and date helpers — mirrors `peak-web/lib/utils.ts`.
library;

String formatWeight(num kg, {String unit = 'kg'}) {
  if (unit == 'lbs') {
    final lbs = kg * 2.20462;
    final s = lbs == lbs.roundToDouble() ? lbs.toStringAsFixed(0) : lbs.toStringAsFixed(1);
    return '$s lbs';
  }
  final s = kg == kg.roundToDouble() ? kg.toStringAsFixed(0) : kg.toStringAsFixed(1);
  return '$s kg';
}

double epley1RM(num weight, num reps) {
  if (reps <= 0) return 0;
  if (reps == 1) return weight.toDouble();
  return weight.toDouble() * (1 + reps / 30);
}

double setVolume(num weight, num reps) => weight.toDouble() * reps;

String formatDuration(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

/// Monday-based start of week, set to 00:00:00.
DateTime startOfWeek(DateTime d) {
  final out = DateTime(d.year, d.month, d.day);
  final diff = (out.weekday - 1) % 7; // weekday: Mon=1..Sun=7
  return out.subtract(Duration(days: diff));
}

double roundToPlate(num kg) => (kg * 2).round() / 2; // 0.5 kg steps
