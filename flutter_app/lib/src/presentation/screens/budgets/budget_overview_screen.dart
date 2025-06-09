// File: lib/src/presentation/screens/budgets/budget_overview_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/budget_providers.dart';
import 'budget_form_screen.dart';

class BudgetOverviewScreen extends ConsumerWidget {
  const BudgetOverviewScreen({super.key});

  void _showMonthYearPicker(BuildContext context, WidgetRef ref, DateTime currentPeriod) async {
    final DateTime? pickedYear = await showDatePicker(
      context: context,
      initialDate: currentPeriod,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 5),
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Select Budget Year',
    );

    if (pickedYear != null && context.mounted) {
        final DateTime? pickedMonth = await showDatePicker(
            context: context,
            initialDate: DateTime(pickedYear.year, currentPeriod.month), // Keep current month initially for month picker
            firstDate: DateTime(pickedYear.year, 1),
            lastDate: DateTime(pickedYear.year, 12),
            initialEntryMode: DatePickerEntryMode.input, // More direct month selection
            helpText: 'Select Budget Month',
            fieldLabelText: 'Month',
            fieldHintText: 'Month (1-12)',
        );
        
        if (pickedMonth != null && context.mounted) {
            final newPeriod = DateTime(pickedYear.year, pickedMonth.month, 1);
            if (newPeriod.year != currentPeriod.year || newPeriod.month != currentPeriod.month) {
                ref.read(budgetPeriodProvider.notifier).state = newPeriod;
                // budgetsProvider will refetch automatically due to watching budgetPeriodProvider
            }
        }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsyncValue = ref.watch(budgetsProvider);
    final selectedPeriod = ref.watch(budgetPeriodProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bütçelerim'),
            Text(DateFormat.yMMMM('tr_TR').format(selectedPeriod), style: theme.textTheme.titleSmall),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _showMonthYearPicker(context, ref, selectedPeriod),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(budgetsProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(budgetsProvider),
        child: budgetsAsyncValue.when(
          data: (budgets) {
            if (budgets.isEmpty) {
              return Center(child: Text('Bu dönem için bütçe bulunmuyor.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              itemCount: budgets.length,
              itemBuilder: (context, index) {
                final budget = budgets[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.category_outlined)),
                    title: Text(budget.category, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('Limit: ${NumberFormat.currency(locale: 'tr_TR', symbol: '₺').format(budget.limitAmount)}'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (String value) async {
                        if (value == 'edit') {
                          final result = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => BudgetFormScreen(budgetToEdit: budget)));
                          if (result == true) ref.invalidate(budgetsProvider);
                        } else if (value == 'delete') {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Bütçeyi Sil'),
                              content: Text('"${budget.category}" kategorisi için oluşturulan bütçeyi silmek istediğinize emin misiniz?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('İptal')),
                                TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text('Sil', style: TextStyle(color: theme.colorScheme.error))),
                              ],
                            ),
                          );
                          if (confirm == true && budget.id != null) {
                            try {
                              // DÜZELTME: Doğru provider adı kullanılıyor
                              await ref.read(budgetActionNotifierProvider.notifier).deleteBudget(budget.id!);
                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bütçe silindi'), backgroundColor: Colors.green));
                            } catch (e) {
                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
                            }
                          }
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                        const PopupMenuItem(value: 'delete', child: Text('Sil')),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text("Hata: $error")),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (context) => const BudgetFormScreen()),
          );
          if (result == true) ref.invalidate(budgetsProvider);
        },
        child: const Icon(Icons.add),
        tooltip: 'Yeni Bütçe Ekle',
      ),
    );
  }
}