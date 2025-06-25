# File: flask_api/app/services/user_service.py
from app.utils.firebase_config import db
from datetime import datetime
import traceback
from firebase_admin import auth
from google.cloud.firestore_v1.base_query import FieldFilter

class UserService:
    # ... mevcut create_user_profile, get_user_profile, update_user_profile metotlarınız burada kalacak ...
    @staticmethod
    def create_user_profile(uid, data):
        try:
            user_ref = db.collection('users').document(uid)
            profile_data = {
                'fullName': data.get('fullName'),
                'username': data.get('username'),
                'email': data.get('email'),
                'birthDate': data.get('birthDate'),
                'profileIconId': data.get('profileIconId', 'icon-1'),
                'riskProfile': None,
                'createdAt': datetime.utcnow().isoformat() + "Z",
                'updatedAt': datetime.utcnow().isoformat() + "Z"
            }
            user_ref.set(profile_data)
            print(f"User profile created in Firestore for UID: {uid}")
            return {"success": True, "message": "User profile created successfully.", "uid": uid}
        except Exception as e:
            print(f"Error creating user profile in Firestore for UID {uid}: {e}")
            traceback.print_exc()
            raise Exception(f"Failed to create user profile due to Firestore error: {str(e)}")

    @staticmethod
    def get_user_profile(uid):
        try:
            if db is None:
                print("UserService: Firestore client (db) is None.")
                raise Exception("Database service not available.")
            user_ref = db.collection('users').document(uid)
            user_doc = user_ref.get()
            if user_doc.exists:
                profile_data = user_doc.to_dict()
                profile_data['uid'] = uid
                if 'createdAt' in profile_data and not isinstance(profile_data['createdAt'], str):
                    profile_data['createdAt'] = profile_data['createdAt'].isoformat() + "Z"
                if 'updatedAt' in profile_data and not isinstance(profile_data['updatedAt'], str):
                    profile_data['updatedAt'] = profile_data['updatedAt'].isoformat() + "Z"
                print(f"User profile fetched from Firestore for UID: {uid}")
                return {"success": True, "profile": profile_data}
            else:
                print(f"No user profile found in Firestore for UID: {uid}")
                return {"success": False, "error": "User profile not found", "status_code": 404}
        except Exception as e:
            print(f"Error fetching user profile from Firestore for UID {uid}: {e}")
            traceback.print_exc()
            raise Exception(f"Failed to fetch user profile due to Firestore error: {str(e)}")

    @staticmethod
    def update_user_profile(uid, data_to_update):
        try:
            if db is None:
                print("UserService: Firestore client (db) is None.")
                raise Exception("Database service not available.")

            user_ref = db.collection('users').document(uid)
            update_payload = {}
            if 'fullName' in data_to_update:
                update_payload['fullName'] = data_to_update['fullName']
            if 'username' in data_to_update:
                update_payload['username'] = data_to_update['username']
            if 'birthDate' in data_to_update:
                update_payload['birthDate'] = data_to_update['birthDate']

            if not update_payload:
                return {"success": False, "error": "No valid fields provided for update."}, 400

            update_payload['updatedAt'] = datetime.utcnow().isoformat() + "Z"
            user_ref.update(update_payload)
            print(f"User profile updated in Firestore for UID: {uid} with data: {update_payload}")
            updated_doc = user_ref.get()
            if updated_doc.exists:
                return {"success": True, "message": "Profile updated successfully.", "profile": updated_doc.to_dict()}
            else:
                return {"success": False, "error": "Profile not found after update attempt."}, 404
        except Exception as e:
            print(f"Error updating user profile in Firestore for UID {uid}: {e}")
            traceback.print_exc()
            raise Exception(f"Failed to update user profile due to Firestore error: {str(e)}")

    # --- YENİ EKLENEN METOTLAR ---

    @staticmethod
    def _delete_collection_by_user(collection_name, uid, batch_size=200):
        """Belirli bir koleksiyondaki kullanıcıya ait tüm dökümanları toplu olarak siler."""
        coll_ref = db.collection(collection_name)
        query = coll_ref.where(filter=FieldFilter('userId', '==', uid))
        
        while True:
            docs = query.limit(batch_size).stream()
            deleted_count = 0
            batch = db.batch()
            for doc in docs:
                batch.delete(doc.reference)
                deleted_count += 1
            
            if deleted_count == 0:
                break
            
            batch.commit()
            print(f"Deleted {deleted_count} documents from '{collection_name}' for user {uid}")
    
    @staticmethod
    def _delete_subcollection_recursively(doc_ref):
        """Bir dökümanın altındaki tüm alt koleksiyonları ve dökümanları siler."""
        for sub_coll in doc_ref.collections():
            for sub_doc in sub_coll.stream():
                UserService._delete_subcollection_recursively(sub_doc.reference) # İç içe silme
            # Alt koleksiyon boşaldıktan sonra, içindeki dökümanları sil
            UserService._delete_collection_by_user(f"{doc_ref.path}/{sub_coll.id}", doc_ref.id.split('/')[-1])

    @staticmethod
    def delete_user_and_all_data(uid):
        """Bir kullanıcıya ait TÜM verileri Firestore'dan ve Auth'dan kalıcı olarak siler."""
        try:
            print(f"DELETION PROCESS STARTED for user: {uid}")

            # 1. Adım: `userId` alanı ile sorgulanan ana koleksiyonları temizle
            collections_to_purge = [
                'user_accounts', 'transactions', 'budgets', 'savings_goals',
                'savings_allocations', 'user_tasks', 'holdings', 'investment_transactions'
            ]
            for coll_name in collections_to_purge:
                UserService._delete_collection_by_user(coll_name, uid)

            # 2. Adım: Doğrudan UID ile isimlendirilmiş dökümanları sil
            db.collection('user_savings_balances').document(uid).delete()
            print(f"Deleted user_savings_balances document for user: {uid}")

            # 3. Adım: Alt koleksiyonları olan `users` dökümanını ve içeriğini sil
            user_doc_ref = db.collection('users').document(uid)
            
            # Finansal Test alt koleksiyonunu sil
            finance_tests_ref = user_doc_ref.collection('FinanceTests')
            for test_doc in finance_tests_ref.stream():
                # Testin altındaki 'answers' koleksiyonunu temizle
                answers_ref = test_doc.reference.collection('answers')
                for answer_doc in answers_ref.stream():
                    answer_doc.reference.delete()
                test_doc.reference.delete()
            print(f"Deleted FinanceTests subcollection for user: {uid}")

            # Ana kullanıcı dökümanını sil
            user_doc_ref.delete()
            print(f"Deleted main user profile document for user: {uid}")

            # 4. Adım: Her şey silindikten sonra kullanıcıyı Authentication'dan sil
            auth.delete_user(uid)
            print(f"DELETION PROCESS COMPLETED for user: {uid}")

            return {"success": True, "message": "User and all associated data were successfully deleted."}

        except Exception as e:
            error_message = f"Error during deletion process for user {uid}: {e}"
            print(error_message)
            traceback.print_exc()
            raise Exception(error_message)