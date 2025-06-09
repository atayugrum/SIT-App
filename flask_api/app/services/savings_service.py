# File: flask_api/app/services/savings_service.py
from app.utils.firebase_config import db
from datetime import datetime, timezone
import traceback
from firebase_admin import firestore 
import uuid

# Yetersiz bakiye durumu için özel hata sınıfı
class InsufficientFundsError(Exception):
    """Yetersiz bakiye durumu için özel hata sınıfı."""
    pass

class SavingsService:
    @staticmethod
    def _update_total_savings_balance(user_id, amount_delta):
        user_savings_ref = db.collection('user_savings_balances').document(user_id)
        # Atomik artırma/azaltma işlemi
        user_savings_ref.set({
            'totalSavingsBalance': firestore.Increment(amount_delta),
            'updatedAt': datetime.now(timezone.utc).isoformat()
        }, merge=True)
        print(f"SAVINGS_SERVICE: User {user_id} total savings balance updated by {amount_delta}.")

    @staticmethod
    def create_savings_allocation(user_id, transaction_id, amount, date_str):
        try:
            if amount <= 0: return
            allocation_doc_ref = db.collection('savings_allocations').document()
            allocation_data = {
                'userId': user_id, 'transactionId': transaction_id, 'amount': float(amount),
                'date': date_str, 'source': 'auto', 'createdAt': datetime.now(timezone.utc).isoformat()
            }
            allocation_doc_ref.set(allocation_data)
            SavingsService._update_total_savings_balance(user_id, float(amount))
            print(f"SAVINGS_SERVICE: Auto savings allocation created for tx {transaction_id}.")
        except Exception as e:
            print(f"SAVINGS_SERVICE: Error creating auto savings allocation: {e}")
            raise

    @staticmethod
    def delete_savings_allocation_by_transaction_id(user_id, transaction_id):
        try:
            alloc_query = db.collection('savings_allocations').where('userId', '==', user_id).where('transactionId', '==', transaction_id)
            alloc_docs = list(alloc_query.stream())
            if not alloc_docs: return
            
            amount_to_revert = alloc_docs[0].to_dict().get('amount', 0.0)
            alloc_docs[0].reference.delete()
            
            if amount_to_revert > 0:
                SavingsService._update_total_savings_balance(user_id, -float(amount_to_revert))
            print(f"SAVINGS_SERVICE: Deleted savings allocation for tx {transaction_id}.")
        except Exception as e:
            traceback.print_exc()
            raise

    @staticmethod
    def update_or_delete_allocation_for_transaction(user_id, transaction_id, new_allocated_amount, new_date_str):
        """
        Bir işlem güncellendiğinde, ona bağlı tasarruf kaydını günceller, oluşturur veya siler.
        """
        try:
            alloc_query = db.collection('savings_allocations').where('transactionId', '==', transaction_id).limit(1)
            existing_alloc_docs = list(alloc_query.stream())
            
            old_allocated_amount = 0.0
            existing_alloc_ref = None

            if existing_alloc_docs:
                existing_alloc_ref = existing_alloc_docs[0].reference
                old_allocated_amount = existing_alloc_docs[0].to_dict().get('amount', 0.0)

            delta = new_allocated_amount - old_allocated_amount

            if delta == 0 and not existing_alloc_ref: return # Değişiklik yok ve kayıt da yok

            if new_allocated_amount > 0:
                if existing_alloc_ref: # Kayıt varsa güncelle
                    existing_alloc_ref.update({'amount': new_allocated_amount, 'date': new_date_str})
                else: # Kayıt yoksa oluştur
                    SavingsService.create_savings_allocation(user_id, transaction_id, new_allocated_amount, new_date_str)
                    return # Bakiye zaten create içinde güncellendiği için çık
            elif existing_alloc_ref: # Yeni alokasyon 0 veya daha azsa ve eskiden kayıt varsa, sil
                existing_alloc_ref.delete()

            # Toplam kumbara bakiyesini fark kadar güncelle
            if delta != 0:
                SavingsService._update_total_savings_balance(user_id, delta)

        except Exception as e:
            print(f"SAVINGS_SERVICE: Error updating allocation for tx {transaction_id}: {e}")
            traceback.print_exc()
            raise

    @staticmethod
    def get_user_savings_balance(user_id):
        if db is None: raise Exception("Firestore client not initialized.")
        user_savings_ref = db.collection('user_savings_balances').document(user_id)
        snapshot = user_savings_ref.get()
        balance = 0.0
        updated_at = None
        if snapshot.exists:
            data = snapshot.to_dict()
            balance = data.get('totalSavingsBalance', 0.0)
            updated_at = data.get('updatedAt')
        return {"success": True, "balance": balance, "updatedAt": updated_at}

    @staticmethod
    def get_user_savings_allocations(user_id, start_date_str=None, end_date_str=None, source_filter=None):
        if db is None: raise Exception("Firestore client not initialized.")
        query = db.collection('savings_allocations').where('userId', '==', user_id)
        if start_date_str: query = query.where('date', '>=', start_date_str)
        if end_date_str: query = query.where('date', '<=', end_date_str)
        if source_filter and source_filter in ['auto', 'manual']: query = query.where('source', '==', source_filter)
        query = query.order_by('date', direction=firestore.Query.DESCENDING).order_by('createdAt', direction=firestore.Query.DESCENDING)
        docs = query.stream()
        allocations_list = [{'id': doc.id, **doc.to_dict()} for doc in docs]
        return {"success": True, "allocations": allocations_list}

    # =========================================================
    # TASARRUF HEDEFLERİ METOTLARI
    # =========================================================

    @staticmethod
    def _get_goals_collection_ref():
        if db is None: raise Exception("Firestore client not initialized.")
        return db.collection('savings_goals')

    @staticmethod
    def create_goal(data):
        try:
            goals_ref = SavingsService._get_goals_collection_ref()
            required_fields = ['userId', 'title', 'targetAmount', 'targetDate']
            for field in required_fields:
                if field not in data or not data[field]:
                    return {"success": False, "error": f"Missing required field: {field}"}, 400
            
            goal_data = {
                'userId': data['userId'],
                'title': data['title'],
                'targetAmount': float(data['targetAmount']),
                'currentAmount': 0.0,
                'targetDate': data['targetDate'],
                'isActive': True,
                'createdAt': datetime.now(timezone.utc).isoformat()
            }
            doc_ref = goals_ref.document()
            doc_ref.set(goal_data)
            created_goal = goal_data.copy()
            created_goal['id'] = doc_ref.id
            return {"success": True, "goal": created_goal}, 201
        except Exception as e:
            traceback.print_exc()
            return {"success": False, "error": str(e)}, 500

    @staticmethod
    def list_goals(user_id):
        try:
            goals_ref = SavingsService._get_goals_collection_ref()
            query = goals_ref.where('userId', '==', user_id).where('isActive', '==', True)
            query = query.order_by('targetDate', direction=firestore.Query.ASCENDING)
            docs = query.stream()
            goals_list = [{'id': doc.id, **doc.to_dict()} for doc in docs]
            return {"success": True, "goals": goals_list}, 200
        except Exception as e:
            traceback.print_exc()
            return {"success": False, "error": str(e)}, 500

    @staticmethod
    def delete_goal(user_id, goal_id):
        try:
            goal_ref = SavingsService._get_goals_collection_ref().document(goal_id)
            savings_balance_ref = db.collection('user_savings_balances').document(user_id)

            @firestore.transactional
            def delete_in_tx(transaction, goal_doc_ref, balance_doc_ref):
                goal_snapshot = goal_doc_ref.get(transaction=transaction)
                if not goal_snapshot.exists or goal_snapshot.to_dict().get('userId') != user_id:
                    raise Exception("Goal not found or user not authorized.")
                
                amount_to_return = goal_snapshot.to_dict().get('currentAmount', 0.0)
                
                if amount_to_return > 0:
                    balance_snapshot = balance_doc_ref.get(transaction=transaction)
                    current_total = balance_snapshot.to_dict().get('totalSavingsBalance', 0.0) if balance_snapshot.exists else 0.0
                    new_balance = current_total + amount_to_return
                    transaction.set(balance_doc_ref, {'totalSavingsBalance': new_balance, 'updatedAt': datetime.now(timezone.utc).isoformat()}, merge=True)
                
                transaction.delete(goal_doc_ref)

            transaction_obj = db.transaction()
            delete_in_tx(transaction_obj, goal_ref, savings_balance_ref)
            return {"success": True, "message": "Goal deleted and funds returned to main savings."}, 200
        except Exception as e:
            traceback.print_exc()
            return {"success": False, "error": str(e)}, 500

    @staticmethod
    def allocate_to_goal(user_id, goal_id, amount):
        try:
            if float(amount) <= 0:
                return {"success": False, "error": "Allocation amount must be positive."}, 400
            
            goal_ref = SavingsService._get_goals_collection_ref().document(goal_id)
            savings_balance_ref = db.collection('user_savings_balances').document(user_id)

            @firestore.transactional
            def allocate_in_tx(transaction, goal_doc_ref, balance_doc_ref, alloc_amount):
                balance_snapshot = balance_doc_ref.get(transaction=transaction)
                goal_snapshot = goal_doc_ref.get(transaction=transaction)

                if not goal_snapshot.exists or goal_snapshot.to_dict().get('userId') != user_id:
                    raise Exception("Goal not found or user not authorized.")

                main_balance = balance_snapshot.to_dict().get('totalSavingsBalance', 0.0) if balance_snapshot.exists else 0.0
                
                if main_balance < alloc_amount:
                    raise InsufficientFundsError(f"Insufficient funds in main savings. Required: {alloc_amount}, Available: {main_balance}")
                
                new_main_balance = main_balance - alloc_amount
                transaction.set(balance_doc_ref, {'totalSavingsBalance': new_main_balance, 'updatedAt': datetime.now(timezone.utc).isoformat()}, merge=True)
                
                transaction.update(goal_doc_ref, {
                    'currentAmount': firestore.Increment(alloc_amount),
                    'updatedAt': datetime.now(timezone.utc).isoformat()
                })
            
            transaction_obj = db.transaction()
            allocate_in_tx(transaction_obj, goal_ref, savings_balance_ref, float(amount))
            return {"success": True, "message": f"Successfully allocated {amount} to goal {goal_id}."}, 200
        
        except InsufficientFundsError as e:
            print(f"SAVINGS_SERVICE: Insufficient funds for user {user_id}: {e}")
            return {"success": False, "error": str(e)}, 400
        except Exception as e:
            traceback.print_exc()
            return {"success": False, "error": str(e)}, 500