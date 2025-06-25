// File: lib/src/presentation/screens/balance/balance_overview_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import '../../../data/models/account_model.dart';
import '../../../presentation/providers/account_providers.dart';
import '../accounts/account_form_screen.dart';
import '../accounts/account_detail_screen.dart';

class BalanceOverviewScreen extends ConsumerWidget {
  const BalanceOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Hesap ve Bakiye Özeti'),
        backgroundColor: Colors.grey.shade100,
        elevation: 0,
        foregroundColor: Colors.grey.shade800,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(accountsProvider.notifier).fetchAccounts(),
          )
        ],
      ),
      body: accountsAsync.when(
        data: (accounts) {
          if (accounts.isEmpty) {
            return Center(
                child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_wallet_outlined,
                      size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text('Henüz bir hesap oluşturmadınız.',
                      style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  const Text(
                      'Yeni bir hesap eklemek için "+" butonuna dokunun.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ));
          }
          final totalFinancialBalance = accounts
              .where((acc) => acc.accountType.toLowerCase() != 'investment')
              .fold<double>(0.0, (sum, acc) => sum + acc.currentBalance);

          final groupedAccounts = groupBy<AccountModel, String>(
            accounts,
            (account) => _getAccountTypeDisplayName(account.accountType),
          );

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(accountsProvider.notifier).fetchAccounts(),
            child: ListView.builder(
              padding: const EdgeInsets.all(12.0),
              itemCount: groupedAccounts.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _TotalBalanceCard(balance: totalFinancialBalance);
                }

                final groupIndex = index - 1;
                final groupTitle = groupedAccounts.keys.elementAt(groupIndex);
                final groupAccounts =
                    groupedAccounts.values.elementAt(groupIndex);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
                      child: Text(
                        groupTitle,
                        style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ),
                    ...groupAccounts
                        .map((account) => _AccountCard(account: account)),
                  ],
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Hata: $err")),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => const AccountFormScreen()));
        },
        backgroundColor: Colors.teal.shade700,
        child: const Icon(Icons.add),
        tooltip: 'Yeni Hesap Ekle',
      ),
    );
  }

  String _getAccountTypeDisplayName(String type) {
    switch (type) {
      case 'bank':
        return 'Banka Hesapları';
      case 'cash':
        return 'Nakit';
      case 'credit_card':
        return 'Kredi Kartları';
      case 'e_wallet':
        return 'E-Cüzdanlar';
      case 'investment':
        return 'Yatırım Hesapları';
      default:
        return 'Diğer Hesaplar';
    }
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
      color: Colors.teal.shade50.withOpacity(0.5),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Toplam Finansal Bakiye',
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: Colors.teal.shade800)),
            const SizedBox(height: 8),
            Text(numberFormat.format(balance),
                style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.grey.shade900, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('(Yatırım hesapları hariç)',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.grey.shade700)),
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
      case 'bank':
        return Icons.account_balance_outlined;
      case 'cash':
        return Icons.wallet_rounded;
      case 'credit_card':
        return Icons.credit_card_outlined;
      case 'e_wallet':
        return Icons.account_balance_wallet_outlined;
      case 'investment':
        return Icons.show_chart;
      default:
        return Icons.question_mark_rounded;
    }
  }

  void _confirmAndArchive(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${account.accountName} Arşivlensin mi?'),
        content: const Text(
            'Hesap silinmeyecek, sadece bu listeden gizlenecektir. Arşivlenmiş hesaplara daha sonra ayarlardan ulaşabilirsiniz.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('İptal')),
          TextButton(
            style:
                TextButton.styleFrom(foregroundColor: Colors.orange.shade800),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ref
                    .read(accountsProvider.notifier)
                    .archiveAccount(account.id);
                // --- DÜZELTME 1: await sonrası context kullanımı öncesi kontrol ---
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Hesap arşivlendi.'),
                    backgroundColor: Colors.blueGrey));
              } catch (e) {
                // --- DÜZELTME 2: Hata durumunda da await sonrası context kullanımı öncesi kontrol ---
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Hata: $e'), backgroundColor: Colors.red));
              }
            },
            child: const Text('Evet, Arşivle'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final numberFormat = NumberFormat.currency(
        locale: account.currency == 'USD' ? 'en_US' : 'tr_TR',
        symbol: account.currency == 'USD' ? '\$' : '₺');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => AccountDetailScreen(account: account))),
        leading: CircleAvatar(
          backgroundColor: Colors.teal.withOpacity(0.1),
          child: Icon(_getIconForAccountType(account.accountType),
              color: Colors.teal.shade700),
        ),
        title: Text(account.accountName,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
            account.accountType == 'credit_card' ? 'Güncel Borç' : 'Bakiye'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              numberFormat.format(account.currentBalance),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: account.currentBalance >= 0
                    ? Colors.green.shade800
                    : theme.colorScheme.error,
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) =>
                          AccountFormScreen(accountToEdit: account)));
                } else if (value == 'archive') {
                  _confirmAndArchive(context, ref);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Düzenle'))),
                const PopupMenuItem(
                    value: 'archive',
                    child: ListTile(
                        leading: Icon(Icons.archive_outlined),
                        title: Text('Arşivle'))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
