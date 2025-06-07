// File: lib/src/presentation/screens/transactions/transactions_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/transaction_providers.dart';
import '../../providers/account_providers.dart';
import '../../providers/analytics_providers.dart'; 
import '../../../data/models/transaction_model.dart';
import 'transaction_card.dart';
import 'transaction_flow_screen.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  void _confirmAndDeleteTransaction(BuildContext context, WidgetRef ref, TransactionModel transaction) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this transaction: "${transaction.category} - ₺${transaction.amount.toStringAsFixed(2)}"?\n\nThis action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
              child: const Text('Delete'),
              onPressed: () async {
                Navigator.of(ctx).pop();
                try {
                  if (transaction.id == null) throw Exception("Transaction ID is null, cannot delete.");
                  await ref.read(transactionsProvider.notifier).deleteTransactionFromList(transaction.id!);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaction deleted successfully!'), backgroundColor: Colors.green));
                    ref.invalidate(accountsProvider);
                    ref.invalidate(dashboardInsightsProvider);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting transaction: ${e.toString().replaceFirst("Exception: ", "")}'), backgroundColor: Colors.redAccent));
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _navigateToEditTransaction(BuildContext context, WidgetRef ref, TransactionModel transaction) {
    Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => TransactionFlowScreen(transactionToEdit: transaction)),
    ).then((updated) {
      if (updated == true && context.mounted) {
        ref.invalidate(transactionsProvider);
        ref.invalidate(accountsProvider);
        ref.invalidate(dashboardInsightsProvider);
      }
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsState = ref.watch(transactionsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Transactions'),
        automaticallyImplyLeading: false, // MainScreen'in bir parçası olduğu için geri tuşu yok
      ),
      body: Column(
        children: [
          // YENİ: Özet Kartı
          _SummaryCard(
            totalIncome: transactionsState.totalIncome,
            totalExpense: transactionsState.totalExpense,
            isLoading: transactionsState.isLoading,
          ),
          // YENİ: Filtreleme Çubuğu
          _FilterBar(),
          const Divider(height: 1, thickness: 1),

          // İşlem Listesi
          Expanded(
            child: transactionsState.isLoading && transactionsState.transactions.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : transactionsState.error != null
                    ? Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text('Error: ${transactionsState.error}', textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.error))))
                    : transactionsState.transactions.isEmpty
                        ? const Center(child: Text('No transactions found for the selected period.'))
                        : RefreshIndicator(
                            onRefresh: () async => ref.read(transactionsProvider.notifier).fetchTransactions(),
                            child: ListView.builder(
                              itemCount: transactionsState.transactions.length,
                              itemBuilder: (context, index) {
                                final tx = transactionsState.transactions[index];
                                return TransactionCard(
                                  transaction: tx,
                                  onTap: () => _navigateToEditTransaction(context, ref, tx),
                                  menuItems: [
                                     PopupMenuItem<String>(
                                      value: 'edit',
                                      child: const ListTile(leading: Icon(Icons.edit_outlined), title: Text('Edit')),
                                      onTap: () => _navigateToEditTransaction(context, ref, tx),
                                    ),
                                    PopupMenuItem<String>(
                                      value: 'delete',
                                      child: const ListTile(leading: Icon(Icons.delete_outline), title: Text('Delete', style: TextStyle(color: Colors.red))),
                                      onTap: () => _confirmAndDeleteTransaction(context, ref, tx),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

// Ayrı bir widget olarak özet kartı
class _SummaryCard extends StatelessWidget {
  final double totalIncome;
  final double totalExpense;
  final bool isLoading;

  const _SummaryCard({required this.totalIncome, required this.totalExpense, required this.isLoading});
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final numberFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);
    final net = totalIncome - totalExpense;

    return Container(
      padding: const EdgeInsets.all(16.0),
      color: theme.cardColor,
      child: isLoading
        ? const Center(child: SizedBox(height: 48, child: LinearProgressIndicator()))
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('Total Income', numberFormat.format(totalIncome), Colors.green.shade700, theme),
              _buildSummaryItem('Total Expense', numberFormat.format(totalExpense), theme.colorScheme.error, theme),
              _buildSummaryItem('Net', numberFormat.format(net), net >= 0 ? Colors.blue.shade800 : theme.colorScheme.error, theme),
            ],
          ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color, ThemeData theme) {
    return Column(
      children: [
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade700)),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }
}


// Ayrı bir widget olarak filtre çubuğu
class _FilterBar extends ConsumerWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Seçili filtreye göre chip'i renklendirmek için mevcut aralığı alalım
    final currentStartDate = ref.watch(transactionsProvider.select((s) => s.startDate));
    final currentEndDate = ref.watch(transactionsProvider.select((s) => s.endDate));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        children: [
          _buildQuickFilterChip(context, ref, 'This Month', QuickDateRange.thisMonth, currentStartDate, currentEndDate),
          _buildQuickFilterChip(context, ref, 'Last 3 Months', QuickDateRange.last3Months, currentStartDate, currentEndDate),
          _buildQuickFilterChip(context, ref, 'Last 6 Months', QuickDateRange.last6Months, currentStartDate, currentEndDate),
          _buildQuickFilterChip(context, ref, 'All Time', QuickDateRange.allTime, currentStartDate, currentEndDate),
          const SizedBox(width: 8),
          ActionChip(
            avatar: const Icon(Icons.calendar_today, size: 16),
            label: const Text('Custom...'),
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                initialDateRange: DateTimeRange(start: currentStartDate, end: currentEndDate),
                firstDate: DateTime(2000),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) {
                ref.read(transactionsProvider.notifier).setDateRange(picked.start, picked.end);
              }
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuickFilterChip(BuildContext context, WidgetRef ref, String label, QuickDateRange range, DateTime currentStart, DateTime currentEnd) {
    bool isSelected = false;
    // Hangi chip'in seçili olduğunu anlamak için basit bir kontrol
    final now = DateTime.now();
    DateTime checkStart;
    // Removed unused variable 'checkEnd'
    switch(range) {
        case QuickDateRange.thisMonth:
            checkStart = DateTime(now.year, now.month, 1);
            if(currentStart.year == checkStart.year && currentStart.month == checkStart.month && currentStart.day == checkStart.day) isSelected = true;
            break;
        case QuickDateRange.last3Months:
            checkStart = DateTime(now.year, now.month - 2, 1);
            if(currentStart.year == checkStart.year && currentStart.month == checkStart.month && currentStart.day == checkStart.day) isSelected = true;
            break;
        case QuickDateRange.last6Months:
            checkStart = DateTime(now.year, now.month - 5, 1);
            if(currentStart.year == checkStart.year && currentStart.month == checkStart.month && currentStart.day == checkStart.day) isSelected = true;
            break;
        case QuickDateRange.allTime:
            checkStart = DateTime(2000);
            if(currentStart.year == checkStart.year) isSelected = true;
            break;
        default: break;
    }
    
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool selected) {
          if (selected) { // Sadece seçildiğinde işlem yap
            ref.read(transactionsProvider.notifier).setQuickDateRange(range);
          }
        },
      ),
    );
  }
}