import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

class MuscleGrid extends StatelessWidget {
  const MuscleGrid({
    super.key,
    required this.onSelect,
    this.selected,
    this.setsByMuscleThisWeek = const {},
  });

  final ValueChanged<MuscleGroup> onSelect;
  final MuscleGroup? selected;
  final Map<MuscleGroup, double> setsByMuscleThisWeek;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.05,
      children: [
        for (final m in MuscleGroup.values)
          _MuscleTile(
            muscle: m,
            sets: setsByMuscleThisWeek[m] ?? 0,
            active: selected == m,
            onTap: () {
              HapticFeedback.selectionClick();
              onSelect(m);
            },
          ),
      ],
    );
  }
}

class _MuscleTile extends StatelessWidget {
  const _MuscleTile({
    required this.muscle,
    required this.sets,
    required this.active,
    required this.onTap,
  });
  final MuscleGroup muscle;
  final double sets;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final setsLabel = sets > 0 ? '${((sets * 10).round() / 10)} sets / wk' : '0 sets';
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: PeakColors.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? PeakColors.primary : PeakColors.outlineVariant.withValues(alpha: 0.45),
            width: active ? 1.8 : 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
            if (active)
              BoxShadow(
                color: PeakColors.primary.withValues(alpha: 0.3),
                blurRadius: 16,
                spreadRadius: 0,
              ),
          ],
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              muscle.label,
              style: PeakType.headlineLg(color: PeakColors.foreground).copyWith(
                fontSize: 18,
                height: 1.1,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(setsLabel, style: PeakType.overline()),
          ],
        ),
      ),
    );
  }
}
