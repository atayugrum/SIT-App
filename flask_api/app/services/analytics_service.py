# File: flask_api/app/services/analytics_service.py
from app.utils.firebase_config import db
from datetime import datetime, timezone, timedelta
from google.cloud.firestore_v1.base_query import FieldFilter
import traceback
import pandas as pd

class AnalyticsService:
    @staticmethod
    def get_dashboard_insights(user_id, days=30):
        """
        Dashboard için gerekli tüm analizleri tek seferde hesaplar ve döndürür.
        - Gelir/Gider Özeti
        - İstek/İhtiyaç Dağılımı
        - Duyguya Göre Harcama Dağılımı
        - Kategoriye Göre Harcama Dağılımı (Pasta Grafik için)
        - Son 7 Günlük Harcama Trendi (Çizgi Grafik için)
        """
        try:
            # Zaman aralığını belirle
            end_date = datetime.now(timezone.utc)
            start_date = end_date - timedelta(days=days)
            start_date_iso = start_date.isoformat()
            end_date_iso = end_date.isoformat()

            # İlgili harcama işlemlerini Firestore'dan tek seferde çek
            transactions_ref = db.collection('transactions')
            query = (transactions_ref
                     .where(filter=FieldFilter("userId", "==", user_id))
                     .where(filter=FieldFilter("date", ">=", start_date_iso))
                     .where(filter=FieldFilter("date", "<=", end_date_iso))
                     .where(filter=FieldFilter("isDeleted", "==", False)))
            
            docs = list(query.stream())

            # Değişkenleri başlat
            income_total = 0.0
            expense_total = 0.0
            needs_total = 0.0
            wants_total = 0.0
            spending_by_emotion = {}
            spending_by_category = {}
            daily_expenses = {}

            # Tüm işlemleri tek döngüde işle
            for doc in docs:
                transaction = doc.to_dict()
                amount = float(transaction.get("amount", 0.0))
                tx_type = transaction.get("type")

                if tx_type == 'income':
                    income_total += amount
                elif tx_type == 'expense':
                    expense_total += amount
                    
                    # İstek/İhtiyaç analizi
                    if transaction.get("isNeed", True):
                        needs_total += amount
                    else:
                        wants_total += amount

                    # Duygu analizi
                    emotion = transaction.get("emotion", "Nötr")
                    if emotion:
                        spending_by_emotion[emotion] = spending_by_emotion.get(emotion, 0.0) + amount

                    # Kategori analizi
                    category = transaction.get("category", "Diğer")
                    spending_by_category[category] = spending_by_category.get(category, 0.0) + amount

            # Son 7 günlük trend için veriyi işle
            seven_days_ago = end_date - timedelta(days=6)
            seven_days_iso = seven_days_ago.isoformat()
            for doc in docs:
                transaction = doc.to_dict()
                tx_date_str = transaction.get('date', '')
                if transaction.get('type') == 'expense' and tx_date_str >= seven_days_iso:
                    day_only = tx_date_str.split('T')[0]
                    daily_expenses[day_only] = daily_expenses.get(day_only, 0.0) + float(transaction.get('amount', 0.0))
            
            expense_trend_7_days = []
            for i in range(7):
                day = seven_days_ago.date() + timedelta(days=i)
                day_str = day.isoformat()
                expense_trend_7_days.append({"date": day_str, "amount": round(daily_expenses.get(day_str, 0.0), 2)})

            # Sonuçları formatla
            emotion_summary_list = [{"emotion": k, "totalAmount": round(v, 2)} for k, v in spending_by_emotion.items()]
            emotion_summary_list.sort(key=lambda x: x['totalAmount'], reverse=True)

            category_summary_list = [{"category": k, "totalAmount": round(v, 2)} for k, v in spending_by_category.items()]
            category_summary_list.sort(key=lambda x: x['totalAmount'], reverse=True)

            dashboard_data = {
                "incomeExpenseSummary": {
                    "incomeTotal": round(income_total, 2),
                    "expenseTotal": round(expense_total, 2),
                    "net": round(income_total - expense_total, 2),
                },
                "needsVsWantsSummary": {
                    "needsTotal": round(needs_total, 2),
                    "wantsTotal": round(wants_total, 2),
                },
                "emotionSummary": emotion_summary_list,
                "categorySummary": category_summary_list,
                "expenseTrend7Days": expense_trend_7_days,
            }

            return {"success": True, "dashboard": dashboard_data}, 200

        except Exception as e:
            print(f"Error in get_dashboard_insights: {e}")
            traceback.print_exc()
            return {"success": False, "error": str(e)}, 500