# SIT App — System Architecture

## Overview

SIT App ("Finansal Asistanınız") is a Turkish-language personal finance management mobile application, built as a Bachelor's thesis project in Finance/Business Administration. The system consists of a Flutter mobile frontend (iOS primary target), a Flask REST API backend hosted on Render, and Google Firebase for authentication and data persistence.

## Tech Stack

| Layer | Technology | Notes |
|-------|-----------|-------|
| Mobile Frontend | Flutter (Dart) | iOS primary; Android supported |
| State Management | Flutter Riverpod 2.x | StateNotifier + FutureProvider pattern |
| Authentication | Firebase Auth | Email/password |
| Backend API | Python / Flask | Hosted on Render.com |
| Database | Google Cloud Firestore | Accessed exclusively via Flask backend |
| AI Features | Google Gemini AI | `google-generativeai` SDK |
| Market Data | yfinance | Stock/fund price lookups |
| Data Processing | pandas | Data aggregation for analytics |
| Production Server | Gunicorn | 2 workers, port 10000 |

## High-Level Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        Flutter App (iOS)                        │
│                                                                 │
│  ┌─────────────┐  ┌──────────────────┐  ┌──────────────────┐  │
│  │  Firebase   │  │   Riverpod       │  │  Flutter HTTP    │  │
│  │  Auth SDK   │  │   Providers      │  │  Service Layer   │  │
│  │ (direct)    │  │  (state layer)   │  │ (API clients)    │  │
│  └──────┬──────┘  └────────┬─────────┘  └────────┬─────────┘  │
└─────────┼──────────────────┼─────────────────────┼────────────┘
          │ Auth             │                      │ REST/JSON
          ▼                  │                      ▼
┌─────────────────┐          │          ┌─────────────────────────┐
│  Firebase Auth  │          │          │  Flask REST API          │
│  (Google Cloud) │          │          │  (Render.com)           │
└─────────────────┘          │          │                         │
                             │          │  Blueprints:            │
                             │          │  /api/users             │
                             │          │  /api/accounts          │
                             │          │  /api/transactions      │
                             │          │  /api/budgets           │
                             │          │  /api/savings           │
                             │          │  /api/analytics         │
                             │          │  /api/investments       │
                             │          │  /api/ai                │
                             │          │  /api/categories        │
                             │          │  /api/tasks             │
                             │          │  /api/finance-tests     │
                             │          └──────────┬──────────────┘
                             │                     │ Firebase Admin SDK
                             │                     ▼
                             │          ┌─────────────────────────┐
                             └─────────►│   Cloud Firestore       │
                             (uid only) │   (Google Cloud)        │
                                        └─────────────────────────┘
```

**Key architectural note:** The Flutter app does **not** use the Cloud Firestore SDK directly for data. All data reads/writes go through the Flask REST API. Firebase Auth is used only for authentication (sign-in/sign-up). The `userId` (Firebase UID) is passed as a query/body parameter on every API call.

## Data Flow Example — Creating a Transaction

1. User fills `TransactionFlowScreen` form → `TransactionFormNotifier` accumulates form state
2. User taps "Save" → `TransactionsNotifier.addTransaction(model)` called
3. `TransactionFlutterService.createTransaction()` sends `POST /api/transactions` with JSON body + `userId`
4. Flask `transaction_routes.py` receives request → calls `TransactionService.create_transaction(data)`
5. `TransactionService` writes to `transactions` Firestore collection
6. `BalanceService.update_balance_on_new_transaction()` updates `user_accounts` document balance
7. If `incomeAllocationPct > 0`: `SavingsService.create_savings_allocation()` auto-creates a savings record
8. Flask returns `{success: true, transaction: {...}}`
9. `TransactionsNotifier` appends result to local state → UI re-renders

## Core Features

| Feature | Description |
|---------|-------------|
| Accounts | Bank, credit card, savings, and investment account management |
| Transactions | Income/expense/transfer CRUD with date, type, and account filtering |
| Budgets | Monthly category-based spending limits with auto-calculated "spent" amounts |
| Savings | Manual + automatic savings allocations; savings goals with progress tracking |
| Analytics | Dashboard insights: income vs. expense, needs vs. wants, emotion-linked spending, 7-day trend |
| AI Features | Natural language transaction parsing (Gemini), budget recommendations, spending forecasts |
| Investments | Portfolio tracking, buy/sell logging, asset analysis via yfinance, opportunity finder |
| Finance Test | Risk profile assessment quiz that feeds into investment recommendations |
| Categories | Custom income/expense categories with subcategories |

## Firestore Collections

| Collection | Purpose | Key Fields |
|-----------|---------|-----------|
| `users` | User profiles | uid, fullName, username, email, birthDate, riskProfile |
| `user_accounts` | Bank/investment accounts | userId, accountName, accountType, currentBalance, isArchived |
| `transactions` | Income/expense records | userId, type, category, amount, date, accountId, isNeed, emotion |
| `user_defined_categories` | Custom categories | userId, categoryName, categoryType, subcategories |
| `budgets` | Monthly budgets | userId, category, limitAmount, year, month |
| `savings_allocations` | Savings records | userId, amount, date, source (auto/manual) |
| `savings_goals` | Savings targets | userId, title, targetAmount, currentAmount, targetDate |
| `user_savings_balances` | Running savings total | userId, balance |
| `holdings` | Investment positions | userId, assetSymbol, quantity |
| `investment_transactions` | Buy/sell records | userId, assetSymbol, type, quantity, pricePerUnit |
| `user_tasks` | Financial tasks | userId, description, isCompleted |
| `FinanceTestItems` | Quiz questions | (global collection, not per-user) |

## Flutter Project Structure

```
sit-app/
├── lib/
│   ├── main.dart                      # App entry point, Firebase init, Turkish locale
│   ├── app_widget.dart                # Root widget, Material 3 theme, AuthWrapper routing
│   ├── firebase_options.dart          # Generated by FlutterFire CLI (committed to git)
│   └── src/
│       ├── core/
│       │   ├── categories.dart        # Hardcoded Turkish category/subcategory definitions
│       │   └── theme/app_theme.dart   # (currently empty — theme defined in app_widget.dart)
│       ├── data/
│       │   ├── models/                # Plain Dart data classes with fromMap()/toMap()
│       │   └── services/              # HTTP API client classes (one per resource domain)
│       └── presentation/
│           ├── providers/             # Riverpod providers & StateNotifiers
│           ├── screens/               # All UI screens (auth, home, transactions, budgets, etc.)
│           └── widgets/               # Shared reusable widget components
├── ios/
│   ├── Podfile                        # CocoaPods config — set platform :ios, '13.0'
│   └── Runner/
│       ├── Info.plist                 # App metadata and permissions
│       └── GoogleService-Info.plist   # Firebase iOS config (gitignored — must add manually)
└── android/
    └── app/
        └── google-services.json       # Firebase Android config (gitignored — must add manually)
