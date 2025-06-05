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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('My Budgets'),
            Text(
              DateFormat.yMMMM().format(selectedPeriod), // Display selected Year and Month
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onPrimary.withOpacity(0.8),
                fontSize: 12, // Smaller font for period
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Select Month/Year',
            onPressed: () => _showMonthYearPicker(context, ref, selectedPeriod),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Budgets',
            onPressed: () => ref.invalidate(budgetsProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(budgetsProvider);
        },
        child: budgetsAsyncValue.when(
          data: (budgets) {
            if (budgets.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.money_off_csred_outlined, size: 60, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'No budgets found for ${DateFormat.yMMMM().format(selectedPeriod)}.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the "+" button to add your first budget for this period.',
                         textAlign: TextAlign.center,
                         style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 80), // Padding for FAB
              itemCount: budgets.length,
              itemBuilder: (context, index) {
                final budget = budgets[index];
                // Placeholder for actual spending - this would require fetching and summing transactions
                // double actualSpending = 0.0; 
                // double remaining = budget.limitAmount - actualSpending;
                // double progress = budget.limitAmount > 0 ? actualSpending / budget.limitAmount : 0.0;
                // if (progress > 1.0) progress = 1.0;
                // if (progress < 0.0) progress = 0.0;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.secondaryContainer,
                      child: Icon(
                        Icons.category_outlined, // Replace with actual category icon later
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                    title: Text(budget.category, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    subtitle: Text('Limit: ${NumberFormat.currency(locale: 'tr_TR', symbol: '₺').format(budget.limitAmount)}'
                                  // '\nSpent: ₺${actualSpending.toStringAsFixed(2)}' // Uncomment when implemented
                                  ),
                    // isThreeLine: true, // Uncomment if you add more lines to subtitle
                    trailing: PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, color: theme.colorScheme.onSurfaceVariant),
                        tooltip: "Options",
                        onSelected: (String value) async {
                           if (value == 'edit') {
                             final result = await Navigator.of(context).push<bool>(
                                MaterialPageRoute(
                                  builder: (context) => BudgetFormScreen(budgetToEdit: budget),
                                ),
                              );
                              if (result == true && context.mounted) {
                                ref.invalidate(budgetsProvider);
                              }
                           } else if (value == 'delete') {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Confirm Delete'),
                                  content: Text('Are you sure you want to delete the budget for "${budget.category}"?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                                    TextButton(
                                        onPressed: () => Navigator.of(ctx).pop(true),
                                        child: Text('Delete', style: TextStyle(color: theme.colorScheme.error))),
                                  ],
                                ),
                              );
                              if (confirm == true && budget.id != null && context.mounted) {
                                try {
                                  await ref.read(budgetNotifierProvider.notifier).deleteBudget(budget.id!);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Budget deleted successfully'), backgroundColor: Colors.green),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error deleting budget: ${e.toString().replaceFirst("Exception: ", "")}'), backgroundColor: Colors.red),
                                    );
                                  }
                                }
                              }
                           }
                        },
                        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'edit',
                            child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Edit')),
                          ),
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: ListTile(leading: Icon(Icons.delete_outline), title: Text('Delete', style: TextStyle(color: Colors.red))),
                          ),
                        ],
                      ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) {
            print("BudgetOverviewScreen Error: $error \n$stack");
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     Icon(Icons.error_outline, size: 60, color: theme.colorScheme.error),
                     const SizedBox(height: 16),
                     Text('Error loading budgets', style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.error)),
                     const SizedBox(height: 8),
                     Text(error.toString().replaceFirst("Exception: ", ""), textAlign: TextAlign.center),
                     const SizedBox(height: 16),
                     ElevatedButton.icon(
                       icon: const Icon(Icons.refresh),
                       label: const Text('Try Again'),
                       onPressed: () => ref.invalidate(budgetsProvider),
                     )
                  ],
                )
              )
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_chart_outlined),
        label: const Text('Add Budget'),
        tooltip: 'Add New Budget',
        onPressed: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (context) => const BudgetFormScreen()),
          );
          if (result == true && context.mounted) {
             ref.invalidate(budgetsProvider); // Refresh list after adding
          }
        },
      ),
    );
  }
}