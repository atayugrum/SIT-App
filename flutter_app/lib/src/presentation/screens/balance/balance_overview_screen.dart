// File: lib/src/presentation/screens/balance/balance_overview_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/account_model.dart';
import '../../../presentation/providers/account_providers.dart';
import '../../widgets/glass_card.dart';
import '../accounts/account_detail_screen.dart';
import '../accounts/account_form_screen.dart';

class BalanceOverviewScreen extends ConsumerWidget {
  const BalanceOverviewScreen({super.key});

  static String _typeLabel(String type) {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.backgroundDark,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Hesap ve Bakiye Özeti'),
        backgroundColor: const Color(0xCC000000),
        border: const Border(
            bottom: BorderSide(color: AppColors.separator, width: 0.5)),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () =>
              ref.read(accountsProvider.notifier).fetchAccounts(),
          child: const Icon(CupertinoIcons.refresh,
              color: AppColors.primaryBlue, size: 20),
        ),
      ),
      child: SafeArea(
        child: accountsAsync.when(
          data: (accounts) {
            if (accounts.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.creditcard,
                        size: 64, color: AppColors.textSecondary),
                    SizedBox(height: 16),
                    Text('Henüz bir hesap oluşturmadınız.',
                        style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16)),
                    SizedBox(height: 8),
                    Text(
                        'Yeni bir hesap eklemek için + butonuna dokunun.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13)),
                  ],
                ),
              );
            }

            final totalBalance = accounts
                .where((a) => a.accountType.toLowerCase() != 'investment')
                .fold<double>(0.0, (sum, a) => sum + a.currentBalance);

            final grouped = groupBy<AccountModel, String>(
              accounts,
              (a) => _typeLabel(a.accountType),
            );

            return CustomScrollView(
              slivers: [
                CupertinoSliverRefreshControl(
                  onRefresh: () =>
                      ref.read(accountsProvider.notifier).fetchAccounts(),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Total balance card
                      GlassCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Toplam Finansal Bakiye',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13)),
                            const SizedBox(height: 8),
                            Text(
                              NumberFormat.currency(
                                      locale: 'tr_TR', symbol: '₺')
                                  .format(totalBalance),
                              style: const TextStyle(
                                  color: AppColors.incomeGreen,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            const Text('(Yatırım hesapları hariç)',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                      // Grouped accounts
                      for (final entry in grouped.entries) ...[
                        Padding(
                          padding:
                              const EdgeInsets.only(top: 20, bottom: 8),
                          child: Text(entry.key,
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ),
                        for (final account in entry.value)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _AccountRow(account: account),
                          ),
                      ],
                      // Add account button
                      const SizedBox(height: 8),
                      CupertinoButton.filled(
                        borderRadius: BorderRadius.circular(12),
                        onPressed: () => Navigator.of(context).push(
                          CupertinoPageRoute(
                              builder: (_) => const AccountFormScreen()),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.add, size: 18),
                            SizedBox(width: 8),
                            Text('Yeni Hesap Ekle'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ]),
                  ),
                ),
              ],
            );
          },
          loading: () =>
              const Center(child: CupertinoActivityIndicator()),
          error: (err, _) => Center(
            child: Text('Hata: $err',
                style: const TextStyle(color: AppColors.danger)),
          ),
        ),
      ),
    );
  }
}

class _AccountRow extends ConsumerWidget {
  final AccountModel account;
  const _AccountRow({required this.account});

  IconData get _icon {
    switch (account.accountType) {
      case 'bank':
        return CupertinoIcons.building_2_fill;
      case 'investment':
        return CupertinoIcons.chart_bar_fill;
      case 'cash':
        return CupertinoIcons.money_dollar_circle_fill;
      case 'credit_card':
        return CupertinoIcons.creditcard_fill;
      case 'e_wallet':
        return CupertinoIcons.device_phone_portrait;
      default:
        return CupertinoIcons.square_fill;
    }
  }

  void _showActions(BuildContext context, WidgetRef ref) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(context).pop();
              _confirmArchive(context, ref);
            },
            child: const Text('Arşivle'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
      ),
    );
  }

  void _confirmArchive(BuildContext context, WidgetRef ref) {
    showCupertinoDialog<void>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text('${account.accountName} Arşivlensin mi?'),
        content: const Text(
            'Hesap silinmeyecek, sadece bu listeden gizlenecektir.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await ref
                    .read(accountsProvider.notifier)
                    .archiveAccount(account.id);
              } catch (_) {}
            },
            child: const Text('Arşivle'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale =
        account.currency == 'USD' ? 'en_US' : 'tr_TR';
    final symbol = account.currency == 'USD' ? '\$' : '₺';
    final fmt =
        NumberFormat.currency(locale: locale, symbol: symbol);
    final balance = account.currentBalance;
    final isCredit = account.accountType == 'credit_card';

    return GestureDetector(
      onTap: () => Navigator.of(context).push(CupertinoPageRoute(
          builder: (_) => AccountDetailScreen(account: account))),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color:
                    AppColors.primaryBlue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child:
                  Icon(_icon, color: AppColors.primaryBlue, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(account.accountName,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  Text(isCredit ? 'Güncel Borç' : 'Bakiye',
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12)),
                ],
              ),
            ),
            Text(
              fmt.format(balance),
              style: TextStyle(
                color: balance >= 0
                    ? AppColors.incomeGreen
                    : AppColors.danger,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _showActions(context, ref),
              child: const Icon(CupertinoIcons.ellipsis,
                  color: AppColors.textSecondary, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}
