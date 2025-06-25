# File: flask_api/app/services/analytics_service.py
from app.utils.firebase_config import db
from datetime import datetime, timezone, timedelta
from google.cloud.firestore_v1.base_query import FieldFilter
from google.cloud import firestore
import traceback
from .savings_service import SavingsService

class AnalyticsService:
    @staticmethod
    def _get_date_range_from_period(period: str):
        today = datetime.now(timezone.utc)
        if period == "this_month":
            start_date = today.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
            end_date = today
        elif period == "last_month":
            end_date = today.replace(day=1, hour=0, minute=0, second=0, microsecond=0) - timedelta(microseconds=1)
            start_date = end_date.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        elif period == "last_3_months":
            temp_date = today.replace(day=1)
            start_date = (temp_date - timedelta(days=60)).replace(day=1)
            end_date = today
        else:
            start_date = today.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
            end_date = today
        
        period_duration = (end_date - start_date).days if (end_date - start_date).days > 0 else 30
        end_date_previous = start_date - timedelta(microseconds=1)
        start_date_previous = end_date_previous - timedelta(days=period_duration)

        return start_date, end_date, start_date_previous, end_date_previous

    @staticmethod
    def _calculate_period_metrics(docs):
        income, expense, needs_total, wants_total = 0.0, 0.0, 0.0, 0.0
        spending_by_emotion, spending_by_category = {}, {}
        for doc in docs:
            transaction = doc.to_dict()
            amount = float(transaction.get("amount", 0.0))
            tx_type = transaction.get("type")
            if tx_type == 'income':
                income += amount
            elif tx_type == 'expense':
                expense += amount
                if transaction.get("isNeed", True): needs_total += amount
                else: wants_total += amount
                emotion = transaction.get("emotion", "Nötr")
                spending_by_emotion[emotion] = spending_by_emotion.get(emotion, 0.0) + amount
                category = transaction.get("category", "Diğer")
                spending_by_category[category] = spending_by_category.get(category, 0.0) + amount
        return {"income": income, "expense": expense, "needs": needs_total, "wants": wants_total, "by_emotion": spending_by_emotion, "by_category": spending_by_category}

    @staticmethod
    def get_v2_analytics(user_id, period="this_month"):
        try:
            transactions_ref = db.collection('transactions')
            
            all_user_transactions_query = transactions_ref.where(filter=FieldFilter("userId", "==", user_id)).where(filter=FieldFilter("isDeleted", "==", False)).order_by("date")
            all_user_docs = list(all_user_transactions_query.stream())

            if not all_user_docs:
                default_data = { "period": {}, "dataSpanDays": 0, "incomeExpenseSummary": {"incomeTotal": 0, "expenseTotal": 0, "net": 0}, "totalFinancialBalance": 0, "savingsBalance": 0, "needsVsWantsSummary": {"needsTotal": 0, "wantsTotal": 0}, "emotionSummary": [], "categorySummary": [], "expenseTrend7Days": [] }
                return {"success": True, "data": default_data}, 200

            # DÜZELTME: Tarih string'inin sadece ilk 10 karakterini alarak hatayı önle.
            first_date_str = all_user_docs[0].to_dict()['date'][:10]
            last_date_str = all_user_docs[-1].to_dict()['date'][:10]
            first_date = datetime.strptime(first_date_str, '%Y-%m-%d')
            last_date = datetime.strptime(last_date_str, '%Y-%m-%d')
            data_span_days = (last_date - first_date).days

            start_date, end_date, start_date_previous, end_date_previous = AnalyticsService._get_date_range_from_period(period)
            
            # Bellekteki listeyi filtrelerken de aynı düzeltmeyi uygula
            current_period_start_str = start_date.strftime('%Y-%m-%d')
            start_date_previous_str = start_date_previous.strftime('%Y-%m-%d')
            
            current_period_docs = [d for d in all_user_docs if current_period_start_str <= d.to_dict().get('date', '')[:10] <= end_date.strftime('%Y-%m-%d')]
            previous_period_docs = [d for d in all_user_docs if start_date_previous_str <= d.to_dict().get('date', '')[:10] < current_period_start_str]
            
            current_metrics = AnalyticsService._calculate_period_metrics(current_period_docs)
            previous_metrics = AnalyticsService._calculate_period_metrics(previous_period_docs)
            
            budgets_ref = db.collection('budgets')
            budget_query = (budgets_ref.where(filter=FieldFilter("userId", "==", user_id)).where(filter=FieldFilter("year", "==", start_date.year)).where(filter=FieldFilter("month", "==", start_date.month)))
            budgets_map = {doc.to_dict()['category']: doc.to_dict()['limitAmount'] for doc in budget_query.stream()}

            def calculate_change(current, previous):
                if previous == 0: return None
                return ((current - previous) / previous) * 100
            
            savings_data = SavingsService.get_user_savings_balance(user_id)
            savings_balance = savings_data.get("balance", 0.0)
            
            accounts_ref = db.collection('user_accounts')
            accounts_query = accounts_ref.where(filter=FieldFilter("userId", "==", user_id)).where(filter=FieldFilter("isArchived", "==", False))
            total_financial_balance = sum(float(acc.to_dict().get('currentBalance', 0.0)) for acc in accounts_query.stream() if acc.to_dict().get('accountType') != 'investment')

            daily_expenses = {}
            seven_days_ago = end_date - timedelta(days=6)
            for doc in current_period_docs:
                transaction = doc.to_dict()
                if transaction.get('type') == 'expense':
                    try:
                        # DÜZELTME: Burada da tarih string'ini kırp
                        tx_date_str = transaction.get('date', '')[:10]
                        tx_date = datetime.strptime(tx_date_str, '%Y-%m-%d').replace(tzinfo=timezone.utc)
                        if tx_date >= seven_days_ago.replace(hour=0, minute=0, second=0, microsecond=0):
                            daily_expenses[tx_date_str] = daily_expenses.get(tx_date_str, 0.0) + float(transaction.get('amount', 0.0))
                    except (ValueError, TypeError): continue
            
            expense_trend_7_days = [{"date": (end_date.date() - timedelta(days=i)).strftime('%Y-%m-%d'), "amount": round(daily_expenses.get((end_date.date() - timedelta(days=i)).strftime('%Y-%m-%d'), 0.0), 2)} for i in range(6, -1, -1)]

            historical_data = {
                "period": {"start": start_date.isoformat(), "end": end_date.isoformat()}, "dataSpanDays": data_span_days,
                "incomeExpenseSummary": {"incomeTotal": round(current_metrics["income"], 2), "expenseTotal": round(current_metrics["expense"], 2), "net": round(current_metrics["income"] - current_metrics["expense"], 2), "incomeChangePercent": calculate_change(current_metrics["income"], previous_metrics["income"]), "expenseChangePercent": calculate_change(current_metrics["expense"], previous_metrics["expense"])},
                "totalFinancialBalance": round(total_financial_balance, 2), "savingsBalance": savings_balance,
                "needsVsWantsSummary": {"needsTotal": round(current_metrics["needs"], 2), "wantsTotal": round(current_metrics["wants"], 2)},
                "emotionSummary": sorted([{"emotion": k, "totalAmount": round(v, 2)} for k, v in current_metrics["by_emotion"].items()], key=lambda x: x['totalAmount'], reverse=True),
                "categorySummary": sorted([{"category": k, "totalAmount": round(v, 2), "budgetLimit": budgets_map.get(k), "budgetUsage": (round(v, 2) / budgets_map[k]) if budgets_map.get(k, 0) > 0 else None} for k, v in current_metrics["by_category"].items()], key=lambda x: x['totalAmount'], reverse=True),
                "expenseTrend7Days": expense_trend_7_days,
            }
            return {"success": True, "data": historical_data}, 200
        except Exception as e:
            traceback.print_exc()
            return {"success": False, "error": str(e)}, 500
    @staticmethod
    def get_category_spending_comparison(user_id, category):
        try:
            today = datetime.now(timezone.utc)
            start_of_this_month = today.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
            end_of_last_month = start_of_this_month - timedelta(microseconds=1)
            start_of_last_month = end_of_last_month.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
            query_start_date_str = start_of_last_month.strftime('%Y-%m-%d')
            transactions_ref = db.collection('transactions')
            query_builder = (transactions_ref.where(filter=FieldFilter("userId", "==", user_id)).where(filter=FieldFilter("type", "==", "expense")).where(filter=FieldFilter("date", ">=", query_start_date_str)).where(filter=FieldFilter("isDeleted", "==", False)))
            if category != "Tüm Harcamalar":
                query_builder = query_builder.where(filter=FieldFilter("category", "==", category))
            all_docs = list(query_builder.stream())
            def process_period(docs, start_date, end_date):
                daily_spending, period_total = {}, 0.0
                period_docs = [d for d in docs if start_date.strftime('%Y-%m-%d') <= d.to_dict().get('date') <= end_date.strftime('%Y-%m-%d')]
                for doc in period_docs:
                    t = doc.to_dict()
                    tx_date = datetime.strptime(t.get('date'), '%Y-%m-%d').day
                    amount = float(t.get("amount", 0.0))
                    daily_spending[tx_date] = daily_spending.get(tx_date, 0.0) + amount
                    period_total += amount
                points = [{"day": day, "amount": round(daily_spending.get(day, 0.0), 2)} for day in range(1, 32)]
                return {"total": round(period_total, 2), "dailyPoints": points}
            current_period_data = process_period(all_docs, start_of_this_month, today)
            previous_period_data = process_period(all_docs, start_of_last_month, end_of_last_month)
            comparison_data = {"category": category, "currentPeriod": {**current_period_data, "label": "Bu Ay"}, "previousPeriod": {**previous_period_data, "label": "Geçen Ay"}}
            return {"success": True, "comparison": comparison_data}, 200
        except Exception as e:
            traceback.print_exc()
            return {"success": False, "error": str(e)}, 500