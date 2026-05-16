import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

enum PeakButtonVariant { primary, secondary, outline, ghost, destructive }

enum PeakButtonSize { sm, md, lg, xl }

class PeakButton extends StatelessWidget {
  const PeakButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = PeakButtonVariant.primary,
    this.size = PeakButtonSize.md,
    this.icon,
    this.fullWidth = true,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final PeakButtonVariant variant;
  final PeakButtonSize size;
  final IconData? icon;
  final bool fullWidth;
  final bool busy;

  double get _height => switch (size) {
        PeakButtonSize.sm => 36,
        PeakButtonSize.md => 44,
        PeakButtonSize.lg => 52,
        PeakButtonSize.xl => PeakSpacing.tap + 4,
      };

  TextStyle _textStyle() {
    final color = switch (variant) {
      PeakButtonVariant.primary => PeakColors.primaryForeground,
      PeakButtonVariant.secondary => PeakColors.foreground,
      PeakButtonVariant.outline => PeakColors.foreground,
      PeakButtonVariant.ghost => PeakColors.foreground,
      PeakButtonVariant.destructive => PeakColors.destructiveForeground,
    };
    return PeakType.buttonLabel(color: color);
  }

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || busy;
    final fg = switch (variant) {
      PeakButtonVariant.primary => PeakColors.primaryForeground,
      PeakButtonVariant.secondary => PeakColors.foreground,
      PeakButtonVariant.outline => PeakColors.foreground,
      PeakButtonVariant.ghost => PeakColors.foreground,
      PeakButtonVariant.destructive => PeakColors.destructiveForeground,
    };

    final bg = switch (variant) {
      PeakButtonVariant.primary => PeakColors.primary,
      PeakButtonVariant.secondary => PeakColors.surfaceContainerHigh,
      PeakButtonVariant.outline => Colors.transparent,
      PeakButtonVariant.ghost => Colors.transparent,
      PeakButtonVariant.destructive => PeakColors.destructive,
    };

    final border = variant == PeakButtonVariant.outline
        ? const BorderSide(color: PeakColors.outlineVariant, width: 1)
        : BorderSide.none;

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: _height,
      child: Material(
        color: disabled ? bg.withValues(alpha: 0.55) : bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: border,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: disabled ? null : onPressed,
          splashColor: PeakColors.foreground.withValues(alpha: 0.06),
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: busy
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation(fg),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: fg, size: 18),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            label,
                            style: _textStyle(),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
