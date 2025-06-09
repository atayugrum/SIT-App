# File: flask_api/app/services/ai_service.py

import re
import os
import json
from datetime import datetime, timezone
import google.generativeai as genai
from dotenv import load_dotenv

load_dotenv()

try:
    GEMINI_API_KEY = os.getenv('GEMINI_API_KEY')
    if not GEMINI_API_KEY:
        raise ValueError("GEMINI_API_KEY ortam değişkeni bulunamadı.")
    
    genai.configure(api_key=GEMINI_API_KEY)
    
    generation_config = genai.types.GenerationConfig(
        max_output_tokens=1024, # JSON listesi için token limitini biraz artıralım
        response_mime_type="application/json",
        temperature=0.2
    )
    
    llm_model = genai.GenerativeModel(
        'gemini-1.5-flash',
        generation_config=generation_config
    )
    print("AI_SERVICE: Google Gemini API (gemini-1.5-flash) başarıyla yapılandırıldı.")

except Exception as e:
    print(f"KRİTİK HATA: Google Gemini API yapılandırılamadı. Hata: {e}")
    llm_model = None


class AIService:
    @staticmethod
    def _get_category_from_llm(chunk: str):
        if not llm_model:
            print("AI_SERVICE_LLM: Model yapılandırılmadığı için varsayılan kategori kullanılıyor.")
            return {"kategori": "Diğer", "tip": "expense"}

        CATEGORIES = [
            "Market", "Yemek/Restoran", "Kahve", "Ulaşım", "Fatura", 
            "Kira Gideri", "Giyim", "Eğlence", "Sağlık", "Eğitim", "Maaş", 
            "Freelance", "Ek Gelir", "Kira Geliri", "Diğer Gelir", "Diğer"
        ]
        
        prompt = f"""
        Bir finansal işlem metnini analiz et. Bu metnin bir 'gelir' mi yoksa 'gider' mi olduğunu belirle. 
        Ardından, aşağıdaki listeden en uygun kategoriyi seç.
        Yanıtını SADECE bir JSON objesi olarak şu formatta ver: {{"kategori": "SeçilenKategori", "tip": "gelir_veya_gider"}}.

        Kategori Listesi: {CATEGORIES}
        
        İşlem Metni: "{chunk}"
        """
        
        try:
            response = llm_model.generate_content(prompt)
            data = json.loads(response.text)
            
            kategori = data.get("kategori", "Diğer")
            tip = data.get("tip", "expense")

            return {
                "kategori": kategori if kategori in CATEGORIES else "Diğer",
                "tip": "income" if tip == "gelir" else "expense"
            }
        except Exception as e:
            print(f"AI_SERVICE_LLM: Metin işlenirken hata oluştu ('{chunk}'). Hata: {e}")
            return {"kategori": "Diğer", "tip": "expense"}

    @staticmethod
    def parse_transaction_text(text: str):
        chunks = text.lower().split(',')
        parsed_transactions = []

        for chunk in chunks:
            chunk = chunk.strip()
            if not chunk: continue

            amount_match = re.search(r'(\d+\.?\d*)', chunk)
            if not amount_match: continue
            
            amount = float(amount_match.group(1))

            llm_result = AIService._get_category_from_llm(chunk)
            
            parsed_transactions.append({
                'amount': amount,
                'category': llm_result['kategori'],
                'type': llm_result['tip'],
                'description': chunk.capitalize(),
                'date': datetime.now(timezone.utc).strftime('%Y-%m-%d'),
            })

        return {"success": True, "parsedTransactions": parsed_transactions}