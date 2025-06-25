# File: flask_api/app/services/budget_service.py
from app.utils.firebase_config import db
from datetime import datetime, timezone, timedelta
import traceback
from firebase_admin import firestore
from google.cloud.firestore_v1.base_query import FieldFilter
import uuid

class BudgetService:
    @staticmethod
    def _get_budget_collection_ref():
        return db.collection('budgets')

    @staticmethod
    def list_budgets(user_id, year=None, month=None):
        try:
            budgets_ref = BudgetService._get_budget_collection_ref()
            
            current_time = datetime.now(timezone.utc)
            target_year = year if year is not None else current_time.year
            target_month = month if month is not None else current_time.month

            query = budgets_ref.where(filter=FieldFilter('userId', '==', user_id)) \
                               .where(filter=FieldFilter('year', '==', int(target_year))) \
                               .where(filter=FieldFilter('month', '==', int(target_month)))
            
            docs = query.stream()
            budgets_list = [{'id': doc.id, **doc.to_dict()} for doc in docs]

            # GÜNCELLEME: Her bütçe için o aydaki toplam harcamayı hesapla ve ekle
            transactions_ref = db.collection('transactions')
            for budget in budgets_list:
                start_of_month_str = datetime(target_year, target_month, 1).strftime('%Y-%m-%d')
                
                # Ayın son gününü doğru hesaplamak için bir sonraki ayın başından bir gün çıkar
                if target_month == 12:
                    end_of_month_dt = datetime(target_year + 1, 1, 1) - timedelta(days=1)
                else:
                    end_of_month_dt = datetime(target_year, target_month + 1, 1) - timedelta(days=1)
                
                end_of_month_str = end_of_month_dt.strftime('%Y-%m-%d')
                
                tx_query = transactions_ref.where(filter=FieldFilter('userId', '==', user_id)) \
                                           .where(filter=FieldFilter('category', '==', budget['category'])) \
                                           .where(filter=FieldFilter('type', '==', 'expense')) \
                                           .where(filter=FieldFilter('date', '>=', start_of_month_str)) \
                                           .where(filter=FieldFilter('date', '<=', end_of_month_str)) \
                                           .where(filter=FieldFilter('isDeleted', '==', False))
                
                spent_amount = sum(tx.to_dict().get('amount', 0.0) for tx in tx_query.stream())
                budget['spentAmount'] = spent_amount

            print(f"Fetched and calculated spending for {len(budgets_list)} budgets for user {user_id} for {target_year}-{target_month}")
            return {"success": True, "budgets": budgets_list}, 200

        except Exception as e:
            traceback.print_exc()
            return {"success": False, "error": f"An internal error occurred: {str(e)}" }, 500

    @staticmethod
    def create_or_update_budget(data):
        try:
            budgets_ref = BudgetService._get_budget_collection_ref()
            required_fields = ['userId', 'category', 'limitAmount']
            if not all(field in data and data[field] is not None for field in required_fields):
                return {"success": False, "error": f"Zorunlu alanlar eksik: {required_fields}"}, 400

            user_id, category, limit_amount = data['userId'], data['category'], float(data['limitAmount'])
            current_time = datetime.now(timezone.utc)
            year, month = data.get('year', current_time.year), data.get('month', current_time.month)

            query = budgets_ref.where('userId', '==', user_id).where('category', '==', category).where('year', '==', int(year)).where('month', '==', int(month)).limit(1)
            existing_docs = list(query.stream())

            budget_payload = {
                'userId': user_id, 'category': category, 'limitAmount': limit_amount,
                'period': data.get('period', 'monthly'), 'isAuto': data.get('isAuto', False),
                'year': int(year), 'month': int(month),
                'updatedAt': datetime.now(timezone.utc).isoformat()
            }

            if existing_docs:
                doc_ref = existing_docs[0].reference
                doc_ref.update(budget_payload)
                budget_id, message, status_code = doc_ref.id, "Bütçe başarıyla güncellendi", 200
            else:
                budget_id = data.get('id') or str(uuid.uuid4())
                doc_ref = budgets_ref.document(budget_id)
                budget_payload['createdAt'] = datetime.now(timezone.utc).isoformat()
                doc_ref.set(budget_payload)
                message, status_code = "Bütçe başarıyla oluşturuldu", 201
            
            final_doc = doc_ref.get().to_dict()
            final_doc['id'] = budget_id
            return {"success": True, "message": message, "budget": final_doc}, status_code
        except Exception as e:
            traceback.print_exc()
            return {"success": False, "error": f"Bir iç sunucu hatası oluştu: {str(e)}"}, 500

    @staticmethod
    def delete_budget(user_id_from_auth, budget_id):
        try:
            doc_ref = BudgetService._get_budget_collection_ref().document(budget_id)
            budget_snapshot = doc_ref.get()
            if not budget_snapshot.exists: return {"success": False, "error": "Bütçe bulunamadı"}, 404
            if budget_snapshot.to_dict().get('userId') != user_id_from_auth: return {"success": False, "error": "Yetkisiz işlem"}, 403
            
            doc_ref.delete()
            return {"success": True, "message": "Bütçe başarıyla silindi"}, 200
        except Exception as e:
            traceback.print_exc()
            return {"success": False, "error": f"Silme sırasında iç sunucu hatası: {str(e)}"}, 500