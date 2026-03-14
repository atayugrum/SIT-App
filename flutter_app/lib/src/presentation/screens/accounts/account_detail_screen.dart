// File: lib/src/presentation/screens/accounts/account_detail_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/account_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../providers/account_providers.dart';
import '../../providers/transaction_providers.dart';
import '../../widgets/glass_card.dart';
import '../transactions/transaction_card.dart';
import '../transactions/transaction_flow_screen.dart';

class AccountDetailScreen extends ConsumerWidget {
  final AccountModel account;
  const AccountDetailScreen({super.key, required this.account});

  void _navigateToEdit(
      BuildContext context, WidgetRef ref, TransactionModel tx) {
    Navigator.of(context)
        .push<bool>(CupertinoPageRoute(
          builder: (_) => TransactionFlowScreen(transactionToEdit: tx),
        ))
        .then((updated) {
      if (updated == true && context.mounted) {
        ref.invalidate(accountTransactionsProvider(account.accountName));
        ref.invalidate(accountsProvider);
      }
    });
  }

  String _accountTypeLabel(String type) {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsState = ref.watch(accountsProvider);
    AccountModel current = account;
    if (accountsState is AsyncData<List<AccountModel>>) {
      try {
        current = accountsState.value.firstWhere((a) => a.id == account.id);
      } catch (_) {}
    }

    final txAsync =
        ref.watch(accountTransactionsProvider(current.accountName));
    final fmt = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    return CupertinoPageScaffold(
      backgroundColor: AppColors.backgroundDark,
      navigationBar: CupertinoNavigationBar(
        middle: Text(current.accountName),
        backgroundColor: const Color(0xCC000000),
        border: const Border(
            bottom: BorderSide(color: AppColors.separator, width: 0.5)),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            ref.invalidate(
                accountTransactionsProvider(current.accountName));
            ref.invalidate(accountsProvider);
          },
          child: const Icon(CupertinoIcons.refresh,
              color: AppColors.primaryBlue, size: 20),
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _accountTypeLabel(current.accountType),
                        style: const TextStyle(
                            color: AppColors.primaryBlue,
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      const Text('Güncel Bakiye',
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(
                        fmt.format(current.currentBalance),
                        style: TextStyle(
                          color: current.currentBalance >= 0
                              ? AppColors.incomeGreen
                              : AppColors.danger,
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Text('Son İşlemler',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
              ),
            ),
            txAsync.when(
              data: (transactions) {
                if (transactions.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          vertical: 40, horizontal: 16),
                      child: Center(
                        child: Text(
                          'Bu hesap için henüz işlem bulunmuyor.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 15),
                        ),
                      ),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final tx = transactions[i];
                      return TransactionCard(
                        transaction: tx,
                        onTap: () => _navigateToEdit(context, ref, tx),
                        actions: [
                          (
                            label: 'Düzenle',
                            isDestructive: false,
                            action: () => _navigateToEdit(context, ref, tx),
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
                  padding: EdgeInsets.all(32),
                  child: Center(child: CupertinoActivityIndicator()),
                ),
              ),
              error: (err, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'İşlemler yüklenirken hata oluştu: $err',
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }
}
