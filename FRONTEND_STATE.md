# SIT App — Flutter Frontend State Management

## Library: Flutter Riverpod 2.x

The app uses **Riverpod** exclusively. The entire widget tree is wrapped in a `ProviderScope` in `main.dart`. There is no BLoC, GetX, or classic `ChangeNotifier`/`Provider` package usage.

All provider files live in `lib/src/presentation/providers/`.

---

## Riverpod Patterns in Use

| Pattern | Used For |
|---------|---------|
| `StateNotifierProvider` | Complex mutable state: lists with CRUD, batch operations, form state |
| `FutureProvider.autoDispose` | Single async fetch; auto-disposes and re-fetches on re-enter |
| `FutureProvider.autoDispose.family` | Parameterized async fetch (e.g., per account ID, per category) |
| `StreamProvider` | Firebase Auth state stream (login/logout detection) |
| `StateProvider` | Simple single-value state (e.g., selected month for budgets) |
| `Provider` | Derived/computed values from other providers; service singletons |

---

## Auth Providers — `auth_providers.dart`

| Provider | Type | Purpose |
|----------|------|---------|
| `firebaseAuthProvider` | `Provider<FirebaseAuth>` | Singleton FirebaseAuth instance |
| `authServiceProvider` | `Provider<AuthService>` | Singleton AuthService |
| `authStateChangesProvider` | `StreamProvider<User?>` | Streams Firebase auth state changes |
| `currentUserProvider` | `Provider<User?>` | Synchronous snapshot of the current user |
| `userIdProvider` | `Provider<String?>` | Extracts `uid` from `currentUserProvider` |

**Auth flow:** `AuthWrapper` watches `authStateChangesProvider`.
- `User?` is non-null → navigate to `HomeScreen`
- `User?` is null → show `LoginScreen`

---

## Account Providers — `account_providers.dart`

| Provider | Type | State Shape |
|----------|------|------------|
| `accountServiceProvider` | `Provider<AccountFlutterService>` | Service singleton |
| `accountsProvider` | `StateNotifierProvider<AccountsNotifier, AsyncValue<List<AccountModel>>>` | Loading / error / list |

### `AccountsNotifier` — Methods

| Method | API Call | Local State Update |
|--------|----------|--------------------|
| `fetchAccounts()` | `GET /api/accounts` | Replaces full list |
| `createAccount(Map data)` | `POST /api/accounts` | Appends new item |
| `updateAccount(String id, Map data)` | `PUT /api/accounts/{id}` | Replaces item in list |
| `archiveAccount(String id)` | `POST /api/accounts/{id}/archive` | Removes item from list |

---

## Transaction Providers — `transaction_providers.dart`

| Provider | Type | State Shape |
|----------|------|------------|
| `transactionServiceProvider` | `Provider<TransactionFlutterService>` | Depends on `userIdProvider` |
| `transactionsProvider` | `StateNotifierProvider<TransactionsNotifier, TransactionsState>` | Complex state (see below) |
| `accountTransactionsProvider` | `FutureProvider.autoDispose.family<List<TransactionModel>, String>` | Per-account (last 3 months) |
| `transactionActionProvider` | `StateNotifierProvider` | Transfer creation + cross-provider invalidation |

### `TransactionsState` Fields

```dart
bool isLoading
String? error
List<TransactionModel> transactions
DateTime startDate
DateTime endDate
String? filterType        // 'income' | 'expense' | null
String? filterAccount     // account name string | null
double totalIncome
double totalExpense
```

### `TransactionsNotifier` — Methods

| Method | Description |
|--------|-------------|
| `fetchTransactions()` | Applies current date, type, and account filters → `GET /api/transactions` |
| `setQuickDateRange(QuickDateRange)` | thisMonth / lastMonth / last3Months / last6Months / allTime → auto-fetches |
| `setDateRange(DateTime, DateTime)` | Custom range → auto-fetches |
| `setFilterType(String?)` | income / expense / null → auto-fetches |
| `setAccountFilter(String?)` | filter by account name → auto-fetches |
| `addTransaction(TransactionModel)` | `POST` + prepend to list + **invalidates** `accountsProvider` + `dashboardInsightsProvider` |
| `updateTransactionInList(String, TransactionModel)` | `PUT` + replaces item in list |
| `deleteTransactionFromList(String)` | `DELETE` + removes item from list |

---

## Budget Providers — `budget_providers.dart`

| Provider | Type | State Shape |
|----------|------|------------|
| `budgetServiceProvider` | `Provider<BudgetFlutterService>` | Service singleton |
| `budgetPeriodProvider` | `StateProvider<DateTime>` | Currently selected month (defaults to now) |
| `budgetsProvider` | `FutureProvider.autoDispose<List<BudgetModel>>` | Depends on `budgetPeriodProvider` |
| `budgetActionProvider` | `StateNotifierProvider<BudgetActionNotifier, AsyncValue<void>>` | Mutation loading/error state |

