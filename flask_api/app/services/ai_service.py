# File: flask_api/app/services/ai_service.py
import re
import os
import json
import traceback
from datetime import datetime, timezone, timedelta
import google.generativeai as genai
from dotenv import load_dotenv
from app.utils.firebase_config import db
from google.cloud.firestore_v1.base_query import FieldFilter

load_dotenv()

# TÜM VERİLERİ İÇEREN, TAM VE NİHAİ REFERANS VERİ SETİ
COST_OF_LIVING_DATA = {
    "turkey_genel": {
        "Yemek/Restoran": {
            "uygun_restoran_yemek": {"price": 350.00, "desc": "Ucuz Restoran Yemeği (Tek Kişi)"},
            "orta_segment_restoran_2kisilik": {"price": 1500.00, "desc": "Orta Sınıf Restoran (İki Kişilik, Üç Çeşit)"},
            "mc_menu": {"price": 310.00, "desc": "Mc Donald's Menüsü"}
        },
        "Market": {
            "sut_1L": {"price": 39.60, "desc": "Süt (1 Litre)"},
            "ekmek_500gr": {"price": 30.65, "desc": "Beyaz Ekmek (500gr)"},
            "pirinc_1kg": {"price": 86.46, "desc": "Pirinç (1kg)"},
            "yumurta_12li": {"price": 90.25, "desc": "Yumurta (12'li)"},
            "yerli_peynir_1kg": {"price": 387.59, "desc": "Yerli Peynir (1kg)"},
            "tavuk_fileto_1kg": {"price": 228.49, "desc": "Tavuk Fileto (1kg)"},
            "kirmizi_et_1kg": {"price": 765.50, "desc": "Kırmızı Et (1kg Bonfile)"},
            "elma_1kg": {"price": 53.96, "desc": "Elma (1kg)"},
            "muz_1kg": {"price": 88.27, "desc": "Muz (1kg)"},
            "portakal_1kg": {"price": 47.28, "desc": "Portakal (1kg)"},
            "domates_1kg": {"price": 59.09, "desc": "Domates (1kg)"},
            "patates_1kg": {"price": 29.28, "desc": "Patates (1kg)"},
            "sogan_1kg": {"price": 23.66, "desc": "Soğan (1kg)"},
            "marul_1adet": {"price": 40.08, "desc": "Marul (1 Adet)"},
            "su_1.5L": {"price": 19.43, "desc": "Su (1.5 Litre)"}
        },
        "Ulaşım": {
            "tek_yon_bilet": {"price": 27.00, "desc": "Tek Yön Toplu Taşıma Bileti"},
            "aylik_kart": {"price": 1800.00, "desc": "Aylık Toplu Taşıma Kartı"},
            "taksi_acilisi": {"price": 42.00, "desc": "Taksi Açılış Ücreti"},
            "taksi_km": {"price": 28.00, "desc": "Taksi Km Ücreti"},
            "benzin_1L": {"price": 47.16, "desc": "Benzin (1 Litre)"}
        },
        "Fatura": {
            "temel_giderler_85m2": {"price": 2741.72, "desc": "Temel Giderler (Elektrik, Su, Isınma, Çöp)"},
            "cep_telefonu_aylik": {"price": 427.29, "desc": "Cep Telefonu Faturası (Aylık)"},
            "internet_aylik": {"price": 545.19, "desc": "İnternet Faturası (Aylık)"}
        },
        "Eğlence": {
            "fitness_aylik": {"price": 1964.77, "desc": "Fitness Kulübü (Aylık)"},
            "tenis_kortu_1saat": {"price": 705.41, "desc": "Tenis Kortu Kirası (1 Saat)"},
            "sinema_bileti": {"price": 250.00, "desc": "Sinema Bileti (1 Kişi)"}
        },
        "Giyim": {
            "kot_pantolon": {"price": 2129.81, "desc": "Kot Pantolon (Levis 501 veya Benzeri)"},
            "yazlik_elbise": {"price": 1728.59, "desc": "Yazlık Elbise (Zara, H&M vb.)"},
            "spor_ayakkabi": {"price": 4179.16, "desc": "Spor Ayakkabı (Nike vb.)"},
            "deri_ayakkabi": {"price": 3791.84, "desc": "Erkek Deri Ayakkabı"}
        },
        "Kira Gideri": {
            "merkezde_1oda": {"price": 25189.77, "desc": "Merkezde 1 Odalı Daire Kirası"},
            "merkez_disi_1oda": {"price": 17876.85, "desc": "Merkez Dışı 1 Odalı Daire Kirası"},
            "merkezde_3oda": {"price": 45689.66, "desc": "Merkezde 3 Odalı Daire Kirası"},
            "merkez_disi_3oda": {"price": 28554.75, "desc": "Merkez Dışı 3 Odalı Daire Kirası"}
        }
    },
    "istanbul": {
        "Yemek/Restoran": {
            "uygun_restoran_yemek": {"price": 450.00, "desc": "Ucuz Restoran Yemeği (Tek Kişi)"},
            "orta_segment_restoran_2kisilik": {"price": 2000.00, "desc": "Orta Sınıf Restoran (İki Kişilik, Üç Çeşit)"},
            "mc_menu": {"price": 300.00, "desc": "Mc Donald's Menüsü"}
        },
        "Market": {
            "sut_1L": {"price": 42.77, "desc": "Süt (1 Litre)"},
            "ekmek_500gr": {"price": 31.17, "desc": "Beyaz Ekmek (500gr)"},
            "pirinc_1kg": {"price": 88.36, "desc": "Pirinç (1kg)"},
            "yumurta_12li": {"price": 104.73, "desc": "Yumurta (12'li)"},
            "yerli_peynir_1kg": {"price": 404.34, "desc": "Yerli Peynir (1kg)"},
            "tavuk_fileto_1kg": {"price": 258.99, "desc": "Tavuk Fileto (1kg)"},
            "kirmizi_et_1kg": {"price": 783.11, "desc": "Kırmızı Et (1kg Bonfile)"},
            "elma_1kg": {"price": 58.31, "desc": "Elma (1kg)"},
            "muz_1kg": {"price": 87.81, "desc": "Muz (1kg)"},
            "portakal_1kg": {"price": 51.46, "desc": "Portakal (1kg)"},
            "domates_1kg": {"price": 63.51, "desc": "Domates (1kg)"},
            "patates_1kg": {"price": 28.71, "desc": "Patates (1kg)"},
            "sogan_1kg": {"price": 27.64, "desc": "Soğan (1kg)"},
            "marul_1adet": {"price": 45.31, "desc": "Marul (1 Adet)"},
            "su_1.5L": {"price": 23.80, "desc": "Su (1.5 Litre)"}
        },
        "Ulaşım": {
            "tek_yon_bilet": {"price": 27.00, "desc": "Tek Yön Toplu Taşıma Bileti"},
            "aylik_kart": {"price": 2120.00, "desc": "Aylık Toplu Taşıma Kartı"},
            "taksi_acilisi": {"price": 40.50, "desc": "Taksi Açılış Ücreti"},
            "taksi_km": {"price": 28.00, "desc": "Taksi Km Ücreti"},
            "benzin_1L": {"price": 46.46, "desc": "Benzin (1 Litre)"}
        },
        "Fatura": {
            "temel_giderler_85m2": {"price": 2863.93, "desc": "Temel Giderler (Elektrik, Su, Isınma, Çöp)"},
            "cep_telefonu_aylik": {"price": 484.90, "desc": "Cep Telefonu Faturası (Aylık)"},
            "internet_aylik": {"price": 585.20, "desc": "İnternet Faturası (Aylık)"}
        },
        "Eğlence": {
            "fitness_aylik": {"price": 2418.15, "desc": "Fitness Kulübü (Aylık)"},
            "tenis_kortu_1saat": {"price": 733.66, "desc": "Tenis Kortu Kirası (1 Saat)"},
            "sinema_bileti": {"price": 300.00, "desc": "Sinema Bileti (1 Kişi)"}
        },
        "Giyim": {
            "kot_pantolon": {"price": 2215.86, "desc": "Kot Pantolon (Levis 501 veya Benzeri)"},
            "yazlik_elbise": {"price": 1836.32, "desc": "Yazlık Elbise (Zara, H&M vb.)"},
            "spor_ayakkabi": {"price": 4453.85, "desc": "Spor Ayakkabı (Nike vb.)"},
            "deri_ayakkabi": {"price": 4172.50, "desc": "Erkek Deri Ayakkabı"}
        },
        "Kira Gideri": {
            "merkezde_1oda": {"price": 37918.79, "desc": "Merkezde 1 Odalı Daire Kirası"},
            "merkez_disi_1oda": {"price": 24382.35, "desc": "Merkez Dışı 1 Odalı Daire Kirası"},
            "merkezde_3oda": {"price": 69772.52, "desc": "Merkezde 3 Odalı Daire Kirası"},
            "merkez_disi_3oda": {"price": 41303.28, "desc": "Merkez Dışı 3 Odalı Daire Kirası"}
        }
    }
}

