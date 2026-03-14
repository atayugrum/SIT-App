// File: lib/src/presentation/screens/transactions/transactions_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/account_providers.dart';
import '../../providers/transaction_providers.dart';
import '../../../core/theme/app_theme.dart';
import 'transaction_card.dart';
import 'transaction_flow_screen.dart';
import 'batch_transaction_screen.dart';
import 'transfer_form_screen.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.backgroundDark,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('İşlemlerim'),
        backgroundColor: const Color(0xCC000000),
        border: const Border(bottom: BorderSide(color: AppColors.separator, width: 0.5)),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _showAddOptions(context),
          child: const Icon(CupertinoIcons.add_circled_solid, color: AppColors.primaryBlue),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _SummaryHeader(),
            Container(height: 0.5, color: AppColors.separator),
            _FilterRow(),
            Container(height: 0.5, color: AppColors.separator),
            Expanded(child: _TransactionList()),
          ],
        ),
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('Nasıl İşlem Eklemek İstersiniz?'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                CupertinoPageRoute(builder: (_) => const TransferFormScreen()),
              );
            },
            child: const Text('Hesaplar Arası Transfer'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                CupertinoPageRoute(builder: (_) => const TransactionFlowScreen()),
              );
            },
            child: const Text('Manuel Giriş'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                CupertinoPageRoute(builder: (_) => const BatchTransactionScreen()),
              );
            },
            child: const Text('AI ile Hızlı Giriş'),
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
}

// ── Özet Başlık ───────────────────────────────────────────────────────────────

class _SummaryHeader extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(transactionsProvider);
    final fmt   = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    return Container(
      color: AppColors.surfaceDark,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryItem(
            label: 'Gelir',
            value: fmt.format(state.totalIncome),
            color: AppColors.incomeGreen,
          ),
          _Divider(),
          _SummaryItem(
            label: 'Gider',
            value: fmt.format(state.totalExpense),
            color: AppColors.danger,
          ),
          _Divider(),
          _SummaryItem(
            label: 'Net',
            value: fmt.format(state.totalIncome - state.totalExpense),
            color: AppColors.primaryBlue,
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 15, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 0.5, height: 36, color: AppColors.separator);
  }
}

// ── Filtre Satırı ─────────────────────────────────────────────────────────────

class _FilterRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state    = ref.watch(transactionsProvider);
    final notifier = ref.read(transactionsProvider.notifier);
    final accounts = ref.watch(accountsProvider);

    final now            = DateTime.now();
    final startOfMonth   = DateTime(now.year, now.month, 1);
    final isThisMonth    = state.startDate.year == startOfMonth.year &&
        state.startDate.month == startOfMonth.month &&
        state.startDate.day == startOfMonth.day;
    final dateLabel = isThisMonth
        ? 'Bu Ay'
        : '${DateFormat.MMMd('tr').format(state.startDate)} – ${DateFormat.MMMd('tr').format(state.endDate)}';

    return Container(
      color: AppColors.surfaceDark,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Tarih filtresi
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: AppColors.surfaceGlass,
            borderRadius: BorderRadius.circular(20),
            onPressed: () => _pickDateRange(context, ref, state, notifier),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(CupertinoIcons.calendar, size: 14, color: AppColors.primaryBlue),
                const SizedBox(width: 6),
                Text(dateLabel,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Hesap filtresi
          Expanded(
            child: accounts.when(
              data: (list) => CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                color: AppColors.surfaceGlass,
                borderRadius: BorderRadius.circular(20),
                onPressed: () => _pickAccount(context, ref, list, state, notifier),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(CupertinoIcons.creditcard, size: 14, color: AppColors.primaryBlue),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        state.filterAccount ?? 'Tüm Hesaplar',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
          ),
        ],
      ),
    );
  }

  void _pickDateRange(BuildContext context, WidgetRef ref,
      dynamic state, dynamic notifier) {
    DateTime tempStart = state.startDate;
    DateTime tempEnd   = state.endDate;

    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 320,
        color: const Color(0xFF1C1C1E),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: const Text('İptal',
                      style: TextStyle(color: AppColors.textSecondary)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const Text('Başlangıç Tarihi',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600)),
                CupertinoButton(
                  child: const Text('Uygula',
                      style: TextStyle(color: AppColors.primaryBlue)),
                  onPressed: () {
                    notifier.setDateRange(tempStart, tempEnd);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: tempStart,
                maximumDate: DateTime.now(),
                minimumDate: DateTime(2000),
                onDateTimeChanged: (d) => tempStart = d,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _pickAccount(BuildContext context, WidgetRef ref, List<dynamic> accounts,
      dynamic state, dynamic notifier) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('Hesap Seç'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              notifier.setAccountFilter(null);
              Navigator.of(context).pop();
            },
            child: const Text('Tüm Hesaplar'),
          ),
          ...accounts.map((a) => CupertinoActionSheetAction(
                onPressed: () {
                  notifier.setAccountFilter(a.accountName);
                  Navigator.of(context).pop();
                },
                child: Text(a.accountName),
              )),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
      ),
    );
  }
}

// ── İşlem Listesi ─────────────────────────────────────────────────────────────

class _TransactionList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(transactionsProvider);

    if (state.isLoading && state.transactions.isEmpty) {
      return const Center(child: CupertinoActivityIndicator(radius: 14));
    }
    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Hata: ${state.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.danger, fontSize: 14)),
        ),
      );
    }
    if (state.transactions.isEmpty) {
      return const Center(
        child: Text('Seçili kriterlere uygun işlem bulunamadı.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
      );
    }

    return CustomScrollView(
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () =>
              ref.read(transactionsProvider.notifier).fetchTransactions(),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(12),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final tx = state.transactions[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TransactionCard(
                    transaction: tx,
                    onTap: () => Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (_) =>
                            TransactionFlowScreen(transactionToEdit: tx),
                      ),
                    ),
                  ),
                );
              },
              childCount: state.transactions.length,
            ),
          ),
        ),
      ],
    );
  }
}
