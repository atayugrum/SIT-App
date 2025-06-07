# File: flask_api/app/services/transaction_service.py
from app.utils.firebase_config import db
from datetime import datetime, timezone
import traceback
from firebase_admin import firestore
import uuid

from .balance_service import BalanceService
from .savings_service import SavingsService

class TransactionService:
    @staticmethod
    def list_transactions(user_id, start_date_str, end_date_str, type=None, account=None):
        try:
            if db is None: raise Exception("Firestore client (db) is not initialized.")
            transactions_ref = db.collection('transactions')
            query = transactions_ref.where('userId', '==', user_id).where('date', '>=', start_date_str).where('date', '<=', end_date_str)
            if type: query = query.where('type', '==', type)
            if account: query = query.where('account', '==', account)
            query = query.where('isDeleted', '==', False)
            query = query.order_by('date', direction=firestore.Query.DESCENDING).order_by('createdAt', direction=firestore.Query.DESCENDING)
            docs = query.stream()
            transactions_list = []
            for doc in docs:
                transaction_data = doc.to_dict(); transaction_data['id'] = doc.id
                transactions_list.append(transaction_data)
            print(f"Fetched {len(transactions_list)} non-deleted transactions for user {user_id}")
            return {"success": True, "transactions": transactions_list}, 200
        except Exception as e:
            print(f"Error listing transactions for user {user_id}: {e}"); traceback.print_exc()
            return {"success": False, "error": f"An internal error occurred: {str(e)}"}, 500

    @staticmethod
    def create_transaction(data):
        try:
            if db is None: raise Exception("Firestore client not initialized.")
            required_fields = ['userId', 'type', 'category', 'amount', 'date', 'account']
            for field in required_fields:
                if field not in data or data[field] is None:
                    return {"success": False, "error": f"Missing required field: {field}"}, 400
            
            doc_ref = db.collection('transactions').document()
            amount = float(data.get('amount', 0)); income_allocation_pct = data.get('incomeAllocationPct'); allocated_to_savings = 0.0
            if data.get('type') == 'income' and income_allocation_pct is not None and int(income_allocation_pct) > 0:
                allocated_to_savings = round(amount * (int(income_allocation_pct) / 100), 2)
            transaction_data = { 'userId': data['userId'], 'type': data['type'], 'category': data['category'], 'subCategory': data.get('subCategory'), 'amount': amount, 'date': data['date'], 'account': data['account'], 'description': data.get('description'), 'isRecurring': data.get('isRecurring', False), 'recurrenceRule': data.get('recurrenceRule'), 'isNeed': data.get('isNeed'), 'emotion': data.get('emotion'), 'incomeAllocationPct': income_allocation_pct if data.get('type') == 'income' else None, 'isDeleted': False, 'createdAt': datetime.now(timezone.utc).isoformat(), 'updatedAt': datetime.now(timezone.utc).isoformat() }
            doc_ref.set(transaction_data)
            print(f"TRANSACTION_SERVICE: Main transaction doc created with ID {doc_ref.id}")
            BalanceService.update_balance_on_new_transaction(data['account'], amount, data['type'], allocated_to_savings)
            if allocated_to_savings > 0:
                SavingsService.create_savings_allocation(user_id=data['userId'], transaction_id=doc_ref.id, amount=allocated_to_savings, date_str=data['date'], source='auto')
            transaction_data['id'] = doc_ref.id
            return {"success": True, "transaction": transaction_data}, 201
        except Exception as e:
            print(f"Error creating transaction: {e}"); traceback.print_exc()
            return {"success": False, "error": f"Internal server error: {str(e)}"}, 500
    
    @staticmethod
    def update_transaction(transaction_id, data):
        try:
            if db is None: raise Exception("Firestore client not initialized.")
            doc_ref = db.collection('transactions').document(transaction_id)
            existing_doc = doc_ref.get()
            if not existing_doc.exists: return {"success": False, "error": "Transaction not found"}, 404
            existing_data = existing_doc.to_dict()
            old_amount = existing_data.get('amount', 0.0); old_type = existing_data.get('type'); old_account = existing_data.get('account'); old_income_allocation_pct = existing_data.get('incomeAllocationPct')
            old_allocated_to_savings = 0.0
            if old_type == 'income' and old_income_allocation_pct is not None and int(old_income_allocation_pct) > 0:
                old_allocated_to_savings = round(old_amount * (int(old_income_allocation_pct) / 100), 2)
            new_amount = float(data.get('amount', old_amount)); new_type = data.get('type', old_type); new_account = data.get('account', old_account); new_income_allocation_pct = data.get('incomeAllocationPct')
            new_allocated_to_savings = 0.0
            if new_type == 'income' and new_income_allocation_pct is not None and int(new_income_allocation_pct) > 0:
                new_allocated_to_savings = round(new_amount * (int(new_income_allocation_pct) / 100), 2)
            update_payload = { 'type': new_type, 'category': data.get('category', existing_data.get('category')), 'subCategory': data.get('subCategory', existing_data.get('subCategory')), 'amount': new_amount, 'date': data.get('date', existing_data.get('date')), 'account': new_account, 'description': data.get('description', existing_data.get('description')), 'isRecurring': data.get('isRecurring', existing_data.get('isRecurring')), 'recurrenceRule': data.get('recurrenceRule', existing_data.get('recurrenceRule')), 'isNeed': data.get('isNeed', existing_data.get('isNeed')), 'emotion': data.get('emotion', existing_data.get('emotion')), 'incomeAllocationPct': new_income_allocation_pct if new_type == 'income' else None, 'updatedAt': datetime.now(timezone.utc).isoformat() }
            doc_ref.update(update_payload)
            print(f"TRANSACTION_SERVICE: Transaction {transaction_id} updated.")
            BalanceService.update_balance_on_update_transaction(old_account, old_amount, old_type, old_allocated_to_savings, new_account, new_amount, new_type, new_allocated_to_savings)
            SavingsService.update_or_delete_allocation_for_transaction(user_id=existing_data['userId'], transaction_id=transaction_id, new_allocated_amount=new_allocated_to_savings, new_date_str=data.get('date', existing_data.get('date')))
            updated_doc = doc_ref.get().to_dict(); updated_doc['id'] = doc_ref.id
            return {"success": True, "transaction": updated_doc}, 200
        except Exception as e:
            print(f"Error updating transaction {transaction_id}: {e}"); traceback.print_exc()
            return {"success": False, "error": f"Internal server error: {str(e)}"}, 500

    @staticmethod
    def delete_transaction(user_id, transaction_id):
        try:
            if db is None: raise Exception("Firestore client not initialized.")
            doc_ref = db.collection('transactions').document(transaction_id)
            doc = doc_ref.get()
            if not doc.exists: return {"success": False, "error": "Transaction not found"}, 404
            
            transaction_data = doc.to_dict()
            if transaction_data.get('userId') != user_id:
                 return {"success": False, "error": "User not authorized to delete this transaction"}, 403

            doc_ref.update({'isDeleted': True, 'updatedAt': datetime.now(timezone.utc).isoformat()})
            print(f"TRANSACTION_SERVICE: Transaction {transaction_id} marked as deleted.")
            
            amount = transaction_data.get('amount', 0.0); tx_type = transaction_data.get('type'); account = transaction_data.get('account'); income_allocation_pct = transaction_data.get('incomeAllocationPct')
            
            allocated_to_savings = 0.0
            if tx_type == 'income' and income_allocation_pct is not None and int(income_allocation_pct) > 0:
                allocated_to_savings = round(amount * (int(income_allocation_pct) / 100), 2)
            
            # ------> DÜZELTME BURADA <------
            # Artık var olan doğru metodu çağırıyoruz.
            BalanceService.update_balance_on_delete_transaction(account, amount, tx_type, allocated_to_savings)
            
            if allocated_to_savings > 0:
                SavingsService.delete_savings_allocation_by_transaction_id(user_id, transaction_id, allocated_to_savings)

            return {"success": True, "message": "Transaction deleted successfully."}, 200
        except Exception as e:
            print(f"Error deleting transaction {transaction_id}: {e}"); traceback.print_exc()
            return {"success": False, "error": f"Internal server error: {str(e)}"}, 500