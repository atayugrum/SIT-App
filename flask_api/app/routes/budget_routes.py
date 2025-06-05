# File: flask_api/app/routes/budget_routes.py
from flask import Blueprint, request, jsonify
from app.services.budget_service import BudgetService
import traceback
from datetime import datetime # For default year/month

budget_bp = Blueprint('budget_bp', __name__, url_prefix='/api/budgets')

@budget_bp.route('', methods=['GET'])
def list_budgets_route():
    user_id = request.args.get('userId')
    if not user_id:
        return jsonify({"success": False, "error": "Missing userId query parameter"}), 400

    try:
        year_str = request.args.get('year')
        month_str = request.args.get('month')

        year = int(year_str) if year_str else None
        month = int(month_str) if month_str else None

    except ValueError:
        return jsonify({"success": False, "error": "Invalid year or month format"}), 400

    print(f"GET /api/budgets for userId: {user_id}, year: {year}, month: {month}")
    try:
        result, status_code = BudgetService.list_budgets(user_id, year, month)
        return jsonify(result), status_code
    except Exception as e:
        print(f"Unhandled exception in list_budgets_route: {e}")
        traceback.print_exc()
        return jsonify({"success": False, "error": "Internal server error"}), 500

@budget_bp.route('', methods=['POST'])
def add_or_update_budget_route():
    data = request.get_json()
    if not data:
        return jsonify({"success": False, "error": "No data provided"}), 400

    # Assuming userId is in data for now. In production, get from auth token.
    if 'userId' not in data:
        return jsonify({"success": False, "error": "userId is required in payload"}), 400

    print(f"POST /api/budgets received data: {data}")
    try:
        result, status_code = BudgetService.create_or_update_budget(data)
        return jsonify(result), status_code
    except Exception as e:
        print(f"Unhandled exception in add_or_update_budget_route: {e}")
        traceback.print_exc()
        return jsonify({"success": False, "error": "Internal server error"}), 500

@budget_bp.route('/<string:budget_id>', methods=['PUT'])
def update_specific_budget_route(budget_id):
    data = request.get_json()
    if not data:
        return jsonify({"success": False, "error": "No update data provided"}), 400

    # For PUT on a specific budget_id, usually only limitAmount and maybe isAuto would change.
    # Assuming userId comes from auth. For now, if passed in data, use it for service layer auth check.
    user_id_from_auth = data.get('userId') # Placeholder for actual auth token user ID extraction
    if not user_id_from_auth: # Should be obtained from an auth token
         return jsonify({"success": False, "error": "User authentication required"}), 401

    # We need to ensure the service method only updates allowed fields
    # The BudgetService.create_or_update_budget is more like an upsert.
    # For a dedicated PUT, we might want a more specific update method in service or adapt.
    # For now, let's re-purpose create_or_update_budget by ensuring ID is handled.
    # This requires the frontend to know if it's creating or updating.
    # A better PUT would just take the fields to update and the budget_id.
    # Let's assume the client will send the full budget object for simplicity for now,
    # and our service handles it as an update if the ID matches.
    # However, a true PUT to /<budget_id> usually implies only that budget_id's document.
    # The create_or_update_budget checks for existence by userId, category, period, year, month.
    # This PUT route might need its own service method: update_budget_by_id(budget_id, user_id, data_to_update)

    # Let's use a more direct update for now, assuming the payload only contains updatable fields
    # and `category_service.py`'s update_category had a better pattern.
    # We'll adapt the update method from category_service.py for budget_service.py
    # For now, this route will be a placeholder or needs BudgetService.update_budget_by_id.

    # For this iteration, since create_or_update_budget handles updates based on composite key,
    # a specific PUT /<budget_id> route needs a more refined service method.
    # Let's make this PUT route call a new service method designed for updating by ID.
    # This requires adding 'update_budget_by_id' to BudgetService.
    # For now, will comment out and use POST for both create/update via create_or_update_budget service method.

    # print(f"PUT /api/budgets/{budget_id} for user {user_id_from_auth} with data: {data}")
    # try:
    #     # result, status_code = BudgetService.update_budget_by_id(user_id_from_auth, budget_id, data)
    #     # return jsonify(result), status_code
    #     return jsonify({"success": False, "error": "PUT method for specific ID not fully implemented yet. Use POST to upsert."}), 501
    # except Exception as e:
    #     # ...
    #     return jsonify({"success": False, "error": "Internal server error"}), 500
    return jsonify({"success": False, "error": "PUT /api/budgets/<id> not fully implemented. Use POST /api/budgets to create/update."}), 501


@budget_bp.route('/<string:budget_id>', methods=['DELETE'])
def delete_budget_route(budget_id):
    user_id_from_auth = request.args.get('userId') # Get from auth token in production
    if not user_id_from_auth:
        return jsonify({"success": False, "error": "User authentication required"}), 401

    print(f"DELETE /api/budgets/{budget_id} for user {user_id_from_auth}")
    try:
        result, status_code = BudgetService.delete_budget(user_id_from_auth, budget_id)
        return jsonify(result), status_code
    except Exception as e:
        print(f"Unhandled exception in delete_budget_route for {budget_id}: {e}")
        traceback.print_exc()
        return jsonify({"success": False, "error": "Internal server error"}), 500