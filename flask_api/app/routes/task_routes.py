# File: flask_api/app/routes/task_routes.py
from flask import Blueprint, request, jsonify
from app.services.task_service import TaskService
import traceback

task_bp = Blueprint('task_bp', __name__, url_prefix='/api/tasks')

@task_bp.route('', methods=['GET'])
def get_tasks_route():
    user_id = request.args.get('userId')
    if not user_id:
        return jsonify({"success": False, "error": "userId parametresi zorunlu."}), 400
    
    result, status_code = TaskService.list_active_tasks(user_id)
    return jsonify(result), status_code

@task_bp.route('', methods=['POST'])
def add_task_route():
    data = request.get_json()
    user_id = data.get('userId')
    description = data.get('description')
    
    if not user_id or not description:
        return jsonify({"success": False, "error": "userId ve description zorunludur."}), 400
        
    result, status_code = TaskService.add_task(user_id, description)
    return jsonify(result), status_code

@task_bp.route('/<string:task_id>/complete', methods=['PUT'])
def complete_task_route(task_id):
    data = request.get_json()
    user_id = data.get('userId') # Normalde auth token'dan alınır
    if not user_id:
        return jsonify({"success": False, "error": "userId zorunludur."}), 400

    result, status_code = TaskService.complete_task(user_id, task_id)
    return jsonify(result), status_code