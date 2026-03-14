# SIT App — Flask Backend API Reference

**Base URL (Production):** `https://sit-app-backend.onrender.com`
**Base URL (Local Dev):** `http://localhost:5000`

All endpoints return JSON. Successful responses always include `"success": true`. Error responses include `"success": false` and an `"error"` or `"message"` field.

> ⚠️ **Security Note:** All endpoints currently accept `userId` as a plain query/body parameter with no server-side token verification. A future iteration should add Firebase ID token validation middleware using `firebase_admin.auth.verify_id_token()`.

---

## Users & Profiles

### `POST /api/users/create_profile`
Creates a new user profile document in Firestore immediately after Firebase Auth signup.

```json
// Request Body
{
  "uid": "string",
  "fullName": "string",
  "username": "string",
  "email": "string",
  "birthDate": "YYYY-MM-DD",
  "profileIconId": "icon-1"
}
// Response 201
{ "success": true, "message": "...", "uid": "string" }
```

Status codes: `201` created · `400` missing fields · `500` server error

---

### `GET /api/users/<uid>/profile`
Returns the user's full profile document.

```json
// Response 200
{
  "uid": "string",
  "fullName": "string",
  "username": "string",
  "email": "string",
  "birthDate": "YYYY-MM-DD",
  "profileIconId": "string",
  "riskProfile": "string | null",
  "createdAt": "ISO8601",
  "updatedAt": "ISO8601"
}
```

Status codes: `200` · `404` user not found · `500`

---

### `PUT /api/users/<uid>/profile`
Updates editable profile fields.

```json
// Request Body (all fields optional)
{ "fullName": "string", "username": "string", "birthDate": "YYYY-MM-DD" }
// Response 200
{ "success": true, "message": "...", "profile": { ...updatedFields } }
```

---

### `DELETE /api/users/<uid>`
Deletes the user profile **and all associated data** (accounts, transactions, budgets, goals, allocations, holdings, etc.) and removes the Firebase Auth user.

```json
// Response 200
{ "success": true, "message": "..." }
```

---

### `GET /api/profile/icons`
Returns all available profile icon IDs (`icon-1` through `icon-10`).

```json
// Response 200
{ "icons": [{ "id": "icon-1" }, { "id": "icon-2" }, ...] }
```

---

## Accounts

### `GET /api/accounts?userId=<uid>`
Lists all non-archived accounts for the user.

```json
// Response 200
{
  "success": true,
  "accounts": [{
    "id": "string",
    "accountName": "string",
    "accountType": "checking | savings | credit_card | investment",
    "currentBalance": 0.0,
    "currency": "TRY",
    "creditLimit": null,
    "statementDay": null,
    "dueDateDay": null
  }]
}
```

---

### `POST /api/accounts`
Creates a new account. `initialBalance` seeds `currentBalance` on creation.

```json
// Request Body
{
  "userId": "string",
  "accountName": "string",
  "accountType": "checking | savings | credit_card | investment",
  "currency": "TRY",
  "initialBalance": 0.0,
  "creditLimit": null,
  "statementDay": null,
  "dueDateDay": null
}
// Response 201
{ "success": true, "message": "...", "account": { ...accountFields } }
```

---

### `PUT /api/accounts/<account_id>`
Updates account metadata. Does **not** change `currentBalance` directly.

```json
// Request Body (all optional)
{ "accountName": "string", "accountType": "string", "currency": "string",
  "creditLimit": null, "statementDay": null, "dueDateDay": null }
// Response 200
{ "success": true, "message": "...", "account": { ...accountFields } }
```

---

### `POST /api/accounts/<account_id>/archive`
Soft-deletes an account (sets `isArchived = true`). Archived accounts are excluded from `GET /api/accounts`.

```json
// Response 200
{ "success": true, "message": "..." }
```

---

## Transactions

### `GET /api/transactions`
Lists transactions within a date range with optional filters.

**Query params:** `userId` (required) · `startDate=YYYY-MM-DD` · `endDate=YYYY-MM-DD` · `type` (income|expense|transfer_in|transfer_out) · `account` (account name string)

```json
// Response 200
{
  "success": true,
  "transactions": [{
    "id": "string",
    "type": "income | expense | transfer_in | transfer_out",
    "category": "string",
    "subCategory": "string | null",
    "amount": 0.0,
    "date": "YYYY-MM-DD",
    "accountId": "string",
    "description": "string | null",
    "isRecurring": false,
    "isNeed": null,
    "emotion": null,
    "incomeAllocationPct": null
  }]
}
```

---

### `POST /api/transactions`
Creates a new transaction, automatically updates the account balance, and optionally creates a savings allocation if `incomeAllocationPct > 0`.