CATEGORY_STRUCTURE = {
    "expense": {
        'Ev & Faturalar': ['Kira Gideri', 'Aidat', 'Elektrik Faturası', 'Su Faturası', 'Doğalgaz & Isınma', 'İnternet Faturası', 'Cep Telefonu Faturası', 'Dijital Abonelikler (Netflix, Spotify vb.)', 'Ev Eşyası & Tadilat'],
        'Market & Gıda': ['Süpermarket Alışverişi', 'Restoran & Kafe', 'Kahve Dükkanları', 'Dışarıdan Sipariş (Yemeksepeti, Getir vb.)', 'Fırın & Pastane'],
        'Ulaşım': ['Toplu Taşıma (Aylık Akbil/Kart)', 'Tek Bilet & Dolum', 'Taksi', 'Yakıt (Benzin/Dizel)', 'Araç Bakım & Sigorta', 'Park & Otoyol Ücretleri'],
        'Kişisel Bakım': ['Kozmetik & Cilt Bakımı', 'Kuaför & Berber', 'Kişisel Hijyen Ürünleri'],
        'Sağlık & Spor': ['İlaç & Vitamin', 'Doktor & Muayene Ücreti', 'Diş Hekimi', 'Spor Salonu Üyeliği', 'Spor Malzemeleri'],
        'Eğlence & Sosyal Yaşam': ['Sinema, Tiyatro, Konser', 'Hobi & Aktiviteler', 'Kitap & Dergi', 'Tatil & Seyahat', 'Barlar & Gece Hayatı'],
        'Giyim & Aksesuar': ['Kıyafet', 'Ayakkabı', 'Aksesuar & Çanta', 'Kuru Temizleme'],
        'Finansal Giderler': ['Kredi Kartı Borcu Ödemesi', 'Kredi Taksiti Ödemesi', 'Banka Masrafları (EFT, Havale vb.)', 'Vergiler'],
        'Diğer': ['Evcil Hayvan Masrafları', 'Hediye', 'Bağış', 'Eğitim & Kurslar', 'Diğer Harcamalar']
    },
    "income": {
        'Maaş & Hak Edişler': ['Aylık Maaş', 'Prim & Bonus', 'Fazla Mesai', 'Serbest Meslek (Freelance)'],
        'Yatırım Gelirleri': ['Faiz Geliri (Mevduat vb.)', 'Temettü (Dividend)', 'Hisse Senedi Satış Karı', 'Kripto Varlık Satış Karı', 'Kira Geliri'],
        'Ek Gelirler': ['Satılan Eşya (Letgo, Dolap vb.)', 'Hediye & Burs', 'Vergi İadesi', 'Diğer Ek Gelirler']
    }
}


