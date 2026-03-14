// File: lib/src/presentation/screens/profile/finance_test_intro_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../../../core/network/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_providers.dart';
import '../../providers/profile_providers.dart';
import '../../widgets/glass_card.dart';

class FinanceTestIntroScreen extends ConsumerWidget {
  const FinanceTestIntroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.backgroundDark,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Finansal Risk Testi'),
        backgroundColor: Color(0xCC000000),
        border: Border(
            bottom: BorderSide(color: AppColors.separator, width: 0.5)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(CupertinoIcons.question_circle_fill,
                  size: 72, color: AppColors.primaryBlue),
              const SizedBox(height: 24),
              const Text(
                'Risk Profili Testi',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Bu test, finansal risk toleransınızı belirlemek için tasarlanmıştır. '
                'Sonuçlar, size özel yatırım önerileri sunmak için kullanılacaktır.',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              CupertinoButton.filled(
                borderRadius: BorderRadius.circular(12),
                onPressed: () => Navigator.of(context).push(
                  CupertinoPageRoute(
                      builder: (_) => const _FinanceTestScreen()),
                ),
                child: const Text('Teste Başla'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FinanceTestScreen extends ConsumerStatefulWidget {
  const _FinanceTestScreen();

  @override
  ConsumerState<_FinanceTestScreen> createState() =>
      _FinanceTestScreenState();
}

class _FinanceTestScreenState extends ConsumerState<_FinanceTestScreen> {
  String get _baseUrl => ApiConstants.baseUrl;
  List<Map<String, dynamic>> _questions = [];
  final Map<String, int> _answers = {};
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _testId;

  @override
  void initState() {
    super.initState();
    _loadTest();
  }

  Future<void> _loadTest() async {
    final userId = ref.read(userIdProvider);
    if (userId == null) return;
    try {
      final itemsRes =
          await http.get(Uri.parse('$_baseUrl/api/finance-tests/items'));
      if (itemsRes.statusCode == 200) {
        final data = jsonDecode(itemsRes.body);
        setState(() {
          _questions =
              List<Map<String, dynamic>>.from(data['items'] ?? []);
        });
      }
      final testRes = await http.post(
        Uri.parse('$_baseUrl/api/finance-tests'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId}),
      );
      if (testRes.statusCode == 201) {
        final data = jsonDecode(testRes.body);
        _testId = data['testId'] as String?;
      }
    } on SocketException {
      // handled by loading state
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    if (_testId == null) return;
    final userId = ref.read(userIdProvider);
    final navigator = Navigator.of(context);
    setState(() => _isSubmitting = true);
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/finance-tests/$_testId/answers'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'answers': _answers,
          'isComplete': true,
        }),
      );
      if (res.statusCode == 200) {
        ref.invalidate(userProfileProvider);
        navigator.pop();
        navigator.pop();
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const CupertinoPageScaffold(
        backgroundColor: AppColors.backgroundDark,
        child: Center(child: CupertinoActivityIndicator()),
      );
    }
    if (_questions.isEmpty) {
      return const CupertinoPageScaffold(
        backgroundColor: AppColors.backgroundDark,
        navigationBar: CupertinoNavigationBar(
          middle: Text('Risk Testi'),
          backgroundColor: Color(0xCC000000),
        ),
        child: SafeArea(
          child: Center(
            child: Text('Sorular yüklenemedi.',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
        ),
      );
    }

    return CupertinoPageScaffold(
      backgroundColor: AppColors.backgroundDark,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Risk Testi'),
        backgroundColor: Color(0xCC000000),
        border: Border(
            bottom: BorderSide(color: AppColors.separator, width: 0.5)),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ..._questions.asMap().entries.map((entry) {
              final q = entry.value;
              final qId =
                  q['id'] as String? ?? entry.key.toString();
              final options = List<Map<String, dynamic>>.from(
                  q['options'] ?? []);
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(q['question'] as String? ?? '',
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 15)),
                      const SizedBox(height: 12),
                      ...options.map((opt) {
                        final value = opt['value'] as int? ?? 0;
                        final selected = _answers[qId] == value;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _answers[qId] = value),
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: selected
                                          ? AppColors.primaryBlue
                                          : AppColors.glassBorder,
                                      width: 2,
                                    ),
                                    color: selected
                                        ? AppColors.primaryBlue
                                        : null,
                                  ),
                                  child: selected
                                      ? const Icon(
                                          CupertinoIcons.checkmark,
                                          size: 12,
                                          color: CupertinoColors.white)
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    opt['text'] as String? ?? '',
                                    style: TextStyle(
                                      color: selected
                                          ? AppColors.textPrimary
                                          : AppColors.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            CupertinoButton.filled(
              borderRadius: BorderRadius.circular(12),
              onPressed: (_isSubmitting ||
                      _answers.length < _questions.length)
                  ? null
                  : _submit,
              child: _isSubmitting
                  ? const CupertinoActivityIndicator(
                      color: CupertinoColors.white)
                  : const Text('Testi Tamamla'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
