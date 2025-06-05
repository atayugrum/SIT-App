# File: flask_api/app/routes/category_routes.py
from flask import Blueprint, request, jsonify
from app.services.category_service import CategoryService
import traceback

category_bp = Blueprint('category_bp', __name__, url_prefix='/api/categories')

@category_bp.route('', methods=['POST'])
def add_category_route():
    data = request.get_json()
    if not data:
        return jsonify({"success": False, "error": "No data provided"}), 400

    user_id_from_auth = data.get('userId') # Placeholder for actual auth token user ID extraction
    if not user_id_from_auth:
         return jsonify({"success": False, "error": "userId is required in payload"}), 400 # Should be from auth

    print(f"POST /api/categories received data: {data}")
    try:
        # Pass entire data, service will extract userId
        result, status_code = CategoryService.create_category(data) 
        return jsonify(result), status_code
    except Exception as e:
        print(f"Unhandled exception in add_category_route: {e}")
        traceback.print_exc()
        return jsonify({"success": False, "error": "Internal server error while creating category"}), 500

@category_bp.route('', methods=['GET'])
def list_categories_route():
    user_id = request.args.get('userId')
    if not user_id:
        return jsonify({"success": False, "error": "Missing userId query parameter"}), 400

    category_type = request.args.get('type')

    print(f"GET /api/categories for userId: {user_id}, type: {category_type}")
    try:
        result, status_code = CategoryService.list_categories(user_id, category_type)
        return jsonify(result), status_code
    except Exception as e:
        print(f"Unhandled exception in list_categories_route: {e}")
        traceback.print_exc()
        return jsonify({"success": False, "error": "Internal server error while listing categories"}), 500

# NEW: Update Category Route
@category_bp.route('/<string:category_id>', methods=['PUT'])
def update_category_route(category_id):
    data_to_update = request.get_json()
    if not data_to_update:
        return jsonify({"success": False, "error": "No data provided for update"}), 400

    # In a real app, get userId from auth token, not client payload for security.
    user_id_from_auth = data_to_update.pop('userId', None) # Remove userId if sent, use auth token's
    # For now, let's assume we'll get it from a simulated auth context or test with it in payload.
    # If you have an auth middleware that sets g.user, use g.user['uid']
    if not user_id_from_auth: # This is a placeholder, replace with actual auth
        user_id_from_auth = request.headers.get('X-User-ID') # Example of custom header for testing
        if not user_id_from_auth:
             return jsonify({"success": False, "error": "User authentication required (userId missing)"}), 401


    print(f"PUT /api/categories/{category_id} for user {user_id_from_auth} with data: {data_to_update}")
    try:
        result, status_code = CategoryService.update_category(user_id_from_auth, category_id, data_to_update)
        return jsonify(result), status_code
    except Exception as e:
        print(f"Unhandled exception in update_category_route for {category_id}: {e}")
        traceback.print_exc()
        return jsonify({"success": False, "error": "Internal server error while updating category"}), 500

# NEW: Delete Category Route (Soft Delete)
@category_bp.route('/<string:category_id>', methods=['DELETE'])
def delete_category_route(category_id):
    # In a real app, get userId from auth token.
    user_id_from_auth = request.args.get('userId') # Or extract from auth token
    if not user_id_from_auth:
        return jsonify({"success": False, "error": "User authentication required (userId missing in query)"}), 401

    print(f"DELETE /api/categories/{category_id} for user {user_id_from_auth}")
    try:
        result, status_code = CategoryService.delete_category(user_id_from_auth, category_id)
        return jsonify(result), status_code
    except Exception as e:
        print(f"Unhandled exception in delete_category_route for {category_id}: {e}")
        traceback.print_exc()
        return jsonify({"success": False, "error": "Internal server error while deleting category"}), 500