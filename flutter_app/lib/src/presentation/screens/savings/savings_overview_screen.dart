// File: lib/src/presentation/screens/savings/savings_overview_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/analytics_models.dart';
import '../../providers/analytics_v2_providers.dart';
import '../../providers/savings_providers.dart';
import '../../providers/task_providers.dart';
import '../../widgets/glass_card.dart';
import 'manual_save_form_screen.dart';
import 'savings_goals_screen.dart';

class SavingsOverviewScreen extends ConsumerWidget {
  const SavingsOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(analyticsV2Provider);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.backgroundDark,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Tasarruflar & Görevler'),
        backgroundColor: const Color(0xCC000000),
        border: const Border(
            bottom:
                BorderSide(color: AppColors.separator, width: 0.5)),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).push(
            CupertinoPageRoute(
                builder: (_) => const ManualSaveFormScreen()),
          ),
          child: const Icon(CupertinoIcons.plus_circle_fill,
              color: AppColors.primaryBlue),
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            CupertinoSliverRefreshControl(
              onRefresh: () async {
                ref.invalidate(analyticsV2Provider);
                ref.invalidate(activeTasksProvider);
              },
            ),
            analyticsAsync.when(
              data: (data) {
                final hasEnoughData =
                    data.historical.dataSpanDays >= 90;
                return SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _SavingsPotentialCard(
                          potential: data.aiProjections.savingsPotential),
                      const SizedBox(height: 16),
                      const _ActiveTasksList(),
                      const SizedBox(height: 16),
                      if (hasEnoughData)
                        _TaskSuggestionsCard(
                            suggestedTasks:
                                data.aiProjections.actionableTasks)
                      else
                        const _InsufficientDataCard(),
                      const SizedBox(height: 16),
                      const _SavingsGoalsNavCard(),
                    ]),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child:
                    Center(child: CupertinoActivityIndicator()),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(
                    child: Text('Veri yüklenemedi: $e',
                        style: const TextStyle(
                            color: AppColors.danger))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavingsPotentialCard extends ConsumerWidget {
  final SavingsPotentialModel potential;
  const _SavingsPotentialCard({required this.potential});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savingsAsync = ref.watch(savingsBalanceProvider);
    final fmt =
        NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          savingsAsync.when(
            data: (balance) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Genel Kumbara Bakiyesi',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13)),
                const SizedBox(height: 6),
                Text(fmt.format(balance.balance),
                    style: const TextStyle(
                        color: AppColors.incomeGreen,
                        fontSize: 28,
                        fontWeight: FontWeight.w700)),
              ],
            ),
            loading: () =>
                const Center(child: CupertinoActivityIndicator()),
            error: (_, __) => const Text('Bakiye yüklenemedi',
                style: TextStyle(color: AppColors.danger)),
          ),
          Container(
              height: 0.5,
              color: AppColors.separator,
              margin: const EdgeInsets.symmetric(vertical: 12)),
          const Text('Aylık Tasarruf Potansiyeli (AI)',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 6),
          Text(fmt.format(potential.monthlyPotential),
              style: const TextStyle(
                  color: AppColors.primaryBlue,
                  fontSize: 22,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(potential.analysis,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}

class _ActiveTasksList extends ConsumerWidget {
  const _ActiveTasksList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTasksAsync = ref.watch(activeTasksProvider);
    final notifier = ref.read(activeTasksProvider.notifier);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Aktif Görevlerim',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          activeTasksAsync.when(
            data: (tasks) {
              if (tasks.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                      child: Text(
                    'Henüz aktif bir göreviniz yok.\nAşağıdaki önerilerden birini ekleyin!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13),
                  )),
                );
              }
              return Column(
                children: tasks
                    .map((task) => Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: task.isCompleted
                                    ? null
                                    : () async {
                                        try {
                                          await notifier
                                              .completeTask(task.id);
                                        } catch (_) {}
                                      },
                                child: Icon(
                                  task.isCompleted
                                      ? CupertinoIcons
                                          .checkmark_circle_fill
                                      : CupertinoIcons.circle,
                                  color: task.isCompleted
                                      ? AppColors.incomeGreen
                                      : AppColors.textSecondary,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(task.description,
                                    style: TextStyle(
                                        color: task.isCompleted
                                            ? AppColors.textSecondary
                                            : AppColors.textPrimary,
                                        decoration: task.isCompleted
                                            ? TextDecoration.lineThrough
                                            : null)),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              );
            },
            loading: () => const Center(
                child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CupertinoActivityIndicator())),
            error: (e, _) => Text('Görevler yüklenemedi: $e',
                style: const TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

class _TaskSuggestionsCard extends ConsumerWidget {
  final List<ActionableTaskModel> suggestedTasks;
  const _TaskSuggestionsCard({required this.suggestedTasks});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTasksAsync = ref.watch(activeTasksProvider);
    final notifier = ref.read(activeTasksProvider.notifier);

    return activeTasksAsync.when(
      data: (activeTasks) {
        final activeDescs =
            activeTasks.map((t) => t.description).toSet();
        final filtered = suggestedTasks
            .where((s) => !activeDescs.contains(s.task))
            .toList();
        if (filtered.isEmpty) return const SizedBox.shrink();

        return GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('AI Görev Önerileri',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              ...filtered.map((s) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.lightbulb_fill,
                            color: Color(0xFFFF9F0A), size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(s.task,
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13)),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () async {
                            try {
                              await notifier.addTask(s.task);
                            } catch (_) {}
                          },
                          child: const Icon(
                              CupertinoIcons.add_circled_solid,
                              color: AppColors.incomeGreen,
                              size: 22),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _InsufficientDataCard extends StatelessWidget {
  const _InsufficientDataCard();

  @override
  Widget build(BuildContext context) {
    return const GlassCard(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(CupertinoIcons.info_circle_fill,
              color: AppColors.primaryBlue, size: 28),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              'Size özel tasarruf görevleri için en az 90 günlük işlem geçmişi gereklidir.',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _SavingsGoalsNavCard extends StatelessWidget {
  const _SavingsGoalsNavCard();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        CupertinoPageRoute(
            builder: (_) => const SavingsGoalsScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: AppColors.primaryBlue, width: 0.5),
        ),
        child: const Row(
          children: [
            Icon(CupertinoIcons.scope,
                color: AppColors.primaryBlue, size: 28),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tasarruf Hedeflerim',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  SizedBox(height: 2),
                  Text('Büyük hedefleriniz için para biriktirin.',
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12)),
                ],
              ),
            ),
            Icon(CupertinoIcons.chevron_right,
                color: AppColors.textSecondary, size: 16),
          ],
        ),
      ),
    );
  }
}
