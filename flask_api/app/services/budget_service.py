# File: flask_api/app/services/budget_service.py
from app.utils.firebase_config import db
from datetime import datetime, timezone
import traceback
from firebase_admin import firestore
import uuid # For generating new budget IDs

class BudgetService:
    @staticmethod
    def _get_budget_collection_ref():
        if db is None: raise Exception("Firestore client (db) is not initialized.")
        return db.collection('budgets')

    @staticmethod
    def list_budgets(user_id, year=None, month=None):
        try:
            budgets_ref = BudgetService._get_budget_collection_ref()
            query = budgets_ref.where('userId', '==', user_id) \
                               .where('period', '==', 'monthly') # Assuming only monthly for now

            # Firestore'da yıl ve ay bazlı filtreleme için genellikle bu alanları
            # doğrudan döküman içinde saklamak ve sorgulamak daha etkilidir.
            # Şimdilik, yıl/ay filtresini backend'de tüm sonuçları çektikten sonra
            # uygulamak yerine, bu alanları dökümana ekleyip sorgulayacağız.
            # Eğer Firestore'da year/month alanları yoksa, bu filtreleme client-side veya 
            # tümünü çekip Python'da filtreleyerek yapılabilir, ancak bu verimsiz olur.
            # Modelimize year ve month eklediğimizi varsayalım.

            current_time = datetime.now(timezone.utc)
            target_year = year if year is not None else current_time.year
            target_month = month if month is not None else current_time.month

            query = query.where('year', '==', int(target_year))
            query = query.where('month', '==', int(target_month))

            # isArchived veya isDeleted alanı varsa onu da ekleyin
            # query = query.where('isArchived', '==', False) 

            query = query.order_by('category', direction=firestore.Query.ASCENDING)

            docs = query.stream()
            budgets_list = []
            for doc in docs:
                budget_item = doc.to_dict()
                budget_item['id'] = doc.id
                budgets_list.append(budget_item)

            print(f"Fetched {len(budgets_list)} budgets for user {user_id} for {target_year}-{target_month}")
            return {"success": True, "budgets": budgets_list}, 200

        except Exception as e:
            print(f"Error listing budgets for user {user_id}: {e}")
            traceback.print_exc()
            # This query will likely require a composite index on userId, period, year, month, category
            return {"success": False, "error": f"An internal error occurred: {str(e)}" }, 500

    @staticmethod
    def create_or_update_budget(data):
        try:
            budgets_ref = BudgetService._get_budget_collection_ref()
            required_fields = ['userId', 'category', 'limitAmount']
            for field in required_fields:
                if field not in data or data[field] is None:
                    return {"success": False, "error": f"Missing required field: {field}"}, 400

            user_id = data['userId']
            category = data['category']
            limit_amount = float(data['limitAmount'])
            period = data.get('period', 'monthly') # Default to monthly

            # For simplicity, assume year/month come from client or default to current
            current_time = datetime.now(timezone.utc)
            year = data.get('year', current_time.year)
            month = data.get('month', current_time.month)

            if limit_amount <= 0:
                return {"success": False, "error": "limitAmount must be positive."}, 400

            # Check if a budget for this user, category, period, year, month already exists
            query = budgets_ref.where('userId', '==', user_id) \
                               .where('category', '==', category) \
                               .where('period', '==', period) \
                               .where('year', '==', int(year)) \
                               .where('month', '==', int(month)) \
                               .limit(1)

            existing_docs = list(query.stream())

            budget_payload = {
                'userId': user_id,
                'category': category,
                'limitAmount': limit_amount,
                'period': period,
                'isAuto': data.get('isAuto', False), # Default to manual
                'year': int(year),
                'month': int(month),
                'updatedAt': datetime.now(timezone.utc).isoformat()
            }

            if existing_docs:
                # Update existing budget
                doc_ref = existing_docs[0].reference
                budget_payload.pop('userId', None) # Not needed for update if doc_ref is specific
                budget_payload.pop('category', None)
                budget_payload.pop('period', None)
                budget_payload.pop('year', None)
                budget_payload.pop('month', None)

                doc_ref.update(budget_payload)
                budget_id = doc_ref.id
                message = "Budget updated successfully"
                status_code = 200
                print(f"Budget {budget_id} updated for user {user_id}")
            else:
                # Create new budget
                budget_id = str(uuid.uuid4()) # Generate a new UUID for the document ID
                doc_ref = budgets_ref.document(budget_id)
                budget_payload['createdAt'] = datetime.now(timezone.utc).isoformat()
                doc_ref.set(budget_payload)
                message = "Budget created successfully"
                status_code = 201
                print(f"Budget {budget_id} created for user {user_id}")

            # Fetch the created/updated document to return
            final_doc = doc_ref.get().to_dict()
            final_doc['id'] = budget_id # Ensure ID is in the response

            return {"success": True, "message": message, "budget": final_doc}, status_code

        except ValueError:
            return {"success": False, "error": "Invalid limitAmount format. Must be a number."}, 400
        except Exception as e:
            print(f"Error creating/updating budget: {e}")
            traceback.print_exc()
            return {"success": False, "error": f"An internal error occurred: {str(e)}"}, 500

    @staticmethod
    def delete_budget(user_id_from_auth, budget_id):
        try:
            doc_ref = BudgetService._get_budget_collection_ref().document(budget_id)
            budget_snapshot = doc_ref.get()

            if not budget_snapshot.exists:
                return {"success": False, "error": "Budget not found"}, 404

            budget_data = budget_snapshot.to_dict()
            if budget_data.get('userId') != user_id_from_auth:
                return {"success": False, "error": "User not authorized to delete this budget"}, 403

            # Perform hard delete for now as per MVP in doc (Section 6.2.1.4)
            doc_ref.delete()
            print(f"Budget {budget_id} deleted for user {user_id_from_auth}")
            return {"success": True, "message": "Budget deleted successfully"}, 200
        except Exception as e:
            print(f"Error deleting budget {budget_id}: {e}")
            traceback.print_exc()
            return {"success": False, "error": f"Internal error during deletion: {str(e)}"}, 500