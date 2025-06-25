# File: flask_api/app/services/transaction_service.py

from app.utils.firebase_config import db
from datetime import datetime, timezone
import traceback
from firebase_admin import firestore
from google.cloud.firestore_v1.base_query import FieldFilter
import uuid
from .balance_service import BalanceService
from .savings_service import SavingsService

class TransactionService:
    @staticmethod
    def list_transactions(user_id, start_date_str, end_date_str, type_filter=None, account_filter=None):
        try:
            transactions_ref = db.collection('transactions')
            query = (
                transactions_ref
                .where(filter=FieldFilter('userId', '==', user_id))
                .where(filter=FieldFilter('date', '>=', start_date_str))
                .where(filter=FieldFilter('date', '<=', end_date_str))
                .where(filter=FieldFilter('isDeleted', '==', False))
            )
            if type_filter and type_filter in ['income', 'expense', 'transfer_in', 'transfer_out']: 
                query = query.where(filter=FieldFilter('type', '==', type_filter))
            
            # Not: Bu sorgu, 'account' alanının bir dizin gerektirmesini önlemek için
            # Python tarafında filtreleme yapar. Büyük veri setlerinde verimsiz olabilir.
            docs = list(query.stream())
            
            transactions_list = [{'id': doc.id, **doc.to_dict()} for doc in docs]

            if account_filter:
                # Düzeltme: Filtreleme hem accountId hem de eski account (name) alanına göre yapılabilir.
                # İdeali, UI'dan accountId gönderilmesidir.
                transactions_list = [tx for tx in transactions_list if tx.get('account') == account_filter or tx.get('accountId') == account_filter]

            # Sıralamayı Python tarafında yapıyoruz
            transactions_list.sort(key=lambda x: (x.get('date', ''), x.get('createdAt', '')), reverse=True)
            
            return {"success": True, "transactions": transactions_list}, 200
        except Exception as e:
            traceback.print_exc()
            return {"success": False, "error": f"Internal server error: {str(e)}"}, 500

    @staticmethod
    def create_transaction(data):
        try:
            # DÜZELTME: Frontend'den 'account' olarak gelen ID'yi 'accountId' olarak kabul et
            if 'account' in data and 'accountId' not in data:
                data['accountId'] = data.pop('account')

            required_fields = ['userId', 'type', 'category', 'amount', 'date', 'accountId']
            if not all(field in data and data[field] is not None for field in required_fields):
                return {"success": False, "error": "Zorunlu alanlar eksik."}, 400

            doc_ref = db.collection('transactions').document()
            amount = float(data.get('amount', 0.0))
            
            transaction_data = {
                'userId': data['userId'], 'type': data['type'], 'category': data['category'],
                'subCategory': data.get('subCategory'), 'amount': amount, 'date': data['date'],
                'accountId': data['accountId'], # Düzeltildi: Artık her zaman accountId var
                'description': data.get('description'), 'isRecurring': data.get('isRecurring', False),
                'recurrenceRule': data.get('recurrenceRule'), 'isNeed': data.get('isNeed'),
                'emotion': data.get('emotion'), 'incomeAllocationPct': data.get('incomeAllocationPct'),
                'isDeleted': False, 'createdAt': datetime.now(timezone.utc).isoformat(),
                'updatedAt': datetime.now(timezone.utc).isoformat()
            }
            doc_ref.set(transaction_data)
            
            # DÜZELTME: Bakiye güncelleme fonksiyonu doğru parametrelerle çağrılıyor
            BalanceService.update_balance_on_new_transaction(
                data['userId'], 
                data['accountId'], 
                amount, 
                data['type'], 
                data.get('incomeAllocationPct', 0)
            )
            
            transaction_data['id'] = doc_ref.id
            return {"success": True, "transaction": transaction_data}, 201
        except Exception as e:
            traceback.print_exc()
            return {"success": False, "error": f"Internal server error: {str(e)}"}, 500

    @staticmethod
    def create_transfer(data):
        try:
            required_fields = ['userId', 'sourceAccountId', 'destinationAccountId', 'amount', 'date']
            if not all(field in data for field in required_fields):
                return {"success": False, "error": "Transfer için zorunlu alanlar eksik."}, 400

            user_id, source_id, dest_id, amount, date_str = data['userId'], data['sourceAccountId'], data['destinationAccountId'], float(data['amount']), data['date']
            description = data.get('description', 'Hesaplar Arası Transfer')
            transfer_id = str(uuid.uuid4())

            source_acc_doc = db.collection('user_accounts').document(source_id).get()
            dest_acc_doc = db.collection('user_accounts').document(dest_id).get()
            if not source_acc_doc.exists or not dest_acc_doc.exists:
                raise ValueError("Kaynak veya hedef hesap bulunamadı.")
            
            source_acc_name = source_acc_doc.to_dict().get('accountName')
            dest_acc_name = dest_acc_doc.to_dict().get('accountName')
            
            db_transaction = db.transaction()
            BalanceService.process_transfer(db_transaction, user_id, source_id, dest_id, amount)

            batch = db.batch()
            source_tx_ref = db.collection('transactions').document()
            source_tx_data = {'userId': user_id, 'type': 'transfer_out', 'category': 'Transfer', 'amount': amount, 'date': date_str, 'account': source_acc_name, 'accountId': source_id, 'description': f"{dest_acc_name} hesabına transfer", 'isDeleted': False, 'transferId': transfer_id, 'createdAt': datetime.now(timezone.utc).isoformat(), 'updatedAt': datetime.now(timezone.utc).isoformat()}
            batch.set(source_tx_ref, source_tx_data)
            
            dest_tx_ref = db.collection('transactions').document()
            dest_tx_data = {'userId': user_id, 'type': 'transfer_in', 'category': 'Transfer', 'amount': amount, 'date': date_str, 'account': dest_acc_name, 'accountId': dest_id, 'description': f"{source_acc_name} hesabından transfer", 'isDeleted': False, 'transferId': transfer_id, 'createdAt': datetime.now(timezone.utc).isoformat(), 'updatedAt': datetime.now(timezone.utc).isoformat()}
            batch.set(dest_tx_ref, dest_tx_data)
            
            batch.commit()
            
            return {"success": True, "message": "Transfer başarıyla tamamlandı."}, 201
        except Exception as e:
            traceback.print_exc()
            return {"success": False, "error": f"Internal server error: {str(e)}"}, 500

    @staticmethod
    def update_transaction(transaction_id, data):
        try:
            doc_ref = db.collection('transactions').document(transaction_id)
            existing_doc = doc_ref.get()
            if not existing_doc.exists:
                return {"success": False, "error": "İşlem bulunamadı."}, 404
            
            old_data = existing_doc.to_dict()

            # DÜZELTME: Gelen veride de 'account' -> 'accountId' dönüşümü yap
            if 'account' in data and 'accountId' not in data:
                data['accountId'] = data.pop('account')

            # BalanceService'i eski ve yeni veriyle çağırarak bakiye tutarlılığını sağla
            BalanceService.update_balance_on_update_transaction(old_data['userId'], old_data, data)
            
            update_payload = data.copy()
            update_payload['updatedAt'] = datetime.now(timezone.utc).isoformat()
            doc_ref.update(update_payload)
            
            updated_doc = doc_ref.get().to_dict()
            updated_doc['id'] = transaction_id
            return {"success": True, "transaction": updated_doc}, 200
        except Exception as e:
            traceback.print_exc()
            return {"success": False, "error": f"Internal server error: {str(e)}"}, 500

    @staticmethod
    def delete_transaction(user_id, transaction_id):
        try:
            doc_ref = db.collection('transactions').document(transaction_id)
            doc = doc_ref.get()
            if not doc.exists: return {"success": True, "message": "İşlem zaten silinmiş."}, 200
            
            txn = doc.to_dict()
            if txn.get('userId') != user_id: return {"success": False, "error": "Yetkisiz işlem."}, 403
            if txn.get('isDeleted') == True: return {"success": True, "message": "İşlem zaten silinmiş."}, 200

            # DÜZELTME: BalanceService'i doğru parametrelerle çağır
            allocated_pct = txn.get('incomeAllocationPct', 0) if txn['type'] == 'income' else 0
            BalanceService.update_balance_on_delete_transaction(user_id, txn['accountId'], txn['amount'], txn['type'], allocated_pct)
            
            doc_ref.update({'isDeleted': True, 'updatedAt': datetime.now(timezone.utc).isoformat()})
            return {"success": True, "message": "İşlem başarıyla silindi."}, 200
        except Exception as e:
            traceback.print_exc()
            return {"success": False, "error": f"Internal server error: {str(e)}"}, 500