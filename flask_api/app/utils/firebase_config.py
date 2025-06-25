# File: flask_api/app/utils/firebase_config.py

import firebase_admin
from firebase_admin import credentials, firestore
import os
import traceback

def initialize_firebase_admin():
    """
    Firebase Admin SDK'yı ortama duyarlı bir şekilde başlatır.
    Eğer zaten başlatılmışsa tekrar başlatmaz.
    Firestore client nesnesini döndürür.
    """
    try:
        # Eğer uygulama zaten başlatılmışsa tekrar başlatmayı deneme
        if not firebase_admin._apps:
            # Render'da bu ortam değişkeni dolu olacak
            if 'GOOGLE_APPLICATION_CREDENTIALS' in os.environ:
                print("Firebase Admin SDK, Render ortam değişkeni ile başlatılıyor.")
                firebase_admin.initialize_app()
            
            # Sizin bilgisayarınızda (lokalde) bu ortam değişkeni olmadığı için bu blok çalışacak.
            else:
                print("Firebase Admin SDK, lokal anahtar dosyası ile başlatılıyor.")
                anahtar_dosya_yolu = r"C:\Users\atayu\Downloads\sit-app-project-firebase-adminsdk-fbsvc-45bdd56ea3.json"
                cred = credentials.Certificate(anahtar_dosya_yolu)
                firebase_admin.initialize_app(cred)
        
        db_client = firestore.client()
        print("Firebase Admin SDK başarıyla başlatıldı ve Firestore client hazır.")
        return db_client

    except Exception as e:
        print(f"KRİTİK HATA: Firebase Admin SDK başlatılamadı: {e}")
        traceback.print_exc()
        return None

# Diğer servislerin doğrudan 'db' nesnesini import edebilmesi için, 
# bu modül ilk yüklendiğinde başlatma fonksiyonunu çağırıp db değişkenini ayarlıyoruz.
db = initialize_firebase_admin()