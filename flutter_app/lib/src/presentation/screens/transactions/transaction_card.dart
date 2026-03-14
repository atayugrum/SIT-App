// File: lib/src/presentation/screens/transactions/transaction_card.dart
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

import '../../../core/categories.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/transaction_model.dart';
import '../../widgets/glass_card.dart';

class TransactionCard extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onTap;
  /// Action sheet seçenekleri: (label, isDestructive, callback)
  final List<({String label, bool isDestructive, VoidCallback action})>? actions;

  const TransactionCard({
    super.key,
    required this.transaction,
    this.onTap,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final fmt       = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    final isIncome  = transaction.type == 'income';
    final color     = isIncome ? AppColors.incomeGreen : AppColors.danger;
    final iconMap   = isIncome ? incomeCategories : expenseCategories;
    final icon      = iconMap[transaction.category] ?? CupertinoIcons.arrow_right_arrow_left_circle_fill;
    final sign      = isIncome ? '+' : '-';

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: onTap ?? (actions != null ? () => _showActions(context) : null),
      child: Row(
        children: [
          // ── Kategori ikonu ─────────────────────────────────────────────────
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),

          // ── Kategori & açıklama ────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.category,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (transaction.subCategory != null &&
                    transaction.subCategory!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    transaction.subCategory!,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
                if (transaction.description != null &&
                    transaction.description!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    transaction.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.textTertiary, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),

          // ── Tutar & tarih ──────────────────────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$sign ${fmt.format(transaction.amount)}',
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat.yMd('tr_TR').format(transaction.date.toLocal()),
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),

          if (actions != null && actions!.isNotEmpty) ...[
            const SizedBox(width: 8),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _showActions(context),
              child: const Icon(CupertinoIcons.ellipsis,
                  color: AppColors.textSecondary, size: 18),
            ),
          ],
        ],
      ),
    );
  }

  void _showActions(BuildContext context) {
    if (actions == null || actions!.isEmpty) return;
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        actions: actions!
            .map((a) => CupertinoActionSheetAction(
                  isDestructiveAction: a.isDestructive,
                  onPressed: () {
                    Navigator.of(context).pop();
                    a.action();
                  },
                  child: Text(a.label),
                ))
            .toList(),
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
      ),
    );
  }
}
