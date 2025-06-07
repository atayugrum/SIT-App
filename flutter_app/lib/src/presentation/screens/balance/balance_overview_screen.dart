// File: lib/src/presentation/screens/balance/balance_overview_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/account_providers.dart';
import '../accounts/account_detail_screen.dart';
import '../accounts/account_form_screen.dart';

class BalanceOverviewScreen extends ConsumerWidget {
  const BalanceOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsyncValue = ref.watch(accountsProvider);
    final theme = Theme.of(context);
    final numberFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Accounts & Balances'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(accountsProvider),
          ),
        ],
      ),
      body: accountsAsyncValue.when(
        data: (accounts) {
          double totalBalance = accounts.fold(0.0, (sum, acc) => sum + acc.currentBalance);
          return Column(
            children: [
              // Toplam Bakiye Kartı
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 4.0,
                  color: theme.colorScheme.secondaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Net Balance', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSecondaryContainer)),
                        Text(numberFormat.format(totalBalance), style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.onSecondaryContainer, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Hesap Listesi
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80), // FAB için boşluk
                  itemCount: accounts.length,
                  itemBuilder: (context, index) {
                    final account = accounts[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Icon(account.accountType == 'Nakit' ? Icons.money : Icons.account_balance),
                        ),
                        title: Text(account.accountName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(account.accountType),
                        trailing: Text(
                          numberFormat.format(account.currentBalance),
                          style: TextStyle(
                            fontSize: 16,
                            color: account.currentBalance >= 0 ? Colors.green.shade800 : theme.colorScheme.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => AccountDetailScreen(account: account),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Error loading accounts: $err', style: TextStyle(color: theme.colorScheme.error)),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final bool? result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (context) => const AccountFormScreen()),
          );
          if (result == true && context.mounted) {
            ref.invalidate(accountsProvider); 
          }
        },
        label: const Text('Add Account'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}