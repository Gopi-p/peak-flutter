import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/db/database.dart';
import '../../../data/exercise_catalog.dart';
import '../../../providers/providers.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import 'routine_exercise_picker_page.dart';

class RoutineEditorPage extends ConsumerWidget {
  const RoutineEditorPage({super.key, required this.routineId});
  final String routineId;

  Future<String?> _pickExercise(BuildContext context, {Set<String> exclude = const {}}) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => RoutineExercisePickerPage(excludeIds: exclude),
      ),
    );
  }

  Future<void> _addExercise(BuildContext context, WidgetRef ref) async {
    final exId = await _pickExercise(context);
    if (exId == null) return;
    await ref.read(routineRepositoryProvider).addEntry(routineId: routineId, exerciseId: exId);
  }

  Future<void> _rename(BuildContext context, WidgetRef ref, String current) async {
    final controller = TextEditingController(text: current);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PeakColors.surfaceContainerHigh,
        title: Text('Rename routine', style: PeakType.headlineLg()),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: PeakType.bodyLg(),
          textCapitalization: TextCapitalization.words,
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('Save')),
        ],
      ),
    );
    if (name != null && name.trim().isNotEmpty) {
      await ref.read(routineRepositoryProvider).rename(routineId, name.trim());
    }
  }

  Future<void> _start(BuildContext context, WidgetRef ref) async {
    final id = await ref.read(sessionRepositoryProvider).startFromRoutine(routineId);
    if (context.mounted) context.go('/session/$id');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routineAsync = ref.watch(_routineProvider(routineId));
    final entriesAsync = ref.watch(routineEntriesProvider(routineId));
    final catalogAsync = ref.watch(exerciseCatalogProvider);

    final routine = routineAsync.valueOrNull;
    return Scaffold(
      backgroundColor: PeakColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(routine?.name.toUpperCase() ?? 'ROUTINE', style: PeakType.overline()),
        actions: [
          IconButton(
            tooltip: 'Rename',
            icon: const Icon(Icons.edit_rounded),
            onPressed: routine == null ? null : () => _rename(context, ref, routine.name),
          ),
        ],
      ),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: PeakColors.primary)),
        error: (e, _) => Center(child: Text('$e', style: PeakType.bodyMd())),
        data: (entries) {
          final catalog = catalogAsync.valueOrNull;
          return Column(
            children: [
              Expanded(
                child: entries.isEmpty
                    ? _empty()
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.fromLTRB(PeakSpacing.edge, 8, PeakSpacing.edge, 8),
                        itemCount: entries.length,
                        onReorder: (oldIndex, newIndex) {
                          final ids = entries.map((e) => e.id).toList();
                          if (newIndex > oldIndex) newIndex -= 1;
                          ids.insert(newIndex, ids.removeAt(oldIndex));
                          ref.read(routineRepositoryProvider).reorderEntries(routineId, ids);
                        },
                        itemBuilder: (context, i) => _SlotCard(
                          key: ValueKey(entries[i].id),
                          routineId: routineId,
                          entry: entries[i],
                          index: i,
                          catalog: catalog,
                          onAddAlternative: () async {
                            final slot = entries[i];
                            final current = _altIds(slot);
                            final exId = await _pickExercise(
                              context,
                              exclude: {slot.exerciseId, ...current},
                            );
                            if (exId == null) return;
                            await ref
                                .read(routineRepositoryProvider)
                                .setAlternatives(slot.id, [...current, exId]);
                          },
                          onRemoveAlternative: (altId) async {
                            final slot = entries[i];
                            final next = _altIds(slot)..remove(altId);
                            await ref.read(routineRepositoryProvider).setAlternatives(slot.id, next);
                          },
                        ),
                      ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(PeakSpacing.edge, 4, PeakSpacing.edge, 12),
                  child: Column(
                    children: [
                      PeakButton(
                        label: 'Add exercise',
                        icon: Icons.add_rounded,
                        size: PeakButtonSize.xl,
                        onPressed: () => _addExercise(context, ref),
                      ),
                      if (entries.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        PeakButton(
                          label: 'Start this routine',
                          icon: Icons.play_arrow_rounded,
                          variant: PeakButtonVariant.secondary,
                          size: PeakButtonSize.xl,
                          onPressed: () => _start(context, ref),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _empty() => Center(
        child: Padding(
          padding: const EdgeInsets.all(PeakSpacing.edge),
          child: Text(
            'No exercises yet.\nTap "Add exercise" to build this routine.',
            textAlign: TextAlign.center,
            style: PeakType.bodyMd(color: PeakColors.mutedForeground),
          ),
        ),
      );
}

List<String> _altIds(RoutineEntry e) => (jsonDecode(e.alternatives) as List).cast<String>();

final _routineProvider = StreamProvider.autoDispose.family<Routine?, String>((ref, id) {
  return ref.watch(routineRepositoryProvider).watchById(id);
});

class _SlotCard extends ConsumerWidget {
  const _SlotCard({
    super.key,
    required this.routineId,
    required this.entry,
    required this.index,
    required this.catalog,
    required this.onAddAlternative,
    required this.onRemoveAlternative,
  });

  final String routineId;
  final RoutineEntry entry;
  final int index;
  final ExerciseCatalog? catalog;
  final VoidCallback onAddAlternative;
  final ValueChanged<String> onRemoveAlternative;

  String _name(String id) => catalog?.byId(id)?.name ?? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ex = catalog?.byId(entry.exerciseId);
    final alts = _altIds(entry);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PeakCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    '${index + 1}',
                    style: PeakType.tabular(PeakType.bodyMd(color: PeakColors.mutedForeground)),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_name(entry.exerciseId), style: PeakType.headlineLg().copyWith(fontSize: 18)),
                      if (ex != null)
                        Text(
                          '${ex.equipment.label} · ${ex.primaryMuscles.map((m) => m.label).join(', ')}',
                          style: PeakType.overline(),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Remove',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline_rounded, color: PeakColors.destructive),
                  onPressed: () => ref.read(routineRepositoryProvider).removeEntry(entry.id),
                ),
                ReorderableDragStartListener(
                  index: index,
                  child: const Icon(Icons.drag_handle_rounded, color: PeakColors.mutedForeground),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('ALTERNATIVES', style: PeakType.overline()),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final altId in alts)
                  InputChip(
                    label: Text(_name(altId), style: PeakType.bodyMd()),
                    backgroundColor: PeakColors.surfaceContainerHigh,
                    deleteIconColor: PeakColors.mutedForeground,
                    onDeleted: () => onRemoveAlternative(altId),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.add_rounded, size: 18, color: PeakColors.primary),
                  label: Text('Add', style: PeakType.bodyMd(color: PeakColors.primary)),
                  backgroundColor: PeakColors.surfaceContainerLow,
                  onPressed: onAddAlternative,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
