// File: lib/src/presentation/screens/accounts/accounts_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/account_model.dart';
import '../../providers/account_providers.dart';
import '../../widgets/glass_card.dart';
import 'account_form_screen.dart';
import 'account_detail_screen.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.backgroundDark,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Hesaplarım'),
        backgroundColor: const Color(0xCC000000),
        border: const Border(
            bottom: BorderSide(color: AppColors.separator, width: 0.5)),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).push(
            CupertinoPageRoute(
                builder: (_) => const AccountFormScreen()),
          ),
          child: const Icon(CupertinoIcons.add_circled_solid,
              color: AppColors.primaryBlue),
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
                    Text('Henüz hiç hesap oluşturmadınız.',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 16)),
                    SizedBox(height: 8),
                    Text(
                        'Yeni hesap eklemek için + butonuna dokunun.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              );
            }

            final grouped = groupBy<AccountModel, String>(
              accounts,
              (a) => _accountTypeLabel(a.accountType),
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
                      for (final entry in grouped.entries) ...[
                        Padding(
                          padding:
                              const EdgeInsets.only(top: 16, bottom: 8),
                          child: Text(entry.key,
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ),
                        for (final account in entry.value)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _AccountCard(account: account),
                          ),
                      ],
                    ]),
                  ),
                ),
              ],
            );
          },
          loading: () =>
              const Center(child: CupertinoActivityIndicator()),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Hesaplar yüklenirken hata oluştu:\n${err.toString().replaceFirst("Exception: ", "")}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                  const SizedBox(height: 16),
                  CupertinoButton(
                    onPressed: () =>
                        ref.read(accountsProvider.notifier).fetchAccounts(),
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _accountTypeLabel(String type) {
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
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(CupertinoPageRoute(
                  builder: (_) =>
                      AccountFormScreen(accountToEdit: account)));
            },
            child: const Text('Düzenle'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(context).pop();
              _confirmAndArchive(context, ref);
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

  void _confirmAndArchive(BuildContext context, WidgetRef ref) {
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
    final currencySymbol =
        account.currency == 'USD' ? '\$' : '₺';
    final locale = account.currency == 'USD' ? 'en_US' : 'tr_TR';
    final fmt = NumberFormat.currency(locale: locale, symbol: currencySymbol);
    final balance = account.currentBalance;
    final isCredit = account.accountType == 'credit_card';

    return GestureDetector(
      onTap: () => Navigator.of(context).push(CupertinoPageRoute(
          builder: (_) => AccountDetailScreen(account: account))),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(_icon,
                  color: AppColors.primaryBlue, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(account.accountName,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
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
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _showActions(context, ref),
              child: const Icon(CupertinoIcons.ellipsis,
                  color: AppColors.textSecondary, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
