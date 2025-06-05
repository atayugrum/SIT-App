# File: flask_api/app/routes/profile_routes.py
from flask import Blueprint, jsonify

profile_utility_bp = Blueprint('profile_utility_bp', __name__, url_prefix='/api/profile')

PROFILE_ICONS = [f"icon-{i}" for i in range(1, 11)] # icon-1, icon-2, ..., icon-10

@profile_utility_bp.route('/icons', methods=['GET'])
def get_profile_icons():
    print("GET /api/profile/icons route hit")
    icon_data = [{"id": icon_id} for icon_id in PROFILE_ICONS]
    return jsonify({"icons": icon_data}), 200