### `BudgetActionNotifier` — Methods

| Method | Description |
|--------|-------------|
| `createOrUpdateBudget(BudgetModel)` | `POST /api/budgets` → invalidates `budgetsProvider` |
| `deleteBudget(String id)` | `DELETE /api/budgets/{id}` → invalidates `budgetsProvider` |

---

## Savings Providers — `savings_providers.dart`

| Provider | Type | State Shape |
|----------|------|------------|
| `savingsFlutterServiceProvider` | `Provider<SavingsFlutterService>` | Service singleton |
| `savingsBalanceProvider` | `FutureProvider.autoDispose<SavingsBalanceModel>` | Current balance |
| `savingsAllocationsProvider` | `StateNotifierProvider<SavingsAllocationsNotifier, SavingsAllocationsState>` | List + date/source filters |
| `savingsGoalsProvider` | `FutureProvider.autoDispose<List<SavingsGoalModel>>` | All goals |
| `savingsGoalNotifierProvider` | `StateNotifierProvider<SavingsGoalNotifier, AsyncValue<void>>` | Goal mutation state |

### `SavingsAllocationsState` Fields

```dart
bool isLoading
String? error
List<SavingsAllocationModel> allocations
DateTime startDate
DateTime endDate
String? filterSource   // 'auto' | 'manual' | null
```

### `SavingsAllocationsNotifier` — Methods

| Method | Description |
|--------|-------------|
| `fetchAllocations()` | `GET /api/savings/allocations` with current filters |
| `addManualSaving(double amount, DateTime date)` | `POST /api/savings/allocations` + re-fetches |
| `setDateRange(DateTime, DateTime)` | Updates filter → auto-fetches |
| `setFilterSource(String?)` | 'auto' / 'manual' / null → auto-fetches |

### `SavingsGoalNotifier` — Methods

| Method | Description |
|--------|-------------|
| `createGoal(String title, double target, DateTime deadline)` | `POST /api/savings/goals` → invalidates `savingsGoalsProvider` |
| `deleteGoal(String id)` | `DELETE /api/savings/goals/{id}` → invalidates `savingsGoalsProvider` |
| `allocateToGoal(String id, double amount)` | `POST /api/savings/goals/{id}/allocate` → invalidates goals + balance |

---

## Category Providers — `category_providers.dart`

| Provider | Type | State Shape |
|----------|------|------------|
| `categoryFlutterServiceProvider` | `Provider<CategoryFlutterService>` | Service singleton |
| `allCustomCategoriesProvider` | `StateNotifierProvider<CustomCategoriesNotifier, AsyncValue<List<UserCategoryModel>>>` | All types |
| `incomeCustomCategoriesProvider` | `StateNotifierProvider` | Income-filtered view |
| `expenseCustomCategoriesProvider` | `StateNotifierProvider` | Expense-filtered view |

### `CustomCategoriesNotifier` — Methods

| Method | Description |
|--------|-------------|
| `fetchCustomCategories()` | `GET /api/categories` (with optional type filter) |
| `addCategory(UserCategoryModel)` | `POST /api/categories` → appends to list |
| `updateCustomCategory(UserCategoryModel)` | `PUT /api/categories/{id}` → replaces in list |
| `deleteCustomCategory(String id)` | `DELETE /api/categories/{id}` → removes from list |

---

## Profile Providers — `profile_providers.dart`

| Provider | Type | State Shape |
|----------|------|------------|
| `profileServiceProvider` | `Provider<ProfileService>` | Service singleton |
| `userProfileProvider` | `FutureProvider.autoDispose<UserProfile?>` | User profile from Flask API |

Fetches from `GET /api/users/{uid}/profile`. The service adds a cache-busting timestamp query param on each call.

---

## Analytics Providers — `analytics_providers.dart`

| Provider | Type | State Shape |
|----------|------|------------|
| `analyticsServiceProvider` | `Provider<AnalyticsFlutterService>` | Service singleton |
| `dashboardInsightsProvider` | `FutureProvider.autoDispose<DashboardInsightsModel>` | Full dashboard data bundle |
| `incomeExpenseSummaryProvider` | `Provider` (derived) | Extracted from `dashboardInsightsProvider` |
| `needsVsWantsProvider` | `Provider` (derived) | Extracted from `dashboardInsightsProvider` |
| `emotionSummaryProvider` | `Provider` (derived) | Extracted from `dashboardInsightsProvider` |
| `aiProjectionsProvider` | `FutureProvider.autoDispose<AIProjectionsModel>` | Gemini AI forecast data |

---

## AI Providers — `ai_providers.dart`

