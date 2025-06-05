# File: flask_api/app/routes/analytics_routes.py
from flask import Blueprint, request, jsonify
from app.services.analytics_service import AnalyticsService
import traceback
from datetime import datetime

analytics_bp = Blueprint('analytics_bp', __name__, url_prefix='/api/insights')

@analytics_bp.route('/monthly-expense-summary', methods=['GET'])
def get_monthly_expense_summary_route():
    user_id = request.args.get('userId')
    year_str = request.args.get('year')
    month_str = request.args.get('month')

    if not user_id:
        return jsonify({"success": False, "error": "Missing userId query parameter"}), 400
    try:
        now = datetime.now()
        year = int(year_str) if year_str else now.year
        month = int(month_str) if month_str else now.month
        if not (1 <= month <= 12): return jsonify({"success": False, "error": "Invalid month"}), 400
    except ValueError: return jsonify({"success": False, "error": "Invalid year/month format"}), 400

    try:
        result, status_code = AnalyticsService.get_monthly_expense_summary(user_id, year, month)
        return jsonify(result), status_code
    except Exception as e:
        traceback.print_exc()
        return jsonify({"success": False, "error": f"Internal server error: {str(e)}"}), 500

@analytics_bp.route('/income-expense-analysis', methods=['GET'])
def get_income_expense_analysis_route():
    user_id = request.args.get('userId')
    year_str = request.args.get('year')
    month_str = request.args.get('month')
    if not user_id: return jsonify({"success": False, "error": "Missing userId"}), 400
    try:
        now = datetime.now()
        year = int(year_str) if year_str else now.year
        month = int(month_str) if month_str else now.month
        if not (1 <= month <= 12): return jsonify({"success": False, "error": "Invalid month"}), 400
    except ValueError: return jsonify({"success": False, "error": "Invalid year/month format"}), 400
        
    try:
        result, status_code = AnalyticsService.get_income_expense_analysis(user_id, year, month)
        return jsonify(result), status_code
    except Exception as e:
        traceback.print_exc()
        return jsonify({"success": False, "error": f"Internal server error: {str(e)}"}), 500

@analytics_bp.route('/trend', methods=['GET'])
def get_spending_trend_route():
    user_id = request.args.get('userId')
    period_param = request.args.get('period', '6m') 
    if not user_id: return jsonify({"success": False, "error": "Missing userId"}), 400
    if period_param not in ['1m', '3m', '6m']: return jsonify({"success": False, "error": "Invalid period. Use '1m', '3m', or '6m'."}), 400
    try:
        result, status_code = AnalyticsService.get_spending_trend(user_id, period_param)
        return jsonify(result), status_code
    except Exception as e:
        traceback.print_exc()
        return jsonify({"success": False, "error": f"Internal server error: {str(e)}"}), 500

@analytics_bp.route('/category-trend', methods=['GET'])
def get_category_trend_route():
    user_id = request.args.get('userId')
    start_date_str = request.args.get('startDate')
    end_date_str = request.args.get('endDate')
    if not user_id or not start_date_str or not end_date_str:
        return jsonify({"success": False, "error": "Missing userId, startDate, or endDate"}), 400
    try:
        datetime.strptime(start_date_str, '%Y-%m-%d')
        datetime.strptime(end_date_str, '%Y-%m-%d')
    except ValueError: return jsonify({"success": False, "error": "Invalid date format. Use YYYY-MM-DD."}), 400
    try:
        result, status_code = AnalyticsService.get_category_trend_data(user_id, start_date_str, end_date_str)
        return jsonify(result), status_code
    except Exception as e:
        traceback.print_exc()
        return jsonify({"success": False, "error": f"Internal server error: {str(e)}"}), 500

@analytics_bp.route('/budget-feedback', methods=['GET'])
def get_budget_feedback_route():
    user_id = request.args.get('userId')
    year_str = request.args.get('year')
    month_str = request.args.get('month')
    if not user_id: return jsonify({"success": False, "error": "Missing userId"}), 400
    try:
        now = datetime.now()
        year = int(year_str) if year_str else now.year
        month = int(month_str) if month_str else now.month
        if not (1 <= month <= 12): return jsonify({"success": False, "error": "Invalid month"}), 400
    except ValueError: return jsonify({"success": False, "error": "Invalid year/month format"}), 400
    try:
        result, status_code = AnalyticsService.get_budget_feedback(user_id, year, month)
        return jsonify(result), status_code
    except Exception as e:
        traceback.print_exc()
        return jsonify({"success": False, "error": f"Internal server error: {str(e)}"}), 500

@analytics_bp.route('/dashboard', methods=['GET'])
def get_dashboard_insights_route():
    user_id = request.args.get('userId')
    if not user_id: return jsonify({"success": False, "error": "Missing userId"}), 400
    try:
        result, status_code = AnalyticsService.get_dashboard_insights(user_id)
        return jsonify(result), status_code
    except Exception as e:
        traceback.print_exc()
        return jsonify({"success": False, "error": f"Internal server error: {str(e)}"}), 500