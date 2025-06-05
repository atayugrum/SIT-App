# File: flask_api/app/routes/account_routes.py
from flask import Blueprint, request, jsonify
from app.services.account_service import AccountService
import traceback

account_bp = Blueprint('account_bp', __name__, url_prefix='/api/accounts')

@account_bp.route('', methods=['POST'])
def add_account_route():
    data = request.get_json()
    if not data:
        return jsonify({"success": False, "error": "No data provided"}), 400

    print(f"POST /api/accounts received data: {data}")
    try:
        result, status_code = AccountService.create_account(data)
        return jsonify(result), status_code
    except Exception as e:
        print(f"Unhandled exception in add_account_route: {e}")
        traceback.print_exc()
        return jsonify({"success": False, "error": "Internal server error while creating account"}), 500

@account_bp.route('', methods=['GET'])
def list_accounts_route():
    user_id = request.args.get('userId')
    if not user_id:
        return jsonify({"success": False, "error": "Missing userId query parameter"}), 400

    print(f"GET /api/accounts for userId: {user_id}")
    try:
        result, status_code = AccountService.list_accounts(user_id)
        return jsonify(result), status_code
    except Exception as e:
        print(f"Unhandled exception in list_accounts_route: {e}")
        traceback.print_exc()
        return jsonify({"success": False, "error": "Internal server error while listing accounts"}), 500