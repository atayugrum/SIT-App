// File: lib/src/presentation/screens/savings/savings_goals_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../presentation/providers/savings_providers.dart';
import '../../../presentation/screens/savings/savings_goal_form_screen.dart';
import '../../../presentation/widgets/savings_goal_card.dart';

class SavingsGoalsScreen extends ConsumerWidget {
  const SavingsGoalsScreen({super.key});

  // DÜZELTİLMİŞ DİYALOG FONKSİYONU
  void _showAllocateDialog(BuildContext context, WidgetRef ref, String goalId, String goalTitle) {
    final amountController = TextEditingController();
    // StatefulBuilder, sadece diyalog içindeki state'i yönetmemizi sağlar.
    showDialog(
      context: context,
      barrierDismissible: false, // İşlem sırasında dışarı tıklamayı engelle
      builder: (context) {
        bool isAllocating = false; // Diyalog içindeki lokal yüklenme durumu
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('"$goalTitle" Hedefine Para Aktar'),
              content: TextField(
                controller: amountController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Aktarılacak Tutar',
                  prefixText: '₺ ',
                  enabled: !isAllocating, // İşlem sırasında giriş alanını kilitle
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isAllocating ? null : () => Navigator.of(context).pop(),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: isAllocating ? null : () async {
                    final amount = double.tryParse(amountController.text);
                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Lütfen geçerli bir tutar girin.'), backgroundColor: Colors.orange)
                      );
                      return;
                    }
                    
                    setState(() => isAllocating = true); // Yükleniyor durumunu başlat

                    try {
                      await ref.read(savingsGoalNotifierProvider.notifier).allocateToGoal(
                        goalId: goalId,
                        amount: amount,
                      );

                      if (!context.mounted) return;
                      Navigator.of(context).pop(); // Önce diyaloğu kapat
                      ScaffoldMessenger.of(context).showSnackBar( // Sonra başarı mesajını göster
                        const SnackBar(content: Text('Para hedefe başarıyla aktarıldı!'), backgroundColor: Colors.green),
                      );

                    } catch (e) {
                      if (!context.mounted) return;
                      Navigator.of(context).pop(); // Hata durumunda da diyaloğu kapat
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Hata: ${e.toString().replaceAll("Exception: ", "")}"), backgroundColor: Colors.red),
                      );
                    }
                    // setState'i tekrar çağırmaya gerek yok çünkü diyalog kapanıyor.
                  },
                  child: isAllocating 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                      : const Text('Aktar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, WidgetRef ref, String goalId, String goalTitle) {
     showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hedefi Sil'),
        content: Text('"$goalTitle" hedefini silmek istediğinize emin misiniz? Hedefe aktarılan tutar ana kumbaranıza geri dönecektir.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('İptal')),
          TextButton(
            onPressed: () async {
              try {
                await ref.read(savingsGoalNotifierProvider.notifier).deleteGoal(goalId);
                if (context.mounted) Navigator.of(context).pop();
              } catch (e) {
                 if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red));
                 }
              }
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          )
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(savingsGoalsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasarruf Hedeflerim'),
        actions: [
          IconButton(
            onPressed: () => ref.refresh(savingsGoalsProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: goalsAsync.when(
        data: (goals) {
          if (goals.isEmpty) {
            return RefreshIndicator(
                onRefresh: () async => ref.refresh(savingsGoalsProvider),
                child: ListView(children: const [Center(child: Padding(
                  padding: EdgeInsets.all(50.0),
                  child: Text('Henüz bir tasarruf hedefi oluşturmadınız.'),
                ))])
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(savingsGoalsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: goals.length,
              itemBuilder: (context, index) {
                final goal = goals[index];
                return SavingsGoalCard(
                  goal: goal,
                  onAllocate: () => _showAllocateDialog(context, ref, goal.id, goal.title),
                  onDelete: () => _showDeleteConfirmDialog(context, ref, goal.id, goal.title),
                  onEdit: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => SavingsGoalFormScreen(goalToEdit: goal)));
                  },
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Hata: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SavingsGoalFormScreen()));
        },
        child: const Icon(Icons.add),
        tooltip: 'Yeni Hedef Ekle',
      ),
    );
  }
}