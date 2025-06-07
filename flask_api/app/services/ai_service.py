# flask_api/app/services/ai_service.py

from app.services.transaction_service import TransactionService
from datetime import datetime, timedelta

class AIService:

    @staticmethod
    def get_budget_recommendation(user_id, category):
        """
        Kullanıcının belirli bir kategorideki geçmiş harcamalarına dayanarak
        aylık bütçe önerisi hesaplar.
        """
        # Son 3 aylık veriyi analiz et
        today = datetime.now()
        three_months_ago = today - timedelta(days=90)

        # TransactionService'i kullanarak ilgili işlemleri al
        # Not: transaction_service'in get_transactions metodu bu filtrelemeyi desteklemelidir.
        try:
            transactions = TransactionService.get_transactions(
                user_id=user_id,
                start_date=three_months_ago.strftime('%Y-%m-%d'),
                end_date=today.strftime('%Y-%m-%d'),
                category=category,
                transaction_type='expense'
            )
        except Exception as e:
            # Hata durumunda veya servis henüz hazır değilse varsayılan bir mantık işletilebilir
            print(f"Error fetching transactions: {e}")
            transactions = []


        if not transactions:
            return {
                "suggestedBudget": 0.0,
                "rationale": "Bu kategori için son 3 ayda yeterli harcama verisi bulunamadı.",
                "transactionCount": 0
            }

        # Aylık harcamaları grupla
        monthly_expenses = {}
        for tx in transactions:
            month_year = tx['date'].strftime('%Y-%m')
            if month_year not in monthly_expenses:
                monthly_expenses[month_year] = 0.0
            monthly_expenses[month_year] += tx['amount']
        
        if not monthly_expenses:
            return {
                "suggestedBudget": 0.0,
                "rationale": "Bu kategori için harcama verisi bulunamadı.",
                "transactionCount": len(transactions)
            }

        # Ortalama aylık harcamayı hesapla
        total_expense = sum(monthly_expenses.values())
        average_monthly_expense = total_expense / len(monthly_expenses)

        # Önerilen bütçeye %15'lik bir güvenlik payı ekle
        safety_factor = 1.15
        suggested_budget = round(average_monthly_expense * safety_factor, 2)

        # Tutarı en yakın 10'un katına yuvarla
        suggested_budget = round(suggested_budget / 10) * 10

        return {
            "suggestedBudget": suggested_budget,
            "rationale": f"Son 3 aylık ortalama harcamanız ({round(average_monthly_expense, 2)} TL) baz alınarak, %15'lik pay ile bir öneri oluşturulmuştur.",
            "transactionCount": len(transactions)
        }