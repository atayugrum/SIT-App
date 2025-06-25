// File: lib/src/presentation/screens/accounts/accounts_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
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
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Hesaplarım'),
        backgroundColor: Colors.grey.shade100,
        elevation: 0,
        foregroundColor: Colors.grey.shade800,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(accountsProvider.notifier).fetchAccounts(),
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
                    Icon(Icons.account_balance_wallet_outlined,
                        size: 80, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text('Henüz hiç hesap oluşturmadınız.',
                        style: TextStyle(fontSize: 18)),
                    const SizedBox(height: 8),
                    const Text(
                        'Yeni bir hesap eklemek için "+" butonuna dokunun.',
                        textAlign: TextAlign.center),
                  ],
                ),
              ));
            }

            final groupedAccounts = groupBy<AccountModel, String>(
              accountsList,
              (account) => _getAccountTypeDisplayName(account.accountType),
            );

            return RefreshIndicator(
              onRefresh: () =>
                  ref.read(accountsProvider.notifier).fetchAccounts(),
              child: ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: groupedAccounts.length,
                itemBuilder: (context, index) {
                  final groupTitle = groupedAccounts.keys.elementAt(index);
                  final groupAccounts = groupedAccounts.values.elementAt(index);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                        child: Text(groupTitle,
                            style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87)),
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
          error: (err, stack) => Center(
                  child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline,
                        color: theme.colorScheme.error, size: 50),
                    const SizedBox(height: 10),
                    Text(
                        'Hesaplar yüklenirken hata oluştu: ${err.toString().replaceFirst("Exception: ", "")}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: theme.colorScheme.error)),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text("Tekrar Dene"),
                        onPressed: () =>
                            ref.read(accountsProvider.notifier).fetchAccounts())
                  ],
                ),
              ))),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (context) => const AccountFormScreen())),
        backgroundColor: Colors.teal.shade700,
        child: const Icon(Icons.add),
        tooltip: 'Hesap Ekle',
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

class _AccountCard extends ConsumerWidget {
  final AccountModel account;
  const _AccountCard({required this.account});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final primaryColor = Colors.teal.shade700;
    IconData accountIconData = Icons.wallet_outlined;
    final accountTypeLower = account.accountType.toLowerCase();

    if (accountTypeLower.contains("bank"))
      accountIconData = Icons.account_balance_outlined;
    else if (accountTypeLower.contains("investment"))
      accountIconData = Icons.show_chart;
    else if (accountTypeLower.contains("cash"))
      accountIconData = Icons.money_outlined;
    else if (accountTypeLower.contains("credit_card"))
      accountIconData = Icons.credit_card_outlined;
    else if (accountTypeLower.contains("e_wallet"))
      accountIconData = Icons.account_balance_wallet_outlined;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: primaryColor.withOpacity(0.1),
          child: Icon(accountIconData, color: primaryColor),
        ),
        title: Text(account.accountName,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
            account.accountType == 'credit_card' ? 'Güncel Borç' : 'Bakiye',
            style: theme.textTheme.bodySmall),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              NumberFormat.currency(
                      locale: account.currency == 'USD' ? 'en_US' : 'tr_TR',
                      symbol: account.currency == 'USD' ? '\$' : '₺')
                  .format(account.currentBalance),
              style: TextStyle(
                  color: account.currentBalance >= 0
                      ? Colors.green.shade800
                      : Colors.red.shade800,
                  fontWeight: FontWeight.w600,
                  fontSize: 16),
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
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => AccountDetailScreen(account: account))),
      ),
    );
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
              Navigator.of(ctx).pop(); // Dialog'u kapat
              try {
                await ref
                    .read(accountsProvider.notifier)
                    .archiveAccount(account.id);
                // --- DÜZELTME 1: `await` sonrası context kullanımı öncesi kontrol ---
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Hesap arşivlendi.'),
                    backgroundColor: Colors.blueGrey));
              } catch (e) {
                // --- DÜZELTME 2: Hata durumunda da `await` sonrası context kullanımı öncesi kontrol ---
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
}
