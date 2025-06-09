# File: flask_api/app/routes/analytics_routes.py
from flask import Blueprint, request, jsonify
from app.services.analytics_service import AnalyticsService

analytics_bp = Blueprint('analytics_bp', __name__, url_prefix='/api/analytics')

@analytics_bp.route('/dashboard', methods=['GET'])
def get_dashboard_insights_route():
    user_id = request.args.get('userId')
    if not user_id: 
        return jsonify({"success": False, "error": "Missing userId"}), 400
    
    days = int(request.args.get('days', 30))
    
    result, status_code = AnalyticsService.get_dashboard_insights(user_id, days)
    return jsonify(result), status_code