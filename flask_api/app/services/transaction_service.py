# File: flask_api/app/services/transaction_service.py
from app.utils.firebase_config import db
from datetime import datetime, timezone
import traceback
from firebase_admin import firestore
from .balance_service import BalanceService
from .savings_service import SavingsService

class TransactionService:
    @staticmethod
    def _get_transaction_doc(transaction_id):
        if db is None: raise Exception("Firestore client not initialized.")
        return db.collection('transactions').document(transaction_id)

    @staticmethod
    def create_transaction(data):
        # ... (Existing create_transaction method - slightly refactored for clarity)
        # Ensure this method correctly calls BalanceService.update_balance_on_new_transaction
        # and SavingsService.create_savings_allocation as implemented in the previous step.
        # For brevity, assuming it's the version from "Okay, you're thinking ahead!" response.
        # Key part is that it returns the created transaction data including its new ID.
        try:
            if db is None: raise Exception("Firestore client (db) is not initialized.")

            required_fields = ['userId', 'type', 'category', 'amount', 'date', 'account']
            for field in required_fields:
                if field not in data or data[field] is None:
                    return {"success": False, "error": f"Missing required field: {field}"}, 400

            if data['type'] not in ['income', 'expense']:
                return {"success": False, "error": "Invalid transaction type"}, 400

            user_id = data['userId']
            transaction_type = data['type']
            transaction_amount = float(data['amount'])
            account_name = data['account'] 
            transaction_date_str = data['date'] 

            transaction_data_to_save = {
                'userId': user_id,
                'type': transaction_type,
                'category': data['category'],
                'subCategory': data.get('subCategory'),
                'amount': transaction_amount,
                'date': transaction_date_str,
                'account': account_name,
                'description': data.get('description', ''),
                'isRecurring': data.get('isRecurring', False),
                'recurrenceRule': data.get('recurrenceRule'),
                'isNeed': data.get('isNeed'), 
                'emotion': data.get('emotion'), 
                'isDeleted': False, # For soft delete
                'createdAt': datetime.now(timezone.utc).isoformat(),
                'updatedAt': datetime.now(timezone.utc).isoformat()
            }

            allocated_to_savings = 0.0
            if transaction_type == 'income':
                allocation_pct_raw = data.get('incomeAllocationPct')
                if allocation_pct_raw is not None:
                    try:
                        allocation_pct = int(allocation_pct_raw)
                        if not (0 <= allocation_pct <= 100):
                            raise ValueError("incomeAllocationPct must be between 0 and 100.")
                        transaction_data_to_save['incomeAllocationPct'] = allocation_pct
                        if allocation_pct > 0:
                            allocated_to_savings = round((transaction_amount * allocation_pct) / 100, 2)
                    except ValueError as ve:
                         return {"success": False, "error": str(ve)}, 400

            new_doc_ref = db.collection('transactions').document()
            new_doc_ref.set(transaction_data_to_save)
            transaction_id = new_doc_ref.id
            print(f"TRANSACTION_SERVICE: Main transaction doc created with ID {transaction_id}")

            BalanceService.update_balance_on_new_transaction(
                user_id, account_name, transaction_amount, transaction_type, allocated_to_savings
            )
            if transaction_type == 'income' and allocated_to_savings > 0:
                SavingsService.create_savings_allocation(
                    user_id, transaction_id, allocated_to_savings, transaction_date_str, source='auto'
                )

            created_transaction = transaction_data_to_save.copy()
            created_transaction['id'] = transaction_id
            return {"success": True, "message": "Transaction created and balances updated", "transaction": created_transaction}, 201
        except Exception as e:
            print(f"Error in create_transaction orchestrator: {e}")
            traceback.print_exc()
            return {"success": False, "error": f"An internal error occurred: {str(e)}"}, 500


    @staticmethod
    def update_transaction(transaction_id, user_id_from_auth, data_to_update):
        try:
            if db is None: raise Exception("Firestore client not initialized.")

            doc_ref = TransactionService._get_transaction_doc(transaction_id)
            transaction_snapshot = doc_ref.get()

            if not transaction_snapshot.exists:
                return {"success": False, "error": "Transaction not found"}, 404

            old_transaction_data = transaction_snapshot.to_dict()
            if old_transaction_data.get('userId') != user_id_from_auth:
                return {"success": False, "error": "User not authorized to update this transaction"}, 403
            if old_transaction_data.get('isDeleted', False):
                 return {"success": False, "error": "Cannot update a deleted transaction"}, 400


            # --- Revert old impacts ---
            old_amount = float(old_transaction_data.get('amount', 0))
            old_type = old_transaction_data.get('type')
            old_account_name = old_transaction_data.get('account')
            old_income_alloc_pct = old_transaction_data.get('incomeAllocationPct')
            old_allocated_to_savings = 0.0
            if old_type == 'income' and old_income_alloc_pct is not None and old_income_alloc_pct > 0:
                old_allocated_to_savings = round((old_amount * old_income_alloc_pct) / 100, 2)

            # Revert balance: add back expense, subtract income (net of savings)
            BalanceService.revert_transaction_impact(
                user_id_from_auth, old_account_name, old_amount, old_type, old_allocated_to_savings
            )
            # Revert savings
            if old_type == 'income' and old_allocated_to_savings > 0:
                SavingsService.delete_savings_allocation_by_transaction_id(user_id_from_auth, transaction_id, old_allocated_to_savings)

            # --- Prepare new data and apply new impacts ---
            new_transaction_data = old_transaction_data.copy() # Start with old, update specific fields

            # Fields that can be updated by user (from your architecture and current flow)
            allowed_update_fields = ['type', 'category', 'subCategory', 'amount', 'date', 'account', 
                                     'description', 'isRecurring', 'recurrenceRule', 
                                     'incomeAllocationPct', 'isNeed', 'emotion']

            for field in allowed_update_fields:
                if field in data_to_update:
                    new_transaction_data[field] = data_to_update[field]

            # Recalculate amount if string, ensure it's float
            if 'amount' in data_to_update:
                new_transaction_data['amount'] = float(data_to_update['amount'])

            new_transaction_data['updatedAt'] = datetime.now(timezone.utc).isoformat()
            # Ensure isDeleted is not accidentally set to true during an update
            new_transaction_data['isDeleted'] = False 


            new_amount = float(new_transaction_data.get('amount', 0))
            new_type = new_transaction_data.get('type')
            new_account_name = new_transaction_data.get('account')
            new_income_alloc_pct = new_transaction_data.get('incomeAllocationPct')
            new_allocated_to_savings = 0.0

            if new_type == 'income' and new_income_alloc_pct is not None:
                try:
                    new_income_alloc_pct = int(new_income_alloc_pct)
                    if not (0 <= new_income_alloc_pct <= 100):
                        raise ValueError("incomeAllocationPct must be between 0 and 100.")
                    new_transaction_data['incomeAllocationPct'] = new_income_alloc_pct # Store potentially corrected int
                    if new_income_alloc_pct > 0:
                        new_allocated_to_savings = round((new_amount * new_income_alloc_pct) / 100, 2)
                except ValueError as ve:
                    # If new alloc pct is invalid, revert changes and return error
                    BalanceService.update_balance_on_new_transaction(user_id_from_auth, old_account_name, old_amount, old_type, old_allocated_to_savings)
                    if old_type == 'income' and old_allocated_to_savings > 0:
                        SavingsService.create_savings_allocation(user_id_from_auth, transaction_id, old_allocated_to_savings, old_transaction_data.get('date'), source='auto')
                    return {"success": False, "error": str(ve)}, 400
            elif new_type == 'expense': # Ensure incomeAllocationPct is None for expenses
                new_transaction_data['incomeAllocationPct'] = None


            # Apply new balance impact
            BalanceService.update_balance_on_new_transaction(
                user_id_from_auth, new_account_name, new_amount, new_type, new_allocated_to_savings
            )
            # Apply new savings impact
            if new_type == 'income' and new_allocated_to_savings > 0:
                SavingsService.create_savings_allocation(
                    user_id_from_auth, transaction_id, new_allocated_to_savings, new_transaction_data.get('date'), source='auto'
                )

            doc_ref.set(new_transaction_data) # Update the document

            updated_transaction_with_id = new_transaction_data.copy()
            updated_transaction_with_id['id'] = transaction_id

            print(f"TRANSACTION_SERVICE: Transaction {transaction_id} updated successfully.")
            return {"success": True, "message": "Transaction updated", "transaction": updated_transaction_with_id}, 200

        except Exception as e:
            print(f"Error updating transaction {transaction_id}: {e}")
            traceback.print_exc()
            # Attempt to restore original financial impact if something went wrong after reverting
            # This is complex and ideally handled by a larger transaction scope or compensation logic
            # For now, we signal a general error.
            return {"success": False, "error": f"Internal error during update: {str(e)}"}, 500

    @staticmethod
    def delete_transaction(transaction_id, user_id_from_auth): # Soft delete
        try:
            if db is None: raise Exception("Firestore client not initialized.")
            doc_ref = TransactionService._get_transaction_doc(transaction_id)
            transaction_snapshot = doc_ref.get()

            if not transaction_snapshot.exists:
                return {"success": False, "error": "Transaction not found"}, 404

            transaction_data = transaction_snapshot.to_dict()
            if transaction_data.get('userId') != user_id_from_auth:
                return {"success": False, "error": "User not authorized to delete this transaction"}, 403

            if transaction_data.get('isDeleted', False):
                return {"success": True, "message": "Transaction already marked as deleted"}, 200


            # Revert financial impacts before marking as deleted
            amount = float(transaction_data.get('amount', 0))
            tx_type = transaction_data.get('type')
            account_name = transaction_data.get('account')
            income_alloc_pct = transaction_data.get('incomeAllocationPct')
            allocated_to_savings = 0.0
            if tx_type == 'income' and income_alloc_pct is not None and income_alloc_pct > 0:
                allocated_to_savings = round((amount * income_alloc_pct) / 100, 2)

            BalanceService.revert_transaction_impact(
                user_id_from_auth, account_name, amount, tx_type, allocated_to_savings
            )
            if tx_type == 'income' and allocated_to_savings > 0:
                SavingsService.delete_savings_allocation_by_transaction_id(user_id_from_auth, transaction_id, allocated_to_savings)

            # Soft delete
            doc_ref.update({
                'isDeleted': True,
                'updatedAt': datetime.now(timezone.utc).isoformat()
            })
            print(f"TRANSACTION_SERVICE: Transaction {transaction_id} soft deleted.")
            return {"success": True, "message": "Transaction deleted successfully"}, 200
        except Exception as e:
            print(f"Error deleting transaction {transaction_id}: {e}")
            traceback.print_exc()
            return {"success": False, "error": f"Internal error during deletion: {str(e)}"}, 500

    @staticmethod
    def list_transactions(user_id, start_date_str=None, end_date_str=None, transaction_type=None):
        try:
            if db is None: raise Exception("Firestore client not initialized.")
            query = db.collection('transactions').where('userId', '==', user_id).where('isDeleted', '==', False) # <-- ADDED isDeleted check

            if start_date_str:
                query = query.where('date', '>=', start_date_str)
            if end_date_str:
                query = query.where('date', '<=', end_date_str)
            if transaction_type and transaction_type in ['income', 'expense']:
                query = query.where('type', '==', transaction_type)

            query = query.order_by('date', direction=firestore.Query.DESCENDING)
            query = query.order_by('createdAt', direction=firestore.Query.DESCENDING)

            docs = query.stream()
            transactions_list = []
            for doc in docs:
                transaction_item = doc.to_dict()
                transaction_item['id'] = doc.id 
                transactions_list.append(transaction_item)

            print(f"Fetched {len(transactions_list)} non-deleted transactions for user {user_id}")
            return {"success": True, "transactions": transactions_list}, 200
        except Exception as e:
            print(f"Error listing transactions: {e}")
            traceback.print_exc()
            return {"success": False, "error": f"An internal error occurred: {str(e)}"}, 500