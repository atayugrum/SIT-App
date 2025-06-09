# File: flask_api/app/routes/investment_routes.py
from flask import Blueprint, request, jsonify
from app.services.investment_service import InvestmentService

investment_bp = Blueprint('investment_bp', __name__, url_prefix='/api/investments')

@investment_bp.route('/accounts', methods=['GET'])
def list_accounts_route():
    user_id = request.args.get('userId') 
    if not user_id: return jsonify({"success": False, "error": "Missing userId"}), 400
    result, status_code = InvestmentService.list_accounts(user_id)
    return jsonify(result), status_code

@investment_bp.route('/portfolio', methods=['GET'])
def get_portfolio_summary_route():
    user_id = request.args.get('userId')
    if not user_id: return jsonify({"success": False, "error": "Missing userId query parameter"}), 400
    result, status_code = InvestmentService.get_portfolio_summary(user_id)
    return jsonify(result), status_code

@investment_bp.route('/analysis/<string:symbol>', methods=['GET'])
def get_asset_analysis_route(symbol):
    if not symbol: return jsonify({"success": False, "error": "Asset symbol is required."}), 400
    result, status_code = InvestmentService.get_asset_analysis(symbol.upper())
    return jsonify(result), status_code

# --- İŞLEM (TRANSACTION) ROTALARI ---

@investment_bp.route('/transactions', methods=['POST'])
def create_transaction_route():
    data = request.get_json()
    if not data: return jsonify({"success": False, "error": "No data provided"}), 400
    result, status_code = InvestmentService.create_transaction(data)
    return jsonify(result), status_code

@investment_bp.route('/transactions', methods=['GET'])
def list_transactions_route():
    user_id = request.args.get('userId')
    if not user_id: return jsonify({"success": False, "error": "Missing userId parameter"}), 400
    
    # Opsiyonel filtreler
    account_id = request.args.get('accountId')
    asset_symbol = request.args.get('assetSymbol')
    
    result, status_code = InvestmentService.list_transactions(user_id, account_id, asset_symbol)
    return jsonify(result), status_code

@investment_bp.route('/transactions/<string:transaction_id>', methods=['PUT'])
def update_transaction_route(transaction_id):
    data = request.get_json()
    if not data: return jsonify({"success": False, "error": "No update data provided"}), 400
    result, status_code = InvestmentService.update_transaction(transaction_id, data)
    return jsonify(result), status_code

@investment_bp.route('/transactions/<string:transaction_id>', methods=['DELETE'])
def delete_transaction_route(transaction_id):
    result, status_code = InvestmentService.delete_transaction(transaction_id)
    return jsonify(result), status_code

# --- HOLDING (POZİSYON) ROTALARI ---
@investment_bp.route('/holdings/<string:holding_id>', methods=['DELETE'])
def delete_holding_route(holding_id):
    # Bu, bir pozisyonu tüm geçmişiyle siler
    result, status_code = InvestmentService.delete_holding(holding_id)
    return jsonify(result), status_code

@investment_bp.route('/holdings/<string:holding_id>', methods=['PUT'])
def override_holding_route(holding_id):
    """
    Bir varlığın tüm geçmişini silip, verilen yeni değerlerle
    tek bir işlem olarak yeniden oluşturur.
    """
    data = request.get_json()
    if not data:
        return jsonify({"success": False, "error": "No data provided"}), 400
        
    result, status_code = InvestmentService.override_holding(holding_id, data)
    return jsonify(result), status_code