// File: lib/src/presentation/screens/budgets/budget_overview_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/categories.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/budget_model.dart';
import '../../providers/budget_providers.dart';
import '../../widgets/glass_card.dart';
import 'budget_form_screen.dart';

class BudgetOverviewScreen extends ConsumerWidget {
  const BudgetOverviewScreen({super.key});

  void _showMonthYearPicker(
      BuildContext context, WidgetRef ref, DateTime current) {
    DateTime temp = current;
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
                      style:
                          TextStyle(color: AppColors.textSecondary)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const Text('Dönem Seç',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600)),
                CupertinoButton(
                  child: const Text('Uygula',
                      style:
                          TextStyle(color: AppColors.primaryBlue)),
                  onPressed: () {
                    ref
                        .read(budgetPeriodProvider.notifier)
                        .state = temp;
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.monthYear,
                initialDateTime: current,
                onDateTimeChanged: (d) => temp = d,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetsProvider);
    final selectedPeriod = ref.watch(budgetPeriodProvider);
    final periodLabel =
        DateFormat.yMMMM('tr_TR').format(selectedPeriod);

    ref.listen<AsyncValue<void>>(budgetActionNotifierProvider,
        (_, next) {
      if (next is AsyncError) {
        showCupertinoDialog(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            content: Text('Hata: ${next.error}'),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Tamam'),
              ),
            ],
          ),
        );
      }
    });

    return CupertinoPageScaffold(
      backgroundColor: AppColors.backgroundDark,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Aylık Bütçelerim'),
        backgroundColor: const Color(0xCC000000),
        border: const Border(
            bottom:
                BorderSide(color: AppColors.separator, width: 0.5)),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).push(
            CupertinoPageRoute(
                builder: (_) => const BudgetFormScreen()),
          ),
          child: const Icon(CupertinoIcons.add_circled_solid,
              color: AppColors.primaryBlue),
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            CupertinoSliverRefreshControl(
              onRefresh: () async => ref.invalidate(budgetsProvider),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(periodLabel,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => _showMonthYearPicker(
                          context, ref, selectedPeriod),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceGlass,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.glassBorder),
                        ),
                        child: const Row(
                          children: [
                            Icon(CupertinoIcons.calendar,
                                size: 14,
                                color: AppColors.primaryBlue),
                            SizedBox(width: 6),
                            Text('Değiştir',
                                style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            budgetsAsync.when(
              data: (budgets) {
                if (budgets.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: Text(
                          'Bu dönem için bütçe bulunmuyor.',
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 15)),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _BudgetCard(budget: budgets[i]),
                      ),
                      childCount: budgets.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child:
                    Center(child: CupertinoActivityIndicator()),
              ),
              error: (err, _) => SliverFillRemaining(
                child: Center(
                    child: Text('Hata: $err',
                        style: const TextStyle(
                            color: AppColors.danger))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetCard extends ConsumerWidget {
  final BudgetModel budget;
  const _BudgetCard({required this.budget});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt =
        NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    final progress =
        (budget.spentAmount / budget.limitAmount).clamp(0.0, 1.0);
    final remaining = budget.limitAmount - budget.spentAmount;

    Color progressColor;
    if (progress > 1.0) {
      progressColor = AppColors.danger;
    } else if (progress > 0.85) {
      progressColor = const Color(0xFFFF9F0A); // iOS orange
    } else {
      progressColor = AppColors.incomeGreen;
    }

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    expenseCategories[budget.category] ??
                        CupertinoIcons.square_grid_2x2_fill,
                    color: AppColors.primaryBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(budget.category,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                ],
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
                            Navigator.of(context).push(
                              CupertinoPageRoute(
                                  builder: (_) => BudgetFormScreen(
                                      budgetToEdit: budget)),
                            );
                          },
                          child: const Text('Düzenle'),
                        ),
                        CupertinoActionSheetAction(
                          isDestructiveAction: true,
                          onPressed: () async {
                            Navigator.of(context).pop();
                            final confirm =
                                await showCupertinoDialog<bool>(
                              context: context,
                              builder: (_) => CupertinoAlertDialog(
                                title: const Text('Bütçeyi Sil'),
                                content: Text(
                                    '"${budget.category}" bütçesini silmek istediğinizden emin misiniz?'),
                                actions: [
                                  CupertinoDialogAction(
                                    onPressed: () =>
                                        Navigator.of(context)
                                            .pop(false),
                                    child: const Text('İptal'),
                                  ),
                                  CupertinoDialogAction(
                                    isDestructiveAction: true,
                                    onPressed: () =>
                                        Navigator.of(context)
                                            .pop(true),
                                    child: const Text('Sil'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true &&
                                context.mounted) {
                              await ref
                                  .read(budgetActionNotifierProvider
                                      .notifier)
                                  .deleteBudget(budget.id!);
                            }
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
                      color: progressColor,
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
              Text('${fmt.format(budget.spentAmount)} harcandı',
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12)),
              Text(fmt.format(budget.limitAmount),
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12)),
            ],
          ),
          Container(
              height: 0.5,
              color: AppColors.separator,
              margin: const EdgeInsets.symmetric(vertical: 10)),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                  remaining >= 0
                      ? 'Kalan Tutar: '
                      : 'Limit Aşıldı: ',
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13)),
              Text(
                fmt.format(remaining.abs()),
                style: TextStyle(
                  color: remaining >= 0
                      ? AppColors.incomeGreen
                      : AppColors.danger,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
