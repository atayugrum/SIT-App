# File: flask_api/app/routes/ai_routes.py
from flask import Blueprint, request, jsonify
from app.services.ai_service import AIService 

ai_bp = Blueprint('ai_bp', __name__, url_prefix='/api/ai')

@ai_bp.route('/parse-text', methods=['POST'])
def parse_text_route():
    data = request.get_json()
    if not data or 'text' not in data:
        return jsonify({"success": False, "error": "Lütfen 'text' alanını içeren bir JSON gönderin."}), 400
    try:
        result = AIService.parse_transaction_text(data['text'])
        return jsonify(result), 200
    except Exception as e:
        return jsonify({"success": False, "error": f"Metin işlenirken bir hata oluştu: {str(e)}"}), 500

@ai_bp.route('/recommendations/budget', methods=['GET'])
def get_budget_recommendation_route():
    user_id = request.args.get('userId')
    category = request.args.get('category')
    if not user_id or not category:
        return jsonify({"success": False, "error": "userId ve category parametreleri zorunludur."}), 400
    try:
        recommendation = AIService.get_budget_recommendation(user_id, category)
        return jsonify(recommendation), 200
    except Exception as e:
        return jsonify({"success": False, "error": f"Bütçe önerisi alınırken bir hata oluştu: {str(e)}"}), 500

@ai_bp.route('/indicator-info/<string:indicator_key>', methods=['GET'])
def get_indicator_info_route(indicator_key):
    current_value_str = request.args.get('value')
    current_value = float(current_value_str) if current_value_str else None
    
    explanation = AIService.get_indicator_explanation(indicator_key.upper(), current_value)
    return jsonify({"success": True, "explanation": explanation}), 200