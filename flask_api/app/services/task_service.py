# File: flask_api/app/services/task_service.py
from app.utils.firebase_config import db
from datetime import datetime, timezone
from google.cloud.firestore_v1.base_query import FieldFilter
import traceback
import uuid

class TaskService:
    @staticmethod
    def _get_tasks_collection():
        return db.collection('user_tasks')

    @staticmethod
    def list_active_tasks(user_id):
        try:
            query = (TaskService._get_tasks_collection()
                     .where(filter=FieldFilter("userId", "==", user_id))
                     .where(filter=FieldFilter("isCompleted", "==", False))
                     .order_by("createdAt"))
            
            docs = query.stream()
            tasks = [{'id': doc.id, **doc.to_dict()} for doc in docs]
            return {"success": True, "tasks": tasks}, 200
        except Exception as e:
            traceback.print_exc()
            return {"success": False, "error": str(e)}, 500

    @staticmethod
    def add_task(user_id, task_description):
        try:
            # Kullanıcının mevcut aktif görev sayısını kontrol et
            active_tasks_result, _ = TaskService.list_active_tasks(user_id)
            if not active_tasks_result.get("success"):
                return active_tasks_result, 500
            
            if len(active_tasks_result.get("tasks", [])) >= 3:
                return {"success": False, "error": "Maksimum aktif görev sayısına ulaştınız (3)."}, 400

            task_id = str(uuid.uuid4())
            task_ref = TaskService._get_tasks_collection().document(task_id)
            
            task_data = {
                "userId": user_id,
                "description": task_description,
                "isCompleted": False,
                "createdAt": datetime.now(timezone.utc).isoformat(),
                "completedAt": None
            }
            
            task_ref.set(task_data)
            task_data['id'] = task_id
            
            return {"success": True, "message": "Görev başarıyla eklendi.", "task": task_data}, 201

        except Exception as e:
            traceback.print_exc()
            return {"success": False, "error": str(e)}, 500

    @staticmethod
    def complete_task(user_id, task_id):
        try:
            task_ref = TaskService._get_tasks_collection().document(task_id)
            task_doc = task_ref.get()

            if not task_doc.exists or task_doc.to_dict().get('userId') != user_id:
                return {"success": False, "error": "Görev bulunamadı veya yetkiniz yok."}, 404

            task_ref.update({
                "isCompleted": True,
                "completedAt": datetime.now(timezone.utc).isoformat()
            })
            
            return {"success": True, "message": "Görev tamamlandı olarak işaretlendi."}, 200
        except Exception as e:
            traceback.print_exc()
            return {"success": False, "error": str(e)}, 500