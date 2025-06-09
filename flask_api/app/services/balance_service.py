# File: flask_api/app/services/balance_service.py
from app.utils.firebase_config import db
from datetime import datetime, timezone
from google.cloud.firestore_v1.base_query import FieldFilter
from google.cloud import firestore
import traceback

class BalanceService:
    @staticmethod
    def _get_account_ref(user_id, account_name):
        """Hesap adından döküman referansını getirir."""
        if db is None: raise Exception("Firestore client (db) is not initialized.")
        accounts_ref = db.collection('user_accounts')
        query = accounts_ref.where(filter=FieldFilter('accountName', '==', account_name)) \
                            .where(filter=FieldFilter('userId', '==', user_id)) \
                            .limit(1)
        docs = list(query.stream())
        if not docs:
            return None
        return docs[0].reference

    @staticmethod
    def _update_balance(account_ref, amount_change):
        """Belirli bir hesap dökümanının bakiyesini atomik olarak günceller."""
        if account_ref.get().to_dict().get('accountType') == 'investment':
            print(f"BALANCE_SERVICE: Skipping balance update for investment account '{account_ref.id}'.")
            return
        
        account_ref.update({
            'currentBalance': firestore.Increment(amount_change),
            'updatedAt': datetime.now(timezone.utc).isoformat()
        })
        print(f"BALANCE_SERVICE: Account '{account_ref.id}' balance updated by {amount_change}.")

    @staticmethod
    def _apply_transaction_effect(user_id, tx_data):
        """Bir işlemin bakiye etkisini uygular."""
        amount = tx_data.get('amount', 0.0)
        tx_type = tx_data.get('type')
        account_name = tx_data.get('account')
        allocated_to_savings = 0.0
        
        if tx_type == 'income' and tx_data.get('incomeAllocationPct') is not None:
            allocated_to_savings = round(amount * (int(tx_data['incomeAllocationPct']) / 100), 2)

        account_ref = BalanceService._get_account_ref(user_id, account_name)
        if not account_ref: return

        net_change = 0.0
        if tx_type == 'income':
            net_change = amount - allocated_to_savings
        elif tx_type == 'expense':
            net_change = -amount
        
        if net_change != 0:
            BalanceService._update_balance(account_ref, net_change)

    @staticmethod
    def _revert_transaction_effect(user_id, tx_data):
        """Bir işlemin bakiye etkisini geri alır."""
        amount = tx_data.get('amount', 0.0)
        tx_type = tx_data.get('type')
        account_name = tx_data.get('account')
        allocated_to_savings = 0.0
        
        if tx_type == 'income' and tx_data.get('incomeAllocationPct') is not None:
            allocated_to_savings = round(amount * (int(tx_data['incomeAllocationPct']) / 100), 2)

        account_ref = BalanceService._get_account_ref(user_id, account_name)
        if not account_ref: return
        
        reversal_amount = 0.0
        if tx_type == 'income':
            reversal_amount = -(amount - allocated_to_savings)
        elif tx_type == 'expense':
            reversal_amount = amount
            
        if reversal_amount != 0:
            BalanceService._update_balance(account_ref, reversal_amount)

    @staticmethod
    def update_balance_on_new_transaction(user_id, account_name, amount, transaction_type, allocated_to_savings=0.0):
        """Yeni bir işlem eklendiğinde çağrılır."""
        tx_data = {
            "account": account_name, "amount": amount, "type": transaction_type,
            "incomeAllocationPct": (allocated_to_savings / amount * 100) if amount > 0 else 0
        }
        BalanceService._apply_transaction_effect(user_id, tx_data)

    @staticmethod
    def update_balance_on_delete_transaction(user_id, account_name, amount, transaction_type, allocated_to_savings=0.0):
        """Bir işlem silindiğinde çağrılır."""
        tx_data = {
            "account": account_name, "amount": amount, "type": transaction_type,
            "incomeAllocationPct": (allocated_to_savings / amount * 100) if amount > 0 else 0
        }
        BalanceService._revert_transaction_effect(user_id, tx_data)

    @staticmethod
    def update_balance_on_update_transaction(user_id, old_tx_data, new_tx_data):
        """Bir işlem güncellendiğinde çağrılır. Önce eskiyi geri alır, sonra yeniyi uygular."""
        print("BALANCE_SERVICE: Reverting old transaction effect...")
        BalanceService._revert_transaction_effect(user_id, old_tx_data)
        
        print("BALANCE_SERVICE: Applying new transaction effect...")
        BalanceService._apply_transaction_effect(user_id, new_tx_data)