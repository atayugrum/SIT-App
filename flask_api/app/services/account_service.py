# File: flask_api/app/services/account_service.py
from app.utils.firebase_config import db
from datetime import datetime, timezone
import traceback
from firebase_admin import firestore

class AccountService:
    @staticmethod
    def create_account(data):
        try:
            if db is None:
                raise Exception("Firestore client (db) is not initialized.")

            required_fields = ['userId', 'accountName', 'accountType', 'currency']
            for field in required_fields:
                if field not in data or data[field] is None:
                    return {"success": False, "error": f"Missing required field: {field}"}, 400

            initial_balance = float(data.get('initialBalance', 0.0))

            account_data = {
                'userId': data['userId'],
                'accountName': data['accountName'],
                'accountType': data['accountType'],
                'initialBalance': initial_balance,
                'currentBalance': initial_balance, # Initially current balance is the initial balance
                'currency': data['currency'].upper(), # Store currency in uppercase
                'createdAt': datetime.now(timezone.utc).isoformat(),
                'updatedAt': datetime.now(timezone.utc).isoformat(),
                'isArchived': False # To allow soft-delete later
            }

            doc_ref = db.collection('user_accounts').document()
            doc_ref.set(account_data)

            created_account = account_data.copy()
            created_account['id'] = doc_ref.id

            print(f"Account created successfully with ID: {doc_ref.id} for user {data['userId']}")
            return {"success": True, "message": "Account created successfully", "account": created_account}, 201

        except Exception as e:
            print(f"Error creating account: {e}")
            traceback.print_exc()
            return {"success": False, "error": f"An internal error occurred: {str(e)}"}, 500

    @staticmethod
    def list_accounts(user_id):
        try:
            if db is None:
                raise Exception("Firestore client (db) is not initialized.")

            query = db.collection('user_accounts').where('userId', '==', user_id).where('isArchived', '==', False)
            query = query.order_by('accountName', direction=firestore.Query.ASCENDING) # Order by name

            docs = query.stream()
            accounts_list = []
            for doc in docs:
                account_item = doc.to_dict()
                account_item['id'] = doc.id
                accounts_list.append(account_item)

            print(f"Fetched {len(accounts_list)} accounts for user {user_id}")
            return {"success": True, "accounts": accounts_list}, 200

        except Exception as e:
            print(f"Error listing accounts for user {user_id}: {e}")
            traceback.print_exc()
            return {"success": False, "error": f"An internal error occurred: {str(e)}"}, 500