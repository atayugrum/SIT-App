# File: flask_api/app/utils/firebase_config.py

import firebase_admin
from firebase_admin import credentials, firestore
import os
import traceback

db = None
try:
    # --- RENDER'DA ÇALIŞACAK KISIM ---
    # Render, 'GOOGLE_APPLICATION_CREDENTIALS' değişkenini bizim için oluşturur.
    if 'GOOGLE_APPLICATION_CREDENTIALS' in os.environ:
        print("Firebase Admin SDK, Render ortam değişkeni ile başlatılıyor.")
        firebase_admin.initialize_app()
    
    # --- SİZİN BİLGİSAYARINIZDA ÇALIŞACAK KISIM ---
    else:
        print("Firebase Admin SDK, lokal anahtar dosyası ile başlatılıyor.")
        
        # === DEĞİŞTİRİLEN SATIR BURASI ===
        # Sizin verdiğiniz dosya yolu buraya eklendi.
        anahtar_dosya_yolu = r"C:\Users\atayu\Downloads\sit-app-project-firebase-adminsdk-fbsvc-45bdd56ea3.json"
        
        cred = credentials.Certificate(anahtar_dosya_yolu)
        firebase_admin.initialize_app(cred)
            
    db = firestore.client()
    print("Firebase Admin SDK başarıyla başlatıldı.")

except Exception as e:
    print(f"KRİTİK HATA: Firebase Admin SDK başlatılamadı: {e}")
    traceback.print_exc()