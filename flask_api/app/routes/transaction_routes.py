# File: flask_api/app/routes/transaction_routes.py
from flask import Blueprint, request, jsonify
from app.services.transaction_service import TransactionService
import traceback
from datetime import datetime, timedelta

transaction_bp = Blueprint('transaction_bp', __name__, url_prefix='/api/transactions')

@transaction_bp.route('', methods=['GET'])
def list_transactions_route():
    user_id = request.args.get('userId')
    if not user_id:
        return jsonify({"success": False, "error": "Missing userId query parameter"}), 400

    # Varsayılan olarak son 30 günü getir
    today = datetime.now().date()
    thirty_days_ago = today - timedelta(days=30)

    start_date_str = request.args.get('startDate', thirty_days_ago.strftime('%Y-%m-%d'))
    end_date_str = request.args.get('endDate', today.strftime('%Y-%m-%d'))
    type_filter = request.args.get('type')
    account_filter = request.args.get('account') # account filtresini al

    print(f"GET /api/transactions for userId: {user_id}, startDate: {start_date_str}, endDate: {end_date_str}, type: {type_filter}, account: {account_filter}")
    try:
        # Servis metoduna account filtresini de geçir
        result, status_code = TransactionService.list_transactions(user_id, start_date_str, end_date_str, type_filter, account_filter)
        return jsonify(result), status_code
    except Exception as e:
        print(f"Unhandled exception in list_transactions_route: {e}")
        traceback.print_exc()
        return jsonify({"success": False, "error": "Internal server error"}), 500

@transaction_bp.route('', methods=['POST'])
def add_transaction_route():
    data = request.get_json()
    if not data:
        return jsonify({"success": False, "error": "No data provided"}), 400
    
    print(f"POST /api/transactions received data: {data}")
    try:
        result, status_code = TransactionService.create_transaction(data)
        return jsonify(result), status_code
    except Exception as e:
        print(f"Unhandled exception in add_transaction_route: {e}")
        traceback.print_exc()
        return jsonify({"success": False, "error": "Internal server error"}), 500

@transaction_bp.route('/<string:transaction_id>', methods=['PUT'])
def update_transaction_route(transaction_id):
    data = request.get_json()
    if not data:
        return jsonify({"success": False, "error": "No update data provided"}), 400
    
    print(f"PUT /api/transactions/{transaction_id} received data: {data}")
    try:
        result, status_code = TransactionService.update_transaction(transaction_id, data)
        return jsonify(result), status_code
    except Exception as e:
        print(f"Unhandled exception in update_transaction_route: {e}")
        traceback.print_exc()
        return jsonify({"success": False, "error": "Internal server error"}), 500

@transaction_bp.route('/<string:transaction_id>', methods=['DELETE'])
def delete_transaction_route(transaction_id):
    # Auth için userId'yi de almak iyi bir pratik
    user_id = request.args.get('userId')
    if not user_id:
        return jsonify({"success": False, "error": "Missing userId query parameter for authorization"}), 400

    print(f"DELETE /api/transactions/{transaction_id} for user {user_id}")
    try:
        result, status_code = TransactionService.delete_transaction(user_id, transaction_id)
        return jsonify(result), status_code
    except Exception as e:
        print(f"Unhandled exception in delete_transaction_route: {e}")
        traceback.print_exc()
        return jsonify({"success": False, "error": "Internal server error"}), 500