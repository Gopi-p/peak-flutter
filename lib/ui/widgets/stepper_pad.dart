import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

/// Stepper — the only weight/reps input path. Big tap targets, no iOS keyboard.
class StepperPad extends StatelessWidget {
  const StepperPad({
    super.key,
    required this.value,
    required this.onChanged,
    this.step = 1,
    this.min = 0,
    this.max = double.infinity,
    this.label,
    this.format,
  });

  final num value;
  final ValueChanged<double> onChanged;
  final double step;
  final double min;
  final double max;
  final String? label;
  final String Function(num value)? format;

  void _dec() {
    final next = (value - step).clamp(min, max).toDouble();
    HapticFeedback.lightImpact();
    onChanged(double.parse(next.toStringAsFixed(2)));
  }

  void _inc() {
    final next = (value + step).clamp(min, max).toDouble();
    HapticFeedback.lightImpact();
    onChanged(double.parse(next.toStringAsFixed(2)));
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StepButton(icon: Icons.remove_rounded, onTap: _dec),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (label != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    label!.toUpperCase(),
                    style: PeakType.overline(),
                  ),
                ),
              Text(
                format != null ? format!(value) : '$value',
                style: PeakType.numericDisplay(),
              ),
            ],
          ),
        ),
        _StepButton(icon: Icons.add_rounded, onTap: _inc),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        height: 64,
        width: 64,
        decoration: BoxDecoration(
          color: PeakColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: PeakColors.outlineVariant.withValues(alpha: 0.6), width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(icon, size: 26, color: PeakColors.foreground),
      ),
    );
  }
}
