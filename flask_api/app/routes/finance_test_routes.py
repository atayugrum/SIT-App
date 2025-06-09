# File: flask_api/app/routes/finance_test_routes.py
from flask import Blueprint, request, jsonify
from app.services.finance_test_service import FinanceTestService

finance_test_bp = Blueprint('finance_test_bp', __name__, url_prefix='/api/finance-tests')

@finance_test_bp.route('/items', methods=['GET'])
def get_test_items_route():
    result, status_code = FinanceTestService.get_all_test_items()
    return jsonify(result), status_code

@finance_test_bp.route('', methods=['POST'])
def start_test_route():
    data = request.get_json()
    if not data or 'userId' not in data:
        return jsonify({"success": False, "error": "userId is required"}), 400
    result, status_code = FinanceTestService.start_test(data['userId'])
    return jsonify(result), status_code

@finance_test_bp.route('/<string:test_id>/answers', methods=['POST'])
def submit_answers_route(test_id):
    data = request.get_json()
    if not data or 'userId' not in data or 'answers' not in data:
        return jsonify({"success": False, "error": "userId and answers are required"}), 400
    
    is_complete = data.get('isComplete', False)
    # DÜZELTME: result'ın tamamını jsonify ile döndürüyoruz.
    result, status_code = FinanceTestService.submit_answers(data['userId'], test_id, data['answers'], is_complete)
    return jsonify(result), status_code

# Diğer result ve last test rotaları da benzer şekilde bu dosyaya eklenebilir.