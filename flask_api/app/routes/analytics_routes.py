# File: flask_api/app/routes/analytics_routes.py
from flask import Blueprint, request, jsonify
from app.services.analytics_service import AnalyticsService
from app.services.ai_service import AIService
from app.services.user_service import UserService
import traceback

analytics_bp = Blueprint('analytics_bp', __name__, url_prefix='/api/analytics')

@analytics_bp.route('/v2/dashboard', methods=['GET'])
def get_v2_dashboard_route():
    user_id = request.args.get('userId')
    period = request.args.get('period', 'this_month')
    if not user_id: 
        return jsonify({"success": False, "error": "Missing userId"}), 400
    
    try:
        historical_result, status_code = AnalyticsService.get_v2_analytics(user_id, period)
        if status_code != 200:
            return jsonify(historical_result), status_code
        
        historical_data = historical_result.get('data', {})
        data_span_days = historical_data.get('dataSpanDays', 0)
        ai_projections = {}

        if data_span_days >= 90:
            print(f"ANALYTICS_ROUTE: Yeterli veri ({data_span_days} gün). AI projeksiyonları oluşturuluyor.")
            user_profile_result = UserService.get_user_profile(user_id)
            risk_profile = user_profile_result.get("profile", {}).get("riskProfile", "medium")
            ai_projections = AIService.get_financial_forecast_and_recommendations(historical_data, risk_profile)
        else:
            print(f"ANALYTICS_ROUTE: Yetersiz veri ({data_span_days} gün). AI projeksiyonları atlanıyor.")
            ai_projections = {
                "spendingForecast": {"next30Days": 0, "analysis": ""},
                "savingsPotential": {"monthlyPotential": 0, "analysis": ""},
                "actionableTasks": []
            }
        
        final_data = {
            "historical": historical_data,
            "aiProjections": ai_projections
        }
        
        return jsonify({"success": True, "data": final_data}), 200

    except Exception as e:
        traceback.print_exc()
        return jsonify({"success": False, "error": str(e)}), 500

@analytics_bp.route('/category-comparison', methods=['GET'])
def get_category_comparison_route():
    user_id = request.args.get('userId')
    category = request.args.get('category', 'Tüm Harcamalar')
    if not user_id:
        return jsonify({"success": False, "error": "userId parametresi zorunludur"}), 400
    try:
        result, status_code = AnalyticsService.get_category_spending_comparison(user_id, category)
        return jsonify(result), status_code
    except Exception as e:
        traceback.print_exc()
        return jsonify({"success": False, "error": str(e)}), 500