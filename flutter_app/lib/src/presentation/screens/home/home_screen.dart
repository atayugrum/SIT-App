// File: lib/src/presentation/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// Gerekli tüm provider ve ekranlar için importlar
import '../../providers/analytics_v2_providers.dart';
import '../../providers/transaction_providers.dart';
import '../../providers/auth_providers.dart';
import '../../providers/profile_providers.dart';
import '../transactions/transactions_screen.dart';
import '../analytics/analytics_v2_screen.dart';
import '../profile/profile_screen.dart';
import '../budgets/budget_overview_screen.dart';
import '../balance/balance_overview_screen.dart';
import '../savings/savings_overview_screen.dart';
import '../investments/investment_overview_screen.dart';
import '../transactions/batch_transaction_screen.dart';
import '../transactions/transaction_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Renk Paleti
    final Color primaryGreen = Colors.teal.shade700;
    final Color softGreenBackground = Colors.teal.shade50.withOpacity(0.5);

    // Gerekli verileri izle
    final analyticsAsync = ref.watch(analyticsV2Provider);
    final userProfileAsync = ref.watch(userProfileProvider);

    // Kullanıcı adını al, yoksa "Kullanıcı" de
    final userName = userProfileAsync.when(
      data: (profile) => profile?.fullName.split(' ').first ?? 'Kullanıcı',
      loading: () => '...',
      error: (e, s) => 'Kullanıcı',
    );

    return Scaffold(
      backgroundColor: Colors.grey.shade100, // Ana arka planı biraz renklendir
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Hoş Geldin, $userName!',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.grey.shade700),
            tooltip: 'Çıkış Yap',
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(analyticsV2Provider);
          ref.invalidate(transactionsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          children: [
            const SizedBox(height: 10),
            // Header Kartları
            analyticsAsync.when(
              data: (v2Data) => _HeaderSection(
                totalBalance: v2Data.historical.totalFinancialBalance,
                savingsBalance: v2Data.historical.savingsBalance,
                primaryColor: primaryGreen,
                backgroundColor: softGreenBackground,
              ),
              loading: () => const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator())),
              error: (err, stack) => _ErrorCard(
                  message: "Bakiye bilgileri yüklenemedi.",
                  onRetry: () => ref.invalidate(analyticsV2Provider)),
            ),
            const SizedBox(height: 30),
            // Modüller
            _SectionTitle(title: 'Modüller'),
            const SizedBox(height: 16),
            _ModuleGrid(primaryColor: primaryGreen),
            const SizedBox(height: 30),
            // Son İşlemler
            _SectionTitle(title: 'Son İşlemler'),
            const SizedBox(height: 16),
            const _RecentTransactionsList(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// --- YARDIMCI WIDGET'LAR ---

class _HeaderSection extends StatelessWidget {
  final double totalBalance;
  final double savingsBalance;
  final Color primaryColor;
  final Color backgroundColor;

  const _HeaderSection({
    required this.totalBalance,
    required this.savingsBalance,
    required this.primaryColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildBalanceItem(
              context,
              'Toplam Varlık',
              totalBalance,
              Icons.account_balance_wallet_outlined,
              primaryColor,
            ),
            Container(
              width: 1,
              height: 60,
              color: primaryColor.withOpacity(0.2),
            ),
            _buildBalanceItem(
              context,
              'Kumbara',
              savingsBalance,
              Icons.savings_outlined,
              primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceItem(BuildContext context, String label, double amount,
      IconData icon, Color color) {
    final numberFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: color)),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          numberFormat.format(amount),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.grey.shade900, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .headlineSmall
          ?.copyWith(color: Colors.grey.shade800, fontWeight: FontWeight.bold),
    );
  }
}

class _ModuleGrid extends StatelessWidget {
  final Color primaryColor;
  const _ModuleGrid({required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      crossAxisSpacing: 12,
      mainAxisSpacing: 16,
      children: [
        _ModuleCard(
            label: 'İşlemler',
            icon: Icons.swap_horiz_rounded,
            color: primaryColor,
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TransactionsScreen()))),
        _ModuleCard(
            label: 'Hesaplar',
            icon: Icons.account_balance_wallet_outlined,
            color: primaryColor,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const BalanceOverviewScreen()))),
        _ModuleCard(
            label: 'Tasarruf',
            icon: Icons.savings_outlined,
            color: primaryColor,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const SavingsOverviewScreen()))),
        _ModuleCard(
            label: 'Bütçeler',
            icon: Icons.pie_chart_outline_rounded,
            color: primaryColor,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const BudgetOverviewScreen()))),
        _ModuleCard(
            label: 'Yatırım',
            icon: Icons.show_chart_rounded,
            color: primaryColor,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const InvestmentOverviewScreen()))),
        _ModuleCard(
            label: 'Analiz',
            icon: Icons.bar_chart_rounded,
            color: primaryColor,
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AnalyticsV2Screen()))),
        _ModuleCard(
            label: 'AI Giriş',
            icon: Icons.auto_awesome_rounded,
            color: primaryColor,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const BatchTransactionScreen()))),
        _ModuleCard(
            label: 'Profil',
            icon: Icons.person_outline_rounded,
            color: primaryColor,
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()))),
      ],
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey.shade800),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentTransactionsList extends ConsumerWidget {
  const _RecentTransactionsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsState = ref.watch(transactionsProvider);
    return transactionsState.transactions.isEmpty
        ? const Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child:
                  Center(child: Text("Başlamak için ilk işleminizi ekleyin.")),
            ),
          )
        : Column(
            children: [
              ...transactionsState.transactions
                  .take(4)
                  .map((tx) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: TransactionCard(transaction: tx),
                      ))
                  .toList(),
              const SizedBox(height: 10),
              if (transactionsState.transactions.length > 4)
                TextButton(
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const TransactionsScreen())),
                    child: const Text("Tümünü Gör →"))
            ],
          );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade700),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
            IconButton(onPressed: onRetry, icon: const Icon(Icons.refresh))
          ],
        ),
      ),
    );
  }
}
