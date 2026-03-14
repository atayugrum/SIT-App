// File: lib/src/presentation/screens/investments/investment_overview_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../../../core/network/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../presentation/providers/auth_providers.dart';
import '../../widgets/glass_card.dart';

final _investmentPortfolioProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final userId = ref.watch(userIdProvider);
  if (userId == null) throw Exception('Kullanıcı oturumu bulunamadı.');
  final baseUrl = ApiConstants.baseUrl;
  final url =
      Uri.parse('$baseUrl/api/investments/portfolio?userId=$userId');
  try {
    final response =
        await http.get(url).timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Portföy yüklenemedi: ${response.statusCode}');
  } on SocketException {
    throw Exception('İnternet bağlantısı yok.');
  }
});

class InvestmentOverviewScreen extends ConsumerWidget {
  const InvestmentOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolioAsync = ref.watch(_investmentPortfolioProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.backgroundDark,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Yatırımlarım'),
        backgroundColor: const Color(0xCC000000),
        border: const Border(
            bottom: BorderSide(color: AppColors.separator, width: 0.5)),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => ref.invalidate(_investmentPortfolioProvider),
          child: const Icon(CupertinoIcons.refresh,
              color: AppColors.primaryBlue, size: 20),
        ),
      ),
      child: SafeArea(
        child: portfolioAsync.when(
          data: (data) {
            final holdings =
                (data['holdings'] as List<dynamic>? ?? []);
            if (holdings.isEmpty) {
              return const Center(
                child: Text(
                  'Henüz yatırım işleminiz yok.\nYeni bir işlem ekleyin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              );
            }
            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final h =
                            holdings[i] as Map<String, dynamic>;
                        final gainLoss =
                            (h['gainLoss'] as num? ?? 0).toDouble();
                        return Padding(
                          padding:
                              const EdgeInsets.only(bottom: 12),
                          child: GlassCard(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBlue
                                        .withValues(alpha: 0.15),
                                    borderRadius:
                                        BorderRadius.circular(22),
                                  ),
                                  child: const Icon(
                                      CupertinoIcons.chart_bar_alt_fill,
                                      color: AppColors.primaryBlue,
                                      size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        h['assetSymbol']
                                                ?.toString() ??
                                            '',
                                        style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 15,
                                            fontWeight:
                                                FontWeight.w600),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Miktar: ${h['quantity']} • Maliyet: ${h['totalCost']}',
                                        style: const TextStyle(
                                            color:
                                                AppColors.textSecondary,
                                            fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  h['currentValue']?.toString() ?? '-',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: gainLoss >= 0
                                        ? AppColors.incomeGreen
                                        : AppColors.danger,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: holdings.length,
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () =>
              const Center(child: CupertinoActivityIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(CupertinoIcons.exclamationmark_circle,
                      size: 48, color: AppColors.danger),
                  const SizedBox(height: 12),
                  Text('$e',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  CupertinoButton(
                    onPressed: () =>
                        ref.invalidate(_investmentPortfolioProvider),
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
