// File: lib/src/presentation/widgets/savings_goal_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../data/models/savings_goal_model.dart';

class SavingsGoalCard extends StatelessWidget {
  final SavingsGoalModel goal;
  final VoidCallback onAllocate;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const SavingsGoalCard({
    super.key,
    required this.goal,
    required this.onAllocate,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    final progress = goal.progress.clamp(0.0, 1.0);
    final primaryColor = Colors.teal.shade700;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                    backgroundColor: primaryColor.withOpacity(0.1),
                    child: Icon(Icons.flag_outlined, color: primaryColor)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(goal.title,
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                          'Hedef Tarihi: ${DateFormat.yMMMd('tr_TR').format(goal.targetDate)}',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit')
                      onEdit();
                    else if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                    const PopupMenuItem(
                        value: 'delete',
                        child:
                            Text('Sil', style: TextStyle(color: Colors.red))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearPercentIndicator(
              percent: progress,
              lineHeight: 12,
              backgroundColor: Colors.grey.shade300,
              progressColor: Colors.green.shade600,
              barRadius: const Radius.circular(6),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(currencyFormat.format(goal.currentAmount),
                    style: theme.textTheme.bodyLarge?.copyWith(
                        color: primaryColor, fontWeight: FontWeight.w600)),
                Text('%${(progress * 100).toStringAsFixed(1)}',
                    style: theme.textTheme.bodySmall),
                Text(currencyFormat.format(goal.targetAmount),
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: Colors.grey.shade800)),
              ],
            ),
            const Divider(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                onPressed: onAllocate,
                icon: const Icon(Icons.add_card_outlined),
                label: const Text('Para Aktar'),
                style: FilledButton.styleFrom(
                    backgroundColor: Colors.teal.shade50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
