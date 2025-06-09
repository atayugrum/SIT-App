# File: flask_api/app/services/transaction_service.py

from app.utils.firebase_config import db
from datetime import datetime, timezone
import traceback
from firebase_admin import firestore
from google.cloud.firestore_v1.base_query import FieldFilter
import uuid

# Diğer servislerle etkileşim için import ediyoruz
from .balance_service import BalanceService
from .savings_service import SavingsService


class TransactionService:
    @staticmethod
    def list_transactions(user_id, start_date_str, end_date_str, type=None, account=None):
        """
        Belirtilen tarih aralığında ve opsiyonel filtrelerle işlemleri listeler.
        Silinmemiş (isDeleted=False) kayıtları getirir.
        """
        try:
            if db is None:
                raise Exception("Firestore client (db) is not initialized.")

            transactions_ref = db.collection('transactions')
            # Temel filtreler
            query = (
                transactions_ref
                .where(filter=FieldFilter('userId', '==', user_id))
                .where(filter=FieldFilter('date', '>=', start_date_str))
                .where(filter=FieldFilter('date', '<=', end_date_str))
                .where(filter=FieldFilter('isDeleted', '==', False))
            )

            # Opsiyonel filtreler
            if type:
                query = query.where(filter=FieldFilter('type', '==', type))
            if account:
                query = query.where(filter=FieldFilter('account', '==', account))

            # Sıralama
            query = query.order_by('date', direction=firestore.Query.DESCENDING).order_by('createdAt', direction=firestore.Query.DESCENDING)
            
            docs = list(query.stream())
            transactions_list = []
            for doc in docs:
                data = doc.to_dict()
                data['id'] = doc.id
                transactions_list.append(data)

            print(f"Fetched {len(transactions_list)} non-deleted transactions for user {user_id}")
            return {"success": True, "transactions": transactions_list}, 200

        except Exception as e:
            print(f"Error listing transactions for user {user_id}: {e}")
            traceback.print_exc()
            return {"success": False, "error": f"An internal error occurred: {str(e)}"}, 500

    @staticmethod
    def create_transaction(data):
        """
        Yeni bir gelir/gider işlemi oluşturur ve ilgili servisleri tetikler.
        """
        try:
            required_fields = ['userId', 'type', 'category', 'amount', 'date', 'account']
            for field in required_fields:
                if field not in data or data[field] is None:
                    return {"success": False, "error": f"Missing required field: {field}"}, 400

            doc_ref = db.collection('transactions').document()
            amount = float(data.get('amount', 0.0))
            income_allocation_pct = data.get('incomeAllocationPct')
            allocated_to_savings = 0.0

            if data['type'] == 'income' and income_allocation_pct is not None and int(income_allocation_pct) > 0:
                allocated_to_savings = round(amount * (int(income_allocation_pct) / 100), 2)

            transaction_data = data.copy()
            transaction_data.update({
                'isDeleted': False,
                'createdAt': datetime.now(timezone.utc).isoformat(),
                'updatedAt': datetime.now(timezone.utc).isoformat()
            })
            doc_ref.set(transaction_data)
            print(f"TRANSACTION_SERVICE: Created transaction with ID {doc_ref.id}")

            BalanceService.update_balance_on_new_transaction(
                user_id=data['userId'],
                account_name=data['account'],
                amount=amount,
                transaction_type=data['type'],
                allocated_to_savings=allocated_to_savings
            )
            
            if allocated_to_savings > 0:
                SavingsService.create_savings_allocation(
                    user_id=data['userId'], transaction_id=doc_ref.id,
                    amount=allocated_to_savings, date_str=data['date']
                )

            transaction_data['id'] = doc_ref.id
            return {"success": True, "transaction": transaction_data}, 201

        except Exception as e:
            traceback.print_exc()
            return {"success": False, "error": f"Internal server error: {str(e)}"}, 500

    @staticmethod
    def update_transaction(transaction_id, data):
        """
        Mevcut işlemi günceller; BalanceService ve SavingsService metotlarını çağırır.
        """
        try:
            doc_ref = db.collection('transactions').document(transaction_id)
            existing_doc = doc_ref.get()
            if not existing_doc.exists:
                return {"success": False, "error": "Transaction not found"}, 404

            old_data = existing_doc.to_dict()
            user_id = old_data.get('userId')

            # 1. ESKİ İŞLEMİN ETKİLERİNİ GERİ AL
            BalanceService._revert_transaction_effect(user_id, old_data)
            if old_data.get('type') == 'income' and old_data.get('incomeAllocationPct', 0) > 0:
                SavingsService.delete_savings_allocation_by_transaction_id(user_id, transaction_id)
            
            # 2. YENİ VERİYİ OLUŞTUR VE KAYDET
            new_amount = float(data.get('amount', old_data.get('amount')))
            new_type = data.get('type', old_data.get('type'))
            new_income_pct = data.get('incomeAllocationPct', old_data.get('incomeAllocationPct'))

            new_allocated = 0.0
            if new_type == 'income' and new_income_pct is not None and int(new_income_pct) > 0:
                new_allocated = round(new_amount * (int(new_income_pct) / 100), 2)
            
            update_payload = old_data.copy()
            update_payload.update(data)
            update_payload['updatedAt'] = datetime.now(timezone.utc).isoformat()
            
            doc_ref.update(update_payload)
            
            # 3. YENİ İŞLEMİN ETKİLERİNİ UYGULA
            new_data = doc_ref.get().to_dict()
            BalanceService._apply_transaction_effect(user_id, new_data)

            if new_allocated > 0:
                # Not: Bu basitçe yenisini oluşturur. Daha karmaşık senaryoda update mantığı gerekir.
                SavingsService.create_savings_allocation(
                    user_id=user_id, transaction_id=transaction_id,
                    amount=new_allocated, date_str=new_data.get('date')
                )
            
            updated_doc = doc_ref.get().to_dict()
            updated_doc['id'] = transaction_id
            return {"success": True, "transaction": updated_doc}, 200

        except Exception as e:
            traceback.print_exc()
            return {"success": False, "error": f"Internal server error: {str(e)}"}, 500

    @staticmethod
    def delete_transaction(user_id, transaction_id):
        """
        Bir işlemi silinmiş olarak işaretler ve ilgili servisleri tetikler.
        """
        try:
            doc_ref = db.collection('transactions').document(transaction_id)
            doc = doc_ref.get()
            if not doc.exists: return {"success": False, "error": "Transaction not found"}, 404
            
            txn = doc.to_dict()
            if txn.get('userId') != user_id: return {"success": False, "error": "Not authorized"}, 403
            if txn.get('isDeleted') == True: return {"success": True, "message": "Transaction already deleted."}, 200

            # 1. Bakiyeleri ve tasarrufları geri al
            BalanceService._revert_transaction_effect(user_id, txn)
            if txn.get('type') == 'income' and txn.get('incomeAllocationPct', 0) > 0:
                SavingsService.delete_savings_allocation_by_transaction_id(user_id, transaction_id)

            # 2. İşlemi silinmiş olarak işaretle
            doc_ref.update({'isDeleted': True, 'updatedAt': datetime.now(timezone.utc).isoformat()})
            
            return {"success": True, "message": "Transaction deleted successfully."}, 200

        except Exception as e:
            traceback.print_exc()
            return {"success": False, "error": f"Internal server error: {str(e)}"}, 500