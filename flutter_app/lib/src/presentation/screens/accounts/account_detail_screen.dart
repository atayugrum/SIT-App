// File: lib/src/presentation/screens/accounts/account_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/src/data/models/transaction_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/account_model.dart';
import '../../providers/transaction_providers.dart';
import '../../providers/account_providers.dart';
import '../transactions/transaction_card.dart';
import '../transactions/transaction_flow_screen.dart';

class AccountDetailScreen extends ConsumerWidget {
  final AccountModel account;

  const AccountDetailScreen({super.key, required this.account});

  void _navigateToEditTransaction(BuildContext context, WidgetRef ref, TransactionModel transaction) {
    Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => TransactionFlowScreen(transactionToEdit: transaction),
      ),
    ).then((updated) {
      // If the transaction was updated, refresh the data
      if (updated == true && context.mounted) {
        ref.invalidate(accountTransactionsProvider(account.accountName));
        ref.invalidate(accountsProvider);
      }
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsState = ref.watch(accountsProvider);
    AccountModel currentAccountDisplay = account;
    
    if (accountsState is AsyncData<List<AccountModel>>) {
      try {
        currentAccountDisplay = accountsState.value.firstWhere((acc) => acc.id == account.id);
      } catch (e) {
        print("AccountDetailScreen: Could not find account with ID ${account.id}, using initial data.");
      }
    }
    
    final transactionsAsyncValue = ref.watch(accountTransactionsProvider(currentAccountDisplay.accountName));
    final theme = Theme.of(context);
    final numberFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    return Scaffold(
      appBar: AppBar(
        title: Text(currentAccountDisplay.accountName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(accountTransactionsProvider(currentAccountDisplay.accountName));
              ref.invalidate(accountsProvider);
            },
          ),
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
                      Text('Current Balance:', style: theme.textTheme.bodyLarge),
                      Text(
                        numberFormat.format(currentAccountDisplay.currentBalance),
                        style: theme.textTheme.displaySmall?.copyWith(
                          color: currentAccountDisplay.currentBalance >= 0 ? Colors.green.shade700 : theme.colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                    final tx = transactions[index];
                    return TransactionCard(
                      transaction: tx,
                      onTap: () => _navigateToEditTransaction(context, ref, tx),
                      // Provide menu items for edit/delete
                      menuItems: [
                        PopupMenuItem<String>(
                          value: 'edit',
                          child: const ListTile(leading: Icon(Icons.edit_outlined), title: Text('Edit')),
                          onTap: () => _navigateToEditTransaction(context, ref, tx),
                        ),
                        // You can add a delete option here as well if needed
                      ],
                    );
                  },
                  childCount: transactions.length,
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(32.0), child: Center(child: CircularProgressIndicator()))),
            error: (err, stack) {
              return SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Error loading transactions: ${err.toString()}', style: TextStyle(color: theme.colorScheme.error)),
                  ),
                )
              );
            }
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}