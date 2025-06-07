# File: flask_api/app/services/balance_service.py
from app.utils.firebase_config import db
from datetime import datetime, timezone
from google.cloud import firestore
import traceback

class BalanceService:
    @staticmethod
    def _get_accounts_collection_ref():
        if db is None: raise Exception("Firestore client (db) is not initialized.")
        return db.collection('user_accounts')

    @staticmethod
    def _update_account_balance(account_name, amount_change):
        try:
            accounts_ref = BalanceService._get_accounts_collection_ref()
            query = accounts_ref.where('accountName', '==', account_name).limit(1)
            docs = query.stream()
            account_doc = next(docs, None)

            if account_doc:
                doc_ref = account_doc.reference
                doc_ref.update({
                    'currentBalance': firestore.Increment(amount_change),
                    'updatedAt': datetime.now(timezone.utc).isoformat()
                })
                print(f"BALANCE_SERVICE: Account '{account_name}' balance updated by {amount_change}.")
            else:
                print(f"BALANCE_SERVICE: Account '{account_name}' not found for balance update.")
                raise Exception(f"Account '{account_name}' not found for balance update.")

        except Exception as e:
            print(f"Error updating balance for account '{account_name}': {e}")
            traceback.print_exc()
            raise e

    @staticmethod
    def update_balance_on_new_transaction(account_name, amount, transaction_type, allocated_to_savings=0.0):
        # Gelir ise, net tutar (gelir - tasarruf) hesaba eklenir.
        # Gider ise, tutar hesaptan düşülür.
        net_amount_change = 0.0
        if transaction_type == 'income':
            net_amount_change = amount - allocated_to_savings
        elif transaction_type == 'expense':
            net_amount_change = -amount
        
        if net_amount_change != 0:
            BalanceService._update_account_balance(account_name, net_amount_change)
    
    @staticmethod
    def update_balance_on_update_transaction(
        old_account, old_amount, old_type, old_allocated_to_savings,
        new_account, new_amount, new_type, new_allocated_to_savings
    ):
        # 1. Eski işlemin etkisini geri al
        old_net_impact = 0.0
        if old_type == 'income':
            old_net_impact = old_amount - old_allocated_to_savings
        elif old_type == 'expense':
            old_net_impact = -old_amount

        if old_account == new_account:
            # Eğer hesap aynı ise, tek bir güncelleme yeterli
            total_change = -old_net_impact # Eski etkiyi ters çevir
            
            new_net_impact = 0.0
            if new_type == 'income':
                new_net_impact = new_amount - new_allocated_to_savings
            elif new_type == 'expense':
                new_net_impact = -new_amount
            
            total_change += new_net_impact
            if total_change != 0:
                 BalanceService._update_account_balance(new_account, total_change)
        else:
            # Hesaplar farklıysa, eski hesaptan eski etkiyi geri al, yeni hesaba yeni etkiyi ekle
            if old_net_impact != 0:
                BalanceService._update_account_balance(old_account, -old_net_impact)
            
            BalanceService.update_balance_on_new_transaction(new_account, new_amount, new_type, new_allocated_to_savings)

    @staticmethod
    def update_balance_on_delete_transaction(account_name, amount, transaction_type, allocated_to_savings=0.0):
        # Silme işlemi, ekleme işleminin tam tersidir.
        net_amount_reversal = 0.0
        if transaction_type == 'income':
            # Silinen gelirin hesaba net etkisini geri al (çıkar)
            net_amount_reversal = -(amount - allocated_to_savings)
        elif transaction_type == 'expense':
            # Silinen gideri hesaba geri ekle
            net_amount_reversal = amount
        
        if net_amount_reversal != 0:
            BalanceService._update_account_balance(account_name, net_amount_reversal)