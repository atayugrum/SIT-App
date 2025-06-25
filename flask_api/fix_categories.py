# File: flask_api/fix_categories.py

import os
# DÜZELTME: Modülün kendisini import ediyoruz
from app.utils import firebase_config
# Kategori yapısını ai_service'den import ediyoruz
from app.services.ai_service import CATEGORY_STRUCTURE

def run_fix():
    """
    Veritabanındaki hatalı 'category' alanlarını düzeltir.
    """
    # DÜZELTME: Fonksiyonu modül üzerinden çağırıyoruz
    firebase_config.initialize_firebase_admin()
    
    # DÜZELTME: db değişkenine modül üzerinden erişiyoruz
    if not firebase_config.db:
        print("HATA: Firestore client (db) alınamadı. İşlem durduruldu.")
        return
    
    print("Firebase Admin SDK başarıyla bağlandı.")

    # Alt kategoriden ana kategoriyi bulmak için bir harita oluşturalım.
    sub_to_main_map = {}
    for main_type, main_categories in CATEGORY_STRUCTURE.items():
        for main_cat, sub_cats in main_categories.items():
            for sub_cat in sub_cats:
                sub_to_main_map[sub_cat] = main_cat
    
    # DÜZELTME: db değişkenine modül üzerinden erişiyoruz
    transactions_ref = firebase_config.db.collection('transactions')
    all_transactions = list(transactions_ref.stream())
    
    docs_to_update = []
    
    print(f"Toplam {len(all_transactions)} işlem kontrol ediliyor...")

    for doc in all_transactions:
        data = doc.to_dict()
        category = data.get('category')
        subcategory = data.get('subCategory')
        
        # Eğer kategori genel bir isimse ('expense' veya 'income') VE bir alt kategori varsa
        if category and category.lower() in ['expense', 'income'] and subcategory:
            correct_main_category = sub_to_main_map.get(subcategory)
            
            if correct_main_category and correct_main_category != category:
                docs_to_update.append({
                    'ref': doc.reference,
                    'old_cat': category,
                    'new_cat': correct_main_category,
                    'sub_cat': subcategory
                })

    if not docs_to_update:
        print("Tüm kategoriler doğru görünüyor. Düzeltilecek bir işlem bulunamadı.")
        return

    print("\n----------------------------------------------------")
    print(f"Toplam {len(docs_to_update)} işlemde kategori hatası tespit edildi.")
    print("Aşağıdaki değişiklikler yapılacak:")
    for item in docs_to_update:
        print(f" - '{item['sub_cat']}' için kategori '{item['old_cat']}' -> '{item['new_cat']}' olarak güncellenecek.")
    print("----------------------------------------------------\n")

    confirmation = input("Yukarıdaki değişiklikleri onaylıyor musunuz? (evet/hayır): ")
    if confirmation.lower() != 'evet':
        print("İşlem kullanıcı tarafından iptal edildi.")
        return

    # DÜZELTME: db değişkenine modül üzerinden erişiyoruz
    batch = firebase_config.db.batch()
    for item in docs_to_update:
        batch.update(item['ref'], {'category': item['new_cat']})
    
    batch.commit()
    print(f"\nBaşarılı! {len(docs_to_update)} adet işlem güncellendi.")


if __name__ == '__main__':
    run_fix()