| Provider | Type | State Shape |
|----------|------|------------|
| `aiFlutterServiceProvider` | `Provider<AIFlutterService>` | Service singleton |
| `budgetSuggestionProvider` | `FutureProvider.autoDispose.family<BudgetSuggestion, String>` | Per category name |
| `batchTransactionProvider` | `StateNotifierProvider<BatchTransactionNotifier, BatchTransactionState>` | Parse + save state |

### `BatchTransactionState` Fields

```dart
bool isLoading
String? error
List<ParsedTransactionModel> parsedItems
```

### `BatchTransactionNotifier` — Methods

| Method | Description |
|--------|-------------|
| `parseText(String text)` | `POST /api/ai/parse-transactions` → populates `parsedItems` |
| `updateItem(int index, Map updates)` | Edits a parsed item locally before saving |
| `setGlobalAccount(String accountName)` | Sets account on all parsed items at once |
| `saveAllTransactions()` | Calls `createTransaction()` for each item in `parsedItems` |
| `clear()` | Resets state back to initial empty state |

---

## Transaction Form Provider — `transaction_form_provider.dart`

A dedicated form state manager used exclusively in `TransactionFlowScreen`. Manages all field values for a single transaction being created or edited.

### `TransactionFormData` Fields

```dart
String? id
String type               // 'income' | 'expense'
String? category
String? subCategory
double? amount
DateTime date
String? account
String? description
int? incomeAllocationPct  // income only (0-100)
bool isRecurring
String? recurrenceRule
bool? isNeed              // expense only
String? emotion           // expense only
DateTime? originalCreatedAt
```

### `TransactionFormNotifier` — Methods

| Method | Description |
|--------|-------------|
| `updateType(String)` | Changes type, resets conditional fields (isNeed, emotion, incomeAllocationPct) |
| `updateCategory(String?)` | Sets category |
| `updateSubCategory(String?)` | Sets sub-category |
| `updateAmount(double?)` | Sets amount |
| `updateDate(DateTime)` | Sets date |
| `updateDescription(String?)` | Sets description |
| `updateAccount(String?)` | Sets account name |
| `updateIsRecurring(bool)` | Toggles recurring flag |
| `updateRecurrenceRule(String?)` | Sets recurrence rule string |
| `updateIncomeAllocationPct(int?)` | Income only — sets auto-savings percentage |
| `updateIsNeed(bool?)` | Expense only — marks as need vs. want |
| `updateEmotion(String?)` | Expense only — tags emotion |
| `loadTransactionForEdit(TransactionModel)` | Populates all fields from an existing transaction |
| `toTransactionModel()` | Converts current form state into a `TransactionModel` |
| `reset()` | Resets all fields to defaults |
| `partialResetForNewEntry(...)` | Resets most fields but preserves date/account for fast sequential entry |

---

## Provider Invalidation Chains

When a transaction is **created**:
1. `transactionsProvider` — prepends new item to list
2. `accountsProvider` — **invalidated** → re-fetches (balance changed)
3. `dashboardInsightsProvider` — **invalidated** → re-fetches analytics
4. `savingsBalanceProvider` — **invalidated** if `incomeAllocationPct > 0`

When a transaction is **updated** or **deleted**:
1. `transactionsProvider` — replaces / removes item in list
2. `accountsProvider` — **invalidated**
3. `dashboardInsightsProvider` — **invalidated**

When the **selected budget month** changes (`budgetPeriodProvider`):
- `budgetsProvider` automatically re-fetches (it depends on `budgetPeriodProvider`)

---

## Data Models

| Model | File | Key Fields |
|-------|------|-----------|
| `TransactionModel` | `transaction_model.dart` | id?, userId, type, category, subCategory?, amount, date, accountId, isNeed?, emotion?, incomeAllocationPct? |
| `AccountModel` | `account_model.dart` | id, userId, accountName, accountType, initialBalance, currentBalance, currency, isArchived |
| `BudgetModel` | `budget_model.dart` | id?, userId, category, limitAmount, spentAmount, period, year, month, isAuto |
| `SavingsGoalModel` | `savings_goal_model.dart` | id, userId, title, targetAmount, currentAmount, targetDate, isActive |
| `SavingsAllocationModel` | `savings_allocation_model.dart` | id?, userId, amount, date, source (auto/manual), transactionId? |
| `SavingsBalanceModel` | `savings_balance_model.dart` | balance, updatedAt? |
| `UserProfileModel` | `user_profile_model.dart` | uid, fullName, username, email, birthDate, profileIconId?, riskProfile? |
| `UserCategoryModel` | `user_category_model.dart` | id?, userId, categoryName, categoryType, iconId?, subcategories, isArchived |
| `DashboardInsightsModel` | `analytics_models.dart` | incomeExpenseSummary, needsVsWantsSummary, emotionSummary, categorySummary, expenseTrend7Days, totalFinancialBalance, savingsBalance |
| `AIProjectionsModel` | `analytics_models.dart` | spendingForecast, savingsPotential, actionableTasks |
