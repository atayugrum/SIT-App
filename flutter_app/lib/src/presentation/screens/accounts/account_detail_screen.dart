// File: flutter_app/lib/src/presentation/screens/accounts/account_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/account_model.dart';
import '../../../data/models/transaction_model.dart'; // Ensure this import is present
import '../../providers/transaction_providers.dart';
import '../../providers/account_providers.dart';
import '../../../core/categories.dart'; // For category icons

class AccountDetailScreen extends ConsumerWidget {
  final AccountModel account;

  const AccountDetailScreen({super.key, required this.account});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsState = ref.watch(accountsProvider);
    AccountModel currentAccountDisplay = account; // Default to initially passed account

    // Try to get the most up-to-date account info from the provider
    if (accountsState is AsyncData<List<AccountModel>>) {
      try {
        currentAccountDisplay = accountsState.value.firstWhere((acc) => acc.id == account.id);
      } catch (e) {
        // If not found (e.g., deleted), stick with initially passed data or handle error
        print("AccountDetailScreen: Could not find account with ID ${account.id} in provider, using initial data.");
      }
    }
    
    final transactionsAsyncValue = ref.watch(accountTransactionsProvider(currentAccountDisplay.accountName));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(currentAccountDisplay.accountName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // ignore: unused_result
              ref.refresh(accountTransactionsProvider(currentAccountDisplay.accountName));
              // ignore: unused_result
              ref.refresh(accountsProvider);
            },
          ),
          // TODO: Add Edit Account button later that navigates to AccountFormScreen(accountToEdit: currentAccountDisplay)
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentAccountDisplay.accountType,
                        style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Current Balance:',
                        style: theme.textTheme.bodyLarge,
                      ),
                      Text(
                        '${currentAccountDisplay.currency.toUpperCase()} ${currentAccountDisplay.currentBalance.toStringAsFixed(2)}',
                        style: theme.textTheme.displaySmall?.copyWith(
                          color: currentAccountDisplay.currentBalance >= 0 ? Colors.green.shade700 : theme.colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // You can add more details like initial balance, created date etc.
                      // SizedBox(height: 8),
                      // Text('Initial Balance: ${currentAccountDisplay.currency.toUpperCase()} ${currentAccountDisplay.initialBalance.toStringAsFixed(2)}', style: theme.textTheme.bodySmall),
                      // Text('Created: ${DateFormat.yMMMd().format(currentAccountDisplay.createdAt)}', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text("Recent Transactions", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ),
          ),
          transactionsAsyncValue.when(
            data: (transactions) {
              if (transactions.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40.0, horizontal: 16.0),
                      child: Text("No transactions found for this account in the selected period.", textAlign: TextAlign.center),
                    ),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final TransactionModel tx = transactions[index]; // Explicitly typed
                    final isIncome = tx.type == 'income';
                    final Color amountColor = isIncome ? Colors.green.shade700 : theme.colorScheme.error;
                    IconData categoryIconData = Icons.swap_horiz_outlined; // Default
                    final Map<String, IconData> icons = isIncome ? incomeCategories : expenseCategories;
                    if (icons.containsKey(tx.category)) {
                      categoryIconData = icons[tx.category]!;
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                      elevation: 1.5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: amountColor.withAlpha(30),
                          child: Icon(categoryIconData, color: amountColor, size: 20),
                        ),
                        title: Text(tx.category + (tx.subCategory != null && tx.subCategory!.isNotEmpty ? " > ${tx.subCategory}" : "")),
                        subtitle: Text(tx.description != null && tx.description!.isNotEmpty 
                                        ? tx.description! 
                                        : DateFormat.yMMMd().add_jm().format(tx.date.toLocal()), // Show time if no desc
                                      maxLines: 1, overflow: TextOverflow.ellipsis,
                                    ),
                        trailing: Text(
                          '${isIncome ? "+" : "-"} ${currentAccountDisplay.currency.toUpperCase()} ${tx.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: amountColor,
                            fontWeight: FontWeight.w600
                          ),
                        ),
                         onTap: () {
                          // TODO: Navigate to TransactionFlowScreen in Edit Mode for this transaction
                          // ref.read(transactionFormNotifierProvider.notifier).loadTransactionForEdit(tx);
                          // Navigator.of(context).push(MaterialPageRoute(builder: (_) => TransactionFlowScreen(transactionToEdit: tx)));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Editing transaction ${tx.id ?? tx.category} coming soon!'))
                          );
                        },
                      ),
                    );
                  },
                  childCount: transactions.length,
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(32.0), child: Center(child: CircularProgressIndicator()))),
            error: (err, stack) {
              print("ACCOUNT_DETAIL_SCREEN: Error loading transactions for account ${account.accountName}: $err\n$stack");
              return SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error loading transactions: ${err.toString().replaceFirst("Exception: ", "")}', textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.error)),
                        const SizedBox(height:10),
                        ElevatedButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: const Text("Retry"),
                            onPressed: () {
                              // ignore: unused_result
                              ref.refresh(accountTransactionsProvider(account.accountName));
                            }
                        )
                      ],
                    ),
                  )
                )
              );
            }
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)), // Padding at the bottom for FAB visibility
        ],
      ),
    );
  }
}