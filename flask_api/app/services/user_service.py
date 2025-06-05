# File: flask_api/app/services/user_service.py
from app.utils.firebase_config import db
from datetime import datetime
import traceback

class UserService:
    @staticmethod
    def create_user_profile(uid, data):
        try:
            user_ref = db.collection('users').document(uid)
            profile_data = {
                'fullName': data.get('fullName'),
                'username': data.get('username'),
                'email': data.get('email'),
                'birthDate': data.get('birthDate'), # Expecting YYYY-MM-DD string
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

    # NEW METHOD TO UPDATE USER PROFILE
    @staticmethod
    def update_user_profile(uid, data_to_update):
        try:
            if db is None:
                print("UserService: Firestore client (db) is None.")
                raise Exception("Database service not available.")

            user_ref = db.collection('users').document(uid)

            # Prepare data for update, only including fields that are allowed to be updated
            # and are present in the input.
            # For now: fullName, username, birthDate
            update_payload = {}
            if 'fullName' in data_to_update:
                update_payload['fullName'] = data_to_update['fullName']
            if 'username' in data_to_update:
                # TODO: Add username uniqueness check if it's being changed
                # This would require querying the users collection.
                # For now, we assume client-side validation or a simpler update.
                update_payload['username'] = data_to_update['username']
            if 'birthDate' in data_to_update: # Expecting YYYY-MM-DD string
                update_payload['birthDate'] = data_to_update['birthDate']

            if not update_payload:
                return {"success": False, "error": "No valid fields provided for update."}, 400

            update_payload['updatedAt'] = datetime.utcnow().isoformat() + "Z"

            user_ref.update(update_payload)
            print(f"User profile updated in Firestore for UID: {uid} with data: {update_payload}")

            # Fetch the updated profile to return it
            updated_doc = user_ref.get()
            if updated_doc.exists:
                return {"success": True, "message": "Profile updated successfully.", "profile": updated_doc.to_dict()}
            else: # Should not happen if update was successful on existing doc
                return {"success": False, "error": "Profile not found after update attempt."}, 404

        except Exception as e:
            print(f"Error updating user profile in Firestore for UID {uid}: {e}")
            traceback.print_exc()
            raise Exception(f"Failed to update user profile due to Firestore error: {str(e)}")