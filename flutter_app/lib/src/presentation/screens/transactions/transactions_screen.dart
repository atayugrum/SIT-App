// File: flutter_app/lib/src/presentation/screens/transactions/transactions_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/transaction_providers.dart';
import '../../../data/models/transaction_model.dart';
import 'transaction_flow_screen.dart'; 
import '../../providers/transaction_form_provider.dart'; 
import '../../../core/categories.dart'; // <-- ADD THIS IMPORT

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(transactionsProvider.notifier).fetchTransactions();
      }
    });
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final notifier = ref.read(transactionsProvider.notifier);
    final currentRange = ref.read(transactionsProvider);

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: DateTimeRange(start: currentRange.startDate, end: currentRange.endDate),
    );
    if (picked != null && mounted) { // Added mounted check
      notifier.setDateRange(picked.start, picked.end);
    }
  }

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
              onPressed: () {
                Navigator.of(ctx).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
              child: const Text('Delete'),
              onPressed: () async {
                Navigator.of(ctx).pop(); // Close dialog
                try {
                  if (transaction.id == null) {
                    throw Exception("Transaction ID is null, cannot delete.");
                  }
                  await ref.read(transactionsProvider.notifier).deleteTransactionFromList(transaction.id!);
                  if (mounted) { // Check mounted again before showing SnackBar
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Transaction deleted successfully!'), backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  if (mounted) { // Check mounted
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error deleting transaction: ${e.toString().replaceFirst("Exception: ", "")}'), backgroundColor: Colors.redAccent),
                    );
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
    // Load the transaction data into the form provider for editing
    ref.read(transactionFormNotifierProvider.notifier).loadTransactionForEdit(transaction);

    Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => TransactionFlowScreen(
          transactionToEdit: transaction, // Pass the transaction to edit
        ),
      ),
    ).then((result) {
      if (result == true && mounted) { // If edit screen popped with success indication
        ref.read(transactionsProvider.notifier).fetchTransactions();
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    // 'ref' is directly available in ConsumerState's build method
    final state = ref.watch(transactionsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh), // Added refresh button
            tooltip: 'Refresh Transactions',
            onPressed: () => ref.read(transactionsProvider.notifier).fetchTransactions(),
          ),
          IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: 'Select Date Range',
            onPressed: () => _selectDateRange(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    'Period: ${DateFormat.yMd().format(state.startDate)} - ${DateFormat.yMd().format(state.endDate)}',
                    style: theme.textTheme.labelMedium,
                ),
                // You can add a Text widget here to show state.filterType if it's active
              ],
            ),
          ),
          if (state.isLoading && state.transactions.isEmpty)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (state.error != null)
            Expanded(child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Error loading transactions:\n${state.error.toString().replaceFirst("Exception: ", "")}', textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.error)),
                )
            ))
          else if (state.transactions.isEmpty)
            const Expanded(child: Center(child: Text('No transactions found for this period.')))
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                itemCount: state.transactions.length,
                itemBuilder: (context, index) {
                  final TransactionModel transaction = state.transactions[index];
                  final bool isIncome = transaction.type == 'income';
                  final Color amountColor = isIncome ? Colors.green.shade700 : theme.colorScheme.error;

                  IconData categoryIconData = Icons.category_outlined; // Default
                  final Map<String, IconData> icons = isIncome ? incomeCategories : expenseCategories;
                  if (icons.containsKey(transaction.category)) {
                    categoryIconData = icons[transaction.category]!;
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    elevation: 1.5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: ListTile( 
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer.withAlpha((255 * 0.5).round()),
                        child: Icon(categoryIconData, size: 22, color: theme.colorScheme.onPrimaryContainer),
                      ),
                      title: Text(
                        transaction.category + (transaction.subCategory != null && transaction.subCategory!.isNotEmpty ? ' > ${transaction.subCategory}' : ''),
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (transaction.description != null && transaction.description!.isNotEmpty)
                            Text(
                              transaction.description!,
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          Text(
                            transaction.account,
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      trailing: Row( 
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${isIncome ? "" : "-"}₺${transaction.amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: amountColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat.yMMMd().format(transaction.date),
                                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            onSelected: (String value) {
                              if (value == 'edit') {
                                _navigateToEditTransaction(context, ref, transaction);
                              } else if (value == 'delete') {
                                _confirmAndDeleteTransaction(context, ref, transaction);
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
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          ref.read(transactionFormNotifierProvider.notifier).reset(); 
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (context) => const TransactionFlowScreen()), // For creating new
          );
          if (result == true && mounted) { 
            ref.read(transactionsProvider.notifier).fetchTransactions();
          }
        },
        label: const Text('Add'),
        icon: const Icon(Icons.add),
        tooltip: 'Add Transaction',
      ),
    );
  }
}