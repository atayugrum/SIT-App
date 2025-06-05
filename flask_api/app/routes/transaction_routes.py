# File: flask_api/app/routes/transaction_routes.py
from flask import Blueprint, request, jsonify
from app.services.transaction_service import TransactionService
import traceback

transaction_bp = Blueprint('transaction_bp', __name__, url_prefix='/api/transactions')

@transaction_bp.route('', methods=['POST'])
def add_transaction_route():
    data = request.get_json()
    if not data:
        return jsonify({"success": False, "error": "No data provided"}), 400

    print(f"POST /api/transactions received data: {data}")
    # Assuming create_transaction now requires userId from auth context, not in data
    # For now, keeping as is if Flutter sends userId in payload
    user_id_from_auth = data.get('userId') # Or get from auth token later
    if not user_id_from_auth:
         return jsonify({"success": False, "error": "userId missing"}), 400

    try:
        result, status_code = TransactionService.create_transaction(data)
        return jsonify(result), status_code
    except Exception as e:
        print(f"Unhandled exception in add_transaction_route: {e}")
        traceback.print_exc()
        return jsonify({"success": False, "error": "Internal server error while creating transaction"}), 500

@transaction_bp.route('', methods=['GET'])
def list_transactions_route():
    user_id = request.args.get('userId')
    if not user_id:
        return jsonify({"success": False, "error": "Missing userId query parameter"}), 400

    start_date = request.args.get('startDate') 
    end_date = request.args.get('endDate')     
    transaction_type = request.args.get('type') 

    print(f"GET /api/transactions for userId: {user_id}, startDate: {start_date}, endDate: {end_date}, type: {transaction_type}")
    try:
        result, status_code = TransactionService.list_transactions(user_id, start_date, end_date, transaction_type)
        return jsonify(result), status_code
    except Exception as e:
        print(f"Unhandled exception in list_transactions_route: {e}")
        traceback.print_exc()
        return jsonify({"success": False, "error": "Internal server error while listing transactions"}), 500

# NEW ROUTE FOR UPDATING A TRANSACTION
@transaction_bp.route('/<string:transaction_id>', methods=['PUT'])
def update_transaction_route(transaction_id):
    data = request.get_json()
    if not data:
        return jsonify({"success": False, "error": "No update data provided"}), 400

    # TODO: Get authenticated user's ID from token instead of trusting client
    user_id_from_auth = data.get('userId') # Or extract from auth token
    if not user_id_from_auth:
        return jsonify({"success": False, "error": "User authentication required (userId missing)"}), 401


    print(f"PUT /api/transactions/{transaction_id} received data: {data} for user {user_id_from_auth}")
    try:
        result, status_code = TransactionService.update_transaction(transaction_id, user_id_from_auth, data)
        return jsonify(result), status_code
    except Exception as e:
        print(f"Unhandled exception in update_transaction_route for {transaction_id}: {e}")
        traceback.print_exc()
        return jsonify({"success": False, "error": "Internal server error while updating transaction"}), 500

# NEW ROUTE FOR DELETING A TRANSACTION (SOFT DELETE)
@transaction_bp.route('/<string:transaction_id>', methods=['DELETE'])
def delete_transaction_route(transaction_id):
    # TODO: Get authenticated user's ID from token
    user_id_from_auth = request.args.get('userId') # Or extract from auth token
    if not user_id_from_auth:
        return jsonify({"success": False, "error": "User authentication required (userId missing in query)"}), 401

    print(f"DELETE /api/transactions/{transaction_id} for user {user_id_from_auth}")
    try:
        result, status_code = TransactionService.delete_transaction(transaction_id, user_id_from_auth)
        return jsonify(result), status_code
    except Exception as e:
        print(f"Unhandled exception in delete_transaction_route for {transaction_id}: {e}")
        traceback.print_exc()
        return jsonify({"success": False, "error": "Internal server error while deleting transaction"}), 500