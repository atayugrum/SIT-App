# File: flask_api/app/services/account_service.py

from app.utils.firebase_config import db
from datetime import datetime, timezone
import traceback
from firebase_admin import firestore
from google.cloud.firestore_v1.base_query import FieldFilter
import uuid


class AccountService:
    @staticmethod
    def create_account(data):
        try:
            if db is None:
                raise Exception("Firestore client (db) is not initialized.")

            required_fields = ['userId', 'accountName', 'accountType', 'currency']
            for field in required_fields:
                if field not in data or data[field] is None:
                    return { "success": False, "error": f"Missing required field: {field}" }, 400

            initial_balance = float(data.get('initialBalance', 0.0))

            account_data = {
                'userId':        data['userId'],
                'accountName':   data['accountName'],
                'accountType':   data['accountType'],
                'initialBalance': initial_balance,
                'currentBalance': initial_balance,
                'currency':      data['currency'].upper(),
                'createdAt':     datetime.now(timezone.utc).isoformat(),
                'updatedAt':     datetime.now(timezone.utc).isoformat(),
                'isArchived':    False
            }
            
            # Yatırım hesapları için kategori ekle
            if account_data['accountType'] == 'investment':
                account_data['category'] = data.get('category', 'Diğer Yatırımlar')

            doc_ref = db.collection('user_accounts').document()
            doc_ref.set(account_data)

            created = account_data.copy()
            created['id'] = doc_ref.id

            print(f"Account created: {doc_ref.id} for user {data['userId']}")
            return { "success": True, "message": "Account created successfully", "account": created }, 201

        except Exception as e:
            print(f"Error creating account: {e}")
            traceback.print_exc()
            return { "success": False, "error": f"An internal error occurred: {str(e)}" }, 500

    @staticmethod
    def list_accounts(user_id):
        try:
            if db is None:
                raise Exception("Firestore client (db) is not initialized.")
            
            query = (
                db.collection('user_accounts')
                  .where(filter=FieldFilter('userId', '==', user_id))
                  .where(filter=FieldFilter('isArchived', '==', False))
                  .order_by('accountName', direction=firestore.Query.ASCENDING)
            )

            docs = query.stream()
            accounts = []
            for doc in docs:
                item = doc.to_dict()
                item['id'] = doc.id
                accounts.append(item)

            print(f"Fetched {len(accounts)} accounts for user {user_id}")
            return { "success": True, "accounts": accounts }, 200

        except Exception as e:
            print(f"Error listing accounts for user {user_id}: {e}")
            traceback.print_exc()
            return { "success": False, "error": f"An internal error occurred: {str(e)}" }, 500

    @staticmethod
    def update_account(account_id, data):
        """
        Mevcut hesabı günceller. Sadece gönderilen alanları değiştirir.
        """
        try:
            ref = db.collection('user_accounts').document(account_id)
            doc = ref.get()
            if not doc.exists:
                return {"success": False, "error": "Account not found"}, 404

            update_payload = {}
            for field in ('accountName', 'accountType', 'currency', 'initialBalance', 'currentBalance'):
                if field in data:
                    # numeric değerler için dönüştürme
                    update_payload[field] = float(data[field]) if 'Balance' in field else data[field]
            update_payload['updatedAt'] = datetime.now(timezone.utc).isoformat()

            ref.update(update_payload)
            updated = ref.get().to_dict()
            updated['id'] = account_id
            return {"success": True, "account": updated}, 200

        except Exception as e:
            print(f"Error updating account {account_id}: {e}")
            traceback.print_exc()
            return {"success": False, "error": f"An internal error occurred: {str(e)}"}, 500

    @staticmethod
    def delete_account(account_id):
        """
        Soft‐delete: isArchived bayrağını True yapar.
        """
        try:
            ref = db.collection('user_accounts').document(account_id)
            doc = ref.get()
            if not doc.exists:
                return {"success": True, "message": "Account already archived."}, 200

            ref.update({
                'isArchived': True,
                'updatedAt': datetime.now(timezone.utc).isoformat()
            })
            return {"success": True, "message": "Account archived successfully."}, 200

        except Exception as e:
            print(f"Error archiving account {account_id}: {e}")
            traceback.print_exc()
            return {"success": False, "error": f"An internal error occurred: {str(e)}"}, 500
