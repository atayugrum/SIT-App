// File: flutter_app/lib/src/presentation/screens/balance/balance_overview_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; 
import '../../../data/models/account_model.dart'; // Import is now actively used by explicit types
import '../../providers/account_providers.dart';
import '../accounts/account_detail_screen.dart'; 

class BalanceOverviewScreen extends ConsumerWidget {
  const BalanceOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsyncValue = ref.watch(accountsProvider);
    final theme = Theme.of(context);
    final numberFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Balance Overview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Balances',
            onPressed: () {
              // ignore: unused_result
              ref.refresh(accountsProvider);
            },
          ),
        ],
      ),
      body: accountsAsyncValue.when(
        data: (List<AccountModel> accountsList) { // <-- EXPLICITLY TYPED accountsList
          double totalNetBalance = 0;
          Map<String, double> balancesByCurrency = {};

          for (AccountModel account in accountsList) { // <-- EXPLICITLY TYPED account (or inferred)
            totalNetBalance += account.currentBalance; 
            balancesByCurrency.update(
              account.currency.toUpperCase(),
              (value) => value + account.currentBalance,
              ifAbsent: () => account.currentBalance,
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              // ignore: unused_result
              ref.refresh(accountsProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Net Balance (Aggregated)', 
                          style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          numberFormat.format(totalNetBalance),
                          style: theme.textTheme.displayMedium?.copyWith(
                            color: totalNetBalance >= 0 ? Colors.green.shade700 : theme.colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (balancesByCurrency.keys.length > 1) ...[
                           const SizedBox(height: 10),
                           Text("Breakdown by Currency:", style: theme.textTheme.labelSmall),
                           ...balancesByCurrency.entries.map((entry) => Text(
                             "${entry.key}: ${NumberFormat.currency(symbol: '', decimalDigits: 2).format(entry.value)}", 
                             style: theme.textTheme.bodySmall,
                           )),
                        ]
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Accounts',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Divider(height: 20, thickness: 1),
                if (accountsList.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32.0),
                    child: Center(child: Text('No accounts found. Add one from the Accounts screen!')),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true, 
                    physics: const NeverScrollableScrollPhysics(), 
                    itemCount: accountsList.length,
                    itemBuilder: (context, index) {
                      final AccountModel account = accountsList[index]; // <-- EXPLICITLY TYPED account
                      IconData accountIconData = Icons.wallet_outlined; 
                      if (account.accountType.toLowerCase().contains("bank")) {
                        accountIconData = Icons.account_balance_outlined;
                      } else if (account.accountType.toLowerCase().contains("cash")) {
                        accountIconData = Icons.money_outlined;
                      } else if (account.accountType.toLowerCase().contains("card")) {
                        accountIconData = Icons.credit_card_outlined;
                      } else if (account.accountType.toLowerCase().contains("saving")) {
                        accountIconData = Icons.savings_outlined;
                      } else if (account.accountType.toLowerCase().contains("investment")) {
                        accountIconData = Icons.trending_up_outlined;
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6.0),
                        elevation: 1.5,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.secondaryContainer,
                            child: Icon(accountIconData, color: theme.colorScheme.onSecondaryContainer),
                          ),
                          title: Text(account.accountName, style: const TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Text("${account.accountType} - ${account.currency.toUpperCase()}"),
                          trailing: Text(
                            // Using currency from account model for individual balance display
                            NumberFormat.currency(symbol: account.currency.toUpperCase() == "TRY" ? "₺" : account.currency.toUpperCase() + " ", decimalDigits: 2)
                                .format(account.currentBalance),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: account.currentBalance >= 0 ? Colors.green.shade700 : theme.colorScheme.error,
                            ),
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => AccountDetailScreen(account: account),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) {
          print("BALANCE_OVERVIEW_SCREEN: Error: $err\n$stack");
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.error_outline, color: theme.colorScheme.error, size: 50),
                   const SizedBox(height: 10),
                   Text('Error loading balance overview: ${err.toString().replaceFirst("Exception: ", "")}', textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.error)),
                   const SizedBox(height:20),
                   ElevatedButton.icon(
                       icon: const Icon(Icons.refresh),
                       label: const Text("Retry"),
                       onPressed: () {
                         // ignore: unused_result
                         ref.refresh(accountsProvider);
                       }
                   )
                ],
              ),
            )
          );
        }
      ),
    );
  }
}