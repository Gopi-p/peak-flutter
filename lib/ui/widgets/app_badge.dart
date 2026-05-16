import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

enum PeakBadgeVariant { primary, secondary, outline, tertiary }

class PeakBadge extends StatelessWidget {
  const PeakBadge({
    super.key,
    required this.label,
    this.variant = PeakBadgeVariant.primary,
  });

  final String label;
  final PeakBadgeVariant variant;

  @override
  Widget build(BuildContext context) {
    final bg = switch (variant) {
      PeakBadgeVariant.primary => PeakColors.primaryContainer.withValues(alpha: 0.22),
      PeakBadgeVariant.secondary => PeakColors.surfaceContainerHigh,
      PeakBadgeVariant.tertiary => PeakColors.tertiaryContainer.withValues(alpha: 0.22),
      PeakBadgeVariant.outline => Colors.transparent,
    };
    final fg = switch (variant) {
      PeakBadgeVariant.primary => PeakColors.primary,
      PeakBadgeVariant.secondary => PeakColors.foreground,
      PeakBadgeVariant.tertiary => PeakColors.tertiary,
      PeakBadgeVariant.outline => PeakColors.foreground,
    };
    final border = variant == PeakBadgeVariant.outline
        ? Border.all(color: PeakColors.outlineVariant, width: 1)
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: border,
      ),
      child: Text(label, style: PeakType.labelMd(color: fg)),
    );
  }
}
