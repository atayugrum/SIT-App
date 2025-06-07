# File: flask_api/app/routes/ai_routes.py

from flask import Blueprint, request, jsonify
from app.services.ai_service import AIService 
# Eğer ai_service.py dosyanız yoksa, bu servisi de bir önceki adımlardaki gibi oluşturmalısınız.
# from app.utils.decorators import token_required # Varsa kullanabilirsiniz

# Blueprint'i tanımlarken tam URL ön ekini burada belirtiyoruz.
# Bu, __init__.py dosyasını daha temiz tutar.
ai_bp = Blueprint('ai_bp', __name__, url_prefix='/api/ai')

@ai_bp.route('/recommendations/budget', methods=['GET'])
# @token_required 
def get_budget_recommendation_route():
    """
    Belirli bir kategori için yapay zeka tabanlı bütçe önerisi sunar.
    Query params: userId, category
    """
    try:
        # Gerçek uygulamada @token_required decorator'ünden gelen kullanıcıyı almalısınız.
        # user_id = g.user['uid'] 
        user_id = request.args.get('userId')
        category = request.args.get('category')

        if not user_id or not category:
            return jsonify({"error": "userId ve category parametreleri zorunludur."}), 400

        # ai_service.py dosyasındaki servisi çağırıyoruz
        recommendation = AIService.get_budget_recommendation(user_id, category)
        
        return jsonify(recommendation), 200

    except Exception as e:
        return jsonify({"error": "Bütçe önerisi alınırken bir hata oluştu.", "details": str(e)}), 500


@ai_bp.route('/test', methods=['GET'])
def test_route():
    """Bu basit test rotası, blueprint'in doğru çalışıp çalışmadığını kontrol eder."""
    return jsonify({"message": "AI rotası /api/ai/test üzerinden başarıyla çalışıyor!"}), 200