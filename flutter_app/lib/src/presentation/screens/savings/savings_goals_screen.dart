// File: lib/src/presentation/screens/savings/savings_goals_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../providers/savings_providers.dart';
import '../../widgets/savings_goal_card.dart';
import 'savings_goal_form_screen.dart';

class SavingsGoalsScreen extends ConsumerWidget {
  const SavingsGoalsScreen({super.key});

  void _showAllocateDialog(
      BuildContext context, WidgetRef ref, String goalId, String goalTitle) {
    final ctrl = TextEditingController();
    bool isAllocating = false;
    String? errorText;

    showCupertinoModalPopup<void>(
      context: context,
      builder: (modalCtx) => StatefulBuilder(
        builder: (ctx, setState) => Container(
          height: 260,
          color: const Color(0xFF1C1C1E),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: isAllocating
                        ? null
                        : () => Navigator.of(ctx).pop(),
                    child: const Text('İptal',
                        style:
                            TextStyle(color: AppColors.textSecondary)),
                  ),
                  Text('"$goalTitle" Hedefine Aktar',
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600)),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: isAllocating
                        ? null
                        : () async {
                            final amount = double.tryParse(
                                ctrl.text.replaceAll(',', '.').trim());
                            if (amount == null || amount <= 0) {
                              setState(() => errorText =
                                  'Geçerli bir tutar girin.');
                              return;
                            }
                            setState(() {
                              isAllocating = true;
                              errorText = null;
                            });
                            try {
                              await ref
                                  .read(savingsGoalNotifierProvider
                                      .notifier)
                                  .allocateToGoal(
                                    goalId: goalId,
                                    amount: amount,
                                  );
                              if (!ctx.mounted) return;
                              Navigator.of(ctx).pop();
                            } catch (e) {
                              if (!ctx.mounted) return;
                              setState(() {
                                isAllocating = false;
                                errorText = 'Hata: $e';
                              });
                            }
                          },
                    child: isAllocating
                        ? const CupertinoActivityIndicator()
                        : const Text('Aktar',
                            style:
                                TextStyle(color: AppColors.primaryBlue)),
                  ),
                ],
              ),
              if (errorText != null) ...[
                const SizedBox(height: 4),
                Text(errorText!,
                    style: const TextStyle(
                        color: AppColors.danger, fontSize: 12)),
              ],
              const SizedBox(height: 12),
              CupertinoTextField(
                controller: ctrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                ],
                prefix: const Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Text('₺ ',
                      style: TextStyle(color: AppColors.textPrimary)),
                ),
                placeholder: '0.00',
                placeholderStyle:
                    const TextStyle(color: AppColors.textSecondary),
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: BoxDecoration(
                  color: AppColors.surfaceGlass,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                autofocus: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, WidgetRef ref,
      String goalId, String goalTitle) {
    showCupertinoDialog<void>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Hedefi Sil'),
        content: Text(
            '"$goalTitle" hedefini silmek istediğinize emin misiniz?'),
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
                    .read(savingsGoalNotifierProvider.notifier)
                    .deleteGoal(goalId);
              } catch (_) {}
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(savingsGoalsProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.backgroundDark,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Tasarruf Hedeflerim'),
        backgroundColor: const Color(0xCC000000),
        border: const Border(
            bottom:
                BorderSide(color: AppColors.separator, width: 0.5)),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).push(
            CupertinoPageRoute(
                builder: (_) => const SavingsGoalFormScreen()),
          ),
          child: const Icon(CupertinoIcons.add_circled_solid,
              color: AppColors.primaryBlue),
        ),
      ),
      child: SafeArea(
        child: goalsAsync.when(
          data: (goals) {
            if (goals.isEmpty) {
              return const Center(
                child: Text(
                    'Henüz bir tasarruf hedefi oluşturmadınız.',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15)),
              );
            }
            return CustomScrollView(
              slivers: [
                CupertinoSliverRefreshControl(
                  onRefresh: () async =>
                      ref.invalidate(savingsGoalsProvider),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final goal = goals[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: SavingsGoalCard(
                            goal: goal,
                            onAllocate: () => _showAllocateDialog(
                                context, ref, goal.id, goal.title),
                            onDelete: () => _showDeleteConfirm(
                                context, ref, goal.id, goal.title),
                            onEdit: () => Navigator.of(context).push(
                              CupertinoPageRoute(
                                  builder: (_) => SavingsGoalFormScreen(
                                      goalToEdit: goal)),
                            ),
                          ),
                        );
                      },
                      childCount: goals.length,
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () =>
              const Center(child: CupertinoActivityIndicator()),
          error: (err, _) => Center(
              child: Text('Hata: $err',
                  style: const TextStyle(color: AppColors.danger))),
        ),
      ),
    );
  }
}
