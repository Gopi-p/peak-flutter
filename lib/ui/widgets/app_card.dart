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

  /// Padding for [child]. Defaults to `EdgeInsets.all(PeakSpacing.gutter)`.
  /// Pass `EdgeInsets.zero` for full-bleed children (e.g. `ListTile`s);
  /// the title header still gets its own inset so it isn't flush to the edge.
  final EdgeInsets? padding;

  static const _defaultPad = EdgeInsets.all(PeakSpacing.gutter);

  @override
  Widget build(BuildContext context) {
    final pad = padding ?? _defaultPad;
    // Title padding is decoupled from child padding so a zero-padding card
    // (used by full-bleed lists) still gets a properly inset header.
    final titlePad = padding == null
        ? EdgeInsets.fromLTRB(pad.left, pad.top, pad.right, 0)
        : EdgeInsets.fromLTRB(
            _defaultPad.left,
            _defaultPad.top,
            _defaultPad.right,
            pad.top > 0 ? 0 : _defaultPad.bottom,
          );

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
              padding: titlePad,
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
