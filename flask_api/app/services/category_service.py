# File: flask_api/app/services/category_service.py
from app.utils.firebase_config import db
from datetime import datetime, timezone
import traceback
from firebase_admin import firestore

class CategoryService:
    @staticmethod
    def _get_category_doc_ref(category_id):
        if db is None: raise Exception("Firestore client (db) is not initialized.")
        return db.collection('user_defined_categories').document(category_id)

    @staticmethod
    def create_category(data):
        try:
            if db is None: raise Exception("Firestore client (db) is not initialized.")
            required_fields = ['userId', 'categoryName', 'categoryType']
            for field in required_fields:
                if field not in data or not data[field]:
                    return {"success": False, "error": f"Missing or empty required field: {field}"}, 400
            if data['categoryType'] not in ['income', 'expense']:
                return {"success": False, "error": "Invalid categoryType. Must be 'income' or 'expense'."}, 400

            existing_query = db.collection('user_defined_categories') \
                .where('userId', '==', data['userId']) \
                .where('categoryType', '==', data['categoryType']) \
                .where('categoryName', '==', data['categoryName'].strip()) \
                .where('isArchived', '==', False).limit(1)
            if len(list(existing_query.stream())) > 0:
                return {"success": False, "error": f"Category '{data['categoryName']}' already exists for this type."}, 409

            category_data = {
                'userId': data['userId'],
                'categoryName': data['categoryName'].strip(),
                'categoryType': data['categoryType'],
                'iconId': data.get('iconId', 'default_category_icon'),
                'subcategories': data.get('subcategories', []),
                'isArchived': False,
                'createdAt': datetime.now(timezone.utc).isoformat(),
                'updatedAt': datetime.now(timezone.utc).isoformat()
            }
            doc_ref = db.collection('user_defined_categories').document()
            doc_ref.set(category_data)
            created_category = category_data.copy()
            created_category['id'] = doc_ref.id
            print(f"Custom category created with ID: {doc_ref.id} for user {data['userId']}")
            return {"success": True, "message": "Custom category created successfully", "category": created_category}, 201
        except Exception as e:
            print(f"Error creating custom category: {e}")
            traceback.print_exc()
            return {"success": False, "error": f"An internal error occurred: {str(e)}"}, 500

    @staticmethod
    def list_categories(user_id, category_type=None):
        try:
            if db is None: raise Exception("Firestore client (db) is not initialized.")
            query = db.collection('user_defined_categories') \
                      .where('userId', '==', user_id) \
                      .where('isArchived', '==', False)
            if category_type and category_type in ['income', 'expense']:
                query = query.where('categoryType', '==', category_type)
            query = query.order_by('categoryName', direction=firestore.Query.ASCENDING)
            docs = query.stream()
            categories_list = [{'id': doc.id, **doc.to_dict()} for doc in docs]
            print(f"Fetched {len(categories_list)} custom categories for user {user_id} (type: {category_type or 'all'})")
            return {"success": True, "categories": categories_list}, 200
        except Exception as e:
            print(f"Error listing custom categories for user {user_id}: {e}")
            traceback.print_exc()
            return {"success": False, "error": f"An internal error occurred: {str(e)}"}, 500

    # NEW: Update Category
    @staticmethod
    def update_category(user_id_from_auth, category_id, data_to_update):
        try:
            if db is None: raise Exception("Firestore client (db) is not initialized.")
            doc_ref = CategoryService._get_category_doc_ref(category_id)
            category_snapshot = doc_ref.get()

            if not category_snapshot.exists:
                return {"success": False, "error": "Category not found"}, 404

            category_data = category_snapshot.to_dict()
            if category_data.get('userId') != user_id_from_auth:
                return {"success": False, "error": "User not authorized to update this category"}, 403
            if category_data.get('isArchived', False):
                return {"success": False, "error": "Cannot update an archived category"}, 400

            update_payload = {}
            allowed_fields = ['categoryName', 'iconId', 'subcategories'] # categoryType usually not changed

            new_category_name = data_to_update.get('categoryName', category_data['categoryName']).strip()
            if 'categoryName' in data_to_update and new_category_name != category_data['categoryName']:
                # Check for duplicate category name if it's being changed
                existing_query = db.collection('user_defined_categories') \
                    .where('userId', '==', user_id_from_auth) \
                    .where('categoryType', '==', category_data['categoryType']) \
                    .where('categoryName', '==', new_category_name) \
                    .where('isArchived', '==', False).limit(1)

                existing_docs = list(existing_query.stream())
                if len(existing_docs) > 0 and existing_docs[0].id != category_id: # Ensure it's not the same document
                    return {"success": False, "error": f"Another category with name '{new_category_name}' already exists for this type."}, 409
                update_payload['categoryName'] = new_category_name

            if 'iconId' in data_to_update:
                update_payload['iconId'] = data_to_update['iconId']
            if 'subcategories' in data_to_update and isinstance(data_to_update['subcategories'], list):
                update_payload['subcategories'] = data_to_update['subcategories']

            if not update_payload:
                return {"success": False, "error": "No valid fields provided for update or no changes detected."}, 400

            update_payload['updatedAt'] = datetime.now(timezone.utc).isoformat()
            doc_ref.update(update_payload)

            updated_doc = doc_ref.get().to_dict()
            updated_doc['id'] = category_id # ensure ID is in response
            print(f"Custom category {category_id} updated for user {user_id_from_auth}")
            return {"success": True, "message": "Category updated successfully", "category": updated_doc}, 200
        except Exception as e:
            print(f"Error updating custom category {category_id}: {e}")
            traceback.print_exc()
            return {"success": False, "error": f"An internal error occurred: {str(e)}"}, 500

    # NEW: Delete Category (Soft Delete)
    @staticmethod
    def delete_category(user_id_from_auth, category_id):
        try:
            if db is None: raise Exception("Firestore client (db) is not initialized.")
            doc_ref = CategoryService._get_category_doc_ref(category_id)
            category_snapshot = doc_ref.get()

            if not category_snapshot.exists:
                return {"success": False, "error": "Category not found"}, 404

            category_data = category_snapshot.to_dict()
            if category_data.get('userId') != user_id_from_auth:
                return {"success": False, "error": "User not authorized to delete this category"}, 403

            if category_data.get('isArchived', False): # Already archived
                 return {"success": True, "message": "Category already archived"}, 200

            update_payload = {
                'isArchived': True,
                'updatedAt': datetime.now(timezone.utc).isoformat()
            }
            doc_ref.update(update_payload)
            print(f"Custom category {category_id} soft deleted for user {user_id_from_auth}")
            return {"success": True, "message": "Category archived successfully"}, 200
        except Exception as e:
            print(f"Error deleting custom category {category_id}: {e}")
            traceback.print_exc()
            return {"success": False, "error": f"An internal error occurred: {str(e)}"}, 500