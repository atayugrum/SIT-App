// File: lib/src/presentation/screens/accounts/account_detail_screen.dart
import 'package:flutter/material.dart';
import '../../../data/models/transaction_model.dart';
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

  void _navigateToEditTransaction(
      BuildContext context, WidgetRef ref, TransactionModel transaction) {
    Navigator.of(context)
        .push<bool>(
      MaterialPageRoute(
        builder: (context) =>
            TransactionFlowScreen(transactionToEdit: transaction),
      ),
    )
        .then((updated) {
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
        currentAccountDisplay =
            accountsState.value.firstWhere((acc) => acc.id == account.id);
      } catch (e) {
        print(
            "Hesap Detay: Hesap ID ${account.id} bulunamadı, başlangıç verisi kullanılıyor.");
      }
    }

    final transactionsAsyncValue = ref
        .watch(accountTransactionsProvider(currentAccountDisplay.accountName));
    final theme = Theme.of(context);
    final numberFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    final primaryColor = Colors.teal.shade700;

    return Scaffold(
      appBar: AppBar(
        title: Text(currentAccountDisplay.accountName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Yenile",
            onPressed: () {
              ref.invalidate(accountTransactionsProvider(
                  currentAccountDisplay.accountName));
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                color: primaryColor.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getAccountTypeDisplayName(
                            currentAccountDisplay.accountType),
                        style: theme.textTheme.titleMedium
                            ?.copyWith(color: primaryColor),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Güncel Bakiye',
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(color: Colors.grey.shade800),
                      ),
                      Text(
                        numberFormat
                            .format(currentAccountDisplay.currentBalance),
                        style: theme.textTheme.displaySmall?.copyWith(
                          color: currentAccountDisplay.currentBalance >= 0
                              ? Colors.black87
                              : theme.colorScheme.error,
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Text("Son İşlemler",
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
          ),
          transactionsAsyncValue.when(
            data: (transactions) {
              if (transactions.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          vertical: 40.0, horizontal: 16.0),
                      child: Text("Bu hesap için henüz işlem bulunmuyor.",
                          textAlign: TextAlign.center),
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
                      menuItems: [
                        PopupMenuItem<String>(
                          value: 'edit',
                          child: const ListTile(
                              leading: Icon(Icons.edit_outlined),
                              title: Text('Düzenle')),
                          onTap: () =>
                              _navigateToEditTransaction(context, ref, tx),
                        ),
                      ],
                    );
                  },
                  childCount: transactions.length,
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
                child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: CircularProgressIndicator()))),
            error: (err, stack) => SliverToBoxAdapter(
                child: Center(
                    child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('İşlemler yüklenirken hata oluştu: ${err.toString()}',
                  style: TextStyle(color: theme.colorScheme.error)),
            ))),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  String _getAccountTypeDisplayName(String type) {
    switch (type) {
      case 'bank':
        return 'Banka Hesabı';
      case 'cash':
        return 'Nakit';
      case 'credit_card':
        return 'Kredi Kartı';
      case 'e_wallet':
        return 'E-Cüzdan';
      case 'investment':
        return 'Yatırım Hesabı';
      default:
        return 'Diğer Hesap';
    }
  }
}
