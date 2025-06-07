# File: flask_api/app/routes/savings_routes.py
from flask import Blueprint, request, jsonify
from app.services.savings_service import SavingsService, InsufficientFundsError
import traceback
from datetime import datetime, timezone

savings_bp = Blueprint('savings_bp', __name__, url_prefix='/api/savings')

@savings_bp.route('/balance', methods=['GET'])
def get_savings_balance_route():
    user_id = request.args.get('userId')
    if not user_id:
        return jsonify({"success": False, "error": "Missing userId query parameter"}), 400

    try:
        result = SavingsService.get_user_savings_balance(user_id)
        return jsonify(result), 200
    except Exception as e:
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

    try:
        result = SavingsService.get_user_savings_allocations(user_id, start_date_str, end_date_str, source_filter)
        return jsonify(result), 200
    except Exception as e:
        traceback.print_exc()
        return jsonify({"success": False, "error": f"Internal server error: {str(e)}"}), 500

@savings_bp.route('/allocations', methods=['POST'])
def add_manual_savings_allocation_route():
    data = request.get_json()
    if not data:
        return jsonify({"success": False, "error": "No data provided"}), 400

    user_id = data.get('userId')
    amount_raw = data.get('amount')
    date_str = data.get('date', datetime.now(timezone.utc).strftime('%Y-%m-%d'))

    if not user_id or amount_raw is None:
        return jsonify({"success": False, "error": "Missing userId or amount"}), 400

    try:
        amount_float = float(amount_raw)
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
            return jsonify(result), result.get("status_code", 400)
    except ValueError:
        return jsonify({"success": False, "error": "Invalid amount format"}), 400
    except Exception as e:
        traceback.print_exc()
        return jsonify({"success": False, "error": f"Internal server error: {str(e)}"}), 500

# =========================================================
# TASARRUF HEDEFLERİ ROTALARI
# =========================================================

@savings_bp.route('/goals', methods=['POST'])
def create_goal_route():
    data = request.get_json()
    if not data or 'userId' not in data:
        return jsonify({"success": False, "error": "Missing data or userId"}), 400
    
    result, status_code = SavingsService.create_goal(data)
    return jsonify(result), status_code

@savings_bp.route('/goals', methods=['GET'])
def list_goals_route():
    user_id = request.args.get('userId')
    if not user_id:
        return jsonify({"success": False, "error": "Missing userId query parameter"}), 400
    
    result, status_code = SavingsService.list_goals(user_id)
    return jsonify(result), status_code

@savings_bp.route('/goals/<goal_id>', methods=['DELETE'])
def delete_goal_route(goal_id):
    user_id = request.args.get('userId') # Auth token'dan alınmalı
    if not user_id:
        return jsonify({"success": False, "error": "Missing userId for authorization"}), 400

    result, status_code = SavingsService.delete_goal(user_id, goal_id)
    return jsonify(result), status_code

@savings_bp.route('/goals/<goal_id>/allocate', methods=['POST'])
def allocate_to_goal_route(goal_id):
    data = request.get_json()
    user_id = data.get('userId') # Auth token'dan alınmalı
    amount = data.get('amount')
    
    if not user_id or not amount:
        return jsonify({"success": False, "error": "Missing userId or amount"}), 400
    
    try:
        result, status_code = SavingsService.allocate_to_goal(user_id, goal_id, float(amount))
        return jsonify(result), status_code
    except ValueError:
        return jsonify({"success": False, "error": "Invalid amount format"}), 400
    except Exception as e:
        return jsonify({"success": False, "error": f"An unexpected error occurred: {str(e)}"}), 500