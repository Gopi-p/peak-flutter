import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/db/database.dart';
import '../../../providers/providers.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';

class RoutinesPage extends ConsumerWidget {
  const RoutinesPage({super.key});

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final name = await _promptName(context, title: 'New routine');
    if (name == null || name.trim().isEmpty) return;
    final id = await ref.read(routineRepositoryProvider).create(name: name.trim());
    if (context.mounted) context.push('/routines/$id');
  }

  Future<void> _seedStarter(BuildContext context, WidgetRef ref) async {
    final catalog = await ref.read(exerciseCatalogProvider.future);
    await ref.read(routineRepositoryProvider).seedPplStarter(catalog);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routinesAsync = ref.watch(routinesStreamProvider);
    return Scaffold(
      backgroundColor: PeakColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text('Routines', style: PeakType.overline()),
        actions: [
          IconButton(
            tooltip: 'New routine',
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _create(context, ref),
          ),
        ],
      ),
      body: routinesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: PeakColors.primary)),
        error: (e, _) => Center(child: Text('$e', style: PeakType.bodyMd())),
        data: (routines) {
          if (routines.isEmpty) return _EmptyState(onSeed: () => _seedStarter(context, ref), onCreate: () => _create(context, ref));
          return ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(PeakSpacing.edge, 8, PeakSpacing.edge, PeakSpacing.edge + 80),
            itemCount: routines.length,
            onReorder: (oldIndex, newIndex) {
              final ids = routines.map((r) => r.id).toList();
              if (newIndex > oldIndex) newIndex -= 1;
              final moved = ids.removeAt(oldIndex);
              ids.insert(newIndex, moved);
              ref.read(routineRepositoryProvider).reorder(ids);
            },
            itemBuilder: (context, i) => _RoutineTile(
              key: ValueKey(routines[i].id),
              routine: routines[i],
              index: i,
            ),
          );
        },
      ),
    );
  }
}

Future<String?> _promptName(BuildContext context, {required String title, String initial = ''}) {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: PeakColors.surfaceContainerHigh,
      title: Text(title, style: PeakType.headlineLg()),
      content: TextField(
        controller: controller,
        autofocus: true,
        style: PeakType.bodyLg(),
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(hintText: 'e.g. Push'),
        onSubmitted: (v) => Navigator.pop(ctx, v),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('Save')),
      ],
    ),
  );
}

class _RoutineTile extends ConsumerWidget {
  const _RoutineTile({super.key, required this.routine, required this.index});
  final Routine routine;
  final int index;

  Future<void> _start(BuildContext context, WidgetRef ref) async {
    final id = await ref.read(sessionRepositoryProvider).startFromRoutine(routine.id);
    if (context.mounted) context.go('/session/$id');
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PeakColors.surfaceContainerHigh,
        title: Text('Delete ${routine.name}?', style: PeakType.headlineLg()),
        content: Text(
          'This removes the routine. Past sessions started from it are untouched.',
          style: PeakType.bodyMd(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: PeakColors.destructive),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(routineRepositoryProvider).softDelete(routine.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(routineEntriesProvider(routine.id));
    final count = entriesAsync.maybeWhen(data: (e) => e.length, orElse: () => 0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PeakCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => context.push('/routines/${routine.id}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(routine.name, style: PeakType.headlineLg().copyWith(fontSize: 20)),
                    const SizedBox(height: 2),
                    Text('$count ${count == 1 ? 'exercise' : 'exercises'}', style: PeakType.overline()),
                  ],
                ),
              ),
            ),
            IconButton(
              tooltip: 'Start this routine',
              icon: const Icon(Icons.play_arrow_rounded, color: PeakColors.primary),
              onPressed: count == 0 ? null : () => _start(context, ref),
            ),
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline_rounded, color: PeakColors.destructive),
              onPressed: () => _confirmDelete(context, ref),
            ),
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.drag_handle_rounded, color: PeakColors.mutedForeground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onSeed, required this.onCreate});
  final VoidCallback onSeed;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(PeakSpacing.edge, 24, PeakSpacing.edge, PeakSpacing.edge),
      children: [
        Text(
          'Save a routine once,\nfollow it every session.',
          style: PeakType.headlineXl().copyWith(fontSize: 28, height: 1.1),
        ),
        const SizedBox(height: 12),
        Text(
          'A routine is an ordered list of exercises. Start a session from it and just log your sets — no muscle picking each time.',
          style: PeakType.bodyMd(color: PeakColors.mutedForeground),
        ),
        const SizedBox(height: 20),
        PeakCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Push / Pull / Legs', style: PeakType.headlineLg().copyWith(fontSize: 18)),
              const SizedBox(height: 4),
              Text(
                'Add the three PPL routines, ready to edit.',
                style: PeakType.bodyMd(color: PeakColors.mutedForeground),
              ),
              const SizedBox(height: 14),
              PeakButton(
                label: 'Add PPL starter',
                icon: Icons.auto_awesome_rounded,
                size: PeakButtonSize.xl,
                onPressed: onSeed,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        PeakButton(
          label: 'Create from scratch',
          icon: Icons.add_rounded,
          variant: PeakButtonVariant.outline,
          size: PeakButtonSize.xl,
          onPressed: onCreate,
        ),
      ],
    );
  }
}
