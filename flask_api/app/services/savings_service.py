# File: flask_api/app/services/savings_service.py
from app.utils.firebase_config import db
from datetime import datetime, timezone
import traceback
from firebase_admin import firestore 

class SavingsService:
    @staticmethod
    def _update_total_savings_balance(user_id, amount_delta):
        if db is None: raise Exception("Firestore client not initialized.")
        user_savings_ref = db.collection('user_savings_balances').document(user_id)

        @firestore.transactional
        def update_in_tx(transaction, doc_ref, delta):
            snapshot = doc_ref.get(transaction=transaction)
            current_total = 0
            if snapshot.exists:
                current_total = snapshot.to_dict().get('totalSavingsBalance', 0.0)

            new_balance = current_total + delta
            payload = {
                'totalSavingsBalance': new_balance,
                'updatedAt': datetime.now(timezone.utc).isoformat()
            }
            if not snapshot.exists: 
                payload['userId'] = user_id # Ensure userId if creating new

            transaction.set(doc_ref, payload, merge=True) 

        transaction_obj = db.transaction() # Corrected: use db.transaction()
        update_in_tx(transaction_obj, user_savings_ref, amount_delta)
        print(f"SAVINGS_SERVICE: User {user_id} total savings balance updated by {amount_delta}.")


    @staticmethod
    def create_savings_allocation(user_id, transaction_id, amount, date_str, source='auto'):
        try:
            if db is None: raise Exception("Firestore client not initialized.")
            if amount <= 0 and source == 'manual': # Auto allocations can be 0 if pct is 0 then rounded
                print("SAVINGS_SERVICE: Manual allocation amount must be positive.")
                # For auto, an allocation_pct of 0 might still call this with amount 0, which is fine (no record)
                # but for manual entry, enforce positive.
                if source == 'manual':
                     return {"success": False, "message": "Manual savings amount must be positive."}

            if amount <= 0 and source == 'auto': # Don't create a record for 0 allocation from auto
                print("SAVINGS_SERVICE: Auto allocation amount is 0 or less. No record created.")
                return {"success": True, "message": "No savings allocation created, amount was zero or less."}


            print(f"SAVINGS_SERVICE: Creating {source} allocation for user {user_id}, tx_id: {transaction_id}, amount: {amount}, date: {date_str}")

            allocation_doc_ref = db.collection('savings_allocations').document() # Auto-generate ID
            allocation_data = {
                'userId': user_id,
                'transactionId': transaction_id, # Can be null for manual
                'amount': float(amount),
                'date': date_str, 
                'source': source,
                'createdAt': datetime.now(timezone.utc).isoformat()
            }
            allocation_doc_ref.set(allocation_data)
            SavingsService._update_total_savings_balance(user_id, float(amount))

            created_allocation = allocation_data.copy()
            created_allocation['id'] = allocation_doc_ref.id
            print(f"SAVINGS_SERVICE: {source} savings allocation created (ID: {allocation_doc_ref.id}) and total balance updated for user {user_id}.")
            return {"success": True, "message": f"{source.capitalize()} savings allocation created.", "allocation": created_allocation}
        except Exception as e:
            print(f"SAVINGS_SERVICE: Error creating {source} savings allocation for {user_id}, tx {transaction_id}: {e}")
            traceback.print_exc()
            raise 

    @staticmethod
    def delete_savings_allocation_by_transaction_id(user_id, transaction_id, amount_to_revert_from_balance):
        try:
            if db is None: raise Exception("Firestore client not initialized.")
            alloc_query = db.collection('savings_allocations').where('userId', '==', user_id).where('transactionId', '==', transaction_id)
            alloc_docs = list(alloc_query.stream())

            if not alloc_docs:
                print(f"SAVINGS_SERVICE: No 'auto' savings allocation found for user {user_id}, tx {transaction_id} to delete.")
                return {"success": True, "message": "No relevant auto savings allocation to delete."}

            deleted_count = 0
            for doc in alloc_docs:
                print(f"SAVINGS_SERVICE: Deleting savings allocation doc {doc.id} for tx {transaction_id}")
                doc.reference.delete()
                deleted_count +=1

            if deleted_count > 0:
                SavingsService._update_total_savings_balance(user_id, -float(amount_to_revert_from_balance))
            return {"success": True, "message": f"{deleted_count} auto allocations deleted."}
        except Exception as e:
            print(f"SAVINGS_SERVICE: Error deleting auto savings allocations for tx {transaction_id}: {e}")
            traceback.print_exc()
            raise

    # Methods for routes (could be more DRY with helper for queries)
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
            updated_at_str = data.get('updatedAt')
            if updated_at_str: # Ensure updatedAt is a string for JSON response
                updated_at = updated_at_str 
        return {"success": True, "balance": balance, "updatedAt": updated_at}

    @staticmethod
    def get_user_savings_allocations(user_id, start_date_str=None, end_date_str=None, source_filter=None):
        if db is None: raise Exception("Firestore client not initialized.")
        query = db.collection('savings_allocations').where('userId', '==', user_id)
        if start_date_str:
            query = query.where('date', '>=', start_date_str)
        if end_date_str:
            query = query.where('date', '<=', end_date_str)
        if source_filter and source_filter in ['auto', 'manual']:
            query = query.where('source', '==', source_filter)

        query = query.order_by('date', direction=firestore.Query.DESCENDING)
        query = query.order_by('createdAt', direction=firestore.Query.DESCENDING)

        docs = query.stream()
        allocations_list = [{'id': doc.id, **doc.to_dict()} for doc in docs]
        return {"success": True, "allocations": allocations_list}