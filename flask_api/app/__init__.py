# File: flask_api/app/__init__.py

from flask import Flask
from flask_cors import CORS
from .utils.firebase_config import initialize_firebase_admin
import os

def create_app():
    # Firebase'i başlat
    try:
        if not initialize_firebase_admin(): 
            print("Firebase Admin SDK zaten başlatılmış.")
        else:
            print("Firebase Admin SDK başlatıldı.")
    except Exception as e:
        print(f"KRİTİK HATA: Firebase Admin SDK başlatılamadı: {e}")

    app = Flask(__name__)
    
    # CORS ayarları
    CORS(app, resources={r"/api/*": {"origins": "*"}}) 

    # --- Blueprint Kayıtları ---
    from .routes.user_routes import user_bp
    from .routes.profile_routes import profile_utility_bp
    from .routes.transaction_routes import transaction_bp
    from .routes.account_routes import account_bp
    from .routes.category_routes import category_bp
    from .routes.savings_routes import savings_bp
    from .routes.budget_routes import budget_bp
    from .routes.analytics_routes import analytics_bp
    from .routes.ai_routes import ai_bp # AI blueprint'i import ediliyor

    # Diğer blueprint'leri olduğu gibi kaydedin (url_prefix olmadan)
    app.register_blueprint(user_bp)
    app.register_blueprint(profile_utility_bp)
    app.register_blueprint(transaction_bp)
    app.register_blueprint(account_bp)
    app.register_blueprint(category_bp)
    app.register_blueprint(savings_bp)
    app.register_blueprint(budget_bp)
    app.register_blueprint(analytics_bp)
    
    # DÜZELTİLMİŞ KISIM: ai_bp'yi url_prefix OLMADAN kaydedin
    app.register_blueprint(ai_bp)
    
    @app.route('/hello')
    def hello():
        return "Hello from SIT App Flask API!"

    print("Flask uygulaması oluşturuldu ve tüm blueprint'ler kaydedildi.")
    return app