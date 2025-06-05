# File: flask_api/app/services/balance_service.py
from app.utils.firebase_config import db
from datetime import datetime, timezone
import traceback
from firebase_admin import firestore 

class BalanceService:
    @staticmethod
    def _get_account_ref(user_id, account_name):
        if db is None: raise Exception("Firestore client (db) is not initialized.")
        accounts_ref = db.collection('user_accounts')
        query = accounts_ref.where('userId', '==', user_id).where('accountName', '==', account_name).limit(1)
        account_docs = list(query.stream())
        if not account_docs:
            # Consider creating account if not exists, or stricter error
            print(f"BALANCE_SERVICE: Account '{account_name}' not found for user {user_id} during balance update.")
            return None 
        return account_docs[0].reference

    @staticmethod
    def update_balance_on_new_transaction(user_id, account_name, transaction_amount, transaction_type, allocated_to_savings=0.0):
        try:
            account_doc_ref = BalanceService._get_account_ref(user_id, account_name)
            if not account_doc_ref:
                raise Exception(f"Account '{account_name}' not found for balance update.")

            effective_amount_change = 0
            if transaction_type == 'income':
                effective_amount_change = transaction_amount - allocated_to_savings
            elif transaction_type == 'expense':
                effective_amount_change = -transaction_amount
            else:
                return # Or raise error for unknown type

            account_doc_ref.update({
                'currentBalance': firestore.Increment(effective_amount_change),
                'updatedAt': datetime.now(timezone.utc).isoformat()
            })
            print(f"BALANCE_SERVICE: Account '{account_name}' balance updated by {effective_amount_change} for new transaction.")
            return {"success": True}
        except Exception as e:
            print(f"BALANCE_SERVICE: Error in update_balance_on_new_transaction for '{account_name}': {e}")
            traceback.print_exc()
            raise

    @staticmethod
    def revert_transaction_impact(user_id, account_name, old_transaction_amount, old_transaction_type, old_allocated_to_savings=0.0):
        """ Reverts the financial impact of a transaction on an account's balance. """
        try:
            account_doc_ref = BalanceService._get_account_ref(user_id, account_name)
            if not account_doc_ref:
                # If account was deleted, we might not be able to revert, or log this.
                print(f"BALANCE_SERVICE: Account '{account_name}' not found for reverting impact. Balance may be inconsistent.")
                return {"success": False, "error": "Account not found for revert"}


            reversal_amount = 0
            if old_transaction_type == 'income':
                # To revert income, subtract the net income (amount - savings)
                reversal_amount = -(old_transaction_amount - old_allocated_to_savings)
            elif old_transaction_type == 'expense':
                # To revert expense, add back the amount
                reversal_amount = old_transaction_amount

            if reversal_amount != 0:
                account_doc_ref.update({
                    'currentBalance': firestore.Increment(reversal_amount),
                    'updatedAt': datetime.now(timezone.utc).isoformat()
                })
                print(f"BALANCE_SERVICE: Account '{account_name}' balance reverted by {reversal_amount}.")
            return {"success": True}
        except Exception as e:
            print(f"BALANCE_SERVICE: Error reverting transaction impact for account '{account_name}': {e}")
            traceback.print_exc()
            raise