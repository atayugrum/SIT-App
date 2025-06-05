# File: flask_api/app/services/analytics_service.py
from app.utils.firebase_config import db
from datetime import datetime, timezone, timedelta
import traceback
from firebase_admin import firestore
import calendar

# Diğer servisleri import etmemiz gerekebilir (örn: SavingsService, BudgetService)
from app.services.savings_service import SavingsService # Eğer dashboard'da savings info kullanılıyorsa
from app.services.budget_service import BudgetService # Budget feedback için eklendi

class AnalyticsService:
    @staticmethod
    def _format_date_for_query(dt_object):
        return dt_object.strftime('%Y-%m-%d')

    @staticmethod
    def _get_start_end_dates_for_period(year, month):
        first_of_month = datetime(year, month, 1, tzinfo=timezone.utc)
        last_day_of_month = calendar.monthrange(year, month)[1]
        last_of_month_dt_object = datetime(year, month, last_day_of_month, 23, 59, 59, 999999, tzinfo=timezone.utc)
        
        return AnalyticsService._format_date_for_query(first_of_month), \
               AnalyticsService._format_date_for_query(last_of_month_dt_object)

    @staticmethod
    def get_monthly_expense_summary(user_id, year, month):
        try:
            if db is None: raise Exception("Firestore client (db) is not initialized.")
            first_of_month_str, last_of_month_str = AnalyticsService._get_start_end_dates_for_period(year, month)
            
            print(f"ANALYTICS_SERVICE: Calculating monthly expense summary for {user_id}, Period: {first_of_month_str} to {last_of_month_str}")

            transactions_ref = db.collection('transactions')
            current_month_query = transactions_ref \
                .where('userId', '==', user_id) \
                .where('type', '==', 'expense') \
                .where('date', '>=', first_of_month_str) \
                .where('date', '<=', last_of_month_str) \
                .where('isDeleted', '==', False)
            
            current_month_docs = list(current_month_query.stream()) 
            by_category_map = {}
            total_expense_current_month = 0.0
            for doc_snapshot in current_month_docs:
                transaction = doc_snapshot.to_dict()
                category = transaction.get('category', 'Uncategorized')
                amount = float(transaction.get('amount', 0.0))
                by_category_map[category] = by_category_map.get(category, 0.0) + amount
                total_expense_current_month += amount
            
            by_category_list = []
            if total_expense_current_month > 0:
                by_category_list = [
                    {"category": k, "amount": round(v, 2), "percentage": round((v / total_expense_current_month) * 100, 2)}
                    for k, v in by_category_map.items()
                ]
                by_category_list.sort(key=lambda x: x['amount'], reverse=True)
            else:
                 by_category_list = [{"category": k, "amount": round(v, 2), "percentage": 0.0} for k,v in by_category_map.items()]

            prev_month_date = datetime(year, month, 1, tzinfo=timezone.utc) - timedelta(days=1)
            prev_month_year = prev_month_date.year
            prev_month_month = prev_month_date.month
            first_of_prev_month_str, last_of_prev_month_str = AnalyticsService._get_start_end_dates_for_period(prev_month_year, prev_month_month)

            prev_month_query = transactions_ref \
                .where('userId', '==', user_id).where('type', '==', 'expense') \
                .where('date', '>=', first_of_prev_month_str).where('date', '<=', last_of_prev_month_str) \
                .where('isDeleted', '==', False)
            total_expense_prev_month = sum(float(doc.to_dict().get('amount', 0.0)) for doc in prev_month_query.stream())

            mom_change_pct = None
            if total_expense_prev_month > 0:
                mom_change_pct = round(((total_expense_current_month - total_expense_prev_month) / total_expense_prev_month) * 100, 2)

            top_sub_categories_map = {}
            for transaction_data in [doc.to_dict() for doc in current_month_docs]: 
                category = transaction_data.get('category')
                sub_category = transaction_data.get('subCategory')
                amount = float(transaction_data.get('amount', 0.0))
                if category and sub_category: 
                    key = f"{category} > {sub_category}"
                    top_sub_categories_map[key] = top_sub_categories_map.get(key, 0.0) + amount
            
            top_sub_categories_list = [{"category_subcategory": k, "amount": round(v,2)} for k,v in top_sub_categories_map.items()]
            top_sub_categories_list.sort(key=lambda x: x['amount'], reverse=True)

            summary = { "year": year, "month": month, "totalExpense": round(total_expense_current_month, 2), "prevMonthTotalExpense": round(total_expense_prev_month, 2), "momChangePct": mom_change_pct, "byCategory": by_category_list, "topSubCategories": top_sub_categories_list[:5] }
            return {"success": True, "summary": summary}, 200
        except Exception as e: 
            print(f"Error in get_monthly_expense_summary: {e}")
            traceback.print_exc()
            return {"success": False, "error": str(e)}, 500

    @staticmethod
    def get_income_expense_analysis(user_id, year, month):
        try:
            if db is None: raise Exception("Firestore client (db) is not initialized.")
            first_of_month_str, last_of_month_str = AnalyticsService._get_start_end_dates_for_period(year, month)
            
            transactions_ref = db.collection('transactions')
            query = transactions_ref.where('userId', '==', user_id).where('date', '>=', first_of_month_str).where('date', '<=', last_of_month_str).where('isDeleted', '==', False)
            docs = query.stream()
            total_income = 0.0; total_expense = 0.0
            income_by_category = {}; expense_by_category = {}

            for doc in docs:
                transaction = doc.to_dict(); amount = float(transaction.get('amount', 0.0)); category = transaction.get('category', 'Uncategorized'); tx_type = transaction.get('type')
                if tx_type == 'income': total_income += amount; income_by_category[category] = income_by_category.get(category, 0.0) + amount
                elif tx_type == 'expense': total_expense += amount; expense_by_category[category] = expense_by_category.get(category, 0.0) + amount
            
            net_value = total_income - total_expense
            coverage_ratio = (total_expense / total_income * 100) if total_income > 0 else None
            top_income_list = sorted(income_by_category.items(), key=lambda x: x[1], reverse=True)
            top_expense_list = sorted(expense_by_category.items(), key=lambda x: x[1], reverse=True)

            analysis = { "year": year, "month": month, "totalIncome": round(total_income, 2), "totalExpense": round(total_expense, 2), "net": round(net_value, 2), "coverageRatio": round(coverage_ratio, 2) if coverage_ratio is not None else None, "topIncomeCategory": {"category": top_income_list[0][0], "amount": round(top_income_list[0][1],2)} if top_income_list else None, "topExpenseCategory": {"category": top_expense_list[0][0], "amount": round(top_expense_list[0][1],2)} if top_expense_list else None }
            return {"success": True, "analysis": analysis}, 200
        except Exception as e: 
            print(f"Error in get_income_expense_analysis: {e}")
            traceback.print_exc()
            return {"success": False, "error": str(e)}, 500

    @staticmethod
    def get_spending_trend(user_id, period_param="6m"):
        try:
            if db is None: raise Exception("Firestore client (db) is not initialized.")
            now = datetime.now(timezone.utc)
            period_months = {"1m": 1, "3m": 3, "6m": 6}.get(period_param, 6)

            end_last_dt = now
            start_last_dt = datetime(now.year, now.month - (period_months -1) , 1, tzinfo=timezone.utc)
            
            end_prev_dt = start_last_dt - timedelta(days=1)
            start_prev_dt = datetime(end_prev_dt.year, end_prev_dt.month - (period_months-1), 1, tzinfo=timezone.utc)

            start_last_str = AnalyticsService._format_date_for_query(start_last_dt)
            end_last_str = AnalyticsService._format_date_for_query(end_last_dt)
            start_prev_str = AnalyticsService._format_date_for_query(start_prev_dt)
            end_prev_str = AnalyticsService._format_date_for_query(end_prev_dt)
            
            transactions_ref = db.collection('transactions')
            def get_total_for_period(start_date, end_date):
                query = transactions_ref.where('userId', '==', user_id).where('type', '==', 'expense').where('date', '>=', start_date).where('date', '<=', end_date).where('isDeleted', '==', False)
                return sum(float(doc.to_dict().get('amount', 0.0)) for doc in query.stream())

            last_total = get_total_for_period(start_last_str, end_last_str)
            prev_total = get_total_for_period(start_prev_str, end_prev_str)
            trend_percent = round(((last_total - prev_total) / prev_total) * 100, 2) if prev_total > 0 else (100.0 if last_total > 0 else 0.0)
            
            return {"success": True, "trend": {"period": period_param, "lastTotal": round(last_total, 2), "prevTotal": round(prev_total, 2), "trendPercent": trend_percent}}, 200
        except Exception as e: 
            print(f"Error in get_spending_trend: {e}")
            traceback.print_exc()
            return {"success": False, "error": str(e)}, 500

    @staticmethod
    def get_category_trend_data(user_id, start_date_str, end_date_str):
        try:
            if db is None: raise Exception("Firestore client (db) is not initialized.")
            transactions_ref = db.collection('transactions')
            query = transactions_ref.where('userId', '==', user_id).where('type', '==', 'expense').where('date', '>=', start_date_str).where('date', '<=', end_date_str).where('isDeleted', '==', False)
            docs = query.stream(); monthly_category_spending = {}

            for doc in docs:
                transaction = doc.to_dict(); tx_date_str_full = transaction.get('date')
                if not tx_date_str_full: continue
                year_month = tx_date_str_full[:7]; category = transaction.get('category', 'Uncategorized'); amount = float(transaction.get('amount', 0.0))
                if year_month not in monthly_category_spending: monthly_category_spending[year_month] = {}
                monthly_category_spending[year_month][category] = monthly_category_spending[year_month].get(category, 0.0) + amount
            
            all_months_set = set(monthly_category_spending.keys()); all_categories_set = set()
            for month_data in monthly_category_spending.values(): all_categories_set.update(month_data.keys())
            
            start_dt = datetime.strptime(start_date_str, '%Y-%m-%d'); end_dt = datetime.strptime(end_date_str, '%Y-%m-%d')
            generated_labels = []; current_dt = start_dt
            while current_dt <= end_dt:
                generated_labels.append(current_dt.strftime('%Y-%m'))
                next_month_val = current_dt.month + 1
                next_year_val = current_dt.year
                if next_month_val > 12: 
                    next_month_val = 1
                    next_year_val += 1
                current_dt = datetime(next_year_val, next_month_val, 1) # Corrected line
            
            sorted_labels = sorted(list(set(generated_labels)))
            sorted_categories = sorted(list(all_categories_set))
            category_data_map = {cat: [0.0] * len(sorted_labels) for cat in sorted_categories}

            for i, month_label in enumerate(sorted_labels):
                if month_label in monthly_category_spending:
                    for category, amount in monthly_category_spending[month_label].items():
                        if category in category_data_map: category_data_map[category][i] = round(amount, 2)
            return {"success": True, "labels": sorted_labels, "data": category_data_map}, 200
        except Exception as e: 
            print(f"Error in get_category_trend_data: {e}")
            traceback.print_exc()
            return {"success": False, "error": str(e)}, 500
            
    @staticmethod
    def get_budget_feedback(user_id, year, month):
        try:
            if db is None: raise Exception("Firestore client (db) is not initialized.")
            first_of_month_str, last_of_month_str = AnalyticsService._get_start_end_dates_for_period(year, month)
            
            transactions_ref = db.collection('transactions')
            spending_query = transactions_ref.where('userId', '==', user_id).where('type', '==', 'expense').where('date', '>=', first_of_month_str).where('date', '<=', last_of_month_str).where('isDeleted', '==', False)
            spent_by_category = {}
            for doc in spending_query.stream(): tx = doc.to_dict(); category = tx.get('category', 'Uncategorized'); amount = float(tx.get('amount', 0.0)); spent_by_category[category] = spent_by_category.get(category, 0.0) + amount

            budgets_ref = db.collection('budgets'); budgets_query = budgets_ref.where('userId', '==', user_id).where('year', '==', year).where('month', '==', month).where('period', '==', 'monthly')
            user_budgets = {doc.to_dict()['category']: doc.to_dict()['limitAmount'] for doc in budgets_query.stream()}

            feedback_list = []; all_relevant_categories = set(spent_by_category.keys()) | set(user_budgets.keys())

            for category in all_relevant_categories:
                spent = spent_by_category.get(category, 0.0); limit = user_budgets.get(category)
                item = {"category": category, "spent": round(spent,2), "limit": round(limit,2) if limit is not None else None}
                if limit is not None and limit > 0: 
                    if spent > limit: item["status"] = "exceeded"; item["excessAmount"] = round(spent - limit, 2); item["excessPct"] = round(((spent - limit) / limit) * 100, 2) 
                    else: item["status"] = "within_limit"; item["remainingAmount"] = round(limit - spent, 2); item["usedPct"] = round((spent / limit) * 100, 2)
                    if item["usedPct"] >= 90: 
                        item["status"] = "near_limit"
                elif limit is None and spent > 0: item["status"] = "no_budget_set"
                else: item["status"] = "neutral" 
                if item["status"] not in ["within_limit", "neutral"] or (item["status"] == "within_limit" and spent > 0 and limit is not None): feedback_list.append(item)
            
            feedback_list.sort(key=lambda x: (x.get('status') != 'exceeded', x.get('status') != 'near_limit', x.get('status') != 'no_budget_set' , -x.get('spent', 0)))
            return {"success": True, "year": year, "month": month, "feedbacks": feedback_list}, 200
        except Exception as e: 
            print(f"Error in get_budget_feedback: {e}")
            traceback.print_exc()
            return {"success": False, "error": str(e)}, 500

    @staticmethod
    def get_dashboard_insights(user_id):
        now = datetime.now(timezone.utc); current_year = now.year; current_month = now.month
        start_of_7_days_ago_str = AnalyticsService._format_date_for_query(now - timedelta(days=6))
        try:
            expense_summary_resp, _ = AnalyticsService.get_monthly_expense_summary(user_id, current_year, current_month)
            income_expense_resp, _ = AnalyticsService.get_income_expense_analysis(user_id, current_year, current_month)
            budget_feedback_resp, _ = AnalyticsService.get_budget_feedback(user_id, current_year, current_month)
            savings_balance_data = SavingsService.get_user_savings_balance(user_id)
            spending_trend_resp, _ = AnalyticsService.get_spending_trend(user_id, period_param="6m")


            transactions_ref = db.collection('transactions')
            expense_trend_query = transactions_ref.where('userId', '==', user_id).where('type', '==', 'expense').where('date', '>=', start_of_7_days_ago_str).where('date', '<=', AnalyticsService._format_date_for_query(now)).where('isDeleted', '==', False).order_by('date', direction=firestore.Query.ASCENDING)
            daily_expenses_map = {}
            for doc in expense_trend_query.stream():
                transaction = doc.to_dict(); tx_date_str = transaction.get('date'); amount = float(transaction.get('amount', 0.0))
                if tx_date_str: daily_expenses_map[tx_date_str] = daily_expenses_map.get(tx_date_str, 0.0) + amount
            
            expense_trend_7_days_list = []
            for i in range(7):
                day_dt = (now - timedelta(days=6)) + timedelta(days=i); day_str = AnalyticsService._format_date_for_query(day_dt)
                expense_trend_7_days_list.append({"date": day_str, "dailyExpense": round(daily_expenses_map.get(day_str, 0.0), 2)})

            dashboard_data = {
                "currentMonthIncomeExpense": income_expense_resp.get("analysis") if income_expense_resp.get("success") else None,
                "currentMonthExpenseByCategory": expense_summary_resp.get("summary", {}).get("byCategory") if expense_summary_resp.get("success") else None,
                "savingsBalance": savings_balance_data.get("balance") if savings_balance_data.get("success") else 0.0,
                "expenseTrend7Days": expense_trend_7_days_list,
                "budgetFeedback": budget_feedback_resp.get("feedbacks") if budget_feedback_resp.get("success") else [],
                "spendingTrend6m": spending_trend_resp.get("trend") if spending_trend_resp.get("success") else None,
            }
            return {"success": True, "dashboard": dashboard_data}, 200
        except Exception as e:
            print(f"Error compiling dashboard insights for {user_id}: {e}")
            traceback.print_exc()
            return {"success": False, "error": str(e)}, 500