class AIService:
    llm_model = None
    generation_config = {}
    try:
        GEMINI_API_KEY = os.getenv('GEMINI_API_KEY')
        if not GEMINI_API_KEY:
            raise ValueError("GEMINI_API_KEY ortam değişkeni bulunamadı.")

        genai.configure(api_key=GEMINI_API_KEY)

        generation_config = genai.types.GenerationConfig(
            max_output_tokens=2048,
            response_mime_type="application/json",
            temperature=0.5
        )

        llm_model = genai.GenerativeModel(
            'gemini-1.5-flash',
            generation_config=generation_config
        )
        print("AI_SERVICE: Google Gemini API başarıyla yapılandırıldı.")

    except Exception as e:
        print(f"KRİTİK HATA: Google Gemini API yapılandırılamadı. Hata: {e}")

    GENERATION_TIMEOUT = 30
    
    @staticmethod
    def get_budget_recommendation(user_id: str, category: str):
        if not AIService.llm_model: return {"success": False, "error": "AI Service not available"}, 503
        try:
            transactions_ref = db.collection('transactions')

            # YENİ KURAL: Kullanıcının en az 90 günlük verisi var mı diye kontrol et
            first_tx_query = transactions_ref.where(filter=FieldFilter("userId", "==", user_id)).where(filter=FieldFilter("isDeleted", "==", False)).order_by("date").limit(1).stream()
            first_tx_doc = next(iter(first_tx_query), None)
            
            if not first_tx_doc:
                raise Exception("Size özel bir öneri için henüz hiç işlem veriniz bulunmuyor.")

            first_date = datetime.strptime(first_tx_doc.to_dict()['date'], '%Y-%m-%d').replace(tzinfo=timezone.utc)
            if (datetime.now(timezone.utc) - first_date).days < 90:
                raise Exception("Size özel bir bütçe önerebilmemiz için en az 90 günlük harcama verisi gereklidir.")

            end_date, start_date = datetime.now(timezone.utc), datetime.now(timezone.utc) - timedelta(days=90)
            query = (transactions_ref.where(filter=FieldFilter("userId", "==", user_id)).where(filter=FieldFilter("category", "==", category)).where(filter=FieldFilter("type", "==", "expense")).where(filter=FieldFilter("date", ">=", start_date.strftime('%Y-%m-%d'))).where(filter=FieldFilter("date", "<=", end_date.strftime('%Y-%m-%d'))).where(filter=FieldFilter("isDeleted", "==", False)))
            docs = list(query.stream())
            
            if not docs: return {"suggestedBudget": 100, "rationale": f"'{category}' kategorisinde son 3 ayda hiç harcama bulunamadı. Genel bir başlangıç bütçesi olarak 100 TL düşünebilirsiniz.", "transactionCount": 0}

            total_spending, wants_spending, needs_spending, emotion_counts = 0.0, 0.0, 0.0, {}
            for doc in docs:
                transaction = doc.to_dict()
                amount = float(transaction.get('amount', 0))
                total_spending += amount
                if not transaction.get("isNeed", True): wants_spending += amount
                else: needs_spending += amount
                emotion = transaction.get("emotion")
                if emotion: emotion_counts[emotion] = emotion_counts.get(emotion, 0) + 1
            
            tx_count, monthly_avg = len(docs), total_spending / 3
            benchmark_data_istanbul = COST_OF_LIVING_DATA.get("istanbul", {}).get(category)
            benchmark_data_tr = COST_OF_LIVING_DATA.get("turkey_genel", {}).get(category)
            benchmark_info = ""
            if benchmark_data_istanbul: benchmark_info += f"- İstanbul Referans Verileri: {json.dumps(benchmark_data_istanbul, ensure_ascii=False)}\n"
            if benchmark_data_tr: benchmark_info += f"- Türkiye Geneli Referans Verileri: {json.dumps(benchmark_data_tr, ensure_ascii=False)}"

            # GÜNCELLENMİŞ VE DAHA AKILLI PROMPT
            prompt = f"""
            Sen, kullanıcının harcama alışkanlıklarını analiz ederek onlara mantıklı ve ulaşılabilir bütçe hedefleri sunan bir finansal danışmansın.

            KULLANICI VERİLERİ ('{category}' kategorisi, son 90 gün):
            - Kullanıcının Aylık Ortalama Harcaması: {monthly_avg:.2f} TL
            - Harcama Tipi Dökümü: İhtiyaç: {needs_spending:.2f} TL, İstek: {wants_spending:.2f} TL
            - Harcama Anındaki Duygu Yoğunluğu: {json.dumps(emotion_counts, ensure_ascii=False)}

            REFERANS VERİLER:
            {benchmark_info}

            GÖREV:
            Aşağıdaki senaryolara göre bir bütçe önerisi ve gerekçesi oluştur:
            1.  **Eğer kullanıcının aylık ortalaması, referans değerlerin (İstanbul veya Türkiye) belirgin şekilde ALTINDAYSA:** Bu durumu olumlu bir geri bildirim olarak belirt. Kullanıcıyı tebrik et ve mevcut harcama seviyesini koruması veya hafifçe artırması için bir bütçe öner. (Örn: ortalaması 150 TL ise, 150 TL veya 200 TL gibi). ASLA mevcut harcamasından daha düşük bir bütçe önerme.
            2.  **Eğer kullanıcının aylık ortalaması, referans değerlerin belirgin şekilde ÜZERİNDEYSE:** Bütçeyi referans değere yaklaştıracak mantıklı bir kesinti öner. Harcama 'İstek' odaklı ise veya 'Suçlu' gibi olumsuz duygular içeriyorsa bu kesinti daha cesur olabilir.
            3.  **Eğer kullanıcının harcaması referans değerlere YAKINSA:** Bu tutarlılığı öv ve bütçeyi bu seviyede tutmasını öner.

            Önerdiğin bütçeyi en yakın anlamlı sayıya yuvarla (örn: 1845 -> 1850). Gerekçen net, ikna edici ve yaptığın analizi yansıtmalı.
            
            Cevabını aşağıdaki JSON formatında ver:
            {{
              "suggestedBudget": <sayısal_bütçe_miktarı_integer>,
              "rationale": "<Bu bütçeyi neden önerdiğine dair, yukarıdaki senaryolara uygun, analitik ve kişiselleştirilmiş gerekçe>",
              "transactionCount": {tx_count}
            }}
            """
            
            response = AIService.llm_model.generate_content(prompt, request_options={'timeout': AIService.GENERATION_TIMEOUT})
            clean_response_text = re.sub(r'```json\s*|\s*```', '', response.text.strip())
            data = json.loads(clean_response_text)
            return data
        except Exception as e:
            traceback.print_exc()
            raise Exception(f"Bütçe önerisi alınamadı: {str(e)}")

    @staticmethod
    def get_financial_forecast_and_recommendations(user_financial_data: dict, risk_profile: str):
        if not AIService.llm_model: raise Exception("AI model is not available.")
        income_summary = user_financial_data.get('incomeExpenseSummary', {})
        needs_wants_summary = user_financial_data.get('needsVsWantsSummary', {})
        category_summary = user_financial_data.get('categorySummary', [])
        top_category = category_summary[0] if category_summary else {}
        
        budget_alerts = [f"{c['category']} (Bütçe: {c['budgetLimit']:.0f} TL, Kullanım: %{((c.get('budgetUsage', 0) or 0) * 100):.0f})" for c in category_summary if c.get('budgetUsage') is not None and c['budgetUsage'] > 0.8]
        income_change, expense_change = income_summary.get('incomeChangePercent'), income_summary.get('expenseChangePercent')
        income_change_str = f"{income_change:.1f}%" if income_change is not None else "Değişim Yok"
        expense_change_str = f"{expense_change:.1f}%" if expense_change is not None else "Değişim Yok"
        
        varied_config = genai.types.GenerationConfig(
            max_output_tokens=AIService.generation_config.max_output_tokens,
            response_mime_type=AIService.generation_config.response_mime_type,
            temperature=0.7
        )

        prompt = f"""
        Sen, 'SIT App' adlı bir kişisel finans uygulamasının içindeki bir yapay zeka asistanısın. Görevin, kullanıcıya kendi verilerine dayanarak kişiselleştirilmiş, uygulanabilir ve sayısal hedefler sunmaktır.

        ## KESİN KURALLAR:
        1.  Tüm metin çıktıların ('analysis', 'task' vb.) **tamamen Türkçe** olmalıdır.
        2.  ASLA başka bir uygulama, excel tablosu veya harici bir araç kullanmasını önerme.
        3.  ASLA "harcamalarınıza dikkat edin", "tasarruf yapın" gibi genel geçer, soyut tavsiyeler verme.
        4.  Kullanıcının risk profili '{risk_profile}'. Tavsiyelerinin tonunu buna göre ayarla.

        ## ANALİZ EDİLECEK VERİLER:
        - Analiz Periyodu: {json.dumps(user_financial_data.get('period', {}))}
        - Toplam Gelir: {income_summary.get('incomeTotal', 0):.2f} TRY (Önceki döneme göre değişim: {income_change_str})
        - Toplam Gider: {income_summary.get('expenseTotal', 0):.2f} TRY (Önceki döneme göre değişim: {expense_change_str})
        - Harcama Dağılımı (İhtiyaçlar/İstekler): {json.dumps(needs_wants_summary)}
        - En Çok Harcama Yapılan Kategori: {json.dumps(top_category)}
        - Bütçe Aşımına Yaklaşan Kategoriler: {json.dumps(budget_alerts) if budget_alerts else "Yok"}

        ## İSTENEN ÇIKTI (JSON FORMATINDA):
        Bu verilere göre aşağıdaki JSON yapısını doldur. "analysis" ve "task" alanlarındaki metinler yukarıdaki kurallara harfiyen uymalıdır.
        {{
          "spendingForecast": {{"next30Days": {income_summary.get('expenseTotal', 0)}, "analysis": "<Gelecek dönem harcama tahminiyle ilgili kısa, Türkçe bir analiz yazısı>"}},
          "savingsPotential": {{"monthlyPotential": {income_summary.get('net', 0)}, "analysis": "<Tasarruf potansiyeliyle ilgili kısa, Türkçe bir analiz yazısı>"}},
          "actionableTasks": [ 
            // Görev 1: En yüksek harcama yapılan kategoriye odaklan. Miktar bazlı bir hedef ver.
            // Örnek: "'{top_category.get('category', 'En Yüksek Harcama')}' kategorisine bu dönem {top_category.get('totalAmount', 0):.2f} TL harcadınız. Gelecek dönem bu harcamayı X TL seviyesinde tutmayı hedefleyebilirsiniz."
            {{"task": "<1. Görev>"}},
            
            // Görev 2: 'İstekler' harcamasına odaklan. Miktar bazlı bir hedef ver.
            // Örnek: "Bu dönem 'İstekler' için toplam {needs_wants_summary.get('wantsTotal', 0):.2f} TL harcadınız. Gelecek dönem için kendinize X TL gibi bir 'istek bütçesi' belirleyin."
            {{"task": "<2. Görev>"}},
            
            // Görev 3: Bütçesi zorlanan bir kategoriye odaklan veya ilginç bir içgörü sun.
            // Örnek: "'Fatura' bütçenizin %95'ini doldurdunuz. Beklenmedik bir artışa karşı dikkatli olun." veya "En çok 'Mutlu' hissederken harcama yapıyorsunuz. Bu harcamaları gözden geçirin."
            {{"task": "<3. Görev>"}},
            
            {{"task": "<4. Tamamen Türkçe, miktar bazlı ve uygulanabilir görev>"}},
            {{"task": "<5. Tamamen Türkçe, miktar bazlı ve uygulanabilir görev>"}},
            {{"task": "<6. Tamamen Türkçe, miktar bazlı ve uygulanabilir görev>"}}
          ]
        }}
        """
        try:
            print("AI_SERVICE: Gelişmiş finansal tahmin ve tavsiye için LLM çağrısı yapılıyor...")
            response = AIService.llm_model.generate_content(prompt, generation_config=varied_config, request_options={'timeout': 45})
            clean_response_text = re.sub(r'```json\s*|\s*```', '', response.text.strip())
            data = json.loads(clean_response_text)
            
            # JSON içindeki her task objesine 'isCompleted' anahtarını ekleyelim
            for task_item in data.get("actionableTasks", []):
                task_item["isCompleted"] = False

            print("AI_SERVICE: LLM'den son yanıt başarıyla alındı.")
            return data
        except Exception as e:
            traceback.print_exc()
            return {"spendingForecast": {"next30Days": 0.0, "analysis": "Tahmin verisi işlenirken bir hata oluştu."}, "savingsPotential": {"monthlyPotential": 0.0, "analysis": "Tasarruf potansiyeli hesaplanamadı."}, "actionableTasks": [{"task": "Analiz alınamadı. Lütfen daha sonra tekrar deneyin.", "isCompleted": False}]}
        
    @staticmethod
    def generate_dynamic_analysis_comment(indicators: dict, horizon: str, symbol: str, risk_profile: str):
        try:
            model = AIService.llm_model
            prompt = f"""
            Sen bir finansal analistsin. Risk profili '{risk_profile}' olan bir kullanıcıya {symbol} adlı varlığın {horizon} teknik durumunu **Türkçe** olarak anlat. 
            Aşağıdaki verilere dayanarak, kullanıcının risk profiline uygun, kolay anlaşılır ve profesyonel bir analiz yorumu yaz. Yorumun tamamen Türkçe olsun.
            Veriler: {json.dumps(indicators)}
            """
            response = model.generate_content(prompt, request_options={'timeout': AIService.GENERATION_TIMEOUT})
            return response.text.strip()
        except Exception as e:
            print(f"AI_SERVICE(generate_dynamic_analysis_comment) HATA: {e}")
            return "Kişiselleştirilmiş analiz yorumu üretilirken bir hata oluştu."

    @staticmethod
    def get_indicator_explanation(indicator_key: str, current_value: float | None = None):
        try:
            model = AIService.llm_model
            value_prompt_part = ""
            if current_value is not None:
                value_prompt_part = f"Ayrıca, bu varlığın mevcut {indicator_key} değerinin {current_value:.2f} olduğunu göz önünde bulundurarak, bu spesifik değerin şu anki durum için ne anlama gelebileceğini Türkçe yorumla."
            prompt = f"""
            Bir yatırım acemisine {indicator_key} göstergesinin ne olduğunu ve ne işe yaradığını çok basit terimlerle Türkçe açıkla.
            {value_prompt_part}
            Cevabını kısa ve net tut.
            """
            response = model.generate_content(prompt, request_options={'timeout': AIService.GENERATION_TIMEOUT})
            return response.text.strip()
        except Exception as e:
            print(f"AI_SERVICE(get_indicator_explanation) HATA: {e}")
            return f"{indicator_key} için açıklama alınamadı."

    @staticmethod
    def find_opportunities_for_user(assets_data: list, user_profile: dict, horizon: str):
        try:
            model = AIService.llm_model
            prompt = f"""
            Sen, kişiye özel yatırım danışmanlığı yapan bir yapay zeka asistanısın.
            KULLANICI PROFİLİ: {json.dumps(user_profile)}
            PİYASA VERİLERİ ({len(assets_data)} varlık): {json.dumps(assets_data)}
            İSTEK:
            1. Kullanıcının risk profilini ve vade tercihini ({horizon}) dikkate alarak, piyasa verileri içinden en uygun 3 ila 5 varlığı seç.
            2. Seçtiğin her varlık için, 'reason' alanını Türkçe olacak şekilde şu formatta bir JSON objesi oluştur: {{"symbol": "VARLIK_SEMBOLÜ", "reason": "Neden uygun olduğuna dair kişisel ve Türkçe gerekçe.", "matchScore": "1-10 arası uygunluk puanı (integer)."}}
            3. Tüm sonuçları bir JSON dizisi içinde döndür.
            """
            response = model.generate_content(prompt, request_options={'timeout': 100})
            return json.loads(response.text)
        except Exception as e:
            print(f"AI_SERVICE(find_opportunities_for_user) HATA: {e}")
            traceback.print_exc()
            return {"error": "Fırsatlar analiz edilirken bir hata oluştu."}

    @staticmethod
    def parse_transaction_text(text: str):
        if not text.strip():
            return {"success": True, "parsedTransactions": []}
        if not AIService.llm_model:
            return {"success": False, "error": "AI Service not available"}, 503

        try:
            today = datetime.now(timezone.utc)
            today_date_str = today.strftime('%Y-%m-%d')
            current_year = today.year

            # --- YENİ: Alt kategoriden ana kategoriyi bulmak için bir harita oluşturalım ---
            # Bu, her seferinde tüm yapıyı aramak yerine hızlı bir arama sağlar.
            sub_to_main_map = {}
            for main_type, main_categories in CATEGORY_STRUCTURE.items():
                for main_cat, sub_cats in main_categories.items():
                    for sub_cat in sub_cats:
                        sub_to_main_map[sub_cat] = main_cat
            # --- YENİ KISIM SONU ---

            prompt = f"""
            Aşağıdaki metinde virgülle ayrılmış finansal işlemleri analiz et. Her işlem için miktar, tip ('gelir' veya 'gider'), tarih, ana kategori ve alt kategori belirle.

            ## KATEGORİ ve ALT KATEGORİ YAPISI:
            İşlemleri sınıflandırırken sadece aşağıdaki JSON yapısını kullan. Metindeki ifadeye en uygun ana kategoriyi ve ardından o ana kategoriye ait alt kategoriyi seç. Eğer uygun bir alt kategori yoksa, "subCategory" değeri null olsun.
            {json.dumps(CATEGORY_STRUCTURE, ensure_ascii=False)}

            ## TARİH KURALLARI:
            - "dün" gibi ifadeleri bugünün tarihine ({today_date_str}) göre hesapla. "15 mayıs" gibi ifadeler için yılı {current_year} olarak varsay.
            - Çıktıdaki tüm tarihleri "YYYY-AA-GG" formatında ver.

            ## ÇIKTI FORMATI:
            Cevabını, her bir işlem için bir obje içeren bir JSON dizisi olarak döndür.
            Format: [{{"amount": <sayı>, "category": "<ana_kategori>", "subCategory": "<alt_kategori_veya_null>", "type": "<tip>", "description": "<orijinal_metin>", "date": "<YYYY-AA-GG>"}}]
            
            ## İŞLENECEK METİN:
            "{text}"
            """

            config = genai.types.GenerationConfig(
                max_output_tokens=2048, 
                response_mime_type="application/json", 
                temperature=0.1
            )

            response = AIService.llm_model.generate_content(prompt, generation_config=config, request_options={'timeout': 40})
            parsed_data = json.loads(response.text)

            final_transactions = []
            for item in parsed_data:
                ai_category = item.get('category')
                ai_subcategory = item.get('subCategory')

                # --- YENİ: AKILLI DÜZELTME ADIMI ---
                # Eğer AI, ana kategori olarak 'expense' veya 'income' gibi genel bir tip döndürdüyse
                # ve bir alt kategori bulduysa, doğru ana kategoriyi biz bulalım.
                if ai_category and ai_category.lower() in ['income', 'expense'] and ai_subcategory:
                    correct_main_category = sub_to_main_map.get(ai_subcategory)
                    if correct_main_category:
                        print(f"Düzeltme: AI kategori olarak '{ai_category}' dedi, ancak '{ai_subcategory}' alt kategorisi '{correct_main_category}' kategorisine ait. Veri düzeltiliyor.")
                        item['category'] = correct_main_category # Hatalı veriyi doğru ana kategoriyle değiştir!
                # --- AKILLI DÜZELTME SONU ---

                # Gelir/Gider tipini belirleme mantığı (bu zaten düzeltilmişti, aynı kalıyor)
                category_from_ai = item.get('category')
                type_from_ai = item.get('type') or item.get('tip')
                
                if (type_from_ai == 'gelir') or \
                   (category_from_ai and category_from_ai.lower() == 'income') or \
                   (category_from_ai and category_from_ai in CATEGORY_STRUCTURE['income']):
                    item['type'] = 'income'
                else:
                    item['type'] = 'expense'
                
                try:
                    datetime.strptime(item.get('date', ''), '%Y-%m-%d')
                except (ValueError, TypeError):
                    item['date'] = today_date_str
                
                if 'subCategory' not in item:
                    item['subCategory'] = None
                
                final_transactions.append(item)

            return {"success": True, "parsedTransactions": final_transactions}
        except Exception as e:
            traceback.print_exc()
            return {"success": False, "error": f"Toplu metin işlenirken bir hata oluştu: {str(e)}"}, 500