```json
// Request Body
{
  "userId": "string",
  "type": "income | expense",
  "category": "string",
  "amount": 0.0,
  "date": "YYYY-MM-DD",
  "accountId": "string",
  "subCategory": null,
  "description": null,
  "isRecurring": false,
  "recurrenceRule": null,
  "isNeed": null,
  "emotion": null,
  "incomeAllocationPct": null
}
// Response 201
{ "success": true, "transaction": { ...transactionFields } }
```

---

### `POST /api/transactions/transfer`
Creates a paired `transfer_out` + `transfer_in` transaction between two accounts and updates both balances atomically.

```json
// Request Body
{
  "userId": "string",
  "sourceAccountId": "string",
  "destinationAccountId": "string",
  "amount": 0.0,
  "date": "YYYY-MM-DD",
  "description": null
}
// Response 201
{ "success": true, "transactions": [ ...outTx, ...inTx ] }
```

---

### `PUT /api/transactions/<transaction_id>`
Updates transaction fields and recalculates affected account balance(s).

```json
// Request Body (all optional — send only changed fields)
{ "type": "string", "category": "string", "amount": 0.0, "date": "YYYY-MM-DD",
  "accountId": "string", "description": null, "isNeed": null, "emotion": null }
// Response 200
{ "success": true, "transaction": { ...transactionFields } }
```

---

### `DELETE /api/transactions/<transaction_id>?userId=<uid>`
Soft-deletes the transaction (`isDeleted = true`) and reverses the balance change on the account.

```json
// Response 200
{ "success": true, "message": "..." }
```

---

## Budgets

### `GET /api/budgets?userId=<uid>&year=YYYY&month=MM`
Lists all budgets for the given month. Each budget includes a real-time calculated `spentAmount` pulled from matching transactions.

```json
// Response 200
{
  "success": true,
  "budgets": [{
    "id": "string",
    "category": "string",
    "limitAmount": 0.0,
    "spentAmount": 0.0,
    "period": "monthly",
    "year": 2025,
    "month": 1,
    "isAuto": false
  }]
}
```

---

### `POST /api/budgets`
Creates or updates a budget. Uses a composite key of `(userId, category, year, month)` — posting to an existing combination updates it.

```json
// Request Body
{
  "userId": "string",
  "category": "string",
  "limitAmount": 0.0,
  "period": "monthly",
  "isAuto": false,
  "year": 2025,
  "month": 1
}
// Response 200 (updated) or 201 (created)
{ "success": true, "message": "...", "budget": { ...budgetFields } }
```

---

### `DELETE /api/budgets/<budget_id>?userId=<uid>`
Soft-deletes a budget.

> ⚠️ `PUT /api/budgets/<budget_id>` currently returns **501 Not Implemented**.

---

## Savings

### `GET /api/savings/balance?userId=<uid>`
Returns the user's current total savings balance.

```json
// Response 200
{ "success": true, "balance": { "balance": 0.0, "updatedAt": "ISO8601" } }
```

---

### `GET /api/savings/allocations?userId=<uid>&startDate=YYYY-MM-DD&endDate=YYYY-MM-DD`
Lists savings allocation records. Optional filter: `source` (auto|manual).

```json
// Response 200
{
  "success": true,
  "allocations": [{
    "id": "string",
    "amount": 0.0,
    "date": "YYYY-MM-DD",
    "source": "auto | manual",
    "transactionId": "string | null"
  }]
}
```

---

### `POST /api/savings/allocations`
Creates a manual savings entry and increases the savings balance.

```json
// Request Body
{ "userId": "string", "amount": 0.0, "date": "YYYY-MM-DD" }
// Response 201
{ "success": true, "message": "..." }
```

---

### `GET /api/savings/goals?userId=<uid>`
Lists all active savings goals for the user.

```json
// Response 200
{
  "success": true,
  "goals": [{
    "id": "string",
    "title": "string",
    "targetAmount": 0.0,
    "currentAmount": 0.0,
    "targetDate": "YYYY-MM-DD",
    "isActive": true
  }]
}
```

---

### `POST /api/savings/goals`
Creates a new savings goal.

```json
// Request Body
{
  "userId": "string",
  "goalName": "string",
  "targetAmount": 0.0,
  "deadline": "YYYY-MM-DD",
  "priority": "string"
}
// Response 201
{ "success": true, "goal": { ...goalFields } }
```

---

### `DELETE /api/savings/goals/<goal_id>?userId=<uid>`
Soft-deletes a savings goal.

---

### `POST /api/savings/goals/<goal_id>/allocate`
Allocates an amount from the user's savings balance to a specific goal, increasing `currentAmount`.

```json
// Request Body
{ "userId": "string", "amount": 0.0 }
// Response 200
{ "success": true, "goal": { ...updatedGoalFields } }
```

---

## Analytics

### `GET /api/analytics/dashboard-insights?userId=<uid>`
Returns full dashboard analytics data: income/expense summary, needs vs. wants breakdown, emotion-linked spending, category spending breakdown, 7-day expense trend, total financial balance, and savings balance.

