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
    try:
        result, status_code = AccountService.create_account(data)
        return jsonify(result), status_code
    except Exception as e:
        traceback.print_exc()
        return jsonify({"success": False, "error": "Internal server error"}), 500

@account_bp.route('', methods=['GET'])
def list_accounts_route():
    user_id = request.args.get('userId')
    if not user_id:
        return jsonify({"success": False, "error": "Missing userId query parameter"}), 400
    try:
        result, status_code = AccountService.list_accounts(user_id)
        return jsonify(result), status_code
    except Exception as e:
        traceback.print_exc()
        return jsonify({"success": False, "error": "Internal server error"}), 500

# --- YENİ ROTALAR ---
@account_bp.route('/<string:account_id>', methods=['PUT'])
def update_account_route(account_id):
    data = request.get_json()
    if not data:
        return jsonify({"success": False, "error": "No update data provided"}), 400
    try:
        result, status_code = AccountService.update_account(account_id, data)
        return jsonify(result), status_code
    except Exception as e:
        traceback.print_exc()
        return jsonify({"success": False, "error": "Internal server error"}), 500

@account_bp.route('/<string:account_id>', methods=['DELETE'])
def delete_account_route(account_id):
    try:
        result, status_code = AccountService.delete_account(account_id)
        return jsonify(result), status_code
    except Exception as e:
        traceback.print_exc()
        return jsonify({"success": False, "error": "Internal server error"}), 500