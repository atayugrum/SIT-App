// File: lib/src/presentation/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// Gerekli tüm provider ve ekranlar için importlar
import '../../providers/analytics_providers.dart';
import '../../providers/transaction_providers.dart';
import '../../providers/auth_providers.dart';
import '../transactions/transactions_screen.dart';
import '../analytics/analytics_overview_screen.dart';
import '../profile/profile_screen.dart';
import '../budgets/budget_overview_screen.dart';
import '../balance/balance_overview_screen.dart';
import '../savings/savings_overview_screen.dart';
import '../investments/investment_overview_screen.dart';
import '../transactions/batch_transaction_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardInsightsAsync = ref.watch(dashboardInsightsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(dashboardInsightsProvider),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              dashboardInsightsAsync.when(
                data: (insights) {
                  // DÜZELTME: Veri modelindeki doğru alan adları kullanıldı.
                  return _buildHeaderCards(
                    context, 
                    theme, 
                    insights.incomeExpenseSummary.net, 
                    insights.savingsBalance
                  );
                },
                loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
                error: (err, stack) => const SizedBox(height: 120, child: Center(child: Text("Bakiye yüklenemedi."))),
              ),

              const SizedBox(height: 24),
              _buildSectionTitle(theme, 'Modüller'),
              const SizedBox(height: 12),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _buildModuleCard(context, theme, 'İşlemlerim', Icons.swap_horiz_rounded, Colors.blue, () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TransactionsScreen()));
                  }),
                  _buildModuleCard(context, theme, 'Hesaplarım', Icons.account_balance_wallet_outlined, Colors.green, () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BalanceOverviewScreen()));
                  }),
                  _buildModuleCard(context, theme, 'Tasarruflar', Icons.savings_outlined, Colors.orange, () {
                     Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SavingsOverviewScreen()));
                  }),
                  _buildModuleCard(context, theme, 'Bütçelerim', Icons.pie_chart_outline_rounded, Colors.red, () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BudgetOverviewScreen()));
                  }),
                  _buildModuleCard(context, theme, 'Yatırımlarım', Icons.show_chart_rounded, Colors.teal, () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const InvestmentOverviewScreen()));
                  }),
                  // EKSİK OLDUĞUNU BELİRTTİĞİNİZ KART
                  _buildModuleCard(context, theme, 'Analizler', Icons.bar_chart_rounded, Colors.purple, () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AnalyticsOverviewScreen()));
                  }),
                   _buildModuleCard(context, theme, 'AI Hızlı Giriş', Icons.auto_awesome_rounded, Colors.indigo, () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BatchTransactionScreen()));
                  }),
                   _buildModuleCard(context, theme, 'Profilim', Icons.person_outline_rounded, Colors.grey.shade600, () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
                  }),
                ],
              ),
              
              const SizedBox(height: 24),
              _buildSectionTitle(theme, 'Son İşlemler'),
              const SizedBox(height: 12),

              _buildRecentTransactionsCard(context, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCards(BuildContext context, ThemeData theme, double netBalance, double savingsBalance) {
    final numberFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BalanceOverviewScreen())),
            child: Card(
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Net Bakiye', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer)),
                    const SizedBox(height: 8),
                    Text(numberFormat.format(netBalance), style: theme.textTheme.headlineMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SavingsOverviewScreen())),
            child: Card(
              color: theme.colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kumbara', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSecondaryContainer)),
                    const SizedBox(height: 8),
                    Text(numberFormat.format(savingsBalance), style: theme.textTheme.headlineMedium?.copyWith(color: theme.colorScheme.onSecondaryContainer, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModuleCard(BuildContext context, ThemeData theme, String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildRecentTransactionsCard(BuildContext context, ThemeData theme) {
    final numberFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);
    return Consumer(
      builder: (context, ref, child) {
        final transactionsState = ref.watch(transactionsProvider);
        return Card(
          elevation: 2.0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: transactionsState.isLoading && transactionsState.transactions.isEmpty
              ? const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))
              : transactionsState.error != null
                ? Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text('Error loading transactions', style: TextStyle(color: theme.colorScheme.error))))
                : transactionsState.transactions.isEmpty
                  ? const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text("No recent transactions.")))
                  : Column(
                      children: transactionsState.transactions.take(4).map((tx) {
                        bool isIncome = tx.type == 'income';
                        return ListTile(
                          dense: true,
                          leading: Icon(isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: isIncome ? Colors.green : Colors.red, size: 24),
                          title: Text(tx.category, style: const TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Text(DateFormat.yMMMd().format(tx.date)),
                          trailing: Text(
                            '${isIncome ? '+' : '-'} ${numberFormat.format(tx.amount)}',
                            style: TextStyle(color: isIncome ? Colors.green.shade700 : theme.colorScheme.error, fontWeight: FontWeight.bold, fontSize: 15)
                          ),
                        );
                      }).toList(),
                    ),
          ),
        );
      }
    );
  }
}