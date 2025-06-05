# File: flask_api/app/__init__.py
from flask import Flask
from flask_cors import CORS
from .utils.firebase_config import initialize_firebase_admin
import os

def create_app():
    try:
        if not initialize_firebase_admin(): 
             print("Firebase Admin SDK already initialized or initialize_firebase_admin handles its own print.")
        else:
             print("Firebase Admin SDK explicitly initialized from create_app.")
    except Exception as e:
        print(f"CRITICAL: Firebase Admin SDK failed to initialize during app creation: {e}")

    app = Flask(__name__)

    CORS(app, resources={r"/api/*": {"origins": "*"}}) 

    from .routes.user_routes import user_bp
    from .routes.profile_routes import profile_utility_bp
    from .routes.transaction_routes import transaction_bp
    from .routes.account_routes import account_bp
    from .routes.category_routes import category_bp
    from .routes.savings_routes import savings_bp
    from .routes.budget_routes import budget_bp # <-- IMPORT NEW BUDGET BLUEPRINT

    app.register_blueprint(user_bp)
    app.register_blueprint(profile_utility_bp)
    app.register_blueprint(transaction_bp)
    app.register_blueprint(account_bp)
    app.register_blueprint(category_bp)
    app.register_blueprint(savings_bp)
    app.register_blueprint(budget_bp) # <-- REGISTER NEW BUDGET BLUEPRINT

    @app.route('/hello')
    def hello():
        return "Hello from SIT App Flask API! Now with budget routes!"

    print("Flask app created and all blueprints registered.")
    return app