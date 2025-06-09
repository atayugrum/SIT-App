// File: lib/src/presentation/screens/accounts/accounts_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
        title: const Text('Hesaplarım'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Notifier üzerinden listeyi yeniden çekmek için fetchAccounts'ı çağırıyoruz.
              ref.read(accountsProvider.notifier).fetchAccounts();
            },
            tooltip: 'Yenile',
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
                    const Text('Henüz hiç hesap oluşturmadınız.', style: TextStyle(fontSize: 18)),
                    const SizedBox(height: 8),
                    const Text('Yeni bir hesap eklemek için "+" butonuna dokunun.', textAlign: TextAlign.center),
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
              IconData accountIconData = Icons.wallet_outlined; // Varsayılan ikon
              
              final accountTypeLower = account.accountType.toLowerCase();
              if (accountTypeLower.contains("bank")) {
                accountIconData = Icons.account_balance_outlined;
              } else if (accountTypeLower.contains("investment")) {
                accountIconData = Icons.show_chart;
              } else if (accountTypeLower.contains("cash")) {
                accountIconData = Icons.money_outlined;
              } else if (accountTypeLower.contains("card")) {
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
                  subtitle: Text("${account.accountType} (${account.currency.toUpperCase()})"),
                  trailing: Text(
                    NumberFormat.currency(
                      locale: account.currency == 'USD' ? 'en_US' : 'tr_TR', 
                      symbol: account.currency == 'USD' ? '\$' : '₺'
                    ).format(account.currentBalance),
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
                      Text('Hesaplar yüklenirken hata oluştu: ${err.toString().replaceFirst("Exception: ", "")}', textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.error)),
                      const SizedBox(height:20),
                      ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text("Tekrar Dene"),
                          onPressed: () {
                            ref.read(accountsProvider.notifier).fetchAccounts();
                          }
                      )
                    ],
                ),
              )
          );
        }
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (context) => const AccountFormScreen()),
          );
          if (result == true && context.mounted) {
            ref.read(accountsProvider.notifier).fetchAccounts();
          }
        },
        child: const Icon(Icons.add),
        tooltip: 'Hesap Ekle',
      ),
    );
  }
}