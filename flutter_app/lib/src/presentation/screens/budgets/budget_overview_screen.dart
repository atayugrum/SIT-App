// File: lib/src/presentation/screens/budgets/budget_overview_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../../../core/categories.dart';
import '../../../data/models/budget_model.dart';
import '../../providers/budget_providers.dart';
import 'budget_form_screen.dart';

class BudgetOverviewScreen extends ConsumerWidget {
  const BudgetOverviewScreen({super.key});

  void _showMonthYearPicker(
      BuildContext context, WidgetRef ref, DateTime currentPeriod) {
    // ... (This function remains the same as in my previous response)
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetsProvider);
    final selectedPeriod = ref.watch(budgetPeriodProvider);
    final theme = Theme.of(context);

    ref.listen<AsyncValue<void>>(budgetActionNotifierProvider,
        (previous, next) {
      next.when(
        data: (_) {},
        error: (err, stack) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Hata oluştu: $err'),
              backgroundColor: theme.colorScheme.error),
        ),
        loading: () {},
      );
    });

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Aylık Bütçelerim'),
        backgroundColor: Colors.grey.shade100,
        elevation: 0,
        foregroundColor: Colors.grey.shade800,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.0),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(DateFormat.yMMMM('tr_TR').format(selectedPeriod),
                    style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold, color: Colors.black87)),
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: const Text('Değiştir'),
                  onPressed: () =>
                      _showMonthYearPicker(context, ref, selectedPeriod),
                  style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade400)),
                ),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(budgetsProvider),
        child: budgetsAsync.when(
          data: (budgets) {
            if (budgets.isEmpty) {
              return Center(child: Text('Bu dönem için bütçe bulunmuyor.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: budgets.length,
              itemBuilder: (context, index) =>
                  _BudgetCard(budget: budgets[index]),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text("Hata: $error")),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const BudgetFormScreen())),
        icon: const Icon(Icons.add),
        label: const Text('Yeni Bütçe'),
        tooltip: 'Yeni Bütçe Ekle',
        backgroundColor: Colors.teal.shade700,
      ),
    );
  }
}

class _BudgetCard extends ConsumerWidget {
  final BudgetModel budget;

  const _BudgetCard({required this.budget});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    final progress = (budget.spentAmount / budget.limitAmount).clamp(0.0, 1.0);
    final remainingAmount = budget.limitAmount - budget.spentAmount;

    Color getProgressColor(double progress) {
      if (progress > 1.0) return Colors.red.shade800;
      if (progress > 0.85) return Colors.orange.shade700;
      return Colors.green.shade600;
    }

    final progressColor = getProgressColor(progress);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                        expenseCategories[budget.category] ??
                            Icons.category_outlined,
                        color: Colors.teal.shade700),
                    const SizedBox(width: 12),
                    Text(budget.category,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'edit') {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) =>
                              BudgetFormScreen(budgetToEdit: budget)));
                    } else if (value == 'delete') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Bütçeyi Sil'),
                          content: Text(
                              '"${budget.category}" kategorisi için oluşturulan bütçeyi silmek istediğinizden emin misiniz?'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('İptal')),
                            TextButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text('Sil',
                                    style: TextStyle(color: Colors.red)))
                          ],
                        ),
                      );
                      if (confirm == true && context.mounted) {
                        await ref
                            .read(budgetActionNotifierProvider.notifier)
                            .deleteBudget(budget.id!);
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                            leading: Icon(Icons.edit_outlined),
                            title: Text('Düzenle'))),
                    const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                            leading: Icon(Icons.delete_outline),
                            title: Text('Sil',
                                style: TextStyle(color: Colors.red)))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearPercentIndicator(
              percent: progress,
              lineHeight: 12,
              backgroundColor: Colors.grey.shade300,
              progressColor: progressColor,
              barRadius: const Radius.circular(6),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${currencyFormat.format(budget.spentAmount)} harcandı',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800)),
                Text(currencyFormat.format(budget.limitAmount),
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: Colors.grey.shade600)),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(remainingAmount >= 0 ? 'Kalan Tutar:' : 'Limit Aşıldı:',
                    style: theme.textTheme.titleMedium),
                const SizedBox(width: 8),
                Text(
                  currencyFormat.format(remainingAmount.abs()),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: remainingAmount >= 0
                        ? Colors.green.shade800
                        : Colors.red.shade800,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
