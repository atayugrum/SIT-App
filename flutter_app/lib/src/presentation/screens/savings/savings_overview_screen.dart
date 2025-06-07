// File: lib/src/presentation/screens/savings/savings_overview_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../screens/savings/savings_goals_screen.dart';
import '../../providers/savings_providers.dart';
import '../../../data/models/savings_allocation_model.dart';
import 'manual_save_form_screen.dart';

class SavingsOverviewScreen extends ConsumerWidget {
  const SavingsOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savingsBalanceAsync = ref.watch(savingsBalanceProvider);
    final allocationsState = ref.watch(savingsAllocationsProvider);
    final allocationsNotifier = ref.read(savingsAllocationsProvider.notifier);
    final theme = Theme.of(context);
    final numberFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Savings (Kumbara)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // DÜZELTME 1: Uyarıyı gidermek için sonucu bir değişkene atıyoruz.
              final _ = ref.refresh(savingsBalanceProvider);
              allocationsNotifier.fetchAllocations();
            },
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // DÜZELTME 2: async bir fonksiyonda await ile beklemek daha doğrudur.
          final refreshedBalance = await ref.refresh(savingsBalanceProvider);
          debugPrint('Refreshed balance: $refreshedBalance');
          await allocationsNotifier.fetchAllocations();
        },
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            savingsBalanceAsync.when(
              data: (balanceModel) => Card(
                elevation: 4,
                color: Colors.blue.shade50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Savings Balance', style: theme.textTheme.titleMedium?.copyWith(color: Colors.blue.shade800)),
                      const SizedBox(height: 8),
                      Text(
                        numberFormat.format(balanceModel.balance),
                        style: theme.textTheme.displayMedium?.copyWith(
                          color: Colors.blue.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (balanceModel.updatedAt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Last updated: ${DateFormat.yMMMd().add_jm().format(balanceModel.updatedAt!.toLocal())}',
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
                        )
                      ]
                    ],
                  ),
                ),
              ),
              loading: () => const Center(child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              )),
              error: (err, stack) => Card(child: ListTile(title: Text('Error loading balance: $err', style: TextStyle(color: theme.colorScheme.error)))),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.track_changes_rounded, color: Colors.purple),
                title: const Text('Tasarruf Hedeflerim'),
                subtitle: const Text('Hedeflerinizi görüntüleyin ve yönetin'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const SavingsGoalsScreen()),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Allocations', style: theme.textTheme.headlineSmall),
              ],
            ),
            const Divider(height: 20),
            if (allocationsState.isLoading && allocationsState.allocations.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (allocationsState.error != null)
              Center(child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Error: ${allocationsState.error}', style: TextStyle(color: theme.colorScheme.error)),
              ))
            else if (allocationsState.allocations.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Text('No savings allocations found for this period.'),
              ))
            else
              ListView.builder( 
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: allocationsState.allocations.length,
                itemBuilder: (context, index) {
                  final SavingsAllocationModel allocation = allocationsState.allocations[index]; 
                  final isAuto = allocation.source == 'auto';
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isAuto ? Colors.green.shade100 : Colors.orange.shade100,
                        child: Icon(
                          isAuto ? Icons.settings_backup_restore_rounded : Icons.input_rounded,
                          color: isAuto ? Colors.green.shade700 : Colors.orange.shade700,
                        ),
                      ),
                      title: Text(isAuto ? "Automatic from Income" : "Manual Deposit"),
                      subtitle: Text('Date: ${DateFormat.yMMMd().format(allocation.date.toLocal())}'),
                      trailing: Text(
                        '+ ${numberFormat.format(allocation.amount)}',
                        style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final bool? saved = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (context) => const ManualSaveFormScreen()), 
          );
          if (saved == true && context.mounted) {
            // Bu uyarıyı da düzeltiyoruz.
            final _ = ref.refresh(savingsBalanceProvider);
            allocationsNotifier.fetchAllocations();
          }
        },
        label: const Text('Manual Save'),
        icon: const Icon(Icons.add_card_rounded),
        tooltip: 'Manually Add to Savings',
      ),
    );
  }
}