import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

class PeakCard extends StatelessWidget {
  const PeakCard({
    super.key,
    this.title,
    this.action,
    required this.child,
    this.padding,
  });

  final String? title;
  final Widget? action;
  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final pad = padding ?? const EdgeInsets.all(PeakSpacing.gutter);
    return Container(
      decoration: BoxDecoration(
        color: PeakColors.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PeakColors.outlineVariant.withValues(alpha: 0.55), width: 0.5),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            PeakColors.surfaceContainerHigh.withValues(alpha: 0.85),
            PeakColors.surfaceContainer,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Padding(
              padding: EdgeInsets.fromLTRB(pad.left, pad.top, pad.right, 0),
              child: Row(
                children: [
                  Expanded(child: Text(title!, style: PeakType.headlineLg())),
                  if (action != null) action!,
                ],
              ),
            ),
          Padding(padding: pad, child: child),
        ],
      ),
    );
  }
}

class PeakSectionLabel extends StatelessWidget {
  const PeakSectionLabel(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label.toUpperCase(), style: PeakType.overline());
  }
}
