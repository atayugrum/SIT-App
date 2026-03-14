// File: lib/src/presentation/widgets/savings_goal_card.dart
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/savings_goal_model.dart';
import 'glass_card.dart';

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
    final fmt =
        NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    final progress = goal.progress.clamp(0.0, 1.0);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(CupertinoIcons.flag_fill,
                    color: AppColors.primaryBlue, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.title,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      'Hedef: ${DateFormat.yMMMd('tr_TR').format(goal.targetDate)}',
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  showCupertinoModalPopup(
                    context: context,
                    builder: (_) => CupertinoActionSheet(
                      actions: [
                        CupertinoActionSheetAction(
                          onPressed: () {
                            Navigator.of(context).pop();
                            onEdit();
                          },
                          child: const Text('Düzenle'),
                        ),
                        CupertinoActionSheetAction(
                          isDestructiveAction: true,
                          onPressed: () {
                            Navigator.of(context).pop();
                            onDelete();
                          },
                          child: const Text('Sil'),
                        ),
                      ],
                      cancelButton: CupertinoActionSheetAction(
                        isDefaultAction: true,
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('İptal'),
                      ),
                    ),
                  );
                },
                child: const Icon(CupertinoIcons.ellipsis,
                    color: AppColors.textSecondary, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.glassBorder,
                      borderRadius: BorderRadius.circular(6),
                    )),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.incomeGreen,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(fmt.format(goal.currentAmount),
                  style: const TextStyle(
                      color: AppColors.incomeGreen,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              Text('%${(progress * 100).toStringAsFixed(1)}',
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12)),
              Text(fmt.format(goal.targetAmount),
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13)),
            ],
          ),
          Container(
              height: 0.5,
              color: AppColors.separator,
              margin: const EdgeInsets.symmetric(vertical: 12)),
          Align(
            alignment: Alignment.centerRight,
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onAllocate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color:
                      AppColors.primaryBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.primaryBlue, width: 0.5),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.plus_circle,
                        color: AppColors.primaryBlue, size: 16),
                    SizedBox(width: 6),
                    Text('Para Aktar',
                        style: TextStyle(
                            color: AppColors.primaryBlue,
                            fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
