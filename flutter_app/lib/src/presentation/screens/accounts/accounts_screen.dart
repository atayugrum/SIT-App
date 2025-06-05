// File: flutter_app/lib/src/presentation/screens/accounts/accounts_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/account_providers.dart';
import 'account_form_screen.dart';
import 'account_detail_screen.dart'; 
import '../../../data/models/account_model.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsyncValue = ref.watch(accountsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Accounts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // ignore: unused_result
              ref.refresh(accountsProvider); // Refresh by re-calling fetchAccounts
            },
          ),
        ],
      ),
      body: accountsAsyncValue.when(
        data: (accountsList) {
          if (accountsList.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.account_balance_wallet_outlined, size: 80, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text('No accounts yet.', style: TextStyle(fontSize: 18)),
                    const SizedBox(height: 8),
                    const Text('Tap the "+" button to add your first account.', textAlign: TextAlign.center),
                  ],
                ),
              )
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: accountsList.length,
            itemBuilder: (context, index) {
              final AccountModel account = accountsList[index];
              IconData accountIconData = Icons.wallet_outlined; // Default
              if (account.accountType.toLowerCase().contains("bank")) {
                accountIconData = Icons.account_balance_outlined;
              } else if (account.accountType.toLowerCase().contains("cash")) {
                accountIconData = Icons.money_outlined;
              } else if (account.accountType.toLowerCase().contains("card")) {
                accountIconData = Icons.credit_card_outlined;
              }

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    child: Icon(accountIconData, color: theme.colorScheme.onSecondaryContainer),
                  ),
                  title: Text(account.accountName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${account.accountType} - ${account.currency.toUpperCase()}"),
                  trailing: Text(
                    '${account.currency.toUpperCase()} ${account.currentBalance.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: account.currentBalance >= 0 ? Colors.green.shade800 : Colors.red.shade800,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
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
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) {
            print("ACCOUNTS_SCREEN: Error loading accounts: $err\n$stack");
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: theme.colorScheme.error, size: 50),
                      const SizedBox(height: 10),
                      Text('Error loading accounts: ${err.toString().replaceFirst("Exception: ", "")}', textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.error)),
                      const SizedBox(height:20),
                      ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text("Retry"),
                          onPressed: () {
                            // ignore: unused_result
                            ref.refresh(accountsProvider);
                          }
                      )
                    ],
                ),
              )
          );
        }
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (context) => const AccountFormScreen()),
          );
          if (result == true && context.mounted) {
            // ignore: unused_result
            ref.refresh(accountsProvider); // Refresh list after adding
          }
        },
        label: const Text('Add Account'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}