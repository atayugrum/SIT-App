# File: flask_api/app/routes/savings_routes.py
from flask import Blueprint, request, jsonify
from app.services.savings_service import SavingsService
import traceback
from datetime import datetime, timezone

savings_bp = Blueprint('savings_bp', __name__, url_prefix='/api/savings')

@savings_bp.route('/balance', methods=['GET'])
def get_savings_balance_route():
    user_id = request.args.get('userId')
    if not user_id:
        return jsonify({"success": False, "error": "Missing userId query parameter"}), 400

    print(f"GET /api/savings/balance for userId: {user_id}")
    try:
        result = SavingsService.get_user_savings_balance(user_id)
        return jsonify(result), 200 # Result already contains success flag
    except Exception as e:
        print(f"Unhandled exception in get_savings_balance_route for {user_id}: {e}")
        traceback.print_exc()
        return jsonify({"success": False, "error": f"Internal server error: {str(e)}"}), 500

@savings_bp.route('/allocations', methods=['GET'])
def list_savings_allocations_route():
    user_id = request.args.get('userId')
    if not user_id:
        return jsonify({"success": False, "error": "Missing userId query parameter"}), 400

    start_date_str = request.args.get('startDate') 
    end_date_str = request.args.get('endDate')   
    source_filter = request.args.get('source') 

    print(f"GET /api/savings/allocations for userId: {user_id}, start: {start_date_str}, end: {end_date_str}, source: {source_filter}")
    try:
        result = SavingsService.get_user_savings_allocations(user_id, start_date_str, end_date_str, source_filter)
        return jsonify(result), 200 # Result already contains success flag
    except Exception as e:
        print(f"Unhandled exception in list_savings_allocations_route for {user_id}: {e}")
        traceback.print_exc()
        return jsonify({"success": False, "error": f"Internal server error: {str(e)}"}), 500

@savings_bp.route('/allocations', methods=['POST']) # For manual savings
def add_manual_savings_allocation_route():
    data = request.get_json()
    if not data:
        return jsonify({"success": False, "error": "No data provided"}), 400

    user_id = data.get('userId') # In real app, get from auth token
    amount_raw = data.get('amount')
    date_str = data.get('date', datetime.now(timezone.utc).strftime('%Y-%m-%d'))

    if not user_id or amount_raw is None:
        return jsonify({"success": False, "error": "Missing userId or amount"}), 400

    try:
        amount_float = float(amount_raw)
    except ValueError:
        return jsonify({"success": False, "error": "Invalid amount format"}), 400

    print(f"POST /api/savings/allocations (manual) for user {user_id}, amount {amount_float}, date {date_str}")
    try:
        result = SavingsService.create_savings_allocation(
            user_id, 
            transaction_id=None, 
            amount=amount_float, 
            date_str=date_str, 
            source='manual'
        )
        if result.get("success"):
            return jsonify(result), 201 
        else:
            # If service method itself returns success:false, it might include a status code
            return jsonify(result), result.get("status_code", 400)
    except Exception as e:
        print(f"Unhandled exception in add_manual_savings_allocation_route: {e}")
        traceback.print_exc()
        return jsonify({"success": False, "error": f"Internal server error: {str(e)}"}), 500