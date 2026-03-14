// File: lib/src/presentation/widgets/cupertino_ai_insight_card.dart
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../providers/home_insight_provider.dart';

/// Ana ekranda gösterilen Gemini tabanlı AI içgörü kartı.
/// BackdropFilter + mor degrade kenarlı glassmorphism tasarım.
class CupertinoAIInsightCard extends ConsumerWidget {
  const CupertinoAIInsightCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightAsync = ref.watch(homeInsightProvider);

    return insightAsync.when(
      loading: () => const _InsightShell(child: _InsightLoading()),
      error: (e, _) => _InsightShell(
        child: _InsightError(
          message: e.toString().replaceFirst('Exception: ', ''),
          onRetry: () => ref.invalidate(homeInsightProvider),
        ),
      ),
      data: (insight) => _InsightShell(
        child: _InsightContent(insight: insight),
      ),
    );
  }
}

// ── Dış kabuk: gradient kenarlık + BackdropFilter blur ──────────────────────

class _InsightShell extends StatelessWidget {
  final Widget child;
  const _InsightShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(1.5), // kenarlık kalınlığı
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18.5),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xCC0A0A1A), // %80 opacity koyu lacivert
              borderRadius: BorderRadius.all(Radius.circular(18.5)),
            ),
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ── İçerik ──────────────────────────────────────────────────────────────────

class _InsightContent extends StatelessWidget {
  final HomeInsightModel insight;
  const _InsightContent({required this.insight});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Başlık satırı
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                CupertinoIcons.sparkles,
                color: CupertinoColors.white,
                size: 15,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'AI Finansal Analiz',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Headline
        Text(
          insight.headline,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),

        if (insight.insights.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(height: 0.5, color: AppColors.glassBorder),
          const SizedBox(height: 12),

          // Insights
          ...insight.insights.map(
            (text) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(
                      CupertinoIcons.circle_fill,
                      size: 5,
                      color: AppColors.accentViolet,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      text,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        if (insight.actions.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(height: 0.5, color: AppColors.glassBorder),
          const SizedBox(height: 12),
          const Text(
            'Aksiyon Adımları',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          ...insight.actions.asMap().entries.map(
            (entry) => _ActionRow(
              index: entry.key + 1,
              text: entry.value,
            ),
          ),
        ],
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  final int index;
  final String text;
  const _ActionRow({required this.index, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => HapticFeedback.lightImpact(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  '$index',
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Yükleniyor durumu ────────────────────────────────────────────────────────

class _InsightLoading extends StatelessWidget {
  const _InsightLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 80,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CupertinoActivityIndicator(color: AppColors.accentViolet),
            SizedBox(height: 10),
            Text(
              'AI analiz hazırlanıyor…',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hata durumu ──────────────────────────────────────────────────────────────

class _InsightError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _InsightError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(CupertinoIcons.exclamationmark_circle,
            color: AppColors.warning, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13),
          ),
        ),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: onRetry,
          child: const Icon(CupertinoIcons.refresh,
              color: AppColors.accentViolet, size: 20),
        ),
      ],
    );
  }
}
