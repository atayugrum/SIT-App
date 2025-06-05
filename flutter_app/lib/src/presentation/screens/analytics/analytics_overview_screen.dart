// File: lib/src/presentation/screens/analytics/analytics_overview_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

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
      // categoryTrendDataProvider, analyticsDateRangeProvider'ı izlediği için otomatik refetch edecektir
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardInsightsAsync = ref.watch(dashboardInsightsProvider);
    final theme = Theme.of(context);
    final numberFormat = NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '₺',
      decimalDigits: 2,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
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
          data: (insights) => _buildDashboardContent(
              context, theme, numberFormat, insights, ref),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) {
            print("AnalyticsOverviewScreen Error (Dashboard Provider): $err\n$stack");
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
                    Text(
                      err.toString().replaceFirst("Exception: ", ""),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      onPressed: () => ref.invalidate(dashboardInsightsProvider),
                    )
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDashboardContent(
    BuildContext context,
    ThemeData theme,
    NumberFormat numberFormat,
    DashboardInsightsModel insights,
    WidgetRef ref,
  ) {
    final DateTimeRange currentCategoryTrendRange =
        ref.watch(analyticsDateRangeProvider);

    // Kategori renklerini atamak için bir yapı
    Map<String, Color> categoryColors = {};
    int colorIndex = 0;
    final defaultColors = [
      Colors.blue.shade300,
      Colors.green.shade300,
      Colors.orange.shade300,
      Colors.purple.shade300,
      Colors.red.shade300,
      Colors.teal.shade300,
      Colors.pink.shade300,
      Colors.amber.shade300,
      Colors.cyan.shade300,
      Colors.lime.shade300,
      Colors.indigo.shade300,
      Colors.brown.shade300,
      Colors.deepOrange.shade300,
      Colors.lightGreen.shade300,
      Colors.blueGrey.shade300,
    ];

    void assignColor(String category) {
      if (!categoryColors.containsKey(category)) {
        categoryColors[category] =
            defaultColors[colorIndex % defaultColors.length];
        colorIndex++;
      }
    }

    // Mevcut ayın gider kategorilerine renk ata
    insights.currentMonthExpenseByCategory
        ?.forEach((cs) => assignColor(cs.category));

    // Category Trend verisi geldiğinde yeni kategorilere renk ata
    final categoryTrendDataForColorAsync = ref.watch(categoryTrendDataProvider);
    categoryTrendDataForColorAsync.whenData((data) {
      data.data.keys.forEach(assignColor);
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: Income vs Expense & Monthly Summary
          if (insights.currentMonthIncomeExpense != null) ...[
            _buildSectionTitle(
              context,
              "Overview for ${DateFormat.yMMMM().format(DateTime(insights.currentMonthIncomeExpense!.year, insights.currentMonthIncomeExpense!.month))}",
            ),
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
                      numberFormat
                          .format(insights.currentMonthIncomeExpense!.totalIncome),
                      Colors.green.shade700,
                    ),
                    const SizedBox(height: 4),
                    _buildInfoRow(
                      context,
                      "Total Expense:",
                      numberFormat.format(
                          insights.currentMonthIncomeExpense!.totalExpense),
                      theme.colorScheme.error,
                    ),
                    const Divider(height: 20, thickness: 0.5),
                    _buildInfoRow(
                      context,
                      "Net Balance:",
                      numberFormat.format(insights.currentMonthIncomeExpense!.net),
                      insights.currentMonthIncomeExpense!.net >= 0
                          ? Colors.green.shade800
                          : theme.colorScheme.error,
                      isLarge: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Section 2: Spending Trend (Last 6 Months)
          if (insights.spendingTrend6m != null) ...[
            _buildSectionTitle(context, "Spending Trend (Last 6 Months)"),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Compared to Previous 6 Months",
                        style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      context,
                      "Last 6m Total:",
                      numberFormat.format(insights.spendingTrend6m!.lastTotal),
                      theme.colorScheme.onSurface,
                    ),
                    _buildInfoRow(
                      context,
                      "Prev 6m Total:",
                      numberFormat.format(insights.spendingTrend6m!.prevTotal),
                      theme.colorScheme.onSurfaceVariant,
                    ),
                    const Divider(height: 20, thickness: 0.5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Trend:", style: theme.textTheme.titleMedium),
                        Text(
                          insights.spendingTrend6m!.trendPercent != null
                              ? "${insights.spendingTrend6m!.trendPercent!.toStringAsFixed(2)}%"
                              : "N/A",
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: (insights.spendingTrend6m!.trendPercent ?? 0) >= 0
                                ? Colors.green.shade700
                                : theme.colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Section 3: Current Month Expense Breakdown Pie Chart & Legend
          if (insights.currentMonthExpenseByCategory != null &&
              insights.currentMonthExpenseByCategory!.isNotEmpty) ...[
            _buildSectionTitle(context, 'Current Month Expense Breakdown'),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event,
                                pieTouchResponse) {
                              // Burada touch işlemleri ekleyebilirsin
                            },
                          ),
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: insights.currentMonthExpenseByCategory!
                              .map((catSpending) {
                            final color =
                                categoryColors[catSpending.category] ??
                                    Colors.grey;
                            return PieChartSectionData(
                              color: color,
                              value: catSpending.amount,
                              title:
                                  "${catSpending.percentage?.toStringAsFixed(0) ?? ''}%",
                              radius: 60,
                              titleStyle: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(color: Colors.black, blurRadius: 2)
                                ],
                              ),
                              showTitle: (catSpending.percentage ?? 0) > 5,
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12.0,
                      runSpacing: 6.0,
                      alignment: WrapAlignment.center,
                      children: insights.currentMonthExpenseByCategory!
                          .map((catSpending) {
                        final color =
                            categoryColors[catSpending.category] ??
                                Colors.grey;
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 12, height: 12, color: color),
                            const SizedBox(width: 6),
                            Text(
                              "${catSpending.category} (${catSpending.percentage?.toStringAsFixed(1) ?? ''}%)",
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Section 4: Savings
          _buildSectionTitle(context, "Savings"),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0)),
            child: ListTile(
              leading: Icon(Icons.savings_rounded,
                  color: Colors.blue.shade700, size: 30),
              title: const Text(
                'Total Savings Balance',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              trailing: Text(
                numberFormat.format(insights.savingsBalance),
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold, color: Colors.blue.shade900),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Section 5: Last 7 Days Expense Trend
          _buildSectionTitle(context, "Last 7 Days Expense Trend"),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 16.0, 16.0, 8.0),
              child: SizedBox(
                height: 200,
                child: insights.expenseTrend7Days.isNotEmpty
                    ? LineChart(
                        _buildDailyExpenseChartData(
                            insights.expenseTrend7Days, theme, numberFormat),
                      )
                    : const Center(
                        child:
                            Text("Not enough data for 7-day trend.")),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Section 6: Category Expense Trend (with date picker)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: _buildSectionTitle(context, "Category Expense Trend")),
              TextButton.icon(
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact),
                icon: const Icon(Icons.date_range_outlined, size: 20),
                label: Text(
                  "${DateFormat.yMd().format(currentCategoryTrendRange.start)} - ${DateFormat.yMd().format(currentCategoryTrendRange.end)}",
                  style: theme.textTheme.bodySmall
                      ?.copyWith(decoration: TextDecoration.underline),
                ),
                onPressed: () =>
                    _showDateRangePickerForTrend(context, ref, currentCategoryTrendRange),
              ),
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
                  padding: const EdgeInsets.fromLTRB(8.0, 16.0, 16.0, 8.0),
                  child: SizedBox(
                    height: 250,
                    child: (catTrendData.labels.isEmpty ||
                            catTrendData.data.isEmpty)
                        ? const Center(
                            child:
                                Text("No category trend data for selected range."),
                          )
                        : LineChart(
                            _buildCategoryTrendChartData(
                                catTrendData, categoryColors, defaultColors, numberFormat),
                          ),
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

          // Section 7: Budget Feedback
          if (insights.budgetFeedback != null &&
              insights.currentMonthIncomeExpense != null) ...[
            _buildSectionTitle(
              context,
              "Budget Feedback (${DateFormat.yMMMM().format(DateTime(insights.currentMonthIncomeExpense!.year, insights.currentMonthIncomeExpense!.month))})",
            ),
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
                        _getIconForBudgetStatus(feedback.status, feedback.limit != null),
                        color: statusColor,
                        size: 28,
                      ),
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
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
          ],
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0, top: 16.0),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .headlineSmall
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    Color valueColor, {
    bool isLarge = false,
  }) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: (isLarge ? theme.textTheme.titleMedium : theme.textTheme.bodyMedium)
              ?.copyWith(color: Colors.grey.shade700),
        ),
        Text(
          value,
          style: (isLarge ? theme.textTheme.titleLarge : theme.textTheme.titleMedium)
              ?.copyWith(color: valueColor, fontWeight: FontWeight.bold),
        ),
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

  // --- GRAFİK OLUŞTURMA METOTLARI ---

  LineChartData _buildDailyExpenseChartData(
      List<DailyExpense> dailyExpenses, ThemeData theme, NumberFormat numberFormat) {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        getDrawingHorizontalLine: (value) => FlLine(
          color: theme.dividerColor.withOpacity(0.1),
          strokeWidth: 1,
        ),
        getDrawingVerticalLine: (value) => FlLine(
          color: theme.dividerColor.withOpacity(0.1),
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (double value, TitleMeta meta) {
              final index = value.toInt();
              if (index >= 0 && index < dailyExpenses.length) {
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    DateFormat.E().format(dailyExpenses[index].date),
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
            getTitlesWidget: (double value, TitleMeta meta) {
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
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: theme.dividerColor, width: 1),
      ),
      minY: 0,
      lineBarsData: [
        LineChartBarData(
          spots: dailyExpenses
              .asMap()
              .entries
              .map((e) => FlSpot(e.key.toDouble(), e.value.dailyExpense))
              .toList(),
          isCurved: true,
          color: theme.primaryColor,
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: theme.primaryColor.withOpacity(0.3),
          ),
        ),
      ],
    );
  }

  LineChartData _buildCategoryTrendChartData(
    CategoryTrendDataModel catTrendData,
    Map<String, Color> categoryColors,
    List<Color> defaultColors,
    NumberFormat numberFormat,
  ) {
    int counter = 0;
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        getDrawingHorizontalLine: (value) => FlLine(
          color: Colors.grey.shade300.withOpacity(0.5),
          strokeWidth: 0.5,
        ),
        getDrawingVerticalLine: (value) => FlLine(
          color: Colors.grey.shade300.withOpacity(0.5),
          strokeWidth: 0.5,
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (double value, TitleMeta meta) {
              final index = value.toInt();
              if (index >= 0 && index < catTrendData.labels.length) {
                final parts = catTrendData.labels[index].split('-'); // "YYYY-MM"
                final labelText = parts.length > 1 ? parts[1] : catTrendData.labels[index];
                return SideTitleWidget(
                  meta: meta,
                  child: Text(labelText, style: const TextStyle(fontSize: 10)),
                );
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 45,
            getTitlesWidget: (double value, TitleMeta meta) {
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
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(
          show: true, border: Border.all(color: Colors.grey.shade400)),
      minY: 0,
      lineBarsData: catTrendData.data.entries.map((entry) {
        final categoryName = entry.key;
        final amounts = entry.value;
        final color = categoryColors[categoryName] ??
            defaultColors[(counter++) % defaultColors.length];
        return LineChartBarData(
          spots: amounts
              .asMap()
              .entries
              .map((e) => FlSpot(e.key.toDouble(), e.value))
              .toList(),
          isCurved: true,
          color: color,
          barWidth: 2.5,
          dotData: const FlDotData(show: true, getDotPainter: _defaultDotPainter),
          isStrokeCapRound: true,
        );
      }).toList(),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((LineBarSpot spot) {
              final categoryIndex = spot.barIndex;
              final categoryName =
                  catTrendData.data.keys.elementAt(categoryIndex);
              final amount = spot.y;
              return LineTooltipItem(
                "$categoryName\n${numberFormat.format(amount)}",
                TextStyle(
                  color: spot.bar.color?.withAlpha(255) ?? Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            }).toList();
          },
        ),
        handleBuiltInTouches: true,
      ),
    );
  }
}

// Helper for dot painter
FlDotPainter _defaultDotPainter(
  FlSpot spot,
  double xPercentage,
  LineChartBarData barData,
  int index, {
  double? size,
}) {
  return FlDotCirclePainter(
    radius: 3,
    color: barData.color ?? Colors.blue,
    strokeWidth: 1,
    strokeColor: Colors.white,
  );
}
