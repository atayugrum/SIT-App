// File: lib/src/presentation/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_providers.dart';
import '../profile/profile_screen.dart'; 
import '../transactions/transactions_screen.dart';
import '../accounts/accounts_screen.dart'; 
import '../balance/balance_overview_screen.dart';
import '../savings/savings_overview_screen.dart';
import '../budgets/budget_overview_screen.dart'; // <-- YENİ IMPORT

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider); 
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SIT App Dashboard'),
        automaticallyImplyLeading: false, 
        actions: [
           IconButton( 
            icon: const Icon(Icons.assessment_outlined), // Bütçe için ikon
            tooltip: 'My Budgets',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const BudgetOverviewScreen()),
              );
            },
          ),
          IconButton( 
            icon: const Icon(Icons.savings_outlined), 
            tooltip: 'My Savings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SavingsOverviewScreen()),
              );
            },
          ),
          IconButton( 
            icon: const Icon(Icons.insights_rounded), 
            tooltip: 'Balance Overview',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const BalanceOverviewScreen()),
              );
            },
          ),
          IconButton( 
            icon: const Icon(Icons.list_alt_rounded),
            tooltip: 'Transactions',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const TransactionsScreen()),
              );
            },
          ),
          IconButton( 
            icon: const Icon(Icons.account_balance_wallet_outlined), 
            tooltip: 'My Accounts',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AccountsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: Padding( 
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center, 
            children: [
              Icon(Icons.home_work_outlined, size: 100, color: theme.primaryColor.withAlpha((255 * 0.7).round())),
              const SizedBox(height: 24),
              Text(
                'Welcome to SIT App!',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              if (user != null) 
                Text(
                  'Logged in as: ${user.email ?? 'No email available'}', 
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 20),
               Text(
                'Manage your finances with ease. 📊',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}