```json
// Response 200
{
  "success": true,
  "data": {
    "incomeExpenseSummary": { "totalIncome": 0.0, "totalExpense": 0.0 },
    "needsVsWantsSummary": { "needsTotal": 0.0, "wantsTotal": 0.0 },
    "emotionSummary": [{ "emotion": "string", "totalAmount": 0.0 }],
    "categorySummary": [{ "category": "string", "totalAmount": 0.0 }],
    "expenseTrend7Days": [{ "date": "YYYY-MM-DD", "totalExpense": 0.0 }],
    "totalFinancialBalance": 0.0,
    "savingsBalance": 0.0,
    "dataSpanDays": 30
  }
}
```

---

### `GET /api/analytics/ai-projections?userId=<uid>`
Returns AI-generated (Gemini) spending forecast, savings potential estimate, and actionable financial tasks.

```json
// Response 200
{
  "success": true,
  "data": {
    "spendingForecast": { "next30Days": 0.0, "analysis": "string" },
    "savingsPotential": { "monthlyPotential": 0.0, "analysis": "string" },
    "actionableTasks": [{ "task": "string", "isCompleted": false }]
  }
}
```

---

## AI

### `POST /api/ai/parse-transactions`
Parses natural language text (Turkish or English) into a structured list of transaction items using Google Gemini.

```json
// Request Body
{ "text": "Bugün markette 150 TL harcadım ve yarın maaş 8000 TL." }
// Response 200
{
  "success": true,
  "parsed": [{
    "type": "expense",
    "amount": 150.0,
    "category": "string",
    "date": "YYYY-MM-DD",
    "description": "string"
  }]
}
```

---

### `GET /api/ai/budget-recommendation?userId=<uid>&category=<categoryName>`
Returns an AI-generated monthly budget recommendation for the specified expense category, based on the user's historical spending and Turkish cost-of-living data.

```json
// Response 200
{ "success": true, "recommendation": { "suggestedLimit": 0.0, "reasoning": "string" } }
```

---

## Investments

### `GET /api/investments/portfolio?userId=<uid>`
Returns portfolio summary with all current holdings and live valuations fetched via yfinance.

### `POST /api/investments/transactions`
Records a buy/sell/dividend investment transaction and updates the corresponding holding.

```json
// Request Body
{
  "userId": "string",
  "accountId": "string",
  "assetSymbol": "string",
  "type": "buy | sell | dividend",
  "quantity": 0.0,
  "pricePerUnit": 0.0,
  "date": "YYYY-MM-DD"
}
// Response 201
{ "success": true, "transaction": { ...investmentTxFields } }
```

### `GET /api/investments/transactions?userId=<uid>`
Lists investment transactions. Optional filters: `accountId`, `assetSymbol`.

### `PUT /api/investments/transactions/<transaction_id>`
Updates an investment transaction and recalculates the holding.

### `DELETE /api/investments/transactions/<transaction_id>`
Deletes an investment transaction and recalculates the holding.

### `GET /api/investments/analysis/<symbol>`
Returns technical analysis and AI commentary for the given asset symbol (e.g., `THYAO.IS`).

### `POST /api/investments/opportunities`
Returns AI-generated investment opportunity recommendations.

```json
// Request Body
{ "userId": "string", "market": "string", "horizon": "string" }
```

### `PUT /api/investments/holdings/<holding_id>`
Manually overrides a holding's quantity or average price.

### `DELETE /api/investments/holdings/<holding_id>`
Deletes a holding entry.

---

## Finance Tests (Risk Profile Assessment)

### `GET /api/finance-tests/items`
Returns all quiz question items used to calculate the user's risk profile.

### `POST /api/finance-tests`
Starts a new test session for the user.

```json
// Request Body
{ "userId": "string" }
// Response 200
{ "success": true, "testId": "string" }
```

### `POST /api/finance-tests/<test_id>/answers`
Submits answers. When `isComplete: true`, calculates the risk profile score and saves it to the user document.

```json
// Request Body
{ "userId": "string", "answers": { "questionId": "answerId" }, "isComplete": true }
// Response 200
{ "success": true, "message": "...", "results": { "riskProfile": "string" } }
```

---

## Tasks

### `GET /api/tasks?userId=<uid>`
Lists all active (incomplete) tasks. Maximum 3 active tasks per user.

### `POST /api/tasks`
Creates a new task.

```json
// Request Body
{ "userId": "string", "description": "string" }
// Response 201
{ "success": true, "message": "...", "task": { "id": "string", "description": "string" } }
```

### `PUT /api/tasks/<task_id>/complete`
Marks a task as completed.

```json
// Request Body
{ "userId": "string" }
// Response 200
{ "success": true, "message": "..." }
```
