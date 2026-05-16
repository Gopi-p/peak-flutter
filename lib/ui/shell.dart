import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'theme/colors.dart';
import 'theme/typography.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    return Scaffold(
      backgroundColor: PeakColors.background,
      body: SafeArea(bottom: false, child: child),
      bottomNavigationBar: _BottomTabBar(location: location),
    );
  }
}

class _BottomTabBar extends StatelessWidget {
  const _BottomTabBar({required this.location});
  final String location;

  static const _tabs = <_TabSpec>[
    _TabSpec(path: '/today', label: 'Today', icon: Icons.bolt_rounded),
    _TabSpec(path: '/insights', label: 'Insights', icon: Icons.insights_rounded),
    _TabSpec(path: '/history', label: 'History', icon: Icons.history_rounded),
    _TabSpec(path: '/library', label: 'Library', icon: Icons.menu_book_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PeakColors.surface.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(color: PeakColors.outlineVariant.withValues(alpha: 0.4)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final t in _tabs)
                Expanded(
                  child: _TabButton(
                    spec: t,
                    active: location == t.path || location.startsWith('${t.path}/'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabSpec {
  const _TabSpec({required this.path, required this.label, required this.icon});
  final String path;
  final String label;
  final IconData icon;
}

class _TabButton extends StatelessWidget {
  const _TabButton({required this.spec, required this.active});
  final _TabSpec spec;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final fg = active ? PeakColors.primary : PeakColors.mutedForeground;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        context.go(spec.path);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(spec.icon, color: fg, size: 24),
            const SizedBox(height: 2),
            Text(
              spec.label,
              style: PeakType.overline(color: fg).copyWith(
                fontSize: 10,
                letterSpacing: 0.5,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
