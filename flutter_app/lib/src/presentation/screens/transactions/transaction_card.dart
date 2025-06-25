// File: lib/src/presentation/widgets/transaction_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/categories.dart';
import '../../../data/models/transaction_model.dart';

class TransactionCard extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onTap;
  final List<PopupMenuEntry<String>>? menuItems;

  const TransactionCard({
    super.key,
    required this.transaction,
    this.onTap,
    this.menuItems,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final numberFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    final isIncome = transaction.type == 'income';

    final Color amountColor =
        isIncome ? Colors.green.shade700 : theme.colorScheme.error;
    final Map<String, IconData> icons =
        isIncome ? incomeCategories : expenseCategories;
    IconData categoryIconData =
        icons[transaction.category] ?? Icons.swap_horiz_outlined;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.only(
              left: 12.0, top: 12.0, bottom: 12.0, right: 0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: amountColor.withOpacity(0.1),
                child: Icon(categoryIconData, color: amountColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.category,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (transaction.subCategory != null &&
                        transaction.subCategory!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Text(
                          transaction.subCategory!,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: Colors.grey.shade700),
                        ),
                      ),
                    if (transaction.description != null &&
                        transaction.description!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        transaction.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ]
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${isIncome ? "+" : "-"} ${numberFormat.format(transaction.amount)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: amountColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat.yMd('tr_TR').format(transaction.date.toLocal()),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              if (menuItems != null && menuItems!.isNotEmpty)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                  tooltip: "Seçenekler",
                  itemBuilder: (BuildContext context) => menuItems!,
                )
              else
                const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}
