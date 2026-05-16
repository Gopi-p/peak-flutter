import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/session_repository.dart';
import '../../../providers/providers.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';

class WhatsNextPage extends ConsumerWidget {
  const WhatsNextPage({super.key, required this.sessionId});
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(_sessionProvider(sessionId));
    return Scaffold(
      backgroundColor: PeakColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text("What's next?", style: PeakType.overline()),
      ),
      body: sessionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: PeakColors.primary)),
        error: (e, _) => Center(child: Text('$e', style: PeakType.bodyMd())),
        data: (session) {
          final lastMuscle = session?.muscles.lastOrNull;
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              PeakSpacing.edge,
              8,
              PeakSpacing.edge,
              PeakSpacing.edge,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Where do we go from here?',
                  style: PeakType.headlineXl().copyWith(fontSize: 28, height: 1.05),
                ),
                const SizedBox(height: 16),
                PeakCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (lastMuscle != null)
                        PeakButton(
                          label: 'Same muscle (${lastMuscle.label})',
                          icon: Icons.refresh_rounded,
                          size: PeakButtonSize.xl,
                          onPressed: () => context.push(
                            '/session/$sessionId/exercise?muscle=${Uri.encodeComponent(lastMuscle.label)}',
                          ),
                        ),
                      const SizedBox(height: 10),
                      PeakButton(
                        label: 'Different muscle',
                        icon: Icons.shuffle_rounded,
                        size: PeakButtonSize.xl,
                        variant: PeakButtonVariant.secondary,
                        onPressed: () => context.push('/session/$sessionId/muscle'),
                      ),
                      const SizedBox(height: 10),
                      PeakButton(
                        label: 'Finish session',
                        icon: Icons.flag_rounded,
                        size: PeakButtonSize.xl,
                        variant: PeakButtonVariant.outline,
                        onPressed: () async {
                          await ref.read(sessionRepositoryProvider).finishSession(sessionId);
                          if (context.mounted) context.go('/session/$sessionId/summary');
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

final _sessionProvider =
    FutureProvider.autoDispose.family((ref, String id) async {
  return ref.watch(sessionRepositoryProvider).sessionById(id);
});