```

## Flask Project Structure

```
flask_api/
├── run.py                             # Entry point — creates app via factory
├── requirements.txt                   # Python dependencies (currently unpinned)
├── Dockerfile                         # python:3.10-slim, Gunicorn, port 10000
└── app/
    ├── __init__.py                    # App factory: CORS setup, all blueprint registration
    ├── routes/                        # HTTP route handlers (thin controllers)
    │   ├── user_routes.py
    │   ├── transaction_routes.py
    │   ├── account_routes.py
    │   ├── budget_routes.py
    │   ├── savings_routes.py
    │   ├── analytics_routes.py
    │   ├── investment_routes.py
    │   ├── ai_routes.py
    │   ├── category_routes.py
    │   ├── task_routes.py
    │   └── finance_test_routes.py
    ├── services/                      # Business logic layer
    │   ├── user_service.py
    │   ├── transaction_service.py
    │   ├── account_service.py
    │   ├── balance_service.py         # Auto-updates account balances on transaction events
    │   ├── budget_service.py
    │   ├── savings_service.py
    │   ├── analytics_service.py
    │   ├── investment_service.py
    │   ├── ai_service.py              # Google Gemini integration
    │   ├── category_service.py
    │   ├── task_service.py
    │   └── finance_test_service.py
    └── utils/
        └── firebase_config.py         # Firebase Admin SDK initialization
```

## Environment & Configuration

### Flutter
| File | Status | Notes |
|------|--------|-------|
| `lib/firebase_options.dart` | Committed to git ✓ | Auto-generated by FlutterFire CLI |
| `ios/Runner/GoogleService-Info.plist` | **Gitignored — must add manually** | Download from Firebase Console |
| `android/app/google-services.json` | **Gitignored — must add manually** | Download from Firebase Console |

### Flask
| File / Variable | Status | Notes |
|----------------|--------|-------|
| `flask_api/.env` | **Gitignored — must create manually** | Contains `GEMINI_API_KEY`, `FIREBASE_SERVICE_ACCOUNT_PATH` |
| `flask_api/serviceAccountKey.json` | **Gitignored — must add manually** | Download from Firebase Console → Service Accounts |
| `GOOGLE_APPLICATION_CREDENTIALS` | Set on Render dashboard | Production only — points to service account JSON |

## Known Limitations & Future Work

- **No authentication middleware on Flask** — `userId` is a plain request parameter with no token verification. Future: add `firebase_admin.auth.verify_id_token()` middleware.
- **CORS allows all origins** — should be restricted to known domains in production.
- **Python dependencies are unpinned** — `yfinance` and `pandas` should be version-pinned.
- **Firebase Flutter SDK is on v2.x** — v3.x is current; migration planned for a future sprint.
- **`PUT /api/budgets/<id>` is not implemented** (returns 501).
