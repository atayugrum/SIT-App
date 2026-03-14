// File: lib/src/presentation/screens/home/home_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/analytics_v2_providers.dart';
import '../../providers/transaction_providers.dart';
import '../../providers/auth_providers.dart';
import '../../providers/profile_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../transactions/transactions_screen.dart';
import '../savings/savings_overview_screen.dart';
import '../balance/balance_overview_screen.dart';
import '../investments/investment_overview_screen.dart';
import '../transactions/batch_transaction_screen.dart';
import '../transactions/transaction_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync   = ref.watch(analyticsV2Provider);
    final userProfileAsync = ref.watch(userProfileProvider);

    final userName = userProfileAsync.when(
      data: (p) => p?.fullName.split(' ').first ?? 'Kullanıcı',
      loading: () => '...',
      error: (_, __) => 'Kullanıcı',
    );

    return CupertinoPageScaffold(
      backgroundColor: AppColors.backgroundDark,
      child: CustomScrollView(
        slivers: [
          // ── Large Title Nav Bar ──────────────────────────────────────────────
          CupertinoSliverNavigationBar(
            largeTitle: Text('Merhaba, $userName'),
            backgroundColor: const Color(0xCC000000),
            border: const Border(
              bottom: BorderSide(color: AppColors.separator, width: 0.5),
            ),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => ref.read(authServiceProvider).signOut(),
              child: const Icon(
                CupertinoIcons.square_arrow_right,
                color: AppColors.textSecondary,
              ),
            ),
          ),

          // ── Pull-to-refresh ──────────────────────────────────────────────────
          CupertinoSliverRefreshControl(
            onRefresh: () async {
              ref.invalidate(analyticsV2Provider);
              ref.invalidate(transactionsProvider);
            },
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Bakiye Glassmorphism Kartı ──────────────────────────────
                analyticsAsync.when(
                  data: (v2) => _BalanceGlassCard(
                    totalBalance: v2.historical.totalFinancialBalance,
                    savingsBalance: v2.historical.savingsBalance,
                  ),
                  loading: () => const _LoadingCard(height: 140),
                  error: (e, _) => _ErrorCard(
                    message: 'Bakiye bilgileri yüklenemedi.',
                    onRetry: () => ref.invalidate(analyticsV2Provider),
                  ),
                ),
                const SizedBox(height: 28),

                // ── Hızlı Erişim Modül Izgara ───────────────────────────────
                const _SectionTitle(title: 'Hızlı Erişim'),
                const SizedBox(height: 14),
                const _QuickAccessGrid(),
                const SizedBox(height: 28),

                // ── Son İşlemler ─────────────────────────────────────────────
                const _SectionTitle(title: 'Son İşlemler'),
                const SizedBox(height: 14),
                const _RecentTransactionsList(),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bakiye Kartı ──────────────────────────────────────────────────────────────

class _BalanceGlassCard extends StatelessWidget {
  final double totalBalance;
  final double savingsBalance;

  const _BalanceGlassCard({
    required this.totalBalance,
    required this.savingsBalance,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TOPLAM VARLIK',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            fmt.format(totalBalance),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 36,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          Container(height: 0.5, color: AppColors.glassBorder),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(CupertinoIcons.money_dollar_circle,
                  color: AppColors.success, size: 16),
              const SizedBox(width: 6),
              const Text(
                'Kumbara',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const Spacer(),
              Text(
                fmt.format(savingsBalance),
                style: const TextStyle(
                  color: AppColors.success,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Hızlı Erişim Izgara ───────────────────────────────────────────────────────

class _QuickAccessGrid extends StatelessWidget {
  const _QuickAccessGrid();

  @override
  Widget build(BuildContext context) {
    final items = [
      _GridItem(
        label: 'Hesaplar',
        icon: CupertinoIcons.creditcard_fill,
        color: AppColors.primaryBlue,
        onTap: () => _push(context, const BalanceOverviewScreen()),
      ),
      _GridItem(
        label: 'Tasarruf',
        icon: CupertinoIcons.money_dollar_circle_fill,
        color: AppColors.success,
        onTap: () => _push(context, const SavingsOverviewScreen()),
      ),
      _GridItem(
        label: 'Yatırım',
        icon: CupertinoIcons.chart_bar_fill,
        color: AppColors.accentIndigo,
        onTap: () => _push(context, const InvestmentOverviewScreen()),
      ),
      _GridItem(
        label: 'AI Giriş',
        icon: CupertinoIcons.sparkles,
        color: AppColors.accentViolet,
        onTap: () => _push(context, const BatchTransactionScreen()),
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.85,
      children: items,
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      CupertinoPageRoute(builder: (_) => screen),
    );
  }
}

class _GridItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _GridItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Son İşlemler ──────────────────────────────────────────────────────────────

class _RecentTransactionsList extends ConsumerWidget {
  const _RecentTransactionsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txState = ref.watch(transactionsProvider);

    if (txState.transactions.isEmpty) {
      return const GlassCard(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Başlamak için ilk işleminizi ekleyin.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        ...txState.transactions
            .take(4)
            .map((tx) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TransactionCard(transaction: tx),
                )),
        if (txState.transactions.length > 4)
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.of(context).push(
              CupertinoPageRoute(builder: (_) => const TransactionsScreen()),
            ),
            child: const Text(
              'Tümünü Gör →',
              style: TextStyle(color: AppColors.primaryBlue, fontSize: 15),
            ),
          ),
      ],
    );
  }
}

// ── Yardımcılar ───────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  final double height;
  const _LoadingCard({required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: const GlassCard(
        child: Center(child: CupertinoActivityIndicator()),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      fillColor: const Color(0x1AFF453A),
      child: Row(
        children: [
          const Icon(CupertinoIcons.exclamationmark_circle, color: AppColors.danger, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onRetry,
            child: const Icon(CupertinoIcons.refresh, color: AppColors.primaryBlue, size: 20),
          ),
        ],
      ),
    );
  }
}
