# File: flask_api/app/services/balance_service.py

from app.utils.firebase_config import db
from datetime import datetime, timezone
from google.cloud.firestore_v1.base_query import FieldFilter
from google.cloud import firestore
import traceback
from .savings_service import SavingsService

class BalanceService:

    @staticmethod
    def _resolve_account_id(user_id: str, account_identifier: str) -> "str | None":
        """
        Gelen tanımlayıcının ID mi yoksa İsim mi olduğunu anlar.
        Eğer bir isim ise, veritabanından sorgulayıp gerçek ID'yi bulur.
        Bu, Flutter tarafından gelebilecek tutarsız veriye karşı backend'i korur.
        """
        if not account_identifier:
            return None
        
        # Firestore ID'leri genellikle 20 karakterli alfanümerik bir yapıdadır.
        # Bu basit kontrol, gelenin bir ID mi yoksa isim mi olduğunu yüksek doğrulukla anlamamızı sağlar.
        if len(account_identifier) == 20 and account_identifier.isalnum():
            # Gelen değer bir ID'ye benziyor, direkt kullan.
            return account_identifier

        # Gelen değer büyük ihtimalle bir hesap adı, veritabanından sorgulayalım.
        print(f"'{account_identifier}' bir hesap adı olarak algılandı, ID'si sorgulanıyor...")
        accounts_ref = db.collection('user_accounts')
        query = accounts_ref.where('userId', '==', user_id).where('accountName', '==', account_identifier).limit(1)
        
        docs = list(query.stream())
        if docs:
            found_id = docs[0].id
            print(f"Hesap bulundu. Ad: '{account_identifier}', Gerçek ID: '{found_id}'")
            return found_id  # Gerçek ID'yi döndür
            
        # Hem ID'ye benzemiyor hem de veritabanında bu isimde bir hesap bulunamadı.
        return None

    @staticmethod
    def _get_account_ref_by_id(account_id: str):
        """Hesap ID'sinden döküman referansını getirir."""
        if db is None: raise Exception("Firestore client (db) is not initialized.")
        return db.collection('user_accounts').document(account_id)

    @staticmethod
    def _update_balance(account_ref, amount_change: float):
        """Belirli bir hesap dökümanının bakiyesini atomik olarak günceller."""
        if not account_ref: return
        
        account_data = account_ref.get().to_dict()
        if account_data and account_data.get('accountType') == 'investment':
            print(f"BALANCE_SERVICE: Skipping balance update for investment account '{account_ref.id}'.")
            return
        
        account_ref.update({
            'currentBalance': firestore.Increment(amount_change),
            'updatedAt': datetime.now(timezone.utc).isoformat()
        })
        print(f"BALANCE_SERVICE: Account '{account_ref.id}' balance updated by {amount_change}.")
    
    @staticmethod
    @firestore.transactional
    def process_transfer(transaction, user_id: str, source_account_id: str, dest_account_id: str, amount: float):
        """Bir hesaptan diğerine para transferi yapar."""
        if amount <= 0: raise ValueError("Transfer tutarı pozitif olmalıdır.")
        
        source_ref = BalanceService._get_account_ref_by_id(source_account_id)
        dest_ref = BalanceService._get_account_ref_by_id(dest_account_id)

        if not source_ref.get(transaction=transaction).exists or not dest_ref.get(transaction=transaction).exists:
            raise ValueError("Kaynak veya hedef hesap bulunamadı.")
        
        transaction.update(source_ref, {'currentBalance': firestore.Increment(-amount)})
        transaction.update(dest_ref, {'currentBalance': firestore.Increment(amount)})
        
        print(f"BALANCE_SERVICE (TX): {source_account_id} -> {dest_account_id} : {amount} transfer edildi.")

    @staticmethod
    def update_balance_on_new_transaction(user_id: str, account_identifier: str, amount: float, transaction_type: str, income_allocation_pct: int = 0):
        """Yeni bir işlem oluşturulduğunda ilgili hesabın bakiyesini ve gerekirse tasarrufları günceller."""
        account_id = BalanceService._resolve_account_id(user_id, account_identifier)
        if not account_id:
            raise ValueError(f"Hesap bulunamadı: {account_identifier}")
        
        account_ref = BalanceService._get_account_ref_by_id(account_id)
        
        net_change = 0.0
        
        if transaction_type == 'income':
            effective_allocation_pct = income_allocation_pct if income_allocation_pct is not None else 0
            allocated_to_savings = round(amount * (effective_allocation_pct / 100.0), 2)
            net_change = amount - allocated_to_savings

            # --- EKSİK OLAN VE YENİDEN EKLENEN KISIM ---
            if allocated_to_savings > 0:
                # İşlem ID'si bu aşamada bilinmediği için transaction_id=None olarak geçiyoruz.
                # Bu, otomatik gelir dağılımından gelen birikim olduğunu belirtir.
                SavingsService.create_savings_allocation(
                    user_id=user_id,
                    amount=allocated_to_savings,
                    date_str=datetime.now(timezone.utc).strftime('%Y-%m-%d'), 
                    source='auto'
                )
                print(f"SAVINGS_SERVICE call: Allocated {allocated_to_savings} to savings for user {user_id}.")
            # --- DÜZELTME SONU ---

        elif transaction_type == 'expense':
            net_change = -amount
        
        if net_change != 0:
            BalanceService._update_balance(account_ref, net_change)

    @staticmethod
    def update_balance_on_delete_transaction(user_id: str, account_identifier: str, amount: float, transaction_type: str, income_allocation_pct: int = 0):
        """Bir işlemin bakiye etkisini geri alır."""
        account_id = BalanceService._resolve_account_id(user_id, account_identifier)
        if not account_id:
            print(f"Hesap '{account_identifier}' bulunamadığı için bakiye geri alınamadı.")
            return

        account_ref = BalanceService._get_account_ref_by_id(account_id)
        reversal_amount = 0.0
        
        if transaction_type == 'income':
            effective_allocation_pct = income_allocation_pct if income_allocation_pct is not None else 0
            allocated_to_savings = amount * (effective_allocation_pct / 100.0)
            reversal_amount = -(amount - allocated_to_savings)
        elif transaction_type == 'expense':
            reversal_amount = amount
            
        if reversal_amount != 0:
            BalanceService._update_balance(account_ref, reversal_amount)

    @staticmethod
    def update_balance_on_update_transaction(user_id, old_tx_data, new_tx_data):
        """Bir işlem güncellendiğinde bakiye değişikliklerini yönetir."""
        old_account_identifier = old_tx_data.get('accountId') or old_tx_data.get('account')
        new_account_identifier = new_tx_data.get('accountId') or new_tx_data.get('account')

        old_pct = old_tx_data.get('incomeAllocationPct', 0)
        new_pct = new_tx_data.get('incomeAllocationPct', 0)

        # Eski işlemi geri al
        BalanceService.update_balance_on_delete_transaction(user_id, old_account_identifier, old_tx_data['amount'], old_tx_data['type'], old_pct)
        # Yeni işlemi uygula
        BalanceService.update_balance_on_new_transaction(user_id, new_account_identifier, new_tx_data['amount'], new_tx_data['type'], new_pct)