# File: flask_api/app/routes/user_routes.py
from flask import Blueprint, request, jsonify
from app.services.user_service import UserService
import traceback

user_bp = Blueprint('user_bp', __name__, url_prefix='/api/users')

@user_bp.route('/create_profile', methods=['POST'])
def create_profile():
    data = request.get_json()
    if not data or 'uid' not in data:
        return jsonify({"success": False, "error": "Missing user ID (uid) in request"}), 400

    uid = data.get('uid')
    required_fields = ['fullName', 'username', 'email', 'birthDate']
    missing_fields = [field for field in required_fields if field not in data]
    if missing_fields:
        return jsonify({"success": False, "error": f"Missing fields: {', '.join(missing_fields)}"}), 400

    try:
        result = UserService.create_user_profile(uid, data)
        return jsonify(result), 201
    except Exception as e:
        print(f"Unhandled exception in /create_profile for UID {uid if 'uid' in data else 'UNKNOWN'}: {e}")
        traceback.print_exc() 
        return jsonify({"success": False, "error": f"Internal server error: {str(e)}"}), 500

@user_bp.route('/<string:uid>/profile', methods=['GET'])
def get_profile(uid):
    try:
        print(f"GET /api/users/{uid}/profile route hit")
        result = UserService.get_user_profile(uid)

        if result.get("success"):
            return jsonify(result["profile"]), 200
        else:
            status_code = result.get("status_code", 500) 
            return jsonify({"success": False, "error": result.get("error", "An unknown error occurred")}), status_code
    except Exception as e:
        print(f"Unhandled exception in /profile for UID {uid}: {e}")
        traceback.print_exc()
        return jsonify({"success": False, "error": f"Internal server error: {str(e)}"}), 500

# NEW ROUTE TO UPDATE USER PROFILE
@user_bp.route('/<string:uid>/profile', methods=['PUT'])
def update_profile(uid):
    data = request.get_json()
    if not data:
        return jsonify({"success": False, "error": "No data provided for update"}), 400

    try:
        print(f"PUT /api/users/{uid}/profile route hit with data: {data}")
        result = UserService.update_user_profile(uid, data)

        if result.get("success"):
            return jsonify(result), 200 # Return updated profile and message
        else:
            status_code = result.get("status_code", 400) # Default to 400 for bad update data
            return jsonify({"success": False, "error": result.get("error", "Failed to update profile")}), status_code
    except Exception as e:
        print(f"Unhandled exception in update /profile for UID {uid}: {e}")
        traceback.print_exc()
        return jsonify({"success": False, "error": f"Internal server error: {str(e)}"}), 500