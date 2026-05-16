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

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});
  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  int _step = 0; // 0 = welcome, 1 = name (new user), 2 = importing
  final _nameCtl = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _nameCtl.dispose();
    super.dispose();
  }

  Future<void> _newUserFlow() async {
    setState(() => _step = 1);
  }

  Future<void> _saveNameAndProceed() async {
    final name = _nameCtl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Tell Peak your name.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(settingsRepositoryProvider).update(displayName: name);
      await markOnboarded();
      ref.read(onboardingDoneProvider.notifier).state = true;
      if (mounted) context.go('/today');
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _importFlow() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final db = ref.read(databaseProvider);
      final service = ExportImportService(db);
      final result = await service.pickAndImport(replace: true);
      if (result == null) {
        // user cancelled
        setState(() => _busy = false);
        return;
      }
      await markOnboarded();
      ref.read(onboardingDoneProvider.notifier).state = true;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Imported ${result.sessions} sessions · ${result.sets} sets.',
            ),
          ),
        );
        context.go('/today');
      }
    } catch (e) {
      setState(() => _error = 'Import failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PeakColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(PeakSpacing.edge, 24, PeakSpacing.edge, PeakSpacing.edge),
          child: _step == 0 ? _buildWelcome() : _buildNameStep(),
        ),
      ),
    );
  }

  Widget _buildWelcome() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        Center(
          child: _PeakMark(),
        ),
        const SizedBox(height: 28),
        Text(
          'Peak',
          style: PeakType.headlineXl().copyWith(fontSize: 44, height: 1.05),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Log every rep.\nClimb every peak.',
          style: PeakType.bodyLg(color: PeakColors.mutedForeground),
          textAlign: TextAlign.center,
        ),
        const Spacer(),
        PeakButton(
          label: 'I\'m new — start over',
          size: PeakButtonSize.xl,
          onPressed: _busy ? null : _newUserFlow,
        ),
        const SizedBox(height: 12),
        PeakButton(
          label: 'Existing user — import data',
          size: PeakButtonSize.xl,
          variant: PeakButtonVariant.secondary,
          onPressed: _busy ? null : _importFlow,
          busy: _busy,
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: PeakType.bodyMd(color: PeakColors.destructive),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 12),
        Text(
          'All data stays on this device.',
          style: PeakType.overline(),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildNameStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: _busy
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      setState(() => _step = 0);
                    },
              child: const Icon(Icons.arrow_back_rounded),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text('What should we call you?', style: PeakType.headlineXl()),
        const SizedBox(height: 8),
        Text(
          'Used on the Today greeting. Nothing leaves the device.',
          style: PeakType.bodyMd(color: PeakColors.mutedForeground),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _nameCtl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          style: PeakType.headlineLg(),
          cursorColor: PeakColors.primary,
          decoration: InputDecoration(
            hintText: 'e.g. Gopi',
            hintStyle: PeakType.headlineLg(color: PeakColors.mutedForeground),
            filled: true,
            fillColor: PeakColors.surfaceContainerLow,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: PeakColors.primary, width: 1.5),
            ),
          ),
          onSubmitted: (_) => _saveNameAndProceed(),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: PeakType.bodyMd(color: PeakColors.destructive)),
        ],
        const Spacer(),
        PeakButton(
          label: 'Continue',
          size: PeakButtonSize.xl,
          onPressed: _busy ? null : _saveNameAndProceed,
          busy: _busy,
        ),
      ],
    );
  }
}

class _PeakMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      width: 96,
      decoration: BoxDecoration(
        color: PeakColors.surfaceContainer,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: PeakColors.primary, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: PeakColors.primary.withValues(alpha: 0.35),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.terrain_rounded, color: PeakColors.primary, size: 56),
      ),
    );
  }
}
