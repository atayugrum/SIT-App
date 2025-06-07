// File: lib/src/presentation/screens/analytics/analytics_overview_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart'; // Ensure fl_chart is in pubspec.yaml

import '../../providers/analytics_providers.dart';
import '../../../data/models/analytics_models.dart';

class AnalyticsOverviewScreen extends ConsumerWidget {
  const AnalyticsOverviewScreen({super.key});

  void _showDateRangePickerForTrend(
      BuildContext context, WidgetRef ref, DateTimeRange currentRange) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: currentRange,
      helpText: 'Select Date Range for Category Trend',
    );
    if (picked != null && picked != currentRange && context.mounted) {
      ref.read(analyticsDateRangeProvider.notifier).state = picked;
      // categoryTrendDataProvider will refetch automatically
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardInsightsAsync = ref.watch(dashboardInsightsProvider);

    final theme = Theme.of(context);
    final numberFormat =
        NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Analytics Dashboard'),
            dashboardInsightsAsync.maybeWhen(
              data: (insights) => Text(
                insights.currentMonthIncomeExpense != null
                    ? "Data for: ${DateFormat.yMMMM().format(DateTime(insights.currentMonthIncomeExpense!.year, insights.currentMonthIncomeExpense!.month))}"
                    : "Current Period Data",
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onPrimary.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
              orElse: () => Text(
                "Loading Period...",
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onPrimary.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed: () {
              ref.invalidate(dashboardInsightsProvider);
              ref.invalidate(categoryTrendDataProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardInsightsProvider);
          ref.invalidate(categoryTrendDataProvider);
        },
        child: dashboardInsightsAsync.when(
          data: (insights) =>
              _buildDashboardContent(context, theme, numberFormat, insights, ref),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) {
            print(
                "AnalyticsOverviewScreen Error (Dashboard Provider): $err\n$stack");
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 60, color: theme.colorScheme.error),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading dashboard insights.',
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(color: theme.colorScheme.error),
                      ),
                      const SizedBox(height: 8),
                      Text(err.toString().replaceFirst("Exception: ", ""),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          onPressed: () =>
                              ref.invalidate(dashboardInsightsProvider))
                    ]),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context, ThemeData theme,
      NumberFormat numberFormat, DashboardInsightsModel insights, WidgetRef ref) {
    final DateTimeRange currentCategoryTrendRange =
        ref.watch(analyticsDateRangeProvider);

    Map<String, Color> categoryColors = {};
    int colorIndex = 0;
    final defaultColors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.cyan,
      Colors.lime,
      Colors.indigo,
      Colors.brown,
      Colors.deepOrange,
      Colors.lightGreen,
      Colors.blueGrey
    ];

    void assignColor(String category) {
      if (!categoryColors.containsKey(category)) {
        categoryColors[category] = defaultColors[colorIndex % defaultColors.length];
        colorIndex++;
      }
    }

    insights.currentMonthExpenseByCategory?.forEach((cs) => assignColor(cs.category));
    final categoryTrendDataForColorAsync = ref.watch(categoryTrendDataProvider);
    categoryTrendDataForColorAsync.whenData((data) {
      data.data.keys.forEach(assignColor);
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (insights.currentMonthIncomeExpense != null) ...[
            _buildSectionTitle(
                context,
                "Current Period Overview (${DateFormat.yMMMM().format(DateTime(insights.currentMonthIncomeExpense!.year, insights.currentMonthIncomeExpense!.month))})"),
            Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0)),
                child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(
                              context,
                              "Total Income:",
                              numberFormat.format(insights.currentMonthIncomeExpense!.totalIncome),
                              Colors.green.shade700),
                          const SizedBox(height: 4),
                          _buildInfoRow(
                              context,
                              "Total Expense:",
                              numberFormat.format(insights.currentMonthIncomeExpense!.totalExpense),
                              theme.colorScheme.error),
                          const Divider(height: 20, thickness: 0.5),
                          _buildInfoRow(
                              context,
                              "Net Balance:",
                              numberFormat.format(insights.currentMonthIncomeExpense!.net),
                              insights.currentMonthIncomeExpense!.net >= 0
                                  ? Colors.green.shade800
                                  : theme.colorScheme.error,
                              isLarge: true),
                          if (insights.currentMonthIncomeExpense!.topIncomeCategory !=
                              null) ...[
                            const SizedBox(height: 8),
                            Text(
                                'Top Income: ${insights.currentMonthIncomeExpense!.topIncomeCategory!.category} (${numberFormat.format(insights.currentMonthIncomeExpense!.topIncomeCategory!.amount)})',
                                style: theme.textTheme.bodySmall)
                          ],
                          if (insights.currentMonthIncomeExpense!.topExpenseCategory !=
                              null) ...[
                            const SizedBox(height: 2),
                            Text(
                                'Top Expense: ${insights.currentMonthIncomeExpense!.topExpenseCategory!.category} (${numberFormat.format(insights.currentMonthIncomeExpense!.topExpenseCategory!.amount)})',
                                style: theme.textTheme.bodySmall)
                          ],
                        ]))),
            const SizedBox(height: 20),
          ],

          if (insights.currentMonthExpenseByCategory != null &&
              insights.currentMonthExpenseByCategory!.isNotEmpty) ...[
            _buildSectionTitle(
                context, 'Current Period Expense Breakdown'),
            Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0)),
                child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(children: [
                      SizedBox(
                          height: 200,
                          child: PieChart(PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 40,
                              sections: insights.currentMonthExpenseByCategory!
                                  .map((catSpending) {
                                final color = categoryColors[catSpending.category] ?? Colors.grey;
                                return PieChartSectionData(
                                    color: color,
                                    value: catSpending.amount,
                                    title:
                                        '${catSpending.percentage?.toStringAsFixed(0) ?? ''}%',
                                    radius: 60,
                                    titleStyle: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        shadows: [
                                          Shadow(color: Colors.black, blurRadius: 2)
                                        ]),
                                    showTitle: (catSpending.percentage ?? 0) > 5);
                              }).toList()))),
                      const SizedBox(height: 16),
                      Wrap(
                          spacing: 12.0,
                          runSpacing: 6.0,
                          alignment: WrapAlignment.center,
                          children: insights.currentMonthExpenseByCategory!
                              .map((catSpending) {
                            final color = categoryColors[catSpending.category] ?? Colors.grey;
                            return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(width: 12, height: 12, color: color),
                                  const SizedBox(width: 6),
                                  Text(catSpending.category,
                                      style: theme.textTheme.bodySmall)
                                ]);
                          }).toList())
                    ]))),
            const SizedBox(height: 20),
          ],

          _buildSectionTitle(context, "Savings"),
          Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0)),
              child: ListTile(
                  leading: Icon(Icons.savings_rounded,
                      color: Colors.blue.shade700, size: 30),
                  title: const Text('Total Savings Balance',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  trailing: Text(numberFormat.format(insights.savingsBalance),
                      style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900)))),
          const SizedBox(height: 24),

          _buildSectionTitle(context, "Last 7 Days Expense Trend"),
          Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0)),
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                  child: SizedBox(
                      height: 200,
                      child: insights.expenseTrend7Days.isNotEmpty
                          ? LineChart(LineChartData(
                              gridData: const FlGridData(show: true),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 30,
                                    interval: 1,
                                    getTitlesWidget:
                                        (double value, TitleMeta meta) {
                                      final index = value.toInt();
                                      if (index >= 0 &&
                                          index < insights.expenseTrend7Days.length) {
                                        return SideTitleWidget(
                                          meta: meta,
                                          child: Text(
                                            DateFormat.E().format(insights.expenseTrend7Days[index].date),
                                            style: const TextStyle(fontSize: 10),
                                          ),
                                        );
                                      }
                                      return const Text('');
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    getTitlesWidget: (value, meta) {
                                      return SideTitleWidget(
                                        meta: meta,
                                        child: Text(
                                          value.toInt().toString(),
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                topTitles:
                                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles:
                                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              borderData: FlBorderData(
                                  show: true,
                                  border: Border.all(color: Colors.grey.shade300)),
                              minY: 0,
                              lineBarsData: [
                                LineChartBarData(
                                  spots: insights.expenseTrend7Days
                                      .asMap()
                                      .entries
                                      .map((e) =>
                                          FlSpot(e.key.toDouble(), e.value.dailyExpense))
                                      .toList(),
                                  isCurved: true,
                                  color: theme.primaryColor,
                                  barWidth: 3,
                                  isStrokeCapRound: true,
                                  dotData: const FlDotData(show: false),
                                  belowBarData: BarAreaData(
                                      show: true,
                                      color: theme.primaryColor.withOpacity(0.2)),
                                ),
                              ],
                            ))
                          : const Center(
                              child: Text("Not enough data for 7-day trend."),
                            )))),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: _buildSectionTitle(context, "Category Expense Trend")),
              TextButton.icon(
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                icon: const Icon(Icons.date_range_outlined, size: 20),
                label: Text(
                    "${DateFormat.yMd().format(currentCategoryTrendRange.start)} - ${DateFormat.yMd().format(currentCategoryTrendRange.end)}",
                    style: theme.textTheme.bodySmall
                        ?.copyWith(decoration: TextDecoration.underline)),
                onPressed: () => _showDateRangePickerForTrend(
                    context, ref, currentCategoryTrendRange),
              )
            ],
          ),
          const SizedBox(height: 8),
          Consumer(builder: (context, ref, _) {
            final categoryTrendAsync = ref.watch(categoryTrendDataProvider);
            return categoryTrendAsync.when(
              data: (catTrendData) => Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0)),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                  child: SizedBox(
                    height: 250,
                    child: (catTrendData.labels.isEmpty ||
                            catTrendData.data.isEmpty)
                        ? const Center(
                            child:
                                Text("No category trend data for selected range."),
                          )
                        : LineChart(LineChartData(
                            gridData: const FlGridData(show: true),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 30,
                                  interval: 1,
                                  getTitlesWidget:
                                      (double value, TitleMeta meta) {
                                    final index = value.toInt();
                                    if (index >= 0 &&
                                        index < catTrendData.labels.length) {
                                      final parts =
                                          catTrendData.labels[index].split('-');
                                      return SideTitleWidget(
                                        meta: meta,
                                        child: Text(
                                          parts.length > 1
                                              ? parts[1]
                                              : catTrendData.labels[index],
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      );
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  getTitlesWidget:
                                      (double value, TitleMeta meta) {
                                    return SideTitleWidget(
                                      meta: meta,
                                      child: Text(
                                        value.toInt().toString(),
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(
                                show: true,
                                border: Border.all(color: Colors.grey.shade300)),
                            minY: 0,
                            lineBarsData: catTrendData.data.entries.map((entry) {
                              final categoryName = entry.key;
                              final amounts = entry.value;
                              final color = categoryColors[categoryName] ??
                                  defaultColors[catTrendData.data.keys
                                          .toList()
                                          .indexOf(categoryName) %
                                      defaultColors.length];
                              return LineChartBarData(
                                spots: amounts
                                    .asMap()
                                    .entries
                                    .map((e) =>
                                        FlSpot(e.key.toDouble(), e.value))
                                    .toList(),
                                isCurved: true,
                                color: color,
                                barWidth: 2,
                                dotData: const FlDotData(show: false),
                              );
                            }).toList(),
                            lineTouchData: LineTouchData(
                              touchTooltipData: LineTouchTooltipData(
                                getTooltipItems: (touchedSpots) {
                                  return touchedSpots.map((LineBarSpot spot) {
                                    final categoryIndex = spot.barIndex;
                                    final categoryName =
                                        catTrendData.data.keys
                                            .elementAt(categoryIndex);
                                    final amount = spot.y;
                                    return LineTooltipItem(
                                        '$categoryName: ${numberFormat.format(amount)}',
                                        TextStyle(
                                            color:
                                                spot.bar.color ?? Colors.blue,
                                            fontWeight: FontWeight.bold));
                                  }).toList();
                                },
                              ),
                            ))),
                  ),
                ),
              ),
              loading: () => const SizedBox(
                  height: 250,
                  child: Center(child: CircularProgressIndicator())),
              error: (e, s) => SizedBox(
                height: 100,
                child: Center(
                  child: Text(
                    "Error loading category trend: ${e.toString().replaceFirst("Exception: ", "")}",
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 24),

          if (insights.budgetFeedback != null && insights.currentMonthIncomeExpense != null) ...[
            _buildSectionTitle(
                context,
                "Budget Feedback (${DateFormat.yMMMM().format(DateTime(insights.currentMonthIncomeExpense!.year, insights.currentMonthIncomeExpense!.month))})"),
            if (insights.budgetFeedback!.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                child: Text(
                  "No budgets set for this month or no spending in budgeted categories yet.",
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: insights.budgetFeedback!.length,
                itemBuilder: (context, index) {
                  final feedback = insights.budgetFeedback![index];
                  Color statusColor = Colors.grey.shade600;
                  String statusText = "No Budget Set";
                  String detailText = "";
                  if (feedback.limit != null) {
                    statusText =
                        "Within Limit (${feedback.usedPct?.toStringAsFixed(0)}% used)";
                    statusColor = Colors.green.shade700;
                    detailText =
                        "Limit: ${numberFormat.format(feedback.limit)}\nSpent: ${numberFormat.format(feedback.spent)}";
                    if (feedback.status == "exceeded") {
                      statusColor = theme.colorScheme.error;
                      statusText =
                          "Exceeded by ${numberFormat.format(feedback.excessAmount)} (${feedback.excessPct?.toStringAsFixed(0)}%)";
                    } else if (feedback.status == "near_limit") {
                      statusColor = Colors.orange.shade800;
                      statusText =
                          "Near Limit (${feedback.usedPct?.toStringAsFixed(0)}% used)";
                    }
                  } else if (feedback.spent > 0) {
                    statusText = "Spent: ${numberFormat.format(feedback.spent)}";
                    detailText = "No budget set for this category.";
                  } else {
                    return const SizedBox.shrink();
                  }

                  return Card(
                    color: statusColor.withOpacity(0.08),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: Icon(
                          _getIconForBudgetStatus(
                              feedback.status, feedback.limit != null),
                          color: statusColor,
                          size: 28),
                      title: Text(
                        feedback.category,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(detailText),
                      trailing: Text(
                        statusText,
                        style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11),
                        textAlign: TextAlign.right,
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              )
          ],
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0, top: 16.0),
      child: Text(title,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value,
      Color valueColor,
      {bool isLarge = false}) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: (isLarge
                    ? theme.textTheme.titleMedium
                    : theme.textTheme.bodyMedium)
                ?.copyWith(color: Colors.grey.shade700)),
        Text(value,
            style: (isLarge
                    ? theme.textTheme.titleLarge
                    : theme.textTheme.titleMedium)
                ?.copyWith(color: valueColor, fontWeight: FontWeight.bold)),
      ],
    );
  }

  IconData _getIconForBudgetStatus(String status, bool hasLimit) {
    if (!hasLimit && status != "no_budget_set") return Icons.help_outline_rounded;
    if (status == "no_budget_set" && !hasLimit) return Icons.label_off_outlined;

    switch (status) {
      case 'exceeded':
        return Icons.error_rounded;
      case 'near_limit':
        return Icons.warning_amber_rounded;
      case 'within_limit':
        return Icons.check_circle_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }
}
