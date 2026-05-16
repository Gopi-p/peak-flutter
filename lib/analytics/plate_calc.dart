const _defaultPlatesKg = <double>[25, 20, 15, 10, 5, 2.5, 1.25];

class PlateLoad {
  const PlateLoad({required this.plates, required this.achievableKg});
  final List<double> plates;
  final double achievableKg;
}

PlateLoad platesPerSide(
  double totalKg, {
  double barKg = 20,
  List<double> available = _defaultPlatesKg,
}) {
  if (totalKg < barKg) {
    return PlateLoad(plates: const [], achievableKg: barKg);
  }
  var perSide = (totalKg - barKg) / 2;
  final plates = <double>[];
  final sorted = [...available]..sort((a, b) => b.compareTo(a));
  for (final p in sorted) {
    while (perSide + 1e-6 >= p) {
      plates.add(p);
      perSide -= p;
    }
  }
  final achievable = barKg + 2 * plates.fold<double>(0, (a, b) => a + b);
  return PlateLoad(plates: plates, achievableKg: achievable);
}
