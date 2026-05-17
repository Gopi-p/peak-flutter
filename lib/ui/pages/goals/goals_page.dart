import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/db/database.dart';
import '../../../providers/providers.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';

class GoalsPage extends ConsumerWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(_goalsStreamProvider);
    return Scaffold(
      backgroundColor: PeakColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text('Goals', style: PeakType.overline()),
      ),
      body: goalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: PeakColors.primary)),
        error: (e, _) => Center(child: Text('$e', style: PeakType.bodyMd())),
        data: (goals) => ListView(
          padding: const EdgeInsets.fromLTRB(
            PeakSpacing.edge,
            8,
            PeakSpacing.edge,
            PeakSpacing.edge,
          ),
          children: [
            Text(
              'Goals',
              style: PeakType.headlineXl().copyWith(fontSize: 32, height: 1.05),
            ),
            const SizedBox(height: 4),
            Text(
              "Pick something you'll fight for.",
              style: PeakType.bodyMd(color: PeakColors.mutedForeground),
            ),
            const SizedBox(height: 16),
            for (final g in goals) _GoalCard(goal: g),
            if (goals.isEmpty)
              PeakCard(
                child: Text(
                  'No goals yet. Tap the button below to set your first.',
                  style: PeakType.bodyMd(color: PeakColors.mutedForeground),
                ),
              ),
            const SizedBox(height: 16),
            PeakButton(
              label: 'Add goal',
              icon: Icons.add_rounded,
              size: PeakButtonSize.xl,
              onPressed: () => _openGoalSheet(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}

final _goalsStreamProvider = StreamProvider<List<Goal>>((ref) {
  return ref.watch(goalRepositoryProvider).watchAll();
});

class _GoalCard extends ConsumerWidget {
  const _GoalCard({required this.goal});
  final Goal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PeakCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(goal.title, style: PeakType.headlineLg().copyWith(fontSize: 18)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      PeakBadge(label: goal.type, variant: PeakBadgeVariant.secondary),
                      PeakBadge(
                        label: '${goal.targetValue}${goal.targetUnit.isEmpty ? '' : ' ${goal.targetUnit}'}',
                        variant: PeakBadgeVariant.primary,
                      ),
                      if (goal.deadline != null)
                        PeakBadge(
                          label: 'by ${goal.deadline!.toIso8601String().substring(0, 10)}',
                          variant: PeakBadgeVariant.outline,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: PeakColors.destructive),
              onPressed: () async {
                await ref.read(goalRepositoryProvider).softDelete(goal.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _openGoalSheet(BuildContext context, WidgetRef ref) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: PeakColors.surfaceContainerHigh,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: const _AddGoalForm(),
    ),
  );
}

class _AddGoalForm extends ConsumerStatefulWidget {
  const _AddGoalForm();
  @override
  ConsumerState<_AddGoalForm> createState() => _AddGoalFormState();
}

class _AddGoalFormState extends ConsumerState<_AddGoalForm> {
  final _title = TextEditingController();
  final _target = TextEditingController();
  final _unit = TextEditingController(text: 'kg');
  String _type = 'lift-target';
  String? _exerciseId;
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _target.dispose();
    _unit.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final value = double.tryParse(_target.text.trim());
    if (_title.text.trim().isEmpty || value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title + positive target are required.')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(goalRepositoryProvider).add(
            title: _title.text.trim(),
            type: _type,
            targetValue: value,
            targetUnit: _unit.text.trim(),
            exerciseId: _exerciseId,
          );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(exerciseCatalogProvider);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('New goal', style: PeakType.headlineLg()),
          const SizedBox(height: 12),
          _PeakField(label: 'Title', controller: _title, hint: 'Bench 100 kg'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _PeakField(label: 'Target', controller: _target, keyboard: TextInputType.number),
              ),
              const SizedBox(width: 10),
              Expanded(child: _PeakField(label: 'Unit', controller: _unit)),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _type,
            dropdownColor: PeakColors.surfaceContainerHigh,
            decoration: _decoration('Type'),
            items: const [
              DropdownMenuItem(value: 'lift-target', child: Text('Lift target')),
              DropdownMenuItem(value: 'weekly-sets', child: Text('Weekly sets')),
              DropdownMenuItem(value: 'bodyweight', child: Text('Body weight')),
              DropdownMenuItem(value: 'frequency', child: Text('Frequency')),
            ],
            onChanged: (v) => setState(() => _type = v ?? 'lift-target'),
          ),
          if (_type == 'lift-target') ...[
            const SizedBox(height: 10),
            catalogAsync.when(
              loading: () => const SizedBox(height: 40),
              error: (_, __) => const SizedBox(),
              data: (cat) => DropdownButtonFormField<String>(
                initialValue: _exerciseId,
                dropdownColor: PeakColors.surfaceContainerHigh,
                decoration: _decoration('Exercise'),
                isExpanded: true,
                items: [
                  for (final e in cat.all..sort((a, b) => a.name.compareTo(b.name)))
                    DropdownMenuItem(value: e.id, child: Text(e.name, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => setState(() => _exerciseId = v),
              ),
            ),
          ],
          const SizedBox(height: 18),
          PeakButton(
            label: 'Save goal',
            size: PeakButtonSize.xl,
            busy: _busy,
            onPressed: _busy ? null : _save,
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: PeakType.overline(),
        filled: true,
        fillColor: PeakColors.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      );
}

class _PeakField extends StatelessWidget {
  const _PeakField({
    required this.label,
    required this.controller,
    this.hint,
    this.keyboard,
  });
  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboard;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      style: PeakType.bodyMd(),
      cursorColor: PeakColors.primary,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
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
    );
  }
}
