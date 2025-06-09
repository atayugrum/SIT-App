# File: flask_api/app/services/finance_test_service.py
from app.utils.firebase_config import db
from datetime import datetime, timezone
import traceback

class FinanceTestService:
    @staticmethod
    def start_test(user_id):
        try:
            test_ref = db.collection('Users').document(user_id).collection('FinanceTests').document()
            test_data = {'userId': user_id, 'startedAt': datetime.now(timezone.utc).isoformat(), 'completedAt': None}
            test_ref.set(test_data)
            return {"success": True, "testId": test_ref.id}, 200
        except Exception as e:
            traceback.print_exc()
            return {"success": False, "error": str(e)}, 500

    @staticmethod
    def get_all_test_items():
        try:
            items_ref = db.collection('FinanceTestItems')
            docs = items_ref.stream()
            items = [doc.to_dict() for doc in docs]
            return {"success": True, "items": items}, 200
        except Exception as e:
            traceback.print_exc()
            return {"success": False, "error": str(e)}, 500

    @staticmethod
    def submit_answers(user_id, test_id, answers, is_complete):
        try:
            test_ref = db.collection('Users').document(user_id).collection('FinanceTests').document(test_id)
            batch = db.batch()
            for answer in answers:
                answer_ref = test_ref.collection('answers').document(answer['itemId'])
                batch.set(answer_ref, {'selectedChoice': answer['selectedChoice']})
            
            if is_complete:
                batch.update(test_ref, {'completedAt': datetime.now(timezone.utc).isoformat()})
            
            batch.commit()

            if is_complete:
                scores_saved, results_data = FinanceTestService.calculate_and_save_scores(user_id, test_id)
                if scores_saved:
                    return {"success": True, "message": "Test completed and scores calculated.", "results": results_data}, 200
                else:
                    return {"success": False, "error": "Scores could not be calculated."}, 500
            
            return {"success": True, "message": "Answers submitted."}, 200
        except Exception as e:
            traceback.print_exc()
            return {"success": False, "error": str(e)}, 500

    @staticmethod
    def get_test_results(user_id, test_id):
        try:
            test_ref = db.collection('Users').document(user_id).collection('FinanceTests').document(test_id)
            doc = test_ref.get()
            if doc.exists:
                return {"success": True, "results": doc.to_dict()}, 200
            else:
                return {"success": False, "error": "Test results not found."}, 404
        except Exception as e:
            traceback.print_exc()
            return {"success": False, "error": str(e)}, 500

    @staticmethod
    def calculate_and_save_scores(user_id, test_id):
        try:
            items_docs = db.collection('FinanceTestItems').stream()
            items_map = {doc.id: doc.to_dict() for doc in items_docs}
            answers_ref = db.collection('Users').document(user_id).collection('FinanceTests').document(test_id).collection('answers')
            answers_docs = answers_ref.stream()
            answers_map = {doc.id: doc.to_dict() for doc in answers_docs}
            
            raw_scores = {'FO': [], 'FWB': [], 'RT': [], 'FCAP': []}
            scale_max_scores = {'FO': 0, 'FWB': 0, 'RT': 0, 'FCAP': 0}
            
            for item_id, item_data in items_map.items():
                scale = item_data['scale']
                user_answer = answers_map.get(item_id)
                score = 0
                max_score_for_item = 1 if scale == 'FO' else (7 if scale == 'RT' else 5)
                
                if user_answer:
                    choice = user_answer['selectedChoice']
                    if scale == 'FO':
                        if choice == item_data.get('correctChoice'): score = 1
                    else:
                        score = int(choice) if choice.isdigit() else 0
                    if item_data.get('reverseScored', False):
                        score = (max_score_for_item + 1) - score
                
                raw_scores[scale].append(score)
                scale_max_scores[scale] += max_score_for_item
            
            normalized_scores = {}
            for scale, scores_list in raw_scores.items():
                raw_sum = sum(scores_list)
                max_possible = scale_max_scores[scale]
                min_possible = len(scores_list) if scale != 'FO' else 0
                if scale == 'FO': min_possible = 0
                
                norm_score = 0
                if (max_possible - min_possible) > 0:
                    norm_score = ((raw_sum - min_possible) / (max_possible - min_possible)) * 100
                normalized_scores[f"{scale.lower()}Score"] = round(norm_score, 2)
            
            total_score = sum(normalized_scores.values()) / len(normalized_scores)
            normalized_scores['totalScore'] = round(total_score, 2)
            
            rt_score = normalized_scores.get('rtScore', 50)
            risk_profile = 'medium'
            if rt_score <= 40: risk_profile = 'low'
            elif rt_score >= 70: risk_profile = 'high'
            
            test_ref = db.collection('Users').document(user_id).collection('FinanceTests').document(test_id)
            test_ref.update(normalized_scores)
            
            user_ref = db.collection('Users').document(user_id)
            user_ref.set({'riskProfile': risk_profile}, merge=True)
            
            print(f"Scores calculated and saved for test {test_id}. Risk profile set to: {risk_profile}")
            
            final_data = test_ref.get().to_dict()
            return True, final_data
        except Exception as e:
            print(f"Error calculating scores for test {test_id}: {e}")
            traceback.print_exc()
            return False, None