// File: lib/src/presentation/screens/savings/savings_overview_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/analytics_models.dart';
import '../../providers/analytics_v2_providers.dart';
import '../../providers/task_providers.dart';
import '../../providers/savings_providers.dart';
import 'savings_goals_screen.dart';
import 'manual_save_form_screen.dart';

class SavingsOverviewScreen extends ConsumerWidget {
  const SavingsOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(analyticsV2Provider);
    final primaryColor = Colors.teal.shade700;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Tasarruflar & Görevler'),
        backgroundColor: Colors.grey.shade100,
        foregroundColor: Colors.grey.shade800,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(analyticsV2Provider);
              ref.invalidate(activeTasksProvider);
            },
            tooltip: "Yenile",
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(analyticsV2Provider);
          ref.invalidate(activeTasksProvider);
        },
        child: analyticsAsync.when(
          data: (data) {
            final hasEnoughDataForAI = data.historical.dataSpanDays >= 90;

            return ListView(
              padding: const EdgeInsets.all(12.0),
              children: [
                _SavingsPotentialCard(
                    potential: data.aiProjections.savingsPotential),
                const SizedBox(height: 16),
                const _ActiveTasksList(),
                const SizedBox(height: 16),
                if (hasEnoughDataForAI)
                  _TaskSuggestionsCard(
                      suggestedTasks: data.aiProjections.actionableTasks)
                else
                  const _InsufficientDataCard(),
                const SizedBox(height: 16),
                _SavingsGoalsNavCard(primaryColor: primaryColor),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text("Veri yüklenemedi: $e")),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => const ManualSaveFormScreen())),
        label: const Text('Manuel Ekle'),
        icon: const Icon(Icons.add_card_rounded),
        backgroundColor: primaryColor,
      ),
    );
  }
}

class _SavingsPotentialCard extends ConsumerWidget {
  final SavingsPotentialModel potential;
  const _SavingsPotentialCard({required this.potential});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savingsBalanceAsync = ref.watch(savingsBalanceProvider);
    final theme = Theme.of(context);
    final format = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    return Card(
      elevation: 4,
      color: Colors.teal.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            savingsBalanceAsync.when(
              data: (balance) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Genel Kumbara Bakiyesi',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(color: Colors.teal.shade800)),
                    const SizedBox(height: 8),
                    Text(format.format(balance.balance),
                        style: theme.textTheme.displaySmall?.copyWith(
                            color: Colors.teal.shade900,
                            fontWeight: FontWeight.bold)),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Text("Bakiye Yüklenemedi",
                  style: TextStyle(color: theme.colorScheme.error)),
            ),
            const Divider(height: 24),
            Text('Aylık Tasarruf Potansiyeli (AI)',
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: Colors.green.shade800)),
            const SizedBox(height: 8),
            Text(format.format(potential.monthlyPotential),
                style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.green.shade900, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(potential.analysis, style: theme.textTheme.bodyMedium),
          ],
        ),
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
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Aktif Görevlerim",
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            activeTasksAsync.when(
              data: (tasks) {
                if (tasks.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(
                        child: Text(
                            "Henüz aktif bir göreviniz yok.\nAşağıdaki önerilerden birini ekleyin!",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey))),
                  );
                }
                return Column(
                  children: tasks
                      .map((task) => CheckboxListTile(
                            value: task.isCompleted,
                            onChanged: (value) async {
                              if (value == true) {
                                try {
                                  await notifier.completeTask(task.id);
                                  // --- DÜZELTME 1 ---
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              "Görev tamamlandı! Harika iş!"),
                                          backgroundColor: Colors.green));
                                } catch (e) {
                                  // --- DÜZELTME 2 ---
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text("Hata: $e"),
                                          backgroundColor: Colors.red));
                                }
                              }
                            },
                            title: Text(task.description),
                            controlAffinity: ListTileControlAffinity.leading,
                          ))
                      .toList(),
                );
              },
              loading: () => const Center(
                  child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator())),
              error: (e, s) => Center(
                  child: Text("Aktif görevler yüklenemedi: $e",
                      style: TextStyle(color: theme.colorScheme.error))),
            )
          ],
        ),
      ),
    );
  }
}

class _TaskSuggestionsCard extends ConsumerWidget {
  final List<ActionableTaskModel> suggestedTasks;
  const _TaskSuggestionsCard({required this.suggestedTasks});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final activeTasksAsync = ref.watch(activeTasksProvider);
    final notifier = ref.read(activeTasksProvider.notifier);

    return activeTasksAsync.when(
      data: (activeTasks) {
        final activeTaskDescriptions =
            activeTasks.map((t) => t.description).toSet();
        final filteredSuggestions = suggestedTasks
            .where((s) => !activeTaskDescriptions.contains(s.task))
            .toList();

        if (filteredSuggestions.isEmpty) return const SizedBox.shrink();

        return Card(
          elevation: 2,
          color: Colors.amber.shade50,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("AI Görev Önerileri",
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...filteredSuggestions
                    .map((suggestion) => ListTile(
                          leading: const Icon(Icons.lightbulb_outline),
                          title: Text(suggestion.task),
                          trailing: IconButton(
                            icon: const Icon(Icons.add_circle_outline,
                                color: Colors.green),
                            onPressed: () async {
                              try {
                                await notifier.addTask(suggestion.task);
                              } catch (e) {
                                // --- DÜZELTME 3 ---
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text("Hata: $e"),
                                        backgroundColor: Colors.red));
                              }
                            },
                            tooltip: "Bu görevi ekle",
                          ),
                        ))
                    .toList()
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, s) => const SizedBox.shrink(),
    );
  }
}

class _InsufficientDataCard extends StatelessWidget {
  const _InsufficientDataCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue.shade700, size: 32),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                "Size özel tasarruf görevleri ve finansal öngörüler sunabilmemiz için en az 90 günlük işlem geçmişi gereklidir.",
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavingsGoalsNavCard extends StatelessWidget {
  final Color primaryColor;
  const _SavingsGoalsNavCard({required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 3,
      color: primaryColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        // --- DÜZELTME 4: 'withOpacity' yerine 'withAlpha' ---
        leading: Icon(Icons.track_changes_rounded,
            color: Colors.white.withAlpha(230), size: 32), // 0.9 opacity
        title: Text("Tasarruf Hedeflerim",
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
        // --- DÜZELTME 5: 'withOpacity' yerine 'withAlpha' ---
        subtitle: Text("Büyük hedefleriniz için para biriktirin.",
            style:
                TextStyle(color: Colors.white.withAlpha(204))), // 0.8 opacity
        trailing: const Icon(Icons.arrow_forward_ios_rounded,
            size: 18, color: Colors.white),
        onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SavingsGoalsScreen())),
      ),
    );
  }
}
