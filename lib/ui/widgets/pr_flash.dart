import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

/// A celebratory pill that flashes when a PR is recorded.
/// Kept subtle — no confetti library, just an animated glow.
class PrFlash extends StatefulWidget {
  const PrFlash({super.key, required this.label, this.visible = false});
  final String label;
  final bool visible;

  @override
  State<PrFlash> createState() => _PrFlashState();
}

class _PrFlashState extends State<PrFlash> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(covariant PrFlash old) {
    super.didUpdateWidget(old);
    if (widget.visible && !old.visible) {
      HapticFeedback.heavyImpact();
      _ctrl.forward(from: 0).then((_) => _ctrl.reverse());
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible && _ctrl.value == 0) return const SizedBox.shrink();
    final t = _ctrl.value;
    return Center(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        opacity: t > 0 ? 1 : 0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: PeakColors.primary,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: PeakColors.primary.withValues(alpha: 0.5 * t),
                blurRadius: 30,
                spreadRadius: 4 * t,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events_rounded, color: PeakColors.primaryForeground, size: 18),
              const SizedBox(width: 8),
              Text(widget.label, style: PeakType.buttonLabel(color: PeakColors.primaryForeground)),
            ],
          ),
        ),
      ),
    );
  }
}
