// File: lib/src/presentation/screens/balance/balance_overview_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/account_model.dart';
import '../../../presentation/providers/account_providers.dart';
import '../accounts/account_form_screen.dart';
import '../../../presentation/screens/transactions/transactions_screen.dart';
import '../../../presentation/providers/transaction_providers.dart';
// YENİ IMPORTLAR



class BalanceOverviewScreen extends ConsumerWidget {
  const BalanceOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hesaplarım ve Bakiyeler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(accountsProvider),
          )
        ],
      ),
      body: accountsAsync.when(
        data: (accounts) {
          if (accounts.isEmpty) {
            return const Center(child: Text('Henüz bir hesap oluşturmadınız.'));
          }
          final totalFinancialBalance = accounts
              .where((acc) => acc.accountType.toLowerCase() != 'investment')
              .fold<double>(0.0, (sum, acc) => sum + acc.currentBalance);

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(accountsProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _TotalBalanceCard(balance: totalFinancialBalance),
                const SizedBox(height: 16),
                ...accounts.map((account) => _AccountCard(account: account)).toList(),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Hata: $err")),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const AccountFormScreen())
          ).then((success) {
            if (success == true) {
              ref.invalidate(accountsProvider);
            }
          });
        },
        child: const Icon(Icons.add),
        tooltip: 'Yeni Hesap Ekle',
      ),
    );
  }
}

class _TotalBalanceCard extends StatelessWidget {
  final double balance;
  const _TotalBalanceCard({required this.balance});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final numberFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Toplam Finansal Bakiye', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer)),
            const SizedBox(height: 8),
            Text(numberFormat.format(balance), style: theme.textTheme.headlineMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _AccountCard extends ConsumerWidget {
  final AccountModel account;
  const _AccountCard({required this.account});

  IconData _getIconForAccountType(String type) {
    switch (type.toLowerCase()) {
      case 'bank': return Icons.account_balance;
      case 'cash': return Icons.wallet_rounded;
      case 'credit_card': return Icons.credit_card;
      case 'savings': return Icons.savings;
      case 'investment': return Icons.show_chart;
      default: return Icons.question_mark;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final numberFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(child: Icon(_getIconForAccountType(account.accountType))),
        title: Text(account.accountName, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text(
          numberFormat.format(account.currentBalance),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: account.currentBalance >= 0 ? Colors.green.shade800 : Colors.red.shade800,
          ),
        ),
        onTap: () {
          // DÜZELTME: Hesap tipine göre doğru parametrelerle doğru ekrana yönlendirme
          if (account.accountType.toLowerCase() == 'investment') {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const TransactionsScreen()
            ));
          } else {
            ref.read(transactionsProvider.notifier).setAccountFilter(account.accountName);
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const TransactionsScreen()
            ));
          }
        },
      ),
    );
  }
}