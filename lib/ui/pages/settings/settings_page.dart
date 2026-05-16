import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/providers.dart';
import '../../../router.dart';
import '../../../services/export_import_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsStreamProvider);
    return Scaffold(
      backgroundColor: PeakColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text('Settings', style: PeakType.overline()),
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: PeakColors.primary)),
        error: (e, _) => Center(child: Text('$e', style: PeakType.bodyMd())),
        data: (s) => ListView(
          padding: const EdgeInsets.fromLTRB(
            PeakSpacing.edge,
            8,
            PeakSpacing.edge,
            PeakSpacing.edge,
          ),
          children: [
            Text(
              'Configuration',
              style: PeakType.headlineXl().copyWith(fontSize: 30, height: 1.05),
            ),
            const SizedBox(height: 16),
            PeakCard(
              title: 'Profile',
              child: _NameField(initial: s.displayName),
            ),
            const SizedBox(height: 12),
            PeakCard(
              title: 'Workout',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _RestSlider(initial: s.defaultRestSeconds),
                  const Divider(color: PeakColors.outlineVariant, height: 24),
                  _RpeToggle(initial: s.rpeEnabled),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const PeakCard(
              title: 'Data',
              child: _DataActions(),
            ),
            const SizedBox(height: 12),
            PeakCard(
              title: 'About',
              child: Text(
                'Peak v0.1 — local-first, single user. Log every rep. Climb every peak.',
                style: PeakType.bodyMd(color: PeakColors.mutedForeground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NameField extends ConsumerStatefulWidget {
  const _NameField({required this.initial});
  final String initial;
  @override
  ConsumerState<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends ConsumerState<_NameField> {
  late final TextEditingController _ctl;

  @override
  void initState() {
    super.initState();
    _ctl = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _ctl,
            style: PeakType.bodyLg(),
            cursorColor: PeakColors.primary,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Display name',
              labelStyle: PeakType.overline(),
              filled: true,
              fillColor: PeakColors.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: PeakColors.primary),
              ),
            ),
            onSubmitted: (v) async {
              await ref.read(settingsRepositoryProvider).update(displayName: v.trim());
            },
          ),
        ),
        const SizedBox(width: 10),
        IconButton(
          icon: const Icon(Icons.save_rounded, color: PeakColors.primary),
          onPressed: () async {
            await ref.read(settingsRepositoryProvider).update(displayName: _ctl.text.trim());
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Saved.')),
            );
          },
        ),
      ],
    );
  }
}

class _RestSlider extends ConsumerStatefulWidget {
  const _RestSlider({required this.initial});
  final int initial;
  @override
  ConsumerState<_RestSlider> createState() => _RestSliderState();
}

class _RestSliderState extends ConsumerState<_RestSlider> {
  late double _v;

  @override
  void initState() {
    super.initState();
    _v = widget.initial.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Default rest', style: PeakType.overline()),
        const SizedBox(height: 4),
        Text(
          '${_v.toInt()}s',
          style: PeakType.numericDisplay(),
        ),
        Slider(
          value: _v,
          min: 30,
          max: 240,
          divisions: 21,
          activeColor: PeakColors.primary,
          inactiveColor: PeakColors.outlineVariant,
          onChanged: (v) {
            HapticFeedback.selectionClick();
            setState(() => _v = v);
          },
          onChangeEnd: (v) async {
            await ref.read(settingsRepositoryProvider).update(defaultRestSeconds: v.toInt());
          },
        ),
      ],
    );
  }
}

class _RpeToggle extends ConsumerWidget {
  const _RpeToggle({required this.initial});
  final bool initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('RPE input', style: PeakType.bodyMd()),
              Text(
                'Show RPE picker on the set logger.',
                style: PeakType.overline(),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: initial,
          activeThumbColor: PeakColors.primary,
          onChanged: (v) async {
            HapticFeedback.selectionClick();
            await ref.read(settingsRepositoryProvider).update(rpeEnabled: v);
          },
        ),
      ],
    );
  }
}

class _DataActions extends ConsumerStatefulWidget {
  const _DataActions();
  @override
  ConsumerState<_DataActions> createState() => _DataActionsState();
}

class _DataActionsState extends ConsumerState<_DataActions> {
  bool _busy = false;

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      final db = ref.read(databaseProvider);
      final svc = ExportImportService(db);
      await svc.exportAndShare();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PeakColors.surfaceContainerHigh,
        title: Text('Replace all data?', style: PeakType.headlineLg()),
        content: Text(
          'Import will REPLACE all current sessions, sets, goals, and body-weight logs.',
          style: PeakType.bodyMd(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: PeakColors.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Replace + import'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      final db = ref.read(databaseProvider);
      final svc = ExportImportService(db);
      final res = await svc.pickAndImport(replace: true);
      if (!mounted) return;
      if (res != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported ${res.sessions} sessions · ${res.sets} sets.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetOnboarding() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PeakColors.surfaceContainerHigh,
        title: Text('Re-show first-launch?', style: PeakType.headlineLg()),
        content: Text(
          'Useful for testing the import / new-user flow. Does not delete data.',
          style: PeakType.bodyMd(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reset')),
        ],
      ),
    );
    if (ok != true) return;
    await resetOnboarded();
    if (!mounted) return;
    ref.read(onboardingDoneProvider.notifier).state = false;
    context.go('/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PeakButton(
          label: 'Export data (JSON)',
          icon: Icons.upload_rounded,
          variant: PeakButtonVariant.secondary,
          busy: _busy,
          onPressed: _busy ? null : _export,
        ),
        const SizedBox(height: 10),
        PeakButton(
          label: 'Import data (JSON)',
          icon: Icons.download_rounded,
          variant: PeakButtonVariant.secondary,
          busy: _busy,
          onPressed: _busy ? null : _import,
        ),
        const SizedBox(height: 10),
        PeakButton(
          label: 'Reset first-launch (testing)',
          variant: PeakButtonVariant.outline,
          onPressed: _resetOnboarding,
        ),
      ],
    );
  }
}
