// File: lib/src/presentation/screens/analytics/analytics_overview_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../data/models/analytics_models.dart';
import '../../providers/analytics_providers.dart';
import '../../widgets/charts/emotion_spending_chart.dart';
import '../../widgets/charts/needs_vs_wants_chart.dart';

class AnalyticsOverviewScreen extends ConsumerWidget {
  const AnalyticsOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ana provider'ı dinleyerek tüm veriyi tek seferde alıyoruz.
    final dashboardInsightsAsync = ref.watch(dashboardInsightsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Analiz ve Raporlar"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(dashboardInsightsProvider),
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(dashboardInsightsProvider),
        child: dashboardInsightsAsync.when(
          data: (insights) {
            // Veri başarıyla geldiğinde tüm kartları bir ListView içinde gösteriyoruz.
            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Her bir analiz bileşeni ayrı bir "kart" widget'ı olarak çağrılıyor.
                _IncomeExpenseCard(summary: insights.incomeExpenseSummary),
                const SizedBox(height: 24),
                const NeedsVsWantsChart(),
                const SizedBox(height: 24),
                const EmotionSpendingChart(),
                const SizedBox(height: 24),
                _CategoryPieChartCard(categorySummary: insights.categorySummary),
                const SizedBox(height: 24),
                _ExpenseTrendCard(trendData: insights.expenseTrend7Days),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text("Analiz verileri yüklenemedi:\n$err"),
            ),
          ),
        ),
      ),
    );
  }
}

// --- YARDIMCI KART WIDGET'LARI ---

/// Gelir, Gider ve Net Durumu gösteren kart.
class _IncomeExpenseCard extends StatelessWidget {
  final IncomeExpenseSummary summary;
  const _IncomeExpenseCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final format = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _InfoColumn(label: 'Gelir', amount: summary.incomeTotal, color: Colors.green.shade700, format: format),
                _InfoColumn(label: 'Gider', amount: summary.expenseTotal, color: Colors.red.shade700, format: format),
              ],
            ),
            const Divider(height: 24, thickness: 1),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Net Durum:', style: theme.textTheme.titleMedium),
                Text(
                  format.format(summary.net),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: summary.net >= 0 ? Colors.green.shade800 : Colors.red.shade800,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

/// Kategoriye göre harcama dağılımını gösteren pasta grafiği kartı.
class _CategoryPieChartCard extends StatelessWidget {
  final List<CategorySpendingItem> categorySummary;
  const _CategoryPieChartCard({required this.categorySummary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final List<Color> colors = [Colors.blue, Colors.green, Colors.purple, Colors.red, Colors.teal, Colors.pinkAccent];

    double total = categorySummary.fold(0, (sum, item) => sum + item.totalAmount);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Kategoriye Göre Harcamalar", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            if (total == 0)
              const Center(child: Text("Bu dönem için harcama verisi bulunmuyor."))
            else
              AspectRatio(
                aspectRatio: 1.5,
                child: PieChart(
                  PieChartData(
                    sections: categorySummary.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final percentage = (item.totalAmount / total) * 100;
                      return PieChartSectionData(
                        color: colors[index % colors.length],
                        value: item.totalAmount,
                        title: '${percentage.toStringAsFixed(0)}%',
                        radius: 80,
                        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      );
                    }).toList(),
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16.0,
              runSpacing: 8.0,
              children: categorySummary.asMap().entries.map((entry) {
                return _Indicator(
                  color: colors[entry.key % colors.length], 
                  text: entry.value.category
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Son 7 günlük harcama trendini gösteren çizgi grafiği kartı.
class _ExpenseTrendCard extends StatelessWidget {
  final List<DailyExpensePoint> trendData;
  const _ExpenseTrendCard({required this.trendData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Son 7 Günlük Harcama Trendi", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            AspectRatio(
              aspectRatio: 1.7,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= trendData.length) return const SizedBox();
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              DateFormat.E('tr_TR').format(trendData[index].date),
                              style: theme.textTheme.bodySmall,
                            
                          ),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: trendData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.amount)).toList(),
                      isCurved: true,
                      color: theme.colorScheme.primary,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: theme.colorScheme.primary.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gelir/Gider kartı için küçük bir sütun.
class _InfoColumn extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final NumberFormat format;

  const _InfoColumn({
    required this.label,
    required this.amount,
    required this.color,
    required this.format,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        Text(
          format.format(amount),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}

/// Pasta grafiği için renk ve etiket göstergesi.
class _Indicator extends StatelessWidget {
  final Color color;
  final String text;
  const _Indicator({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 16, height: 16, color: color),
        const SizedBox(width: 4),
        Text(text, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}