// File: lib/src/presentation/screens/transactions/transactions_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/account_providers.dart';
import '../../providers/transaction_providers.dart';
import '../../../data/models/transaction_model.dart';
import 'transaction_card.dart';
import 'transaction_flow_screen.dart';
import 'batch_transaction_screen.dart';
import 'transfer_form_screen.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsState = ref.watch(transactionsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('İşlemlerim'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          _HeaderSection(),
          const Divider(height: 1, thickness: 1),
          Expanded(
            child: transactionsState.isLoading &&
                    transactionsState.transactions.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : transactionsState.error != null
                    ? Center(
                        child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text('Hata: ${transactionsState.error}',
                                textAlign: TextAlign.center,
                                style:
                                    TextStyle(color: theme.colorScheme.error))))
                    : transactionsState.transactions.isEmpty
                        ? const Center(
                            child: Text(
                                'Seçili kriterlere uygun işlem bulunamadı.'))
                        : RefreshIndicator(
                            onRefresh: () => ref
                                .read(transactionsProvider.notifier)
                                .fetchTransactions(),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(8.0),
                              itemCount: transactionsState.transactions.length,
                              itemBuilder: (context, index) {
                                final tx =
                                    transactionsState.transactions[index];
                                return TransactionCard(
                                  transaction: tx,
                                  onTap: () => _navigateToEditTransaction(
                                      context, ref, tx),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOptions(context),
        label: const Text('Yeni İşlem Ekle'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.teal.shade700,
      ),
    );
  }

  void _navigateToEditTransaction(
      BuildContext context, WidgetRef ref, TransactionModel transaction) {
    Navigator.of(context).push<bool>(
      MaterialPageRoute(
          builder: (context) =>
              TransactionFlowScreen(transactionToEdit: transaction)),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Nasıl İşlem Eklemek İstersiniz?",
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.swap_horiz_rounded,
                    size: 30, color: Colors.blue.shade700),
                title: const Text('Hesaplar Arası Transfer'),
                subtitle: const Text('Hesaplarınız arasında para aktarın.'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const TransferFormScreen()));
                },
              ),
              const Divider(),
              ListTile(
                leading: Icon(Icons.edit_note,
                    size: 30, color: Colors.purple.shade700),
                title: const Text('Manuel Giriş'),
                subtitle: const Text('Tek bir işlemi adımlarla ekleyin.'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const TransactionFlowScreen()));
                },
              ),
              const Divider(),
              ListTile(
                leading: Icon(Icons.auto_awesome,
                    size: 30, color: Colors.orange.shade700),
                title: const Text('AI ile Hızlı Giriş'),
                subtitle:
                    const Text('Birden çok işlemi metin yazarak ekleyin.'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const BatchTransactionScreen()));
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeaderSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(transactionsProvider);
    final accounts = ref.watch(accountsProvider);
    final theme = Theme.of(context);
    final numberFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    return Container(
      padding: const EdgeInsets.all(12.0),
      color: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('Gelir', numberFormat.format(state.totalIncome),
                  Colors.green.shade700, theme),
              _buildSummaryItem(
                  'Gider',
                  numberFormat.format(state.totalExpense),
                  theme.colorScheme.error,
                  theme),
              _buildSummaryItem(
                  'Net',
                  numberFormat.format(state.totalIncome - state.totalExpense),
                  Colors.blue.shade800,
                  theme),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _DateFilterChip(),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: accounts.when(
                  data: (accList) => DropdownButtonFormField<String?>(
                    value: state.filterAccount,
                    decoration: const InputDecoration(
                        labelText: 'Hesap',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                    isExpanded: true,
                    hint: const Text("Tüm Hesaplar"),
                    items: [
                      const DropdownMenuItem<String?>(
                          value: null, child: Text("Tüm Hesaplar")),
                      ...accList.map((a) => DropdownMenuItem(
                          value: a.accountName,
                          child: Text(
                            a.accountName,
                            overflow: TextOverflow.ellipsis,
                          )))
                    ],
                    onChanged: (value) {
                      ref
                          .read(transactionsProvider.notifier)
                          .setAccountFilter(value);
                    },
                  ),
                  loading: () => const SizedBox(),
                  error: (e, s) => const Text("Hesaplar yüklenemedi"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
      String label, String value, Color color, ThemeData theme) {
    return Column(
      children: [
        Text(label,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: Colors.grey.shade700)),
        const SizedBox(height: 4),
        Text(value,
            style: theme.textTheme.titleMedium
                ?.copyWith(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _DateFilterChip extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(transactionsProvider);
    final notifier = ref.read(transactionsProvider.notifier);

    String getChipLabel() {
      final now = DateTime.now();
      final startOfThisMonth = DateTime(now.year, now.month, 1);
      if (state.startDate.year == startOfThisMonth.year &&
          state.startDate.month == startOfThisMonth.month &&
          state.startDate.day == startOfThisMonth.day) {
        return "Bu Ay";
      }
      return "${DateFormat.yMd('tr').format(state.startDate)} - ${DateFormat.yMd('tr').format(state.endDate)}";
    }

    return ActionChip(
      avatar: const Icon(Icons.calendar_today, size: 16),
      label: Text(getChipLabel()),
      onPressed: () async {
        final picked = await showDateRangePicker(
          context: context,
          initialDateRange:
              DateTimeRange(start: state.startDate, end: state.endDate),
          firstDate: DateTime(2000),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          locale: const Locale('tr', 'TR'),
        );
        if (picked != null) {
          notifier.setDateRange(picked.start, picked.end);
        }
      },
    );
  